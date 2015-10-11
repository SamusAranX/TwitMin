//
//  TMTweetWindow.swift
//  TwitMin
//
//  Created by Peter Wunder on 12.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//


import Cocoa
import Accounts
import Social
import CoreLocation

class TMTweetWindow: NSWindow, NSWindowDelegate, NSTextViewDelegate, NSTextStorageDelegate, CLLocationManagerDelegate {

	@IBOutlet var vfxView: NSVisualEffectView!
	
	@IBOutlet var tmTextView: NSTextView!
	@IBOutlet var tmAccountPopUp: NSPopUpButton!
	@IBOutlet var tmTextLengthLabel: NSTextField!
	@IBOutlet var tmTweetButton: NSButton!
	
	@IBOutlet var avatarViewContainer: NSView!
	@IBOutlet var avatarBackgroundView: NSImageView!
	@IBOutlet var avatarView: NSImageView!
	
	@IBOutlet var locationButton: NSButton!
	@IBOutlet var mediaButton: NSButton!
	
	var appDelegate: AppDelegate!
	var locationManager: CLLocationManager!
	var geoCoder: CLGeocoder!
	
//	var acStore: ACAccountStore!
//	var accountDict = [String:ACAccount]()
	
	// Here's a bunch of HTTP status codes, taken from Twitter's docs: https://dev.twitter.com/overview/api/response-codes
	let statusCodes = [
		200: "OK",
		304: "Not Modified",
		400: "Bad Request",
		401: "Unauthorized",
		403: "Forbidden",
		404: "Not Found",
		406: "Not Acceptable",
		410: "Gone",
		420: "420 Enhance Your Calm",
		422: "Unprocessable Entity",
		429: "Too Many Requests",
		500: "Internal Server Error",
		502: "Bad Gateway",
		503: "Service Unavailable",
		504: "Gateway timeout"
	]
	
	// And another bunch of codes, this time error codes from the Twitter API
	let errorCodes = [
		32: "Could not authenticate you",
		34: "Sorry, that page does not exist",
		64: "Your account is suspended and is not permitted to access this feature",
		68: "The Twitter REST API v1 is no longer active. Please migrate to API v1.1. https://dev.twitter.com/rest/public",
		88: "Rate limit exceeded",
		89: "Invalid or expired token",
		92: "SSL is required",
		130: "Over capacity",
		131: "Internal error",
		135: "Could not authenticate you",
		161: "You are unable to follow more people at this time",
		179: "Sorry, you are not authorized to see this status",
		185: "User is over daily status update limit",
		187: "Status is a duplicate",
		215: "Bad authentication data",
		226: "This request looks like it might be automated. To protect our users from spam and other malicious activity, we can’t complete this action right now.",
		231: "User must verify login",
		251: "This endpoint has been retired and should not be used.",
		261: "Application cannot perform write actions.",
		271: "You can’t mute yourself.",
		272: "You are not muting the specified user."
	]
	
	// Called in Tweet Window Controller
	func initialize() {
		self.titleVisibility = NSWindowTitleVisibility.Hidden
		
		self.appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
		
		self.delegate = self
		
		self.locationManager = CLLocationManager()
		self.locationManager.delegate = self
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
		self.locationManager.distanceFilter = 100
		self.geoCoder = CLGeocoder()
		
		self.tmTextView.font = NSFont.systemFontOfSize(12)
		self.tmTextView.textContainerInset = NSSize(width: 4, height: 8)
		self.tmTextView.textStorage!.delegate = self
		
		self.tmAccountPopUp.removeAllItems() // Remove Xcode's example items (Item 1, Item 2, etc.) from the popup button. (There has to be a better way of doing this)
		self.tmAccountPopUp.addItemsWithTitles(Array(appDelegate.accountDict.keys)) // Populate the account list
		
		self.avatarView.layer!.cornerRadius = self.avatarView.bounds.width / 2
		updateAvatarImageView()
	}
	
	func updateAvatarImageView() {
		let avatarImage = appDelegate.avatarDict[self.tmAccountPopUp.titleOfSelectedItem!]
		if avatarImage == nil {
			self.avatarView.image = NSImage(named: "DummyRect")
		} else {
			self.avatarView.image = appDelegate.avatarDict[self.tmAccountPopUp.titleOfSelectedItem!]
		}
	}
	
	func windowWillShow() {
		if !self.visible {
			let systemAppearanceName = (NSUserDefaults.standardUserDefaults().stringForKey("AppleInterfaceStyle") ?? "Light").lowercaseString
			let systemAppearance = systemAppearanceName == "dark" ? NSAppearance(named: NSAppearanceNameVibrantDark) : NSAppearance(named: NSAppearanceNameVibrantLight)
			self.appearance = systemAppearance
			
			self.tmTextView.string = ""
			self.tmTextLengthLabel.integerValue = 140
			self.tmTextLengthLabel.textColor = NSColor.labelColor()
			self.tmTweetButton.enabled = false
			
			self.locationButton.enabled = CLLocationManager.authorizationStatus() == .Authorized
			self.locationManager.startUpdatingLocation()
		}
	}
	
