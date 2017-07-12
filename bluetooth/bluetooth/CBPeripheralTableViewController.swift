//
//  CBPeripheralTableViewController.swift
//  bluetooth
//
//  Created by tiger on 2017/7/4.
//  Copyright © 2017年 tiger. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

private let kTemperatureServiceUUIDString: String  = "DEADF154-0000-0000-0000-0000DEADF154" //Service UUID
private let kCurrentTemperatureCharacteristicUUIDString = "CCCCFFFF-DEAD-F154-1319-740381000000"//     Current Temperature Characteristic
private let kMinimumTemperatureCharacteristicUUIDString = "C0C0C0C0-DEAD-F154-1319-740381000000"//     Minimum Temperature Characteristic
private let kMaximumTemperatureCharacteristicUUIDString = "EDEDEDED-DEAD-F154-1319-740381000000"//     Maximum Temperature Characteristic
private let kAlarmCharacteristicUUIDString =              "AAAAAAAA-DEAD-F154-1319-740381000000"//     Alarm Characteristic

class CBPeripheralTableViewController: UIViewController,CBPeripheralManagerDelegate {
    
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var minTemperatureLabel: UILabel!
    @IBOutlet weak var maxTemperatureLabel: UILabel!
    
    var peripheralManager: CBPeripheralManager!
    var timer: Timer?
    
    private var temperatureAlarmService: CBMutableService!
    
    private var tempCharacteristic: CBMutableCharacteristic!
    private var minTemperatureCharacteristic: CBMutableCharacteristic!
    private var maxTemperatureCharacteristic: CBMutableCharacteristic!
    private var alarmCharacteristic: CBMutableCharacteristic!
    
    private var minTemperature: Int = 50
    private var maxTemperature: Int = 250
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initData()
        self.refreshMaxMin()
    }
    
    private func initData() {
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        self.temperatureAlarmService = CBMutableService(type: CBUUID(string: kTemperatureServiceUUIDString), primary: true)
        let minimumTemperatureUUID = CBUUID(string: kMinimumTemperatureCharacteristicUUIDString)
        let maximumTemperatureUUID = CBUUID(string: kMaximumTemperatureCharacteristicUUIDString)
        let currentTemperatureUUID = CBUUID(string: kCurrentTemperatureCharacteristicUUIDString)
        let temperatureAlarmUUID = CBUUID(string: kAlarmCharacteristicUUIDString)
        let properties: CBCharacteristicProperties = [ .read, .notify, .writeWithoutResponse, .write ]
        let permissions: CBAttributePermissions = [ .readable,.writeable]
        self.minTemperatureCharacteristic = CBMutableCharacteristic(type: minimumTemperatureUUID, properties: properties, value: nil, permissions: permissions)
        self.maxTemperatureCharacteristic = CBMutableCharacteristic(type: maximumTemperatureUUID, properties: properties, value: nil, permissions: permissions)
        self.tempCharacteristic = CBMutableCharacteristic(type: currentTemperatureUUID, properties: properties, value: nil, permissions: [.readable])
        self.alarmCharacteristic = CBMutableCharacteristic(type: temperatureAlarmUUID, properties: properties, value: nil, permissions: [.readable])
        self.temperatureAlarmService.characteristics = [minTemperatureCharacteristic,maxTemperatureCharacteristic,tempCharacteristic,alarmCharacteristic]
    }
    
    private func fire() {
        self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(temperatureChanged), userInfo: nil, repeats: true)
    }

    func temperatureChanged() {
        var temperature: Int = Int(arc4random()%240)
        let data = Data(buffer: UnsafeBufferPointer(start: &temperature, count: 1))
        let minData = Data(buffer: UnsafeBufferPointer(start: &self.minTemperature, count: 1))
        let maxData = Data(buffer: UnsafeBufferPointer(start: &self.maxTemperature, count: 1))
        self.peripheralManager.updateValue(data, for: self.tempCharacteristic, onSubscribedCentrals: nil)
        self.peripheralManager.updateValue(minData, for: self.minTemperatureCharacteristic, onSubscribedCentrals: nil)
        self.peripheralManager.updateValue(maxData, for: self.maxTemperatureCharacteristic, onSubscribedCentrals: nil)
        self.currentTemperatureLabel.text = String(format: "%0.1f°",CGFloat(temperature)/10.0)
    }
    
    private func refreshMaxMin() {
        self.maxTemperatureLabel.text = String(format: "%MAX %0.1f°",CGFloat(self.maxTemperature)/10.0)
        self.minTemperatureLabel.text = String(format: "%MIN %0.1f°",CGFloat(self.minTemperature)/10.0)
    }
    
    deinit {
        self.timer?.invalidate()
        self.timer = nil
        if self.peripheralManager.isAdvertising {
            self.peripheralManager.stopAdvertising()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @available(iOS 6.0, *)
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unsupported:
            break
        case .poweredOn:
            self.peripheralManager.add(self.temperatureAlarmService)
            break
        case .poweredOff:
            break
        case .unauthorized:
            break
        default:
            break
        }
    }
    
    @available(iOS 6.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        
    }
    
    @available(iOS 6.0, *)
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            UIAlertController.showAlert(title: "Error", message: error?.localizedDescription, vc: self.navigationController!)
        } else {
            self.fire()
        }
    }
    
    @available(iOS 6.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if !peripheralManager.isAdvertising {
            var advertisementData: [String: Any] = [CBAdvertisementDataServiceUUIDsKey: [service.uuid] ]
            advertisementData[CBAdvertisementDataLocalNameKey] = ServiceConfiguration.servicesName
            peripheralManager.startAdvertising(advertisementData)
        }
    }
    
    @available(iOS 6.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        
    }
    
    @available(iOS 6.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        
    }
    
    @available(iOS 6.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
    }
    
    @available(iOS 6.0, *)
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let request = requests.first {
            if (request.value == nil) {
                return
            }
            if request.characteristic == self.maxTemperatureCharacteristic {
                let resultInt: Int = request.value!.withUnsafeBytes { $0.pointee }
                self.maxTemperature = resultInt
                let maxData = Data(buffer: UnsafeBufferPointer(start: &self.maxTemperature, count: 1))
                self.peripheralManager.updateValue(maxData, for: self.maxTemperatureCharacteristic, onSubscribedCentrals: nil)
            } else if request.characteristic == self.minTemperatureCharacteristic {
                let resultInt: Int = request.value!.withUnsafeBytes { $0.pointee }
                self.minTemperature = resultInt
                let minData = Data(buffer: UnsafeBufferPointer(start: &self.minTemperature, count: 1))
                self.peripheralManager.updateValue(minData, for: self.minTemperatureCharacteristic, onSubscribedCentrals: nil)
            }
            self.refreshMaxMin()
        }
    }
    
    @available(iOS 6.0, *)
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        
    }

}
