//
//  TMTweetWindowController.swift
//  TwitMin
//
//  Created by Peter Wunder on 12.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

class TMTweetWindowController: NSWindowController {
	
	var tweetWindow: TMTweetWindow { return self.window as! TMTweetWindow }

    override func windowDidLoad() {
        super.windowDidLoad()

		println("Initializing Tweet Window")
		self.tweetWindow.initialize()
		
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
	
	override func showWindow(sender: AnyObject?) {
		self.tweetWindow.windowWillShow()
		
		super.showWindow(sender)
		
		println("Showing Tweet Window")
	}
    
}
