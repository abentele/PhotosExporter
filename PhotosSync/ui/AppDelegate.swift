//
//  AppDelegate.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 21.10.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    private let logger = Logger(loggerName: "AppDelegate", logLevel: .info)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let preferences = PreferencesReader.readPreferencesFile()
        logger.info("Read preferences file; content:\n\(preferences.toYaml())")

        for plan in preferences.plans {
            // separator for multiple export jobs
            logger.info("")
            logger.info("=====================================================================")
            logger.info("")
            
            if plan.enabled {
                logger.info("Start export using plan:\n\(plan.toYaml(indent: 10))")
                do {
                    let photosExporter = try PhotosExporterFactory.createPhotosExporter(plan: plan)
                    photosExporter.exportPhotos()
                } catch {
                    print("Photos exporter could not be instantiated from preferences: \(String(describing: plan.name))")
                }
            } else {
                logger.info("Ignore disabled plan: \(String(describing: plan.name))")
            }
        }
        
        //PreferencesReader.writePreferencesFile(preferences: preferences)

        NSApp.terminate(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
}

