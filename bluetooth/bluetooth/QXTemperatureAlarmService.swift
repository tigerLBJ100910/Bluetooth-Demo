//
//  TemperatureDataManager.swift
//  bluetooth
//
//  Created by tiger on 2017/7/5.
//  Copyright © 2017年 tiger. All rights reserved.
//

import UIKit
import Foundation
import CoreBluetooth

/****************************************************************************/
/*						Service Characteristics								*/
/****************************************************************************/
private let kTemperatureServiceUUIDString: String  = "DEADF154-0000-0000-0000-0000DEADF154" //Service UUID
private let kCurrentTemperatureCharacteristicUUIDString = "CCCCFFFF-DEAD-F154-1319-740381000000"//     Current Temperature Characteristic
private let kMinimumTemperatureCharacteristicUUIDString = "C0C0C0C0-DEAD-F154-1319-740381000000"//     Minimum Temperature Characteristic
private let kMaximumTemperatureCharacteristicUUIDString = "EDEDEDED-DEAD-F154-1319-740381000000"//     Maximum Temperature Characteristic
private let kAlarmCharacteristicUUIDString =              "AAAAAAAA-DEAD-F154-1319-740381000000"//     Alarm Characteristic

public let kAlarmServiceEnteredBackgroundNotification = NSNotification.Name("kAlarmServiceEnteredBackgroundNotification")
public let kAlarmServiceEnteredForegroundNotification = NSNotification.Name("kAlarmServiceEnteredForegroundNotification")

enum AlarmType: Int {
    case kAlarmHigh = 0
    case kAlarmLow = 1
}

protocol QXTemperatureAlarmProtocol: NSObjectProtocol {
    func alarmService(service: QXTemperatureAlarmService,didSoundAlarmOfType alarm: AlarmType)
    func alarmServiceDidStopAlarm(service: QXTemperatureAlarmService)
    func alarmServiceDidChangeTemperature(service: QXTemperatureAlarmService)
    func alarmServiceDidChangeTemperatureBounds(service: QXTemperatureAlarmService);
    func alarmServiceDidChangeStatus(service: QXTemperatureAlarmService);
    func alarmServiceDidReset()
}
    
class QXTemperatureAlarmService: NSObject,CBPeripheralDelegate {
    
    
    weak var peripheralDelegate: QXTemperatureAlarmProtocol?
    
    var peripheral: CBPeripheral {
        return servicePeripheral
    }
    private var servicePeripheral: CBPeripheral!
    private var temperatureAlarmService: CBService!
    
    private var tempCharacteristic: CBCharacteristic!
    public var minTemperatureCharacteristic: CBCharacteristic!
    public var maxTemperatureCharacteristic: CBCharacteristic!
    private var alarmCharacteristic: CBCharacteristic!
    
    private var temperatureAlarmUUID: CBUUID!
    private var minimumTemperatureUUID: CBUUID!
    private var maximumTemperatureUUID: CBUUID!
    private var currentTemperatureUUID: CBUUID!
    
    /* Querying Sensor */
    var temperature:CGFloat {
        get {
            var result: CGFloat = CGFloat.nan
            if (self.tempCharacteristic != nil && tempCharacteristic.value != nil) {
                let resultInt: Int = tempCharacteristic.value!.withUnsafeBytes { $0.pointee }
                return CGFloat(resultInt)/10.0
            }
            return result
        }
    }
    
    var maximumTemperature:CGFloat {
        get {
            var result: CGFloat = 25
            if (self.maxTemperatureCharacteristic != nil && maxTemperatureCharacteristic.value != nil) {
                let resultInt: Int = maxTemperatureCharacteristic.value!.withUnsafeBytes { $0.pointee }
                return CGFloat(resultInt)/10.0
            }
            return result
        }
    }
    var minimumTemperature:CGFloat {
        get {
            var result: CGFloat = 5
            if (self.minTemperatureCharacteristic != nil && minTemperatureCharacteristic.value != nil) {
                let resultInt: Int = minTemperatureCharacteristic.value!.withUnsafeBytes { $0.pointee }
                return CGFloat(resultInt)/10.0
            }
            return result
        }
    }
    
    init(peripheral: CBPeripheral,controller: QXTemperatureAlarmProtocol?) {
        super.init()
        self.servicePeripheral = peripheral
        self.servicePeripheral.delegate = self
        self.peripheralDelegate = controller
        
        self.minimumTemperatureUUID = CBUUID(string: kMinimumTemperatureCharacteristicUUIDString)
        self.maximumTemperatureUUID = CBUUID(string: kMaximumTemperatureCharacteristicUUIDString)
        self.currentTemperatureUUID = CBUUID(string: kCurrentTemperatureCharacteristicUUIDString)
        self.temperatureAlarmUUID = CBUUID(string: kAlarmCharacteristicUUIDString)
    }
    
    deinit {
        if self.servicePeripheral != nil {
            self.servicePeripheral.delegate = QXDiscovery.sharedInstance
            self.servicePeripheral = nil
        }
    }
    
    public func reset() {
        if self.servicePeripheral != nil {
            self.servicePeripheral = nil;
        }
    }
    
    public func start() {
        let serviceUUID = CBUUID(string: kTemperatureServiceUUIDString)
        let services = [serviceUUID]
        self.servicePeripheral.discoverServices(services)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object1 = object as? QXTemperatureAlarmService {
            if object1.peripheral.identifier.uuidString == self.peripheral.identifier.uuidString {
                return true
            }
        }
        return false
    }
    
