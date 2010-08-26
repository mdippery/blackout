//
//  BlackoutAppDelegate.m
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import "BOApplication.h"
#import "NSEvent+Blackout.h"


@interface BOApplication ()
- (IBAction)activateScreenSaverOrMenu:(id)sender;
@end


@implementation BOApplication

- (void)awakeFromNib
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [[bar statusItemWithLength:NSSquareStatusItemLength] retain];
    [statusItem setTitle:@"!"];
    [statusItem setHighlightMode:YES];
    [statusItem setAction:@selector(activateScreenSaverOrMenu:)];
}

- (void)dealloc
{
    [statusItem release];
    [super dealloc];
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
