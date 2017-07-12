//
//  ConnectViewController.swift
//  bluetooth
//
//  Created by tiger on 2017/7/6.
//  Copyright © 2017年 tiger. All rights reserved.
//

import UIKit

class QXConnectViewController: UIViewController,QXTemperatureAlarmProtocol {

    @IBOutlet weak var connectDeviceLabel: UILabel!
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var minTemperatureLabel: UILabel!
    @IBOutlet weak var maxTemperatureLabel: UILabel!
    
    var currentlyDisplayingService: QXTemperatureAlarmService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshView()
        self.currentlyDisplayingService.peripheralDelegate = self
    }
    
    private func refreshView() {
        self.connectDeviceLabel.text = self.currentlyDisplayingService.peripheral.name
        self.currentTemperatureLabel.text = String(format: "%0.1f°",self.currentlyDisplayingService.temperature)
        self.minTemperatureLabel.text = String(format: "MIN %0.1f°",self.currentlyDisplayingService.minimumTemperature)
        self.maxTemperatureLabel.text = String(format: "MAX %0.1f°",self.currentlyDisplayingService.maximumTemperature)
    }
    
    @IBAction func maxTemperatureChanged(sender: UISegmentedControl) {
        var maxInt = 250
        if self.currentlyDisplayingService.maximumTemperature.isNaN {
            
        } else {
            maxInt = Int(self.currentlyDisplayingService.maximumTemperature*10)
        }
        if sender.selectedSegmentIndex == 0 {
            maxInt = maxInt-5
        } else {
            maxInt = maxInt+5
        }
        let data = Data(buffer: UnsafeBufferPointer(start: &maxInt, count: 1))
        self.currentlyDisplayingService.peripheral.writeValue(data, for: self.currentlyDisplayingService.maxTemperatureCharacteristic, type: .withResponse)
    }
    
    @IBAction func minTemperatureChanged(sender: UISegmentedControl) {
        var minInt = 50
        if self.currentlyDisplayingService.minimumTemperature.isNaN {
            
        } else {
            minInt = Int(self.currentlyDisplayingService.minimumTemperature*10)
        }
        if sender.selectedSegmentIndex == 0 {
            minInt = minInt-5
        } else {
             minInt = minInt+5
        }
        let data = Data(buffer: UnsafeBufferPointer(start: &minInt, count: 1))
        self.currentlyDisplayingService.peripheral.writeValue(data, for: self.currentlyDisplayingService.minTemperatureCharacteristic, type: .withResponse)
    }
    
    func alarmService(service: QXTemperatureAlarmService,didSoundAlarmOfType alarm: AlarmType) {
    
    }
    
    func alarmServiceDidStopAlarm(service: QXTemperatureAlarmService) {
        
    }
    
    func alarmServiceDidChangeTemperature(service: QXTemperatureAlarmService) {
        self.refreshView()
    }
    
    func alarmServiceDidChangeTemperatureBounds(service: QXTemperatureAlarmService) {
         refreshView()
    }
    
    func alarmServiceDidChangeStatus(service: QXTemperatureAlarmService) {
       
    }
    
    func alarmServiceDidReset() {
        
    }
}
