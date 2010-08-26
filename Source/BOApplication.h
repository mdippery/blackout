//
//  BlackoutAppDelegate.h
//  Blackout
//
//  Created by Michael Dippery on 8/26/2010.
//  Copyright 2010 Michael Dippery. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BOApplication : NSObject
{
    IBOutlet NSMenu *mainMenu;
    
    NSStatusItem *statusItem;
}

- (IBAction)activateMenu:(id)sener;
- (IBAction)activateScreenSaver:(id)sender;

@end
