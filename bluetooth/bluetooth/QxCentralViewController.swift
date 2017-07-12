//
//  CBCentralManagerViewController.swift
//  bluetooth
//
//  Created by tiger on 2017/7/4.
//  Copyright © 2017年 tiger. All rights reserved.
//

import UIKit
import CoreBluetooth

class QxCentralViewController: UITableViewController,QXDiscoveryDelegate,QXTemperatureAlarmProtocol {
    
    lazy var discovery = QXDiscovery.sharedInstance
    let sectionTitle: [String] = ["已配对的设备","可用设备"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initData()
        self.initView()
    }

    private func initData() {
        self.discovery.discoveryDelegate = self
        self.discovery.alarmDelegate = self
        self.discovery.startScanningForUUIDStrings(uuids: nil)
    }
    
    private func initView() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    deinit {
        
    }
    
    //MARK: - TableView DataSource/Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return discovery.connectedServices.count
        } else if section == 1 {
            return discovery.foundPeripherals.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitle[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!  = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        if (cell == nil) {
            cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "UITableViewCell")
        }
        if indexPath.section == 0 {
            cell.textLabel?.text = discovery.connectedServices[indexPath.row].peripheral.name
        } else if indexPath.section == 1 {
            cell.textLabel?.text = discovery.foundPeripherals[indexPath.row].name
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var peripheral: CBPeripheral! = nil
        if indexPath.section == 0 {
            peripheral = self.discovery.connectedServices[indexPath.row].peripheral
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QXConnectViewController") as! QXConnectViewController
            vc.currentlyDisplayingService = self.discovery.connectedServices[indexPath.row];
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 1 {
            peripheral = self.discovery.foundPeripherals[indexPath.row]
            if peripheral.state == .disconnected {
                self.discovery.connectPeripheral(peripheral: peripheral)
            }
        }
        
    }
    
    //MARK: - CBCentralManagerDelegate
    func discoveryDidRefresh() {
        self.tableView.reloadData()
    }
    
    func discoveryStatePoweredOff() {
        
    }
    
    func alarmService(service: QXTemperatureAlarmService,didSoundAlarmOfType alarm: AlarmType) {
        
    }
    
    func alarmServiceDidStopAlarm(service: QXTemperatureAlarmService) {
        
    }
    
    func alarmServiceDidChangeTemperature(service: QXTemperatureAlarmService) {
        
    }
    
    func alarmServiceDidChangeTemperatureBounds(service: QXTemperatureAlarmService) {
    
    }
    
    func alarmServiceDidChangeStatus(service: QXTemperatureAlarmService) {
        
    }
    
    func alarmServiceDidReset() {
        
    }
    
}
