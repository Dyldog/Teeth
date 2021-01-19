import Foundation
import CoreBluetooth
import SwiftyBluetooth

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
        
        print("Discovering")
        
        discover { devices in
            print("Found \(devices.count) devices")
            devices.forEach { device in
                print("Connecting to \(device.identifier)...")
                self.connect(to: device) { didAuth in
                    
                    if didAuth {
                        print("Authenticated")
                        print("Reading device name...")
                        self.readValue(
                            from: device,
                            service: "D35B1000-E01C-9FAC-BA8D-7CE20BDBA0C6",
                            characteristic: "D35B1003-E01C-9FAC-BA8D-7CE20BDBA0C6") { data in
                            print("Device name:")
                            print(String(data: data, encoding: .utf8)!)
                        }
                    } else {
                        print("Failed to authenticate")
                    }
                }
            }
        }
//        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: [CBUUID(string: "EA70")], timeoutAfter: 5) { result in
//            switch result {
//            case let .scanResult(peripheral, advertisementData, RSSI):
//                peripheral.connect(withTimeout: 5) { result in
//                    peripheral.writeValue(
//                        ofCharacWithUUID: "D35B1001-E01C-9FAC-BA8D-7CE20BDBA0C6",
//                        fromServiceWithUUID: "D35B1000-E01C-9FAC-BA8D-7CE20BDBA0C6",
//                        value: "imeeble".data(using: .utf8)!) { result in
//                        print(result)
//
//                        peripheral.readValue(
//                            ofCharacWithUUID: "D35B1003-E01C-9FAC-BA8D-7CE20BDBA0C6",
//                            fromServiceWithUUID: "D35B1000-E01C-9FAC-BA8D-7CE20BDBA0C6") { result in
//                            if let data = try? result.get() {
//                                print(String(data: data, encoding: .utf8))
//                            }
//                        }
//                    }
//                }
//            default:
//                break
//            }
//        }
    }
    
    func discover(completion: @escaping ([Peripheral]) -> Void) {
        var devices: [Peripheral] = []
        SwiftyBluetooth.scanForPeripherals(withServiceUUIDs: [CBUUID(string: "EA70")], timeoutAfter: 10) { result in
            switch result {
            case let .scanResult(peripheral, advertisementData, RSSI):
                guard devices.contains(where: { $0.identifier == peripheral.identifier }) == false,
                      let connectable = advertisementData["kCBAdvDataIsConnectable"] as? Int else { break }
                if connectable == 1 {
                    devices.append(peripheral)
                    SwiftyBluetooth.Central.sharedInstance.stopScan()
                }
            case let .scanStopped(peripherals, error):
                completion(devices)
            default:
                break
            }
        }
    }
    
    func connect(to device: Peripheral, completion: @escaping (Bool) -> Void) {
        device.connect(withTimeout: nil) { result in
            switch result {
            case .success:
                self.authenticate(device: device, completion: completion)
            case .failure(let error):
                print(error)
                completion(false)
            }
            
        }
    }
    
    private func authenticate(device: Peripheral, completion: @escaping (Bool) -> Void) {
        device.writeValue(
            ofCharacWithUUID: "D35B1001-E01C-9FAC-BA8D-7CE20BDBA0C6",
            fromServiceWithUUID: "D35B1000-E01C-9FAC-BA8D-7CE20BDBA0C6",
            value: "imeeble".data(using: .utf8)!) { result in
            
            do {
                try result.get()
                completion(true)
            } catch {
                print(error)
                completion(false)
            }
        }
    }
    
    func readValue(from device: Peripheral, service: String, characteristic: String, completion: @escaping (Data) -> Void) {
        device.readValue(
            ofCharacWithUUID: characteristic,
            fromServiceWithUUID: service) { result in
            if let data = try? result.get() {
                completion(data)
            }
        }
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
            connect(to: peripheral, completion: { device in
                
            })
        }
    }
        
    var connectCompletions: [UUID: (CBPeripheral) -> Void] = [:]
    
    func connect(to device: CBPeripheral, completion: @escaping (CBPeripheral) -> Void) {
        print("Connecting...")
        device.delegate = self
        manager.connect(device, options: nil)
        connectCompletions[device.identifier] = completion
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let completion = connectCompletions[peripheral.identifier] {
            connectCompletions.removeValue(forKey: peripheral.identifier)
            print("Did connect...")
            peripheral.discoverServices(nil)
        }
        
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
        if let char = findCharacteristicfromUUID(
            in: peripheral, service: MEEBLUE_MAIN_SERVICE,
            characteristic: MEEBLUE_MAIN_AUTHENTICATION
        ) {
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
            if let char = findCharacteristicfromUUID(in: peripheral, service: MEEBLUE_CLOSE_SERVICE, characteristic: MEEBLUE_MAIN_DEVICE_NAME) {
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

