//
//  TMAboutWindow.swift
//  TwitMin
//
//  Created by Peter Wunder on 13.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa
import CoreGraphics

extension NSAttributedString {
	class func hyperlinkFromString(inString: String, url: NSURL) -> NSAttributedString {
		let attrString = NSMutableAttributedString(string: inString)
		let range = NSMakeRange(0, attrString.length)
		
		attrString.beginEditing()
		attrString.addAttribute(NSLinkAttributeName, value: url.absoluteString, range: range)
		
		attrString.addAttribute(NSForegroundColorAttributeName, value: NSColor.blueColor(), range: range)
		attrString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range)
		
		attrString.endEditing()
		
		return attrString
	}
}

class TMAboutWindow: NSWindow {

	@IBOutlet var aboutVersionLabel: NSTextField!
	@IBOutlet var aboutTextLabel: NSTextField!
	
	func initialize() {
		let versionNumber = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]!
		let buildNumber = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"]!
		aboutVersionLabel.stringValue = "Version \(versionNumber) (\(buildNumber))"
		
		let path = NSBundle.mainBundle().pathForResource("Credits", ofType: "rtf")!
		let rtfData = NSData(contentsOfFile: path)!
		let aboutText = NSMutableAttributedString(RTF: rtfData, documentAttributes: nil)
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineSpacing = 1
		paragraphStyle.alignment = NSTextAlignment.Center

		aboutText!.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, aboutText!.length))
		aboutText!.addAttribute(NSFontAttributeName, value: NSFont.systemFontOfSize(11), range: NSMakeRange(0, aboutText!.length))
		
		aboutTextLabel.allowsEditingTextAttributes = true
		aboutTextLabel.attributedStringValue = aboutText!
		
		// Using hyperlinks with NSText(Field|View)s is fucking impossible
//		let cgEventDown = CGEventCreateMouseEvent(nil, CGEventType.LeftMouseDown, CGPoint(x: 150, y: 150), CGMouseButton.Left)
//		let cgEventUp = CGEventCreateMouseEvent(nil, CGEventType.LeftMouseUp, CGPoint(x: 150, y: 150), CGMouseButton.Left)
//		CGEventPost(CGEventTapLocation.CGHIDEventTap, cgEventDown)
//		CGEventPost(CGEventTapLocation.CGHIDEventTap, cgEventUp)
		
//		let eventDown = NSEvent(CGEvent: cgEventDown!)
//		let eventUp = NSEvent(CGEvent: cgEventUp!)
//		aboutTextLabel.mouseDown(eventDown!)
//		aboutTextLabel.mouseUp(eventUp!)
		
	}
}
