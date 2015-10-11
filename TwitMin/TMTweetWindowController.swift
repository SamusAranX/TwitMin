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

		self.tweetWindow.initialize()
		
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
	
	func avatarImageDownloaded(username: String) {
		dispatch_async(dispatch_get_main_queue()) {
			self.tweetWindow.updateAvatarImageView()
		}
	}
	
	override func showWindow(sender: AnyObject?) {
		self.tweetWindow.windowWillShow()
		
		super.showWindow(sender)
	}
    
}
