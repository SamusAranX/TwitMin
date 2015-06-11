//
//  KeyMaskHelper.h
//  TwitMin
//
//  Created by Peter Wunder on 11.06.15.
//  Copyright © 2015 Peter Wunder. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyMaskHelper : NSObject

+ (NSUInteger) cmdMask;
+ (NSUInteger) shiftMask;
+ (NSUInteger) ctrlMask;
+ (NSUInteger) altMask;

@end
