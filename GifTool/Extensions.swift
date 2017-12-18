//
//  Extensions.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import UIKit

extension Optional {
    
    var logable: Any {
        switch self {
        case .none:
            return "⁉️"
        case let .some(value):
            return value
        }
    }
}

extension Data {
    func sizeString(units: ByteCountFormatter.Units = [.useAll], countStyle: ByteCountFormatter.CountStyle = .file) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = units
        bcf.countStyle = .file
        
        return bcf.string(fromByteCount: Int64(count))
    }}

extension UILabel {
    
    func set(font: UIFont, color: UIColor, text: String) {
        self.font = font
        self.textColor = color
        self.text = text
    }
}

extension UIFont {
    
    class func Font(_ size: CGFloat) -> UIFont! {
        guard let f = UIFont(name: ".SFUIDisplay-Light", size: size) else {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.light)
        }
        return f
    }
    
    class func FontMedium(_ size: CGFloat) -> UIFont! {
        guard let f = UIFont(name: ".SFUIDisplay-Medium", size: size) else {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.medium)
        }
        return f
    }
    
    class func FontRegular(_ size: CGFloat) -> UIFont! {
        guard let f = UIFont(name: ".SFUIDisplay-Regular", size: size) else {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.regular)
        }
        return f
    }
    
    class func FontBold(_ size: CGFloat) -> UIFont! {
        guard let f = UIFont(name: ".SFUIDisplay-Semibold", size: size) else {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.semibold)
        }
        return f
    }
    
    class func FontHardBold(_ size: CGFloat) -> UIFont! {
        guard let f = UIFont(name: ".SFUIDisplay-Bold", size: size) else {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.bold)
        }
        return f
    }
    
    class func FontHeavyBold(_ size: CGFloat) -> UIFont! {
        guard let f = UIFont(name: ".SFUIDisplay-Heavy", size: size) else {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.heavy)
        }
        return f
    }
}

extension UIViewController {
    
    func displayError(_ message: String) {
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                // do nothing...
            }
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
    }
    
    func displayInfo(_ message: String) {
        let alertController = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            // do nothing...
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension UIView {
    
    public func removeAllSubview() {
        subviews.forEach({ $0.removeFromSuperview() })
    }

    func makeColor(includeSelf: Bool = false) {
        if includeSelf {
            self.backgroundColor = UIColor.random()
        }
        for view in subviews {
            view.backgroundColor = UIColor.random(alpha: 0.5)
        }
    }
}

extension UIColor {
    
    public static func random(alpha: CGFloat = 1.0) -> UIColor {
        let randomRed = CGFloat.random()
        let randomGreen = CGFloat.random()
        let randomBlue = CGFloat.random()
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: alpha)
    }
    
}

private extension CGFloat {
    static func random(_ lower: CGFloat = 0, _ upper: CGFloat = 1) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (upper - lower) + lower
    }
}

public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
}
