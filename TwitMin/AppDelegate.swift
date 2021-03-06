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
import Accounts

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	var tweetWindowController: TMTweetWindowController!
	var preferencesWindowController: TMPreferencesWindowController!
	var aboutWindowController: TMAboutWindowController!
	
	@IBOutlet weak var statusBarMenu: NSMenu!
	
	// These will all get set in applicationDidFinishLaunching
	var statusBarItem: NSStatusItem!
	var hotKeyCenter: DDHotKeyCenter!
	var composeHotKey: DDHotKey!
	
	var accountStore: ACAccountStore!
	var accountDict: [String: ACAccount]!
	var avatarDict: [String: NSImage]!
	
	var accountsScript: NSAppleScript! // Opens the 'Internet Accounts' preference pane
	var privacyScript: NSAppleScript! // Opens the 'Security' preference pane, showing the 'Privacy' section
	
	var UIColorDict: Dictionary<String, NSColor>!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Add system theme change listener
		DistributedNotificationCenter.default().addObserver(self, selector: #selector(systemThemeChanged), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
		
		// Load colors from UIColors.plist, we'll probably use them in a later version
		if let path = Bundle.main.path(forResource: "UIColors", ofType: "plist") {
			UIColorDict = Dictionary<String, NSColor>()
			let dict = NSDictionary(contentsOfFile: path) as! Dictionary<String, String>
			for key in dict.keys {
				UIColorDict[key] = NSColor(hexString: dict[key]!)
			}
		} else {
			println("Couldn't load UIColors.plist, something is really wrong")
		}
		
		// Initialize the status bar icon
		statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		statusBarItem.menu = statusBarMenu
		let statusBarIcon = #imageLiteral(resourceName: "StatusBarIcon")
		statusBarIcon.isTemplate = true
		statusBarItem.button!.image = statusBarIcon
		
		// Get ahold of the window controllers
        let tweetWindowControllerName = NSNib.Name("TMTweetWindow")
        let preferencesWindowControllerName = NSNib.Name("TMPreferencesWindow")
        let aboutWindowControllerName = NSNib.Name("TMAboutWindow")
		tweetWindowController = TMTweetWindowController(windowNibName: tweetWindowControllerName)
		preferencesWindowController = TMPreferencesWindowController(windowNibName: preferencesWindowControllerName)
		aboutWindowController = TMAboutWindowController(windowNibName: aboutWindowControllerName)
		
		// Initialize the tweet window hotkey
		hotKeyCenter = DDHotKeyCenter.shared()
		let hotKeyOptionSet: NSEvent.ModifierFlags = [.command, .shift]
		composeHotKey = DDHotKey(keyCode: UInt16(kVK_Return), modifierFlags: hotKeyOptionSet.rawValue, task: {
			event in
			
			self.actuallyShowTweetWindow()
		})
		hotKeyCenter.register(composeHotKey)
        
        // Load AppleScripts
        let asPath1 = Bundle.main.path(forResource: "PrefAccounts", ofType: "scpt")!
        let asPath2 = Bundle.main.path(forResource: "PrefPrivacy", ofType: "scpt")!
        let asURL1 = URL(fileURLWithPath: asPath1)
        let asURL2 = URL(fileURLWithPath: asPath2)
        accountsScript = NSAppleScript(contentsOf: asURL1, error: nil)
        privacyScript = NSAppleScript(contentsOf: asURL2, error: nil)
		
		// Get all registered Twitter accounts
		accountStore = ACAccountStore()
		let accType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        
        guard (accType != nil) else {
            println("accType is nil, abandon all hope")
            NSApp.terminate(self)
            return
        }
		
		accountStore.requestAccessToAccounts(with: accType!, options: nil) {
			(granted, error) in
            
            guard (error != nil) else {
                println("Error!")
                println(error)
                NSApp.terminate(self)
                return
            }
			
			if granted { // Access to Twitter accounts granted
				let twitterAccounts = self.accountStore.accounts(with: accType) as! [ACAccount]
				if (self.accountStore.accounts != nil) && self.accountStore.accounts!.count > 0 && !twitterAccounts.isEmpty {
					println(twitterAccounts)
					
					self.accountDict = [String: ACAccount]()
					self.avatarDict = [String: NSImage]()
					for t in twitterAccounts {
						self.accountDict[t.username] = t
						
						TweetWrapper.getUserAvatar(t) {
							(image) in
							
							if image != nil {
								self.avatarDict[t.username] = image
								self.tweetWindowController.avatarImageDownloaded(t.username)
							} else {
								println("Couldn't retrieve avatar for \(t.username)")
							}
						}
					}
				} else { // There are no Twitter accounts
                    DispatchQueue.main.async {
                        let alert = self.prepareAlert("No Twitter accounts found",
                                                      message: "To use TwitMin, you'll need to have at least one Twitter account set up in macOS.\nTo do that, go to System Preferences → Internet Accounts.",
                                                      buttons: ["Quit", "Open System Preferences…"])
                        let alertResult = alert.runModal()
                        switch(alertResult) {
                        case .alertFirstButtonReturn:
                            println("Quitting") // Do nothing, we'll quit in a second anyway
                        case .alertSecondButtonReturn:
                            println("Opening InternetAccounts.prefPane")
                            self.accountsScript.executeAndReturnError(nil)
                        default:
                            // what
                            println("what")
                        }
                        
                        NSApp.terminate(self)
                    }
				}
			} else { // Access denied
                DispatchQueue.main.async {
                    let alert = self.prepareAlert("Can't access Twitter",
                                                  message: "TwitMin needs access to Twitter in order to post tweets.\nGo to System Preferences → Security & Privacy → Privacy and allow TwitMin to access Twitter.",
                                                  buttons: ["Quit", "Open System Preferences…"])
                    let alertResult = alert.runModal()
                    switch(alertResult) {
                    case .alertFirstButtonReturn:
                        println("Quitting") // Do nothing, we'll quit in a second anyway
                    case .alertSecondButtonReturn:
                        println("Opening Security.prefPane")
                        self.privacyScript.executeAndReturnError(nil)
                    default:
                        // what
                        println("what")
                    }
                    
                    NSApp.terminate(self)
                }
			}
		}
	}
	
	// This method creates a ready-made NSAlert for us
	// This isn't really needed, I just did this to minimize NSAlert-related code
	func prepareAlert(_ title: String, message: String, buttons: [String]) -> NSAlert {
		let alert = NSAlert()
		alert.alertStyle = .warning
		alert.messageText = title
		alert.informativeText = message
		for b in buttons {
			alert.addButton(withTitle: b)
		}
		return alert
	}
	
	@objc func systemThemeChanged(_ notification: Notification) {
		// If the user changes their system's color scheme, we'll know
        let systemAppearanceName = (UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light").lowercased()
		let systemAppearance = systemAppearanceName == "dark" ? NSAppearance(named: NSAppearance.Name.vibrantDark) : NSAppearance(named: NSAppearance.Name.vibrantLight)
		
		if tweetWindowController.window != nil && tweetWindowController.window!.isVisible {
			tweetWindowController.window?.appearance = systemAppearance
		}
	}
	
	// IBAction that gets called from the menu bar item
	@IBAction func showTweetWindow(_ sender: NSMenuItem) {
		self.actuallyShowTweetWindow()
	}
	
	@IBAction func showPreferencesWindow(_ sender: AnyObject) {
		NSApp.activate(ignoringOtherApps: true)
		preferencesWindowController.showWindow(nil)
	}
	
	func actuallyShowTweetWindow() {
		NSApp.activate(ignoringOtherApps: true)
		tweetWindowController.showWindow(nil)
	}
	
	@IBAction func showAboutWindow(_ sender: NSMenuItem) {
		NSApp.activate(ignoringOtherApps: true)
		aboutWindowController.showWindow(nil)
		println(aboutWindowController.window)
	}
	
	@IBAction func quitApp(_ sender: NSMenuItem) {
		NSApp.terminate(self)
	}
	
	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
		println("Deregistering hotkeys")
		hotKeyCenter.unregisterAllHotKeys()
	}
	
}

