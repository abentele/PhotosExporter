//
//  StatusMenuController.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {

    private let logger = Logger(loggerName: "StatusMenuController", logLevel: .info)

    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var preferencesWindow: NSWindow!
    
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @IBOutlet weak var backupPlansMenuItem: NSMenuItem!
    
    var backupPlanMenuItems: [NSMenuItem] = []
    
    func updateMenu(preferences: Preferences) {
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
    }
    
    @objc func runExportTask(sender: AnyObject?) {
        if let menuItem = sender as? NSMenuItem, let plan = menuItem.representedObject as? Plan {
            logger.info("Start export using plan:\n\(plan.toYaml(indent: 10))")
            do {
                let photosExporter = try PhotosExporterFactory.createPhotosExporter(plan: plan)
                photosExporter.exportPhotos()
            } catch {
                print("Photos exporter could not be instantiated from preferences: \(String(describing: plan.name))")
            }
        }
    }
    
    @IBAction func preferencesClicked(_ sender: Any) {
        preferencesWindow.setIsVisible(true)
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

}
