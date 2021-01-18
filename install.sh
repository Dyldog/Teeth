# sudo apt-get update
# sudo apt-get install clang
# sudo apt-get install libcurl4 libpython2.7 libpython2.7-dev
wget https://swift.org/builds/swift-5.2.5-release/ubuntu1804/swift-5.2.5-RELEASE/swift-5.2.5-RELEASE-ubuntu18.04.tar.gz
tar xzf swift-5.2.5-RELEASE-ubuntu18.04.tar.gz
sudo mv swift-5.2.5-RELEASE-ubuntu18.04 /usr/share/swift
# echo "export PATH=/usr/share/swift/usr/bin:$PATH" >> ~/.bashrc
source ~/.bashrc