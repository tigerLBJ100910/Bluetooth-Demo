//
//  UIAlertViewController.swift
//  bluetooth
//
//  Created by tiger on 2017/7/5.
//  Copyright © 2017年 tiger. All rights reserved.
//

import UIKit

extension UIAlertController {
    class func showAlert(title: String?,message: String?,vc: UIViewController?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "确定", style: UIAlertActionStyle.default) { (action) in
            
        }
        alert.addAction(action)
        if vc != nil {
            alert.show(vc!, sender: nil)
        } else {
            alert.show(UIApplication.shared.keyWindow!.rootViewController!, sender: nil)
        }
    }
}
