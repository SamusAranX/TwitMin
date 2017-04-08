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
	
	class func getUserAvatar(_ account: ACAccount, completion: @escaping (NSImage?) -> ()) {
		let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first!
		
		let imageURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("avatar_\(account.username).png")
		let imagePath = imageURL.path
		print(imagePath)
		
		let defaultsKey = "avatarURL_\(account.username)"
		let fileManager = FileManager()
		
		let requestURL = URL(string: "https://api.twitter.com/1.1/users/show.json")
        let requestParameters: [String: Any] = ["screen_name": account.username, "include_entities": "false"]
        let getRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.GET, url: requestURL, parameters: requestParameters)!
		getRequest.account = account
		
		getRequest.perform() {
			(responseData, response, error) in
			
			do {
				// We'll try to parse Twitter's response here
                let responseObject = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
				var avatarURLString = responseObject["profile_image_url_https"] as! String
				let sizeRegex = RegEx("(_normal|_bigger|_mini)")!
				let sizeRange = sizeRegex.range(avatarURLString)
                avatarURLString = (avatarURLString as NSString).replacingCharacters(in: sizeRange, with: "")
				
				let savedURLString = UserDefaults.standard.string(forKey: defaultsKey)
				
				if avatarURLString == savedURLString && fileManager.fileExists(atPath: imagePath) {
					// Avatar hasn't changed
					println("Using saved image for @\(account.username), avatar URL hasn't changed since last check")
					let savedImage = NSImage(contentsOfFile: imagePath)
					completion(savedImage)
				} else {
					// This is either the first check, or the Avatar URL has changed
					// or the avatar image doesn't exist, so we'll have to re-download it
					
					let avatarURL = URL(string: avatarURLString)!
					
					let imageRequest: URLRequest = URLRequest(url: avatarURL)
					let session = URLSession(configuration: URLSessionConfiguration.default)
					
					let dataTask = session.dataTask(with: imageRequest, completionHandler: {
						(data, response, error) in
						
						if error == nil && data != nil {
							println("Got image for @\(account.username), writing URL to user defaults and saving image to disk")
							UserDefaults.standard.set(avatarURLString, forKey: defaultsKey)
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
					}) 
					dataTask.resume()
				}
			} catch {
				println("Exception thrown")
				completion(nil)
			}
		}
	}
	
	class func tweet(_ account: ACAccount, text: String, location: CLLocation?, completion: @escaping (_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) {
		self.tweet(account, text: text, location: location, media: nil, completion: completion)
	}
	
	class func tweet(_ account: ACAccount, text: String, location: CLLocation?, media: [String]?, completion: @escaping (_ data: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) {
		// Trim whitespace and newlines from the tweet text
		let tweetText = text.trim()
		
		// Check whether the tweet's length is valid
		if TwitterText.remainingCharacterCount(tweetText) >= 0 && !tweetText.isEmpty {
			var parameters = ["status" : tweetText] // Twitter API stuff, we're setting the actual tweet text here
			
			if location != nil {
				parameters["lat"] = String(location!.coordinate.latitude)
				parameters["long"] = String(location!.coordinate.longitude)
			}
			
			var requestURL: URL!
			if media == nil || media!.count == 0 {
				requestURL = URL(string: "https://api.twitter.com/1.1/statuses/update.json")
			} else if media != nil && media!.count > 0 {
				requestURL = URL(string: "https://api.twitter.com/1.1/statuses/update_with_media.json")
			}
			
			// Create a tweet post request
			let postRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: SLRequestMethod.POST, url: requestURL, parameters: parameters)!
			postRequest.account = account // Use the passed account object for posting
			
//			if media != nil && media!.count > 0 {
//				for path in media! {
//					// TODO
//				}
//			}
			
			// Perform the request
			postRequest.perform(handler: completion)
		} else {
			// This should never be reached
			println("Tweet is an empty string")
		}
	}
	
}
