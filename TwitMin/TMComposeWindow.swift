//
//  TMComposeWindow.swift
//  TwitMin
//
//  Created by Peter Wunder on 09.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import Accounts
import Social

class TMComposeWindow: NSWindow, NSTextViewDelegate {
	
	// The two NSVisualEffectViews behind the text view and the bottom view with the buttons
	@IBOutlet var upperVFXView: NSVisualEffectView!
	@IBOutlet var lowerVFXView: NSVisualEffectView!
	
	// The window's UI elements
	@IBOutlet var composeTextView: NSTextView!
	@IBOutlet var composeLengthLabel: NSTextField!
	@IBOutlet var composeAccountPopUp: NSPopUpButton!
	@IBOutlet var composeSendButton: NSButton!
	
	let twitterText = TwitterText()
	var acStore: ACAccountStore!
	var accountDict = [String:ACAccount]()
	
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
	
	func initialize() {
		self.titleVisibility = NSWindowTitleVisibility.Hidden
		
		self.composeTextView.textContainerInset = NSSize(width: 10, height: 10)
		//self.composeTextView.insertionPointColor = NSColor.labelColor()
		self.composeTextView.textColor = NSColor.labelColor()
		
		self.composeAccountPopUp.removeAllItems() // Remove Xcode's example items (Item 1, Item 2, etc.) from the popup button
		
		acStore = ACAccountStore()
		
		let accType = acStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter) // We want only the Twitter accounts
		
		acStore.requestAccessToAccountsWithType(accType, options: nil) { // Ask the user for permission to access their Twitter accounts
			(granted, error) in
			
			if granted { // We may access their Twitter accounts
				println("Permission granted")
				if (self.acStore.accounts != nil) && self.acStore.accounts?.count > 0 { // Are there even any Twitter accounts?
					println("Listing Twitter accounts")
					let twitterAccounts = self.acStore.accountsWithAccountType(accType) as! [ACAccount] // Get a list of ACAccounts
					for t in twitterAccounts {
						self.accountDict[t.username] = t // Add those ACAccounts to a dictionary
					}
					println(self.accountDict) // Print the dictionary for good measure
					self.composeAccountPopUp.addItemsWithTitles(self.accountDict.keys.array) // Populate the account list
				} else { // There are no Twitter accounts registered in OS X
					println("No Twitter accounts found")
					
					// Prepare an NSAlert
					let alert = self.prepareAlert("No Twitter accounts found",
						message: "To use TwitMin, you'll need to have at least one Twitter account set up in OS X.\nTo do that, go to System Preferences → Internet Accounts.",
						buttons: ["Quit", "Open System Preferences…"])
					
					dispatch_async(dispatch_get_main_queue()) {
						// The callback we're in right now isn't happening on the main thread, so I use dispatch_async to show the NSAlert on the main thread
						alert.beginSheetModalForWindow(self, completionHandler: {
							result in
							
							switch(result) {
							case NSAlertFirstButtonReturn:
								// User clicked the Quit button, do nothing
								println("Quitting")
							case NSAlertSecondButtonReturn:
								// User clicked the Open System Preferences button, do just that
								println("Opening InternetAccounts.prefPane")
								NSWorkspace.sharedWorkspace().openURL(NSURL(fileURLWithPath: "/System/Library/PreferencePanes/InternetAccounts.prefPane"))
							default:
								// what
								println("How the frick did you even get here")
							}
							
							self.close() // There's nothing we can do. Just quit
						})
					}
				}
			} else { // We may not access their Twitter accounts
				println("Permission denied")
				
				// Same as above
				let alert = self.prepareAlert("Can't access Twitter",
					message: "TwitMin needs access to Twitter in order to post tweets.\nGo to System Preferences → Security & Privacy → Privacy and allow TwitMin to access Twitter.",
					buttons: ["Quit", "Open System Preferences…"])
				dispatch_async(dispatch_get_main_queue()) {
					alert.beginSheetModalForWindow(self, completionHandler: {
						result in
						
						switch(result) {
						case NSAlertFirstButtonReturn:
							println("Quitting")
						case NSAlertSecondButtonReturn:
							println("Opening Security.prefPane")
							NSWorkspace.sharedWorkspace().openURL(NSURL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
							// TODO: Actually open Sys Prefs on Privacy Tab
						default:
							println("How the frick did you even get here")
						}
						
						self.close() // There's nothing we can do. Just quit
					})
				}
				
			}
		}
	}
	
	func tweetTextChange() {
		// Trim whitespace and newlines from the tweet text
		if let tweetText = composeTextView.string {
			let trimmedTweetText = tweetText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
			let remainingChars = TwitterText.remainingCharacterCount(trimmedTweetText)
			composeLengthLabel.integerValue = remainingChars
			
			// Pretty sure that someone more skilled than me could do this with Cocoa Bindings
			// I didn't because Cocoa Bindings don't make any damn sense
			composeLengthLabel.textColor = remainingChars >= 0 ? NSColor.labelColor() : NSColor(red:1, green:0.14, blue:0, alpha:1)
			composeSendButton.enabled = remainingChars < 140 && remainingChars >= 0
		} else {
			println("Tweet text is nil")
		}
	}
	
	func heyListen() {
		composeTextView.string = ""
		tweetTextChange()
	}
	
	func textDidChange(notification: NSNotification) {
		tweetTextChange()
	}
	
	func systemThemeChanged(themeName: String) {
		if themeName == "dark" {
			self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
		} else {
			self.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
		}
	}
	
	@IBAction func sendTweetClicked(sender: NSButton) {
		// Disable button so that this can't be called twice by accident
		sender.enabled = false
		
		// Get the selected Twitter account
		let selectedAccount = accountDict[composeAccountPopUp.titleOfSelectedItem!]
		println(selectedAccount)
		
		// Trim whitespace and newlines from the tweet text
		let tweetText = composeTextView.string?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		
		// Check whether the tweet's length is valid
		if composeLengthLabel.integerValue >= 0 && tweetText != "" {
			let parameters = ["status" : tweetText!] // Twitter API stuff, we're setting the actual tweet text here
			
			// let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json") // This is the endpoint we'll use to upload images
			let requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json") // This is the regular text-only endpoint
			
			// Create a tweet post request
			let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.POST, URL: requestURL, parameters: parameters)
			postRequest.account = selectedAccount! // Use the selected Twitter account for posting
			
			// Perform the request
			postRequest.performRequestWithHandler {
				responseData, response, error in
				
				do {
					// We'll try to parse Twitter's response here
					let responseObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments)
					println(responseObject)
				} catch {
					// We're not doing anything with the response object right now, so this is okay
					println("JSON object creation failed")
				}
				
				// We're doing this next bit on the main thread because this callback is running on a different thread
				// Not doing this on the main thread creates problems when the window is closed
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
						
						// TODO: Actual error handling
					}
				}
			}
		} else {
			// This should never be reached
			println("Tweet is an empty string")
		}
	}
	
}