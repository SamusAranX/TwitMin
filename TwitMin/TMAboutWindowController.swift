//
//  TMAboutWindowController.swift
//  TwitMin
//
//  Created by Peter Wunder on 12.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

class TMAboutWindowController: NSWindowController {

	var aboutWindow: TMAboutWindow { return self.window as! TMAboutWindow }
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		println("Initializing About Window")
		self.aboutWindow.initialize()
		
		// Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	}

	
}
