//
//  BlackoutAppDelegate.m
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import "BOApplication.h"


@implementation BOApplication

- (void)awakeFromNib
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [[bar statusItemWithLength:NSSquareStatusItemLength] retain];
    [statusItem setTitle:@"!"];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:mainMenu];
}

- (void)dealloc
{
    [statusItem release];
    [super dealloc];
}

- (IBAction)activateScreenSaver:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

@end
