//
//  TMTextView.swift
//  TwitMin
//
//  Created by Peter Wunder on 20.07.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

class TMTextView: NSTextView {

	override func awakeFromNib() {
		super.textContainerInset = NSSize(width: 0, height: 10)
	}
	
	override var textContainerOrigin: NSPoint {
		let origin = super.textContainerOrigin
		let newOrigin = NSPoint(x: origin.x, y: 0)
		return newOrigin
	}
    
}
