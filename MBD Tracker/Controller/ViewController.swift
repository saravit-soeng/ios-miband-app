//
//  ViewController.swift
//  MBD Tracker
//
//  Created by Soeng Saravit on 4/7/21.
//

import UIKit
import CoreBluetooth
import Pulsator

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var deviceTableView: UITableView!
    var devices:[CBPeripheral]?
    var connectedPeripheral: CBPeripheral?
    var isScanable = true
    var bgImageView = UIImageView(image: UIImage(named: "mi_band_01.png"))
    var placeholderLabel = UILabel()
    var pulsator = Pulsator()
    var selectedIndexPath: IndexPath?
    var pairedDevices: [CBPeripheral]? // stored already paired devices
    let heartRateUuid = CBUUID(string: "0x180D")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        deviceTableView.tableHeaderView = UIView()
        deviceTableView.tableFooterView = UIView()
        deviceTableView.delegate = self
        deviceTableView.dataSource = self
        
        // placeholder view for first load
        self.view.addSubview(bgImageView)
        self.view.addSubview(placeholderLabel)
        bgImageView.center = view.center
        bgImageView.bounds.size = CGSize(width: 100, height: 100)
        placeholderLabel.text = "Scan to search nearby devices"
        placeholderLabel.alpha = 0.5
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        placeholderLabel.topAnchor.constraint(equalTo: self.bgImageView.bottomAnchor, constant: 0).isActive = true
        
        // adding pulsator animation
        self.view.layer.addSublayer(pulsator)
        pulsator.position = view.center
        pulsator.numPulse = 4
        pulsator.radius = 200
        pulsator.backgroundColor = UIColor(red: 51/255.0, green: 153/255.0, blue: 255/255.0, alpha: 0.8).cgColor
        pulsator.animationDuration = 2.5
        
        // show or hide elements on first start
        isHideElements(tableview: true, bgImage: false, placeholderLabel: false, pulsator: true)
        
        devices = [CBPeripheral]()
        BluetoothService.shared.centralManager?.delegate = self
    }
    
    func isHideElements(tableview b1:Bool, bgImage b2:Bool, placeholderLabel b3:Bool, pulsator b4:Bool) {
        self.deviceTableView.isHidden = b1
        self.bgImageView.isHidden = b2
        self.placeholderLabel.isHidden = b3
        self.pulsator.isHidden = b4
    }
    
    
    @objc func stopScanning() {
        print("BLE: Stop scanning")
        BluetoothService.shared.centralManager?.stopScan()
        pulsator.stop()
        self.deviceTableView.reloadData()
        isHideElements(tableview: false, bgImage: true, placeholderLabel: true, pulsator: true)
    }
    
    @IBAction func scanAction(_ sender: Any) {
        if isScanable {
            isHideElements(tableview: true, bgImage: false, placeholderLabel: true, pulsator: false)
            pulsator.start()
            devices = []
            // scan for already paired device
            self.pairedDevices = BluetoothService.shared.centralManager?.retrieveConnectedPeripherals(withServices: [heartRateUuid])
            // scan for all devices
            BluetoothService.shared.centralManager?.scanForPeripherals(withServices: nil, options: nil)
            Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(stopScanning), userInfo: nil, repeats: false)
        }else{
            let alert = UIAlertController(title: "Scan Fail!", message: "Please check bluetooth connection", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { ACTION in
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = deviceTableView.dequeueReusableCell(withIdentifier: "devicesCell")! as! DevicesTableViewCell
        if indexPath.row == 0{
            cell.separatorInset.top = 100.0
        }
        let device = devices![indexPath.row]
        var icon = UIImage(named: "bluetooth-icon.png")
        var deviceName = "Unknown Device"
        if let dName = device.name {
            deviceName = dName
            if dName.lowercased().contains("mi"){
                icon = UIImage(named: "mi_band_02.png")
            }
        }
        
        let isPaired = pairedDevices?.contains(where: { pairedDevice in
            if pairedDevice.identifier.uuidString == device.identifier.uuidString {
                return true
            }
            return false
        })
        var status = "Unpaired Device"
        if isPaired! {
            status = "Paired Device"
        }
        
        cell.bindView(icon: icon!, deviceName: deviceName, status: status)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let connect = UIContextualAction(style: .normal, title: "Connect") { _, _, _ in
            self.selectedIndexPath = indexPath
            self.connectedPeripheral = self.devices![indexPath.row]
            self.connectedPeripheral?.delegate = self
            self.deviceTableView.reloadRows(at: [indexPath], with: .automatic)
            self.performSegue(withIdentifier: "connectedDeviceID", sender: self.connectedPeripheral)
        }
        connect.backgroundColor = .blue
        return UISwipeActionsConfiguration(actions: [connect])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "connectedDeviceID" {
            let dest = segue.destination as! ConnectedDeviceViewController
            dest.peripheral = sender as? CBPeripheral
        }
    }
}

//Mark - implement delegate method when bluetooth is connected
extension ViewController:CBCentralManagerDelegate, CBPeripheralDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            print("BLE: powered on")
            isScanable = true
        }else {
            isScanable = false
            let alert = UIAlertController(title: "Bluetooth", message: "Something went wrong with Bluetooth, please check connection!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { ACTION in
                
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !devices!.contains(peripheral) && peripheral.name != nil && peripheral.name!.lowercased().contains("mi"){
            self.devices?.append(peripheral)
        }
    }
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("called from willRestoreState method in ViewController class")
    }
}
