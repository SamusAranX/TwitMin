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
import CoreLocation
import Accounts

/* Silly not-quite-hack to work around a bug in the first beta of Swift 2.0
where the print() function sometimes called the print() function for actual printing */
func println<T>(value: T) {
	print(value)
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
	
	var tweetWindowController: TMTweetWindowController!
	var preferencesWindowController: TMPreferencesWindowController!
	var aboutWindowController: TMAboutWindowController!
	
	@IBOutlet weak var statusBarMenu: NSMenu!
	
	// These will all get set in applicationDidFinishLaunching
	var statusBarItem: NSStatusItem!
	var hotKeyCenter: DDHotKeyCenter!
	var composeHotKey: DDHotKey!
	var locationManager: CLLocationManager!
	
	var accountStore: ACAccountStore!
	var accountDict: [String: ACAccount]!
	var avatarDict: [String: NSImage]!
	
	var accountsScript: NSAppleScript! // Opens the 'Internet Accounts' preference pane
	var privacyScript: NSAppleScript! // Opens the 'Security' preference pane, showing the 'Privacy' section
	
	var UIColorDict: Dictionary<String, NSColor>?
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Add system theme change listener
		NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: "systemThemeChanged:", name: "AppleInterfaceThemeChangedNotification", object: nil)
		
		// Load colors from UIColors.plist, we'll probably use them in a later version
		if let path = NSBundle.mainBundle().pathForResource("UIColors", ofType: "plist") {
			UIColorDict = Dictionary<String, NSColor>()
			let dict = NSDictionary(contentsOfFile: path) as! Dictionary<String, String>
			for key in dict.keys {
				UIColorDict![key] = NSColor(hexString: dict[key]!)
			}
		} else {
			println("Couldn't load UIColors.plist, something is really wrong")
		}
		
		// Initialize the status bar icon
		statusBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
		statusBarItem.menu = statusBarMenu
		let statusBarIcon = NSImage(named: "StatusBarIcon")
		statusBarIcon!.template = true
		statusBarItem.button!.image = statusBarIcon
		
		// Get ahold of the window controllers
		tweetWindowController = TMTweetWindowController(windowNibName: "TMTweetWindow")
		preferencesWindowController = TMPreferencesWindowController(windowNibName: "TMPreferencesWindow")
		aboutWindowController = TMAboutWindowController(windowNibName: "TMAboutWindow")
		
		// Initialize the tweet window hotkey
		hotKeyCenter = DDHotKeyCenter.sharedHotKeyCenter()
		let hotKeyOptionSet: NSEventModifierFlags = [.CommandKeyMask, .ShiftKeyMask]
		composeHotKey = DDHotKey(keyCode: UInt16(kVK_Return), modFlags: hotKeyOptionSet, task: {
			event in
			
			self.actuallyShowTweetWindow()
		})
		hotKeyCenter.registerHotKey(composeHotKey)
		
		// Get all registered Twitter accounts
		accountStore = ACAccountStore()
		let accType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
		
		accountStore.requestAccessToAccountsWithType(accType, options: nil) {
			(granted, error) in
			
			if granted { // Access to Twitter accounts granted
				let twitterAccounts = self.accountStore.accountsWithAccountType(accType) as! [ACAccount]
				if (self.accountStore.accounts != nil) && !self.accountStore.accounts!.isEmpty && !twitterAccounts.isEmpty {
					println(twitterAccounts)
					
					self.accountDict = [String: ACAccount]()
					self.avatarDict = [String: NSImage]()
					for t in twitterAccounts {
						self.accountDict[t.username] = t
						
						TweetWrapper.getUserAvatar(t) {
							(image) in
							
							if image != nil {
								self.avatarDict[t.username] = image
							} else {
								println("Couldn't retrieve avatar for \(t.username)")
							}
						}
					}
				} else { // There are no Twitter accounts
					let alert = self.prepareAlert("No Twitter accounts found",
						message: "To use TwitMin, you'll need to have at least one Twitter account set up in OS X.\nTo do that, go to System Preferences → Internet Accounts.",
						buttons: ["Quit", "Open System Preferences…"])
					
					let alertResult = alert.runModal()
					switch(alertResult) {
					case NSAlertFirstButtonReturn:
						println("Quitting") // Do nothing, we'll quit in a second anyway
					case NSAlertSecondButtonReturn:
						println("Opening InternetAccounts.prefPane")
						self.accountsScript.executeAndReturnError(nil)
					default:
						// what
						println("what")
					}
					
					NSApp.terminate(self)
				}
			} else { // Access denied
				let alert = self.prepareAlert("Can't access Twitter",
					message: "TwitMin needs access to Twitter in order to post tweets.\nGo to System Preferences → Security & Privacy → Privacy and allow TwitMin to access Twitter.",
					buttons: ["Quit", "Open System Preferences…"])
				
				let alertResult = alert.runModal()
				switch(alertResult) {
				case NSAlertFirstButtonReturn:
					println("Quitting") // Do nothing, we'll quit in a second anyway
				case NSAlertSecondButtonReturn:
					println("Opening Security.prefPane")
					self.privacyScript.executeAndReturnError(nil)
				default:
					// what
					println("what")
				}
				
				NSApp.terminate(self)
			}
		}
		
		// Load AppleScripts
		let asPath1 = NSBundle.mainBundle().pathForResource("PrefAccounts", ofType: "scpt")!
		let asPath2 = NSBundle.mainBundle().pathForResource("PrefPrivacy", ofType: "scpt")!
		let asURL1 = NSURL(fileURLWithPath: asPath1)
		let asURL2 = NSURL(fileURLWithPath: asPath2)
		accountsScript = NSAppleScript(contentsOfURL: asURL1, error: nil)
		privacyScript = NSAppleScript(contentsOfURL: asURL2, error: nil)
		
		// Initialize the location manager, but don't start it yet
		// We'll do that on the first activation of the location button inside the tweet window
		locationManager = CLLocationManager()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.distanceFilter = 100
		//locationManager.startUpdatingLocation()
	}
	
	// This method creates a ready-made NSAlert for us
	// This isn't really needed, I just did this to minimize NSAlert-related code below
	func prepareAlert(title: String, message: String, buttons: [String]) -> NSAlert {
		let alert = NSAlert()
		alert.alertStyle = .WarningAlertStyle
		alert.messageText = title
		alert.informativeText = message
		for b in buttons {
			alert.addButtonWithTitle(b)
		}
		return alert
	}
	
	func systemThemeChanged(notification: NSNotification) {
		// If the user changes their system's color scheme, we'll know
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
	
	/*
	*	LOCATION MANAGER DELEGATE STUFF
	*/
	
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		println("Authorization changed to \(status.name())")
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		println("Location Manager failed with error: \(error)")
	}
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
		if !locations.isEmpty {
			println("Location was updated")
		} else {
			println("For some reason, the locations array is empty. Welp")
		}
	}
	
}

