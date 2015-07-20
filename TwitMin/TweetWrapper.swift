//
//  TweetWrapper.swift
//  TwitMin
//
//  Created by Peter Wunder on 18.07.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import Accounts
import Social
import CoreLocation

class TweetWrapper: NSObject {
	
	class func getUserAvatar(account: ACAccount, completion: (NSImage?) -> ()) {
		let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first
		let imagePath = documentsPath!.stringByAppendingPathComponent("avatar_\(account.username).png")
		let defaultsKey = "avatarURL_\(account.username)"
		let fileManager = NSFileManager()
		
		let requestURL = NSURL(string: "https://api.twitter.com/1.1/users/show.json")
		let requestParameters = ["screen_name": account.username, "include_entities": "false"]
		let getRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, URL: requestURL, parameters: requestParameters)
		getRequest.account = account
		
		getRequest.performRequestWithHandler() {
			(responseData, response, error) in
			
			do {
				// We'll try to parse Twitter's response here
				let responseObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments)
				var avatarURLString = responseObject["profile_image_url_https"] as! String
				let sizeRegex = RegEx("(_normal|_bigger|_mini)")
				let sizeRange = sizeRegex!.range(avatarURLString)
				avatarURLString = avatarURLString.stringByReplacingCharactersInRange(sizeRange, withString: "")
				
				let savedURLString = NSUserDefaults.standardUserDefaults().stringForKey(defaultsKey)
				
				if avatarURLString == savedURLString && fileManager.fileExistsAtPath(imagePath) {
					// Avatar hasn't changed
					println("Using saved image for @\(account.username), avatar URL hasn't changed since last check")
					let savedImage = NSImage(contentsOfFile: imagePath)
					completion(savedImage)
				} else {
					// This is either the first check, or the Avatar URL has changed
					// or the avatar image doesn't exist, so we'll have to re-download it
					
					let avatarURL = NSURL(string: avatarURLString)!
					
					let imageRequest: NSURLRequest = NSURLRequest(URL: avatarURL)
					let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
					
					let dataTask = session.dataTaskWithRequest(imageRequest) {
						(data, response, error) in
						
						if error == nil && data != nil {
							println("Got image for @\(account.username), writing URL to user defaults and saving image to disk")
							NSUserDefaults.standardUserDefaults().setObject(avatarURLString, forKey: defaultsKey)
							let image = NSImage(data: data!)
							image!.saveAsPngWithPath(imagePath)
							completion(image)
						} else if error != nil {
							println("An error occurred while downloading image")
							println(error)
							completion(nil)
						} else if data == nil {
							println("data is nil")
							completion(nil)
						} else {
							println("What?")
							completion(nil)
						}
					}
					dataTask!.resume()
				}
			} catch {
				println("Exception thrown")
				completion(nil)
			}
		}
	}
	
	class func tweet(account: ACAccount, text: String, location: CLLocation?, completion: (data: NSData!, response: NSHTTPURLResponse!, error: NSError!) -> Void) {
		self.tweet(account, text: text, location: location, media: nil, completion: completion)
	}
	
	class func tweet(account: ACAccount, text: String, location: CLLocation?, media: [String]?, completion: (data: NSData!, response: NSHTTPURLResponse!, error: NSError!) -> Void) {
		// Trim whitespace and newlines from the tweet text
		let tweetText = text.trim()
		
		// Check whether the tweet's length is valid
		if TwitterText.remainingCharacterCount(tweetText) >= 0 && !tweetText.isEmpty {
			var parameters = ["status" : tweetText] // Twitter API stuff, we're setting the actual tweet text here
			
			if location != nil {
				parameters["lat"] = String(location!.coordinate.latitude)
				parameters["long"] = String(location!.coordinate.longitude)
			}
			
			var requestURL: NSURL!
			if media == nil || media!.count == 0 {
				requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")
			} else if media != nil && media!.count > 0 {
				requestURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json")
			}
			
			// Create a tweet post request
			let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.POST, URL: requestURL, parameters: parameters)
			postRequest.account = account // Use the passed account object for posting
			
			if media != nil && media!.count > 0 {
				for path in media! {
					//					postRequest.add
				}
			}
			
			// Perform the request
			postRequest.performRequestWithHandler(completion)
			//			postRequest.performRequestWithHandler {
			//				responseData, response, error in
			//
			//				//				do {
			//				//					// We'll try to parse Twitter's response here
			//				//					let responseObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.AllowFragments)
			//				////					println(responseObject)
			//				//				} catch {
			//				//					// We're not doing anything with the response object right now, so this is okay
			//				//					println("JSON object creation failed")
			//				//				}
			//
			//				// We're doing this next bit on the main thread because this callback is running on a different thread
			//				// Not doing this on the main thread creates problems when the window is closed
			//				dispatch_async(dispatch_get_main_queue()) {
			//					if response.statusCode == 200 { // 200 = HTTP OK, Tweet was sent successfully
			//						println("Tweet sent!")
			//						self.close()
			//					} else { // Anything but HTTP 200, which means the whole thing failed
			//						if let errorMessage = self.statusCodes[response.statusCode] {
			//							println("HTTP \(response.statusCode): \(errorMessage)")
			//						} else {
			//							println("Unknown error: HTTP \(response.statusCode)")
			//						}
			//
			//						// Re-enable the button
			//						sender.enabled = true
			//					}
			//				}
			//			}
		} else {
			// This should never be reached
			println("Tweet is an empty string")
		}
	}
	
}