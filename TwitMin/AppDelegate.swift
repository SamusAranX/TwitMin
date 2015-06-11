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

	@IBOutlet weak var composeWindow: TMComposeWindow!
	@IBOutlet weak var preferencesWindow: NSWindow!
	
	@IBOutlet weak var statusBarMenu: NSMenu!
	
	var statusBarItem: NSStatusItem!
	var hotKeyCenter: DDHotKeyCenter!
	var composeHotKey: DDHotKey!

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "interfaceThemeChanged:", name: "AppleInterfaceThemeChangedNotification", object: nil)
		
		statusBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
		statusBarItem.menu = statusBarMenu
		let statusBarIcon = NSImage(named: "StatusBarIcon")
		statusBarIcon?.template = true
		statusBarItem.button!.image = statusBarIcon
		
		let systemAppearance = (NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") ?? "Light").lowercaseString
		
		preferencesWindow.appearance = NSAppearance(named: systemAppearance == "dark" ? NSAppearanceNameVibrantDark : NSAppearanceNameVibrantLight)
		composeWindow.appearance = NSAppearance(named: systemAppearance == "dark" ? NSAppearanceNameVibrantDark : NSAppearanceNameVibrantLight)
		composeWindow.initialize()
		
		hotKeyCenter = DDHotKeyCenter.sharedHotKeyCenter()
		// I'm using the KeyMaskHelper class below because Xcode is stupid and won't let me use things like NSCommandKeyMask directly
		composeHotKey = DDHotKey(keyCode: UInt16(kVK_Return), modifierFlags: KeyMaskHelper.cmdMask() | KeyMaskHelper.shiftMask(), task: {
			event in
			
			self.actuallyShowTweetWindow()
		})
		
		hotKeyCenter.registerHotKey(composeHotKey)
	}
	
	func interfaceThemeChanged(notification: NSNotification) {
		// If the user changed their system's color scheme, we're gonna know
		let systemAppearance = (NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") ?? "Light").lowercaseString
		composeWindow.systemThemeChanged(systemAppearance)
	}

	// IBAction that gets called from the menu bar item
	@IBAction func showTweetWindow(sender: NSMenuItem) {
		self.actuallyShowTweetWindow()
	}
	
	func actuallyShowTweetWindow() {
		println("Show Tweet Window!")
		
		// Bring window to front, no matter where it is
		NSApp.activateIgnoringOtherApps(true)
		
		if !composeWindow.visible { // The window is not open right now, this makeKeyAndOrderFront call is opening it
			composeWindow.heyListen()
		}
		composeWindow.makeKeyAndOrderFront(nil)
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

