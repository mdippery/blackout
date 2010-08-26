//
//  NSImage+Convenience.h
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSImage (ConvenienceAdditions)
+ (id)imageWithContentsOfFile:(NSString *)path;
@end
