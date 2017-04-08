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
    }
	
	func avatarImageDownloaded(_ username: String) {
		DispatchQueue.main.async {
			self.tweetWindow.updateAvatarImageView()
		}
	}
	
	override func showWindow(_ sender: Any?) {
		self.tweetWindow.windowWillShow()
		
		super.showWindow(sender)
	}
    
}
