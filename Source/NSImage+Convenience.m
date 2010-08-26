//
//  NSImage+Convenience.m
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import "NSImage+Convenience.h"


@implementation NSImage (ConvenienceAdditions)

+ (id)imageWithContentsOfFile:(NSString *)path
{
    return [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
}

@end
