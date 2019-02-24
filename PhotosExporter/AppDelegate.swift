//
//  AppDelegate.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 21.10.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.close()
        export()
        NSApp.terminate(self)
    }

}

