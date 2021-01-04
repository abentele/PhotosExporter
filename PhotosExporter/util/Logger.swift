//
//  Logger.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 10.03.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation

enum LogLevel: String, Codable {
    case debug
    case info
    case warn
    case error
}

/**
 * Simple Logger Utility class.
 */
class Logger {
    
    var dateFormatter = DateFormatter()
    var loggerName: String = ""
    public var logLevel = LogLevel.info
    
    init() {
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }
    
    convenience init(loggerName: String, logLevel: LogLevel) {
        self.init()
        self.loggerName = loggerName
        self.logLevel = logLevel
    }
    
    private func normalizeLength(text: String, length: Int) -> String {
        var result = text
        if result.count > length {
            result = String(result[...result.index(result.startIndex, offsetBy: length)])
        }
        while result.count < length {
            result = result + " "
        }
        return result
    }

    private func printFormatted(_ level: LogLevel, _ text: String) {
        print("\(dateFormatter.string(from: Date())) \(normalizeLength(text: loggerName, length: 15)) \(normalizeLength(text: level.rawValue, length: 8)) \(text)")
    }
    
    func isDebugEnabled() -> Bool {
        return logLevel == .debug
    }
    
    func debug(_ text: String) {
        if logLevel == .debug {
            printFormatted(.debug, text)
        }
    }
    
    func info(_ text: String) {
        if logLevel == .debug || logLevel == .info {
            printFormatted(.info, text)
        }
    }

    func warn(_ text: String) {
        if logLevel == .debug || logLevel == .info || logLevel == .warn {
            printFormatted(.warn, text)
        }
    }

    func error(_ text: String) {
        printFormatted(.error, text)
    }
}
