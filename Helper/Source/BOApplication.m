/*
 * Copyright (C) 2010 Michael Dippery <mdippery@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "BOApplication.h"

#import <Carbon/Carbon.h>

#import "BONotifications.h"
#import "BOKeys.h"


static OSStatus BOHotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
    // Delay screen saver activation for a half-second -- otherwise
    // it gets kicked off almost immediately.
    [(BOApplication *)userData performSelector:@selector(activateScreenSaver:) withObject:(BOApplication *)userData afterDelay:0.5];
    return noErr;
}


@interface BOApplication ()
- (void)setupNotifications;
@end

@interface BOApplication (Notifications)
- (void)terminate:(NSNotification *)note;
- (void)updateHotkeys:(NSNotification *)note;
@end


@implementation BOApplication

- (void)setupNotifications
{
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(terminate:) name:BOApplicationShouldTerminate object:nil];
    [dnc addObserver:self selector:@selector(updateHotkeys:) name:BOApplicationShouldUpdateHotkeys object:nil];
}

#pragma mark Application Status

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    [self registerGlobalHotkey:self];
    [self setupNotifications];
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    NSLog(@"Blackout is shutting down");
    NSString *obj = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationWillTerminate object:obj];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Application Functionality

- (void)registerGlobalHotkey:(id)sender;
{
    // Source: http://dbachrach.com/blog/2005/11/program-global-hotkeys-in-cocoa-easily/
    
    EventHotKeyRef hotKeyRef;
    EventHotKeyID hotKeyID;
    EventTypeSpec eventType;
    
    hotKeyID.signature = 'blo1';
    hotKeyID.id = 1;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    
    InstallApplicationEventHandler(BOHotkeyHandler, 1, &eventType, self, NULL);
    RegisterEventHotKey(BODefaultKeyCode, BODefaultModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
}

- (void)activateScreenSaver:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

#pragma mark Notification Handlers

- (void)terminate:(NSNotification *)note
{
    [NSApp terminate:self];
}

- (void)updateHotkeys:(NSNotification *)note
{
    NSNumber *code = [[note userInfo] objectForKey:BOKeyCodeNotificationKey];
    NSNumber *flags = [[note userInfo] objectForKey:BOKeyFlagNotificationKey];
    NSLog(@"Updating hot key with code: %u flags %u", [code unsignedShortValue], [flags unsignedIntValue]);
}

@end
