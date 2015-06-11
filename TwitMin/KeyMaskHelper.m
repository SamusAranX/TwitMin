//
//  KeyMaskHelper.m
//  TwitMin
//
//  Created by Peter Wunder on 11.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

#import "KeyMaskHelper.h"
@import AppKit;

@implementation KeyMaskHelper

+ (NSUInteger)cmdMask {
	return NSCommandKeyMask;
}
+ (NSUInteger)shiftMask {
	return NSShiftKeyMask;
}
+ (NSUInteger)ctrlMask {
	return NSControlKeyMask;
}
+ (NSUInteger)altMask {
	return NSAlternateKeyMask;
}

@end
