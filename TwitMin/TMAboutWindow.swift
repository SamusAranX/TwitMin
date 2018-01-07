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
	class func hyperlinkFromString(_ inString: String, url: URL) -> NSAttributedString {
		let attrString = NSMutableAttributedString(string: inString)
		let range = NSMakeRange(0, attrString.length)
		
		attrString.beginEditing()
		attrString.addAttribute(NSAttributedStringKey.link, value: url.absoluteString, range: range)
		
        attrString.addAttribute(NSAttributedStringKey.foregroundColor, value: NSColor.blue, range: range)
        attrString.addAttribute(NSAttributedStringKey.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: range)
		
		attrString.endEditing()
		
		return attrString
	}
}

class TMAboutWindow: NSWindow {

	@IBOutlet var aboutVersionLabel: NSTextField!
	@IBOutlet var aboutTextLabel: NSTextField!
	
	func initialize() {
		let versionNumber = Bundle.main.infoDictionary!["CFBundleShortVersionString"]!
		aboutVersionLabel.stringValue = "Version \(versionNumber)"
		
		let path = Bundle.main.path(forResource: "Credits", ofType: "rtf")!
		let rtfData = try! Data(contentsOf: URL(fileURLWithPath: path))
		let aboutText = NSMutableAttributedString(rtf: rtfData, documentAttributes: nil)
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineSpacing = 1
		paragraphStyle.alignment = NSTextAlignment.center

        aboutText!.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, aboutText!.length))
        aboutText!.addAttribute(NSAttributedStringKey.font, value: NSFont.systemFont(ofSize: 11), range: NSMakeRange(0, aboutText!.length))
		
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