    /* Set the alarm cutoffs */
    public func writeLowAlarmTemperature(low: Int) {
        var value: Int16 = Int16(low)
        
        if self.servicePeripheral == nil {
            //Not connected to a peripheral
            return ;
        }
        
        if self.minTemperatureCharacteristic == nil {
            //No valid minTemp characteristic
            return;
        }
        
        let data = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        self.servicePeripheral.writeValue(data, for: self.minTemperatureCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    public func writeHighAlarmTemperature(high: Int) {
        var value: Int16 = Int16(high)
        
        if self.servicePeripheral == nil {
            //Not connected to a peripheral
            return ;
        }
        
        if self.maxTemperatureCharacteristic == nil {
            //No valid minTemp characteristic
            return;
        }
        
        let data = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
        self.servicePeripheral.writeValue(data, for: self.maxTemperatureCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    /* Behave properly when heading into and out of the background */
    func enteredBackground() {
        // Find the fishtank service
        if self.servicePeripheral == nil || self.servicePeripheral.services!.count < 1 {
            return
        }
        for service in self.servicePeripheral.services! {
            if service.uuid.isEqual(CBUUID(string: kTemperatureServiceUUIDString)) {
                // Find the temperature characteristic
                if service.characteristics == nil || service.characteristics!.count < 1 {
                    return
                }
                for characteristic in service.characteristics! {
                    if characteristic.isEqual(self.currentTemperatureUUID) {
                        // And STOP getting notifications from it
                        self.servicePeripheral.setNotifyValue(false, for: characteristic)
                    }
                }
            }
        }
    }
    
    func enteredForeground() {
        // Find the fishtank service
        if self.servicePeripheral == nil || self.servicePeripheral.services!.count < 1 {
            return
        }
        for service in self.servicePeripheral.services! {
            if service.uuid.isEqual(CBUUID(string: kTemperatureServiceUUIDString)) {
                // Find the temperature characteristic
                if service.characteristics == nil || service.characteristics!.count < 1 {
                    return
                }
                for characteristic in service.characteristics! {
                    if characteristic.isEqual(self.currentTemperatureUUID) {
                        // And STOP getting notifications from it
                        self.servicePeripheral.setNotifyValue(true, for: characteristic)
                    }
                }
            }
        }
    }

    
    //MARK: - 
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if peripheral != self.servicePeripheral {
            return
        }
        
        if error != nil {
            UIAlertController.showAlert(title: "Error", message: error?.localizedDescription, vc: nil)
            return
        }
        
        let services = peripheral.services
        if ((services == nil) || services!.count < 1) {
            return
        }
        
        self.temperatureAlarmService = nil
        for service in services! {
            if service.uuid.uuidString == kTemperatureServiceUUIDString {
                temperatureAlarmService = service
                break
            }
        }
        
        if self.temperatureAlarmService != nil {
            let uuids: [CBUUID]? = [self.currentTemperatureUUID,self.minimumTemperatureUUID,self.maximumTemperatureUUID,self.temperatureAlarmUUID]
            self.servicePeripheral.discoverCharacteristics(uuids, for: self.temperatureAlarmService)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristics    = service.characteristics
        
        if (peripheral != self.servicePeripheral) {
            return
        }
        
        if (service != self.temperatureAlarmService) {
            return
        }
        
        if characteristics == nil || characteristics!.count < 1 {
            return
        }
        
        if (error != nil) {
            UIAlertController.showAlert(title: "Error", message: error?.localizedDescription, vc: nil)
            return
        }
        
        
        for characteristic in characteristics! {
            if (characteristic.uuid.isEqual(self.minimumTemperatureUUID)) { // Min Temperature.
                self.minTemperatureCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if (characteristic.uuid.isEqual(self.maximumTemperatureUUID)) { // Max Temperature.
                self.maxTemperatureCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if (characteristic.uuid.isEqual(self.temperatureAlarmUUID)) { // Alarm
                self.alarmCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
            else if (characteristic.uuid.isEqual(self.currentTemperatureUUID)) { // Current Temp
                self.tempCharacteristic = characteristic
                peripheral.readValue(for: tempCharacteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if peripheral != self.servicePeripheral {
            return
        }
        
        if let tError = error as NSError? {
            if tError.code != 0 {
                return
            }
        }
        
        if characteristic.uuid.isEqual(self.currentTemperatureUUID) {
            self.tempCharacteristic = characteristic
            self.peripheralDelegate?.alarmServiceDidChangeTemperature(service: self)
        } else if characteristic.uuid.isEqual(self.minimumTemperatureUUID) {
            self.minTemperatureCharacteristic = characteristic
            self.peripheralDelegate?.alarmServiceDidChangeTemperature(service: self)
        } else if  characteristic.uuid.isEqual(self.maximumTemperatureUUID) {
            self.maxTemperatureCharacteristic = characteristic
            self.peripheralDelegate?.alarmServiceDidChangeTemperature(service: self)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheral.readValue(for: characteristic)
        if characteristic.uuid.isEqual(self.minimumTemperatureUUID) || characteristic.uuid.isEqual(self.maximumTemperatureUUID) {
            self.peripheralDelegate?.alarmServiceDidChangeTemperatureBounds(service: self)
        }
    }
    
}
