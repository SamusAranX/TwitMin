//
//  TMPreferencesWindow.swift
//  TwitMin
//
//  Created by Peter Wunder on 22.07.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

class TMPreferencesWindow: NSWindow, NSToolbarDelegate {

	func initialize() {
		self.toolbar!.delegate = self
	}
	
	func windowWillShow() {
//        if !isVisible {
//			self.toolbar!.selectedItemIdentifier = self.toolbar!.items[0].itemIdentifier
//        }
	}
	
	@IBAction func toolbarItemSelected(_ sender: NSToolbarItem) {
		println(sender.itemIdentifier)
	}
	
	func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		var itemIdentifiers = [NSToolbarItem.Identifier]()
		for item in toolbar.items {
			itemIdentifiers.append(item.itemIdentifier)
		}
		return itemIdentifiers
	}
	
}
