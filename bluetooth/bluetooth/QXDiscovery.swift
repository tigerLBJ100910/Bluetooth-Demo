//
//  QXCentralManager.swift
//  bluetooth
//
//  Created by tiger on 2017/7/5.
//  Copyright © 2017年 tiger. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth


/****************************************************************************/
/*							UI protocols									*/
/****************************************************************************/
protocol QXDiscoveryDelegate: NSObjectProtocol {
    func discoveryDidRefresh()
    func discoveryStatePoweredOff()
}

/****************************************************************************/
/*							Manager class									*/
/****************************************************************************/
class QXDiscovery: NSObject,CBCentralManagerDelegate,CBPeripheralDelegate {
    
    public static let sharedInstance = QXDiscovery()
    
    var previousState: Int = -1
    var centralManager: CBCentralManager!
    var foundPeripherals: [CBPeripheral]!
    var connectedServices: [QXTemperatureAlarmService]!
    
    weak var discoveryDelegate: QXDiscoveryDelegate?
    weak var alarmDelegate: QXTemperatureAlarmProtocol?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        self.foundPeripherals = [CBPeripheral]()
        self.connectedServices = [QXTemperatureAlarmService]()
    }
    
    deinit {
        self.centralManager.stopScan()
    }
    
    //MARK: - Public
    func startScanningForUUIDStrings(uuids: [CBUUID]?) {
        self.centralManager.scanForPeripherals(withServices: [CBUUID(string: "DEADF154-0000-0000-0000-0000DEADF154")], options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: false)])
    }
    
    func stopScanning() {
        self.centralManager.stopScan()
    }
    
    func connectPeripheral(peripheral: CBPeripheral) {
        if (peripheral.state == .disconnected) {
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    func disconnectPeripheral(peripheral: CBPeripheral) {
        if (peripheral.state == .connected) {
            self.centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func clearDevices() {
        foundPeripherals.removeAll()
        for service in connectedServices {
            service.reset()
        }
        connectedServices.removeAll()
    }
    
    //MARK: - Private 
    private func loadSavedDevices() {
        let devices:[String]? = UserDefaults.standard.array(forKey: "StoredDevices") as? [String]
        var uuids = [UUID]()
        if devices != nil && devices!.count > 0 {
            for device in devices! {
                let uuid = UUID(uuidString: device)
                if uuid != nil {
                   uuids.append(uuid!)
                }
            }
        }
        if uuids.count > 0 {
            self.centralManager.retrievePeripherals(withIdentifiers: uuids)
        }
    }
    
    private func addSavedDevice(uuid: String) {
        let devices:[String]? = UserDefaults.standard.array(forKey: "StoredDevices") as? [String]
        if devices != nil && devices!.count > 0 {
            var newDevices = [String]()
            newDevices.append(contentsOf: devices!)
            newDevices.append(uuid)
            UserDefaults.standard.set(newDevices, forKey: "StoredDevices")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func removeSavedDevice(uuid: String) {
        let devices:[String]? = UserDefaults.standard.array(forKey: "StoredDevices") as? [String]
        if devices != nil && devices!.count > 0 {
            var newDevices = [String]()
            newDevices.append(contentsOf: devices!)
            for index in 0..<newDevices.count {
                if newDevices[index] == uuid {
                    newDevices.remove(at: index)
                    break
                }
            }
            UserDefaults.standard.set(newDevices, forKey: "StoredDevices")
            UserDefaults.standard.synchronize()
        }
    }
    

    //Delegates
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            self.loadSavedDevices()
            discoveryDelegate?.discoveryDidRefresh()
            break
        case .poweredOff:
            self.clearDevices()
            self.discoveryDelegate?.discoveryDidRefresh()
            if self.previousState == -1 {
                self.discoveryDelegate?.discoveryStatePoweredOff()
            }
        case .resetting:
            self.clearDevices()
            self.discoveryDelegate?.discoveryDidRefresh()
            self.alarmDelegate?.alarmServiceDidReset()
        default:
            break
        }
        self.previousState = 1
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NSLog("%@",advertisementData);
        if !foundPeripherals.contains(peripheral) {
            foundPeripherals.append(peripheral)
            self.discoveryDelegate?.discoveryDidRefresh()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let service = QXTemperatureAlarmService(peripheral: peripheral, controller: alarmDelegate)
        service.start()
        if !connectedServices.contains(service) {
            connectedServices.append(service)
        }
        
        if foundPeripherals.contains(peripheral) {
            if let index = foundPeripherals.index(of: peripheral) {
                foundPeripherals.remove(at: index)
            }
        }
        
        self.alarmDelegate?.alarmServiceDidChangeStatus(service: service)
        self.discoveryDelegate?.discoveryDidRefresh()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        for index in 0..<connectedServices.count {
            let service = connectedServices[index]
            if service.peripheral == peripheral {
                alarmDelegate?.alarmServiceDidChangeStatus(service: service)
                break
            }
        }
        discoveryDelegate?.discoveryDidRefresh()
    }
    
}