	// NSWindowDelegate
	func windowWillClose(notification: NSNotification) {
		println("Window will close")
		self.locationManager.stopUpdatingLocation()
	}
	
	@IBAction func accountListItemSelected(sender: NSPopUpButton) {
		updateAvatarImageView()
	}
	
	func textDidChange(notification: NSNotification) {
		// Trim whitespace and newlines from the tweet text
		if let tweetText = self.tmTextView.string {
			let trimmedTweetText = tweetText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
			let remainingChars = TwitterText.remainingCharacterCount(trimmedTweetText)
			self.tmTextLengthLabel.integerValue = remainingChars
			
			// Pretty sure that someone smarter than me could do this with Cocoa Bindings
			// I didn't because Cocoa Bindings don't make any damn sense
			self.tmTextLengthLabel.textColor = remainingChars >= 0 ? NSColor.labelColor() : NSColor(red:1, green:0.14, blue:0, alpha:1)
			self.tmTweetButton.enabled = remainingChars < 140 && remainingChars >= 0
		} else {
			println("Tweet text is nil")
		}
	}
	
	/*
	*   TEXT STORAGE DELEGATE STUFF
	*/
	
	override func textStorageDidProcessEditing(notification: NSNotification) {
		let textStorage: NSTextStorage = notification.object as! NSTextStorage
		let wholeRange = NSMakeRange(0, textStorage.length)
		textStorage.removeAttribute(NSForegroundColorAttributeName, range: wholeRange)
		textStorage.addAttribute(NSForegroundColorAttributeName, value: NSColor.labelColor(), range: wholeRange)
		
		let entities = TwitterText.entitiesInText(textStorage.string) as! [TwitterTextEntity]
//		println(entities)
		for e in entities {
			// Slightly darker blue on light background, slightly brighter blue on dark background
			let entityColor = self.appearance == NSAppearanceNameVibrantDark ? NSColor(red:0.08, green:0.49, blue:0.98, alpha:1) : NSColor(calibratedRed:0.51, green:0.75, blue:0.99, alpha:1)
			textStorage.addAttribute(NSForegroundColorAttributeName, value: entityColor, range: e.range)
		}
	}
	
	/*
	*	LOCATION MANAGER DELEGATE STUFF
	*/
	
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		println("Authorization changed to \(status.name())")
		self.locationButton.enabled = status == .Authorized
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		println("Location Manager failed with error: \(error)")
	}
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
		if !locations.isEmpty {
			println("Location was updated: \(locations.first)")
		} else {
			println("For some reason, the locations array is empty. Welp")
		}
	}
	
	/*
	*	BUTTON STUFF
	*/
	
	@IBAction func locationButtonPressed(sender: NSButton) {
//		println(self.appDelegate.locationManager.location)
		println("Use Location: \(sender.state == NSOnState)")
	}
	
	@IBAction func mediaImportButtonPressed(sender: NSButton) {
		println("Media Import Button pressed")
	}
	
	@IBAction func tweetButtonPressed(sender: NSButton) {
		// Disable button so that this can't be called twice by accident
		sender.enabled = false
		
		// Get the selected Twitter account
		let selectedAccount = appDelegate.accountDict[self.tmAccountPopUp.titleOfSelectedItem!]
		println(selectedAccount!)
		
		let tweetText = tmTextView.string!
		let tweetLocation = (locationButton.enabled && locationButton.state == NSOnState) ? locationManager.location : nil
		if TwitterText.remainingCharacterCount(tweetText) >= 0 && !tweetText.isEmpty {
			TweetWrapper.tweet(selectedAccount!, text: tmTextView.string!, location: tweetLocation) {
				(responseData, response, error) in
				
				do {
					// We'll try to parse Twitter's response here
					let responseObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments)
					println(responseObject)
				} catch {
					// We're not doing anything with the response object right now, so this is okay
					println("JSON object creation failed")
				}
				
				dispatch_async(dispatch_get_main_queue()) {
					if response.statusCode == 200 { // 200 = HTTP OK, Tweet was sent successfully
						println("Tweet sent!")
						self.close()
					} else { // Anything but HTTP 200, which means the whole thing failed
						if let errorMessage = self.statusCodes[response.statusCode] {
							println("HTTP \(response.statusCode): \(errorMessage)")
						} else {
							println("Unknown error: HTTP \(response.statusCode)")
						}
						
						// Re-enable the button
						sender.enabled = true
					}
				}
			}
		}
	}
}
