//
//  PreferencesWindowController.swift
//  PhotosSync
//
//  Created by Andreas Bentele on 11.06.19.
//  Copyright © 2019 Andreas Bentele. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {

    var generalSettingsViewController: GeneralSettingsViewController?
    var plansViewController: PlansViewController?
    var currentView: NSView?
    
    @IBOutlet weak var toolBar: NSToolbar!
    @IBOutlet weak var generalToolbarButton: NSToolbarItem!
    @IBOutlet weak var plansToolbarButton: NSToolbarItem!

    override var windowNibName: String! {
        return "PreferencesWindow"
    }
    
    init() {
        super.init(window: nil) // Call this to get NSWindowController to init with the windowNibName property
    }

    // Override this as required per the class spec
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init()")
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        toolbarButtonGeneralClicked(self)
    }
    
    @IBAction func toolbarButtonGeneralClicked(_ sender: Any) {
        if (generalSettingsViewController == nil) {
            generalSettingsViewController = GeneralSettingsViewController()
        }
        switchToView(viewController: generalSettingsViewController!, toolbarItem: generalToolbarButton)
        //toolBar.selectedItemIdentifier = generalToolbarButton.itemIdentifier
    }
    
    @IBAction func toolbarButtonPlansClicked(_ sender: Any) {
        if (plansViewController == nil) {
            plansViewController = PlansViewController()
        }
        switchToView(viewController: plansViewController!, toolbarItem: plansToolbarButton)
        //toolBar.selectedItemIdentifier = plansToolbarButton.itemIdentifier
    }

    func switchToView(viewController: NSViewController, toolbarItem: NSToolbarItem) {
        let view = viewController.view
        
        toolBar.selectedItemIdentifier = toolbarItem.itemIdentifier
        
        self.window!.title = toolbarItem.label
        
        if let currentView = currentView {
            currentView.removeFromSuperview()
        }
        
        var windowFrame: CGRect = self.window!.frame;
        let currentContentViewFrame = self.window!.contentView!.frame;
        let nextViewFrame = view.frame;
        
        let wd: CGFloat = NSWidth(currentContentViewFrame) - NSWidth(nextViewFrame);
        let hd: CGFloat = NSHeight(currentContentViewFrame) - NSHeight(nextViewFrame);
        
        if(hd < 0) {
            windowFrame.size.height += hd * -1;
            windowFrame.origin.y -= hd * -1;
        } else {
            windowFrame.size.height -= hd;
            windowFrame.origin.y += hd;
        }
        
        if(wd < 0) {
            windowFrame.size.width += wd * -1;
        } else {
            windowFrame.size.width -= wd;
        }
        
        self.window!.setFrame(windowFrame, display:true, animate:true)
        
        self.window!.contentView!.addSubview(view);
        
        currentView = view
    }
}
