import Foundation
import CoreBluetooth

let MEEBLUE_MAIN_SERVICE = CBUUID(string: "D35B1000-E01C-9FAC-BA8D-7CE20BDBA0C6")
let MEEBLUE_MAIN_AUTHENTICATION = CBUUID(string: "D35B1001-E01C-9FAC-BA8D-7CE20BDBA0C6")
let MEEBLUE_MAIN_BEACON_STATE = CBUUID(string: "D35B1002-E01C-9FAC-BA8D-7CE20BDBA0C6")
let MEEBLUE_MAIN_DEVICE_NAME = CBUUID(string: "D35B1003-E01C-9FAC-BA8D-7CE20BDBA0C6")

let MEEBLUE_CLOSE_SERVICE = CBUUID(string: "D35B6000-E01C-9FAC-BA8D-7CE20BDBA0C6")
let MEEBLUE_CLOSE_STATE = CBUUID(string: "D35B6001-E01C-9FAC-BA8D-7CE20BDBA0C6")
let MEEBLUE_CLOSE_DATA = CBUUID(string: "D35B6002-E01C-9FAC-BA8D-7CE20BDBA0C6")
let MEEBLUE_CLOSE_WHITE_LIST = CBUUID(string: "D35B6003-E01C-9FAC-BA8D-7CE20BDBA0C6")

class BTManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var manager: CBCentralManager!
    var device: CBPeripheral?
    
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
        if central.state == .poweredOn {
            scan()
        }
    }
    
    func scan() {
        manager.scanForPeripherals(withServices: [CBUUID(string: "EA70")], options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered device...")
        print(peripheral)
        print(advertisementData)
        
        if let connectable = advertisementData["kCBAdvDataIsConnectable"] as? Int, connectable == 1 {
            central.stopScan()
            device = peripheral
            connect(to: peripheral)
        }
    }
    
    func connect(to device: CBPeripheral) {
        print("Connecting...")
        device.delegate = self
        manager.connect(device, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Did connect...")
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect...")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services = peripheral.services!
        
        services.forEach { service in
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    var hasAuthed: Bool = false
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard hasAuthed == false else { return }
        if let char = findCharacteristicfromUUID(in: peripheral, service: MEEBLUE_MAIN_SERVICE, characteristic: MEEBLUE_MAIN_AUTHENTICATION) {
            print("Authenticating")
            hasAuthed = true
            peripheral.setNotifyValue(true, for: char)
            peripheral.writeValue(
                "imeeble".data(using: .utf8)!,
                for: char,
                type: .withResponse
            )
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print(characteristic.value)
        print(error)
        
        if error == nil, characteristic.uuid == MEEBLUE_MAIN_AUTHENTICATION {
            if let char = findCharacteristicfromUUID(in: peripheral, service: MEEBLUE_MAIN_SERVICE, characteristic: MEEBLUE_MAIN_DEVICE_NAME) {
                print(String(data: char.value!, encoding: .utf8))
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let characteristicData = characteristic.value else { return }
        
        print(String(data: characteristicData, encoding: .utf8))
    }
    
    func findCharacteristicfromUUID(in peripheral: CBPeripheral, service: CBUUID, characteristic: CBUUID) -> CBCharacteristic? {
        guard let service = peripheral.services?.first(where: { $0.uuid == service }) else { return nil }
        guard let  characteristic = service.characteristics?.first(where: { $0.uuid == characteristic }) else { return nil }
        
        return characteristic
    }
}

let manager = BTManager()

RunLoop.main.run()

