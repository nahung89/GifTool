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

extension UILabel {
    
    func setLineHeight(height: CGFloat) {
        var txt: String = ""
        if let t = self.text {
            txt = t
        }
        
        let paragrahStyle = NSMutableParagraphStyle.init()
        paragrahStyle.minimumLineHeight = height
        paragrahStyle.maximumLineHeight = height
        
        self.attributedText = NSAttributedString(string: txt,
                                                 attributes: [NSAttributedStringKey.paragraphStyle : paragrahStyle])
    }
    
    func setLineHeightCenter(height: CGFloat) {
        var txt: String = ""
        if let t = self.text {
            txt = t
        }
        
        let paragrahStyle = NSMutableParagraphStyle.init()
        paragrahStyle.minimumLineHeight = height
        paragrahStyle.maximumLineHeight = height
        paragrahStyle.alignment = .center
        
        self.attributedText = NSAttributedString(string: txt,
                                                 attributes: [NSAttributedStringKey.paragraphStyle : paragrahStyle])
        
    }
    
    
    func set(font: UIFont, color: UIColor, text: String) {
        self.font = font
        self.textColor = color
        self.text = text
    }
}

extension UIView {
    
    @objc convenience init(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        self.init(frame: CGRect(x: x, y: y, width: w, height: h))
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
}

extension CGRect {
    
    init(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        self.init(x: x, y: y, width: w, height: h)
    }
}

extension CGSize {
    var w: CGFloat {
        get {
            return self.width
        } set(value) {
            self.width = value
        }
    }
    
    var h: CGFloat {
        get {
            return self.height
        } set(value) {
            self.height = value
        }
    }
}

extension CGRect {
    
    var x: CGFloat {
        get {
            return self.origin.x
        } set(value) {
            self.origin.x = value
        }
    }
    
    var y: CGFloat {
        get {
            return self.origin.y
        } set(value) {
            self.origin.y = value
        }
    }
    
    var w: CGFloat {
        get {
            return self.size.width
        } set(value) {
            self.size.width = value
        }
    }
    
    var h: CGFloat {
        get {
            return self.size.height
        } set(value) {
            self.size.height = value
        }
    }
    
}

extension UIView {
    
    public func removeAllSubview() {
        for (_, v) in self.subviews.enumerated() {
            v.removeFromSuperview()
        }
    }
}

extension UIView {
    
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

extension UIView {
    
    var size: CGSize {
        get {
            return self.frame.size
        } set(value) {
            self.frame.size = value
        }
    }
    
    
    var zeroPointRect: CGRect {
        return CGRect.init(x: 0, y: 0, w: self.w, h: self.h)
    }
    
    var x: CGFloat {
        get {
            return self.frame.origin.x
        } set(value) {
            self.frame.origin.x = value
        }
    }
    
    var y: CGFloat {
        get {
            return self.frame.origin.y
        } set(value) {
            self.frame.origin.y = value
        }
    }
    
    var w: CGFloat {
        get {
            return self.frame.size.width
        } set(value) {
            self.frame.size.width = value
        }
    }
    
    var h: CGFloat {
        get {
            return self.frame.size.height
        } set(value) {
            self.frame.size.height = value
        }
    }
    
    var maxX: CGFloat {
        return self.frame.maxX
    }
    
    var maxY: CGFloat {
        return self.frame.maxY
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
    
    public class func isOldDevice() -> Bool {
        let modelName = UIDevice().modelName
        switch modelName {
        case "Simulator",
             "iPhone 4",
             "iPhone 4s",
             "iPhone 5",
             "iPhone 5c",
             "iPhone 5s",
             "iPhone 6",
             "iPhone 6 Plus",
             "iPhone 6s",
             "iPhone 6s Plus":
            return true
        default:
            return false
        }
    }

    public enum Versions: Float {
        case five = 5.0
        case six = 6.0
        case seven = 7.0
        case eight = 8.0
        case nine = 9.0
        case ten = 10.0
    }
    
    public class func systemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    public class func systemFloatVersion() -> Float {
        return (systemVersion() as NSString).floatValue
    }
    
    public class func isVersion(_ version: Versions) -> Bool {
        return systemFloatVersion() >= version.rawValue && systemFloatVersion() < (version.rawValue + 1.0)
    }
    
    public class func isVersionOrLater(_ version: Versions) -> Bool {
        return systemFloatVersion() >= version.rawValue
    }
    
    public class func isVersionOrEarlier(_ version: Versions) -> Bool {
        return systemFloatVersion() < (version.rawValue + 1.0)
    }
    
    public class var CURRENT_VERSION: String {
        return "\(systemFloatVersion())"
    }
    
    public class func isOS10Later() -> Bool {
        return isVersionOrLater(.ten)
    }
    
    static let isIphoneX: Bool = {
        // iPhoneX is alway iOS 11 later
        guard #available(iOS 11.0, *),
            UIDevice.current.userInterfaceIdiom == .phone else {
                return false
        }
        let nativeSize = UIScreen.main.nativeBounds.size
        let (w, h) = (nativeSize.width, nativeSize.height)
        let (d1, d2): (CGFloat, CGFloat) = (1125.0, 2436.0)
        
        return (w == d1 && h == d2) || (w == d2 && h == d1)
    }()
    
}
