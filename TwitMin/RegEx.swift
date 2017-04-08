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
			try self.expression = NSRegularExpression(pattern: self.pattern, options: [.caseInsensitive])
		} catch {
			return nil
		}
	}
	
	func match(_ input: String) -> Bool {
		let matches = self.expression!.matches(in: input, options: [], range:NSMakeRange(0, input.characters.count))
		
		return matches.count > 0
	}
	
	func range(_ input: String) -> Range<String.Index> {
		let matches = self.expression!.matches(in: input, options: [], range: NSMakeRange(0, input.characters.count))
		
		return matches[0].range.toRange(input)
	}
}
