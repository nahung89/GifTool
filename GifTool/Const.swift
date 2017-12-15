//
//  Const.swift
//  GifTool
//
//  Created by Nah on 12/15/17.
//  Copyright © 2017 Nah. All rights reserved.
//

import Foundation
import XCGLogger
import UIKit

let timeOutTime = 30.0
    
let logFileName = "\(UIDevice.current.modelName)-\(UIDevice.current.systemVersion)-\(UIDevice.current.name)-\(Date()).log"

let log: XCGLogger = {
        // Emojis
        let emojiLogFormatter = PrePostFixLogFormatter()
        emojiLogFormatter.apply(prefix: "⚛", postfix: "⚛", to: .verbose)
        emojiLogFormatter.apply(prefix: "🔷", postfix: "🔷", to: .debug)
        emojiLogFormatter.apply(prefix: "♻️", postfix: "♻️", to: .info)
        emojiLogFormatter.apply(prefix: "⚠️", postfix: "⚠️", to: .warning)
        emojiLogFormatter.apply(prefix: "🚫", postfix: "🚫", to: .error)
        emojiLogFormatter.apply(prefix: "🆘", postfix: "🆘", to: .severe)
        
        // File path
        var documentDirFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        documentDirFileURL.appendPathComponent(logFileName)
        let path = documentDirFileURL.path
        
        let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: true)
        
        
        // Create a destination for the system console log (via NSLog)
        //    let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")
        //    // Optionally set some configuration options
        //    systemDestination.outputLevel = .debug
        //    systemDestination.showLogIdentifier = false
        //    systemDestination.showFunctionName = false
        //    systemDestination.showThreadName = true
        //    systemDestination.showLevel = false
        //    systemDestination.showFileName = true
        //    systemDestination.showLineNumber = true
        //    systemDestination.showDate = true
        //    // Add the destination to the logger
        //    log.add(destination: systemDestination)
        
        
        // Create a file log destination
        let fileDestination = FileDestination(writeToFile: path, identifier: "advancedLogger.fileDestination")
        // Optionally set some configuration options
        fileDestination.outputLevel = .debug
        fileDestination.showLogIdentifier = false
        fileDestination.showFunctionName = false
        fileDestination.showThreadName = true
        fileDestination.showLevel = true
        fileDestination.showFileName = true
        fileDestination.showLineNumber = true
        fileDestination.showDate = true
        // Process this destination in the background
        fileDestination.logQueue = XCGLogger.logQueue
        fileDestination.formatters = [emojiLogFormatter]
        
        // Add the destination to the logger
        log.add(destination: fileDestination)
        
        log.setup(level: .debug,
                  showFunctionName: false,
                  showThreadName: true,
                  showLevel: true,
                  showFileNames: true,
                  showLineNumbers: true,
                  writeToFile: nil,
                  fileLevel: .debug)
        log.formatters = [emojiLogFormatter]
        
        log.info("[Device]: \(UIDevice.current.modelName)-\(UIDevice.current.systemVersion)-\(UIDevice.current.name)")
        
        return log
}()



