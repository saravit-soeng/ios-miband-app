//
//  BluetoothService.swift
//  MBD Tracker
//
//  Created by Soeng Saravit on 12/7/21.
//

import Foundation
import CoreBluetooth

class BluetoothService: NSObject {
    static let shared = BluetoothService()
    static let savedPeripheralKey = "saved-peripheral"
    var centralManager:CBCentralManager?
    
    override init() {
        super.init()
        print("BLE: init bluetooth service")
        centralManager = CBCentralManager(delegate: nil, queue: nil)
//        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey : "com.saravitsoeng.MBD-Tracker.centralManager"])
    
    }
}

extension BluetoothService: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("BLE: updated state from BluetoothService class")
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("called from willRestoreState methon in BluetoothService class")
    }
}
