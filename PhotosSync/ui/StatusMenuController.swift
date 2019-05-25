//
//  StatusMenuController.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 24.05.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var preferencesWindow: NSWindow!
    
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    override func awakeFromNib() {
        statusBarItem.menu = statusMenu
        
        if let button = statusBarItem.button {
            button.image = NSImage(named: "statusBarIcon")
            
            // for dark mode, automatically invert the image
            button.image?.isTemplate = true
        }
    }
    
    @IBAction func preferencesClicked(_ sender: Any) {
        preferencesWindow.setIsVisible(true)
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

}
