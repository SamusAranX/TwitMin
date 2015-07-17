//
//  Regex.swift
//  TwitMin
//
//  Created by Peter Wunder on 16.07.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

// Small wrapper for NSRegularExpression because dealing with regular expressions in Swift sucks
class RegEx {
	var expression: NSRegularExpression?
	let pattern: String
	
	init?(_ pattern: String) {
		self.pattern = pattern
		do {
			try self.expression = NSRegularExpression(pattern: self.pattern, options: [.CaseInsensitive])
		} catch {
			return nil
		}
	}
	
	func match(input: String) -> Bool {
		let matches = self.expression!.matchesInString(input, options: [], range:NSMakeRange(0, input.characters.count))
		return matches.count > 0
	}
}