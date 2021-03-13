//
//  AppDelegate.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 21.10.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Cocoa
import Photos

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let logger = Logger(loggerName: "AppDelegate", logLevel: .info)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) in
            if (status != PHAuthorizationStatus.authorized) {
                self.logger.warn("Not authorized to access the photo library. Abort.")
                return;
            }
            
            self.executeAllPlans()
            
            DispatchQueue.main.sync {
                NSApp.terminate(self)
            }
        });
    }
    
    func executeAllPlans() {
        var preferences: Preferences
        do {
            preferences = try PreferencesReader.readPreferencesFile()
        } catch {
            print("Error reading preferences: \(error)")
            return;
        }
        logger.info("Read preferences file; content:\n\(preferences.toYaml())")
        
        let photosMetadataReader = PhotosMetadataReader(config: preferences.config)
        photosMetadataReader.readMetadata(completion: {(photosMetadata: PhotosMetadata) in
            
            photosMetadata.rootCollection.printYaml(indent: 0)
            
            for plan in preferences.plans {
                // separator for multiple export jobs
                self.logger.info("")
                self.logger.info("=====================================================================")
                self.logger.info("")

                if plan.enabled {
                    self.logger.info("Start export using plan:\n\(plan.toYaml(indent: 10))")
                    do {
                        let photosExporter = try PhotosExporterFactory.createPhotosExporter(plan: plan)
                        photosExporter.exportPhotos(photosMetadata: photosMetadata)
                    } catch {
                        print("Error exporting photos for plan: \(String(describing: plan.name)); error: \(error)")
                    }
                } else {
                    self.logger.info("Ignore disabled plan: \(String(describing: plan.name))")
                }
            }
        });
        
        
        //PreferencesReader.writePreferencesFile(preferences: preferences)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }
    
}

