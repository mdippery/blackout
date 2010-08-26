//
//  NSEvent+Blackout.m
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import "NSEvent+Blackout.h"

#define LEFT_MOUSE_BUTTON   (1 << 0)
#define RIGHT_MOUSE_BUTTON  (1 << 1)


@implementation NSEvent (Blackout)

+ (BOOL)isCommandKeyDown
{
    return ([self modifierFlags] & NSCommandKeyMask) == NSCommandKeyMask;
}

+ (BOOL)isControlKeyDown
{
    return ([self modifierFlags] & NSControlKeyMask) == NSControlKeyMask;
}

@end
