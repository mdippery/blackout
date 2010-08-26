//
//  BlackoutAppDelegate.m
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import "BOApplication.h"
#import "NSEvent+Blackout.h"
#import "NSImage+Convenience.h"


@interface BOApplication ()
@property (readonly) NSImage *statusMenuImage;
@property (readonly) NSImage *alternateStatusMenuImage;
- (IBAction)activateScreenSaverOrMenu:(id)sender;
@end


@implementation BOApplication

@dynamic statusMenuImage;
@dynamic alternateStatusMenuImage;

- (void)awakeFromNib
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [[bar statusItemWithLength:NSSquareStatusItemLength] retain];
    [statusItem setImage:[self statusMenuImage]];
    [statusItem setAlternateImage:[self alternateStatusMenuImage]];
    [statusItem setHighlightMode:YES];
    [statusItem setAction:@selector(activateScreenSaverOrMenu:)];
}

- (void)dealloc
{
    [statusItem release];
    [super dealloc];
}

- (NSImage *)statusMenuImage
{
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"Moon" ofType:@"png"];
    return [NSImage imageWithContentsOfFile:imgPath];
}

- (NSImage *)alternateStatusMenuImage
{
    return [self statusMenuImage];
}

- (IBAction)activateScreenSaverOrMenu:(id)sender
{
    if ([NSEvent isCommandKeyDown] || [NSEvent isControlKeyDown]) {
        [self activateMenu:sender];
    } else {
        [self activateScreenSaver:sender];
    }
}

- (IBAction)activateMenu:(id)sender
{
    [statusItem popUpStatusItemMenu:mainMenu];
}

- (IBAction)activateScreenSaver:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

@end
