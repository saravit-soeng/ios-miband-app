//
//  ConnectedDeviceViewController.swift
//  MBD Tracker
//
//  Created by Soeng Saravit on 12/7/21.
//

import UIKit
import CoreBluetooth

class ConnectedDeviceViewController: UIViewController {
    
    var peripheral: CBPeripheral?
    var apiService: APIService?
    var mqttService:MQTTService?

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var batteryLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var heartRateLabel: UILabel!

    let heartRateUuid = CBUUID(string: "0x180D")
    let batteryUuid = CBUUID(string: "0x180F")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide back button
        self.navigationItem.setHidesBackButton(true, animated: false)
        // Custom background view
        self.containerView.layer.cornerRadius = 8
        
        self.apiService = APIService()
        self.mqttService = MQTTService()
        BluetoothService.shared.centralManager?.delegate = self
        
        // first connect from home screen
        if let peripheral = peripheral {
            self.setUpView(navTitle: peripheral.name)
            // connect to ble device
            self.peripheral?.delegate = self
            BluetoothService.shared.centralManager?.connect(self.peripheral!, options: nil)
        }
    }
    
    //Mark: - set up screen view for first load
    func setUpView(navTitle:String?) {
        self.navigationItem.title = navTitle
        self.statusLabel.text = "Connecting"
        self.heartRateLabel.text = "--"
    }
    
    @IBAction func disconnectAction(_ sender: Any) {
        let alert = UIAlertController(title: "Disconnect", message: "Are you sure to disconnect the device?", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok   ", style: .default) { _ in
            UserDefaults.standard.removeObject(forKey: BluetoothService.savedPeripheralKey)
            BluetoothService.shared.centralManager?.cancelPeripheralConnection(self.peripheral!)
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let mainVC = mainStoryboard.instantiateViewController(withIdentifier: "rootNavVC")
            self.view.window?.rootViewController = mainVC
            self.view.window?.makeKeyAndVisible()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(ok)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
}

//Mark: - implement delegate method when bluetooth is connected
extension ConnectedDeviceViewController:CBCentralManagerDelegate, CBPeripheralDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("BLE: powered on")
            // load data from userdefault after reconnected the app
            if let peripheralID = UserDefaults.standard.string(forKey: BluetoothService.savedPeripheralKey) {
                print(peripheralID)
                let peripheralUUID = UUID(uuidString: peripheralID)
                let retreivedPeripherals = BluetoothService.shared.centralManager?.retrievePeripherals(withIdentifiers: [peripheralUUID!])
                self.peripheral = retreivedPeripherals?[0]
                self.setUpView(navTitle: self.peripheral!.name)
                self.peripheral?.delegate = self
                BluetoothService.shared.centralManager?.connect(self.peripheral!, options: nil)
            }
            print("Start connecting to \(self.peripheral?.name ?? "unknown device")")
        }else {
            let alert = UIAlertController(title: "Bluetooth", message: "Something went wrong with Bluetooth, please check connection!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { ACTION in
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "unknown device")")
        
        if peripheral.state == .connected {
            self.statusLabel.text = "Connected"
            // Store the peripheral id to userdefaults
            UserDefaults.standard.set(peripheral.identifier.uuidString, forKey: BluetoothService.savedPeripheralKey)
        }else if peripheral.state == .disconnected{
            self.statusLabel.text = "Disconnected"
        }
        self.peripheral!.discoverServices([heartRateUuid, batteryUuid])
//        self.peripheral?.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services!{
            print("=> Discovered service: ", service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print(service)
        for chara in service.characteristics!{
            print(chara)
            if chara.properties.contains(.read){
                print("\(chara.uuid): properties contains .read")
                peripheral.readValue(for: chara)
            }
            if chara.properties.contains(.notify) {
                print("\(chara.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: chara)
            }
        }
        print("---------")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
        let heartRateControlPointCBUUID = CBUUID(string: "2A39")
        let batteryLevelCharacteristicCBUUID = CBUUID(string: "0x2A19")
        
        switch characteristic.uuid {
        case heartRateControlPointCBUUID:
            if characteristic.value != nil {
                print("Heart Rate Control Point: \(readByte(from: characteristic))")
            }else{
                print("Heart Rate Control Point: no value")
            }
        case heartRateMeasurementCharacteristicCBUUID:
            let bpm = readByte(from: characteristic)
            print("=> Heart rate: ",bpm)
            self.heartRateLabel.text = "\(bpm) BPM"
            // post heart rate data via api
            apiService?.addHeartRate(heartRate: bpm)
            //publish message to mqtt
            let payload: [String:Any] = ["heart_rate":bpm, "device":"ios"]
            self.mqttService?.publishMessageToBroker(payload: payload)
        case batteryLevelCharacteristicCBUUID:
            let battery = readByte(from: characteristic)
            print("Battery level: \(battery)%")
            self.batteryLabel.text = "\(battery)%"
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("called from willRestoreState method in ConnectedDeviceVC class")
    }
    
    // Convert byte value to int value
    private func readByte(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
          
        if byteArray.count == 1{
            // for battery level
            return Int(byteArray[0])
        }else{
            let firstBitValue = byteArray[0] & 0x01
            if firstBitValue == 0 {
                // Heart Rate Value Format is in the 2nd byte
                return Int(byteArray[1])
            } else {
                // Heart Rate Value Format is in the 2nd and 3rd bytes
                return (Int(byteArray[1]) << 8) + Int(byteArray[2])
            }
        }
    }
}
