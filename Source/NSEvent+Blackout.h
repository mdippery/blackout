//
//  NSEvent+Blackout.h
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSEvent (Blackout)
+ (BOOL)isCommandKeyDown;
+ (BOOL)isControlKeyDown;
@end
