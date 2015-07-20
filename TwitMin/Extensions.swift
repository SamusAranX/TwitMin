//
//  Extensions.swift
//  TwitMin
//
//  Created by Peter Wunder on 15.07.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import CoreLocation

extension CLAuthorizationStatus {
	func name() -> String {
		switch self {
		case CLAuthorizationStatus.Authorized:
			return "Authorized"
		case .Denied:
			return "Denied"
		case .NotDetermined:
			return "NotDetermined"
		case .Restricted:
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
		return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
	}
	
	subscript (index: Int) -> String? {
		if index >= self.characters.count {
			return nil
		}
		
		let i = advance(self.startIndex, index)
		return String(self[i])
	}
	
	subscript (range: Range<Int>) -> String? {
		if range.startIndex < 0 || range.endIndex > self.characters.count {
			return nil
		}
		
		let range = Range(start: advance(startIndex, range.startIndex), end: advance(startIndex, range.endIndex))
		
		return self[range]
	}
}

extension NSRange {
	func toRange(string: String) -> Range<String.Index> {
		let startIndex = advance(string.startIndex, location)
		let endIndex = advance(startIndex, length)
		return startIndex..<endIndex
	}
}

extension NSColor {
	public convenience init?(hexString: String) {
		var hex = hexString
		
		if hex.hasPrefix("#") {
			hex = hex.substringFromIndex(advance(hex.startIndex, 1))
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
			
			NSScanner(string: redHex).scanHexInt(&r)
			NSScanner(string: greenHex).scanHexInt(&g)
			NSScanner(string: blueHex).scanHexInt(&b)
			
			self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: 1)
		} else {
			return nil
		}
	}
}

extension NSImage {
	func saveAsPngWithPath(path: String) -> Bool {
		var imageData = self.TIFFRepresentation
		let imageRep = NSBitmapImageRep(data: imageData!)
		imageData = imageRep!.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: ["": ""])
		
		return imageData!.writeToFile(path, atomically: false)
	}
}




