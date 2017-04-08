//
//  Extensions.swift
//  TwitMin
//
//  Created by Peter Wunder on 15.07.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import CoreLocation

/* Thingy to work around Apple's stupid decision to let NSWindow.print() take precedence over Swift.print()
   I could count the number of people actually wanting to print when calling print() on one hand */
func println<T>(_ value: T) {
	print(value)
}

extension CLAuthorizationStatus {
	func name() -> String {
		switch self {
		case CLAuthorizationStatus.authorized:
			return "Authorized"
		case .denied:
			return "Denied"
		case .notDetermined:
			return "NotDetermined"
		case .restricted:
			return "Restricted"
		}
	}
}

extension CLPlacemark {
	func humanReadableName() -> String {
		return "\(self.subAdministrativeArea!), \(self.administrativeArea!)"
	}
}

extension String {
	func trim() -> String {
		return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	subscript (index: Int) -> String? {
		if index >= self.characters.count {
			return nil
		}
		
		let i = index.advanced(by: 0)
//		let i = advance(self.startIndex, index)
		return String(self[i])
	}
	
	subscript (range: Range<Int>) -> String? {
		if range.lowerBound < 0 || range.upperBound > self.characters.count {
			return nil
		}
		
//		let _range = Range(start: startIndex.advancedBy(range.startIndex), end: startIndex.advancedBy(range.endIndex))
		let _range = Range(characters.index(startIndex, offsetBy: range.lowerBound) ..< characters.index(startIndex, offsetBy: range.upperBound))
		
		return self[_range]
	}
}

extension NSRange {
	func toRange(_ string: String) -> Range<String.Index> {
		// let startIndex = advance(string.startIndex, location)
		let startIndex = string.characters.index(string.startIndex, offsetBy: location)
		// let endIndex = advance(startIndex, length)
		let endIndex = <#T##String.CharacterView corresponding to `startIndex`##String.CharacterView#>.index(startIndex, offsetBy: length)
		
		return startIndex..<endIndex
	}
}

extension NSColor {
	public convenience init?(hexString: String) {
		var hex = hexString
		
		if hex.hasPrefix("#") {
			let substrIndex = hex.characters.index(hex.startIndex, offsetBy: 1)
			hex = hex.substring(from: substrIndex)
		}
		
		let hexRegex = RegEx("^([0-9a-f]){3}$|^([0-9a-f]){6}$")
		
		if hexRegex!.match(hex) {
			if hex.characters.count == 3 {
				let redHex   = hex[0]!
				let greenHex = hex[1]!
				let blueHex  = hex[2]!
				
				hex = redHex + redHex + greenHex + greenHex + blueHex + blueHex
			}
			
			let redHex = hex[0..<2]!
			let greenHex = hex[2..<4]!
			let blueHex = hex[4..<6]!
			
			var r: CUnsignedInt = 0, g: CUnsignedInt = 0, b: CUnsignedInt = 0
			
			Scanner(string: redHex).scanHexInt32(&r)
			Scanner(string: greenHex).scanHexInt32(&g)
			Scanner(string: blueHex).scanHexInt32(&b)
			
			self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
		} else {
			return nil
		}
	}
}

extension NSImage {
	func saveAsPngWithPath(_ path: String) -> Bool {
		var imageData = self.tiffRepresentation
		let imageRep = NSBitmapImageRep(data: imageData!)
		imageData = imageRep!.representation(using: NSBitmapImageFileType.PNG, properties: ["": ""])
		
		return ((try? imageData!.write(to: URL(fileURLWithPath: path), options: [])) != nil)
	}
}




