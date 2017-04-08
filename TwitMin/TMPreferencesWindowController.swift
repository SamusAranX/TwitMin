//
//  TMPreferencesWindowController.swift
//  TwitMin
//
//  Created by Peter Wunder on 12.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

class TMPreferencesWindowController: NSWindowController {
	
	var preferencesWindow: TMPreferencesWindow { return self.window as! TMPreferencesWindow }

    override func windowDidLoad() {
        super.windowDidLoad()
		
		self.preferencesWindow.initialize()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
	
	override func showWindow(_ sender: Any?) {
		self.preferencesWindow.windowWillShow()
		
		super.showWindow(sender)
	}
    
}
