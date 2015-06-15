//
//  TMTextField.swift
//  TwitMin
//
//  Created by Peter Wunder on 13.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

import Cocoa

class TMTextField: NSTextField {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
	
	override func resetCursorRects() {
		self.addCursorRect(self.bounds, cursor: NSCursor.pointingHandCursor())
	}
    
}
