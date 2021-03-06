//
//  StatusMenuController.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2021 Andreas Bentele. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {

    private let logger = Logger(loggerName: "StatusMenuController", logLevel: .info)

    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @IBOutlet weak var backupPlansMenuItem: NSMenuItem!
    
    var backupPlanMenuItems: [NSMenuItem] = []
    
    var preferencesWindowController: PreferencesWindowController?
    
    var preferences: Preferences?
    
    func updateMenu(preferences: Preferences) {
        self.preferences = preferences
        
        // remove previous items
        for menuItem in backupPlanMenuItems {
            statusMenu.removeItem(menuItem)
        }
        backupPlanMenuItems = []
        
        for plan in preferences.plans {
            if (plan.enabled) {
                var title: String
                if let name = plan.name {
                    title = "   " + name
                } else {
                    title = "   <untitled>"
                }
                let menuItem : NSMenuItem = NSMenuItem(title: title, action: #selector(runExportTask(sender:)), keyEquivalent: "")
                menuItem.representedObject = plan
                menuItem.target = self
                //runSubmenu.addItem(menuItem)
                statusMenu.insertItem(menuItem, at: statusMenu.index(of: backupPlansMenuItem) + 1)
                backupPlanMenuItems.append(menuItem)
            }
        }
    }
    
    override func awakeFromNib() {
        statusBarItem.menu = statusMenu
        
        if let button = statusBarItem.button {
            button.image = NSImage(named: "statusBarIcon")
            
            // for dark mode, automatically invert the image
            button.image?.isTemplate = true
        }
        
        //preferencesClicked(self)
    }
    
    @objc func runExportTask(sender: AnyObject?) {
        if let menuItem = sender as? NSMenuItem, let plan = menuItem.representedObject as? Plan {
            logger.info("Start export using plan:\n\(plan.toYaml(indent: 10))")
            
            let photosMetadataReader = PhotosMetadataReader()
            photosMetadataReader.readMetadata(completion: {(photosMetadata: PhotosMetadata) in
                do {
                    let photosExporter = try PhotosExporterFactory.createPhotosExporter(plan: plan)
                    photosExporter.exportPhotos(photosMetadata: photosMetadata)
                } catch {
                    print("Photos exporter could not be instantiated from preferences: \(String(describing: plan.name))")
                }
            });
        }
    }
    
    @IBAction func preferencesClicked(_ sender: Any) {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController!.showWindow(nil)
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

}
