//
//  StopWatch.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 10.03.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation


/**
 * Stop watch to measure and print elapsed time.
 *
 * Pattern 1:
 * let stopWatch = StopWatch("<any description>")
 * ...do something...
 * stopWatch.stop()
 *
 * Pattern 2:
 * StopWatch.measureTime(description: "<any description>", callback: <your callback function which does something>)
 */
class StopWatch {
    
    let logger = Logger(loggerName: "StopWatch", logLevel: .info) // change to .debug if the StopWatch should log

    var description: String
    var begin: TimeInterval
    
    
    init(_ description: String) {
        self.description = description
        begin = ProcessInfo.processInfo.systemUptime
    }
    
    func stop() {
        if logger.isDebugEnabled() {
            let diff = (ProcessInfo.processInfo.systemUptime - begin)
            let valueAsStr = String(format: "%.1f", diff*1000.0)
            logger.debug("\(description): \(valueAsStr)ms")
        }
    }
    
    class func measureTime<RESULT_TYPE>(description: String, callback: () throws -> RESULT_TYPE) throws -> RESULT_TYPE {
        let stopWatch = StopWatch(description)
        let result: RESULT_TYPE = try callback()
        stopWatch.stop()
        return result
    }

}
