//
//  StopWatch.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 01.03.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Foundation

/**
 * Stop watch to measure and print elapsed time.
 *
 * let stopWatch = StopWatch("<any description>", logLevel)
 * stopWatch.start()
 * ...do something...
 * stopWatch.stop()
 */
class StopWatch {
    
    var logger: Logger
    
    var description: String
    var begin: TimeInterval = 0
    var running = false
    
    let WINDOW = 100
    
    // values for this window
    var fileSizes: [UInt64]?
    var durationSeconds = [Double]()
    
    init(_ description: String, _ logLevel: LogLevel, addFileSizes: Bool) {
        self.description = description
        self.logger = Logger(loggerName: "StopWatch", logLevel: logLevel)
        if addFileSizes {
            self.fileSizes = [UInt64]()
        }
    }
    
    func start() {
        start(fileSizeFn: { return 0})
    }
    
    func start(fileSizeFn: () throws -> UInt64) {
        if logger.isDebugEnabled() {
            if running {
                logger.warn("StopWatch \(description): called start before stop")
            }
            running = true
            begin = ProcessInfo.processInfo.systemUptime
            
            if let fileSizes = self.fileSizes {
                do {
                    let fileSize = try fileSizeFn()
                    self.fileSizes = fileSizes + [fileSize]
                }
                catch let error as NSError {
                    logger.error("Unable to determine file size: \(error)")
                }
                if self.fileSizes!.count > WINDOW {
                    self.fileSizes!.remove(at: 0)
                }
            }
        }
    }
    
    func stop() {
        if logger.isDebugEnabled() {
            if !running {
                logger.warn("StopWatch \(description): didn't call start before calling stop")
            }
            
            running = false
            
            let diffSeconds = ProcessInfo.processInfo.systemUptime - begin
            let diffMillisAsStr = String(format: "%.1f", diffSeconds*1000.0)

            durationSeconds = durationSeconds + [diffSeconds]
            if durationSeconds.count > WINDOW {
                durationSeconds.remove(at: 0)
            }
            
            var accumulatedTimeSeconds: Double = 0
            for d in durationSeconds {
                accumulatedTimeSeconds = accumulatedTimeSeconds + d
            }
            let accumulatedAsStr = String(format: "%.1f", accumulatedTimeSeconds*1000.0)
            
            let count = durationSeconds.count
            
            let avg = accumulatedTimeSeconds / Double(count)
            let avgAsStr = String(format: "%.1f", avg*1000.0)
            
            if let fileSizes = self.fileSizes {
                var accumulatedFileSize: UInt64 = 0
                for fileSize in fileSizes {
                    accumulatedFileSize = accumulatedFileSize + fileSize
                }
                
                let mbPerSecondAccumulated = Double(accumulatedFileSize) / 1024 / 1024 / accumulatedTimeSeconds
                let mbPerSecondAccumulatedAsStr = String(format: "%.1f", mbPerSecondAccumulated)
                logger.debug("\(description): \(diffMillisAsStr)ms; accumulated: \(accumulatedAsStr); count: \(count); avg time: \(avgAsStr)ms; \(mbPerSecondAccumulatedAsStr) MB/s")
            }
            else {
                if (count == 1) {
                    logger.debug("\(description): \(diffMillisAsStr)ms; accumulated: \(accumulatedAsStr); count: \(count); avg time: \(avgAsStr)ms")
                } else {
                    logger.debug("\(description): \(diffMillisAsStr)ms")
                }
            }

        }
    }
}
