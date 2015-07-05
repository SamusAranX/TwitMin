//
//  AppDelegate.swift
//  TwitMin
//
//  Created by Peter Wunder on 09.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import AppKit
import Cocoa
import Carbon

/* Silly not-quite-hack to work around a bug in the first beta of Swift 2.0 
where the print() function sometimes called the print() function for actual printing */
func println<T>(value: T) {
	print(value)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var tweetWindowController: TMTweetWindowController!
	var preferencesWindowController: TMPreferencesWindowController!
	var aboutWindowController: TMAboutWindowController!
	
	@IBOutlet weak var statusBarMenu: NSMenu!
	
	var statusBarItem: NSStatusItem!
	var hotKeyCenter: DDHotKeyCenter!
	var composeHotKey: DDHotKey!

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "systemThemeChanged:", name: "AppleInterfaceThemeChangedNotification", object: nil)
		
		statusBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
		statusBarItem.menu = statusBarMenu
		let statusBarIcon = NSImage(named: "StatusBarIcon")
		statusBarIcon?.template = true
		statusBarItem.button!.image = statusBarIcon
		
		tweetWindowController = TMTweetWindowController(windowNibName: "TMTweetWindow")
		preferencesWindowController = TMPreferencesWindowController(windowNibName: "TMPreferencesWindow")
		aboutWindowController = TMAboutWindowController(windowNibName: "TMAboutWindow")
		
		hotKeyCenter = DDHotKeyCenter.sharedHotKeyCenter()
		let hotKeyOptionSet: NSEventModifierFlags = [.CommandKeyMask, .ShiftKeyMask]
		composeHotKey = DDHotKey(keyCode: UInt16(kVK_Return), modFlags: hotKeyOptionSet, task: {
			event in
			
			self.actuallyShowTweetWindow()
		})
		
		hotKeyCenter.registerHotKey(composeHotKey)
	}
	
	func systemThemeChanged(notification: NSNotification) {
		// If the user changed their system's color scheme, we're gonna know
		let systemAppearanceName = (NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") ?? "Light").lowercaseString
		let systemAppearance = systemAppearanceName == "dark" ? NSAppearance(named: NSAppearanceNameVibrantDark) : NSAppearance(named: NSAppearanceNameVibrantLight)
		
		if tweetWindowController.window != nil && tweetWindowController.window!.visible {
			tweetWindowController.window?.appearance = systemAppearance
		}
		
		// On second thought, let's not do this
//		if preferencesWindowController.window != nil && preferencesWindowController.window!.visible {
//			preferencesWindowController.window?.appearance = systemAppearance
//		}
//		if aboutWindowController.window != nil && aboutWindowController.window!.visible {
//			aboutWindowController.window?.appearance = systemAppearance
//		}
	}

	// IBAction that gets called from the menu bar item
	@IBAction func showTweetWindow(sender: NSMenuItem) {
		self.actuallyShowTweetWindow()
	}
	
	func actuallyShowTweetWindow() {
		println("Show Tweet Window!")
		
		NSApp.activateIgnoringOtherApps(true)
		tweetWindowController.showWindow(nil)
	}
	
	@IBAction func showAboutWindow(sender: NSMenuItem) {
		NSApp.activateIgnoringOtherApps(true)
		aboutWindowController.showWindow(nil)
		println(aboutWindowController.window)
	}
	
	@IBAction func quitApp(sender: NSMenuItem) {
		NSApp.terminate(self)
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
		println("Deregistering hotkeys")
		hotKeyCenter.unregisterAllHotKeys()
	}


}

