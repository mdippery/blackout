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

#import "BOBundle.h"
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
- (void)initNotifications;
- (void)terminate:(NSNotification *)note;
- (void)updateHotkeys:(NSNotification *)note;
- (void)update:(NSNotification *)note;
@end


@implementation BOApplication

- (NSString *)version
{
    return [[[BOBundle helperBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)buildNumber
{
    return [[[BOBundle helperBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSString *)notificationIdentifier
{
    return [[BOBundle helperBundle] bundleIdentifier];
}

- (void)initNotifications
{
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(terminate:) name:BOApplicationShouldTerminate object:nil];
    [dnc addObserver:self selector:@selector(updateHotkeys:) name:BOApplicationShouldUpdateHotkeys object:nil];
    [dnc addObserver:self selector:@selector(update:) name:BOApplicationShouldCheckForUpdate object:nil];
}

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
    
    NSInteger hotkeyCode = [BOPreferencesGetValue(BOKeyCodePreferencesKey) integerValue];
    NSUInteger hotkeyModifiers = [BOPreferencesGetValue(BOModifierPreferencesKey) unsignedIntegerValue];
    if (hotkeyCode == 0) hotkeyCode = BODefaultKeyCode;
    if (hotkeyModifiers == 0) hotkeyModifiers = BODefaultModifiers;
    
    InstallApplicationEventHandler(BOHotkeyHandler, 1, &eventType, self, NULL);
    RegisterEventHotKey(hotkeyCode, hotkeyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
}

- (void)activateScreenSaver:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

#pragma mark NSApp Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    [self registerGlobalHotkey:self];
    [self initNotifications];
    NSAssert([BOBundle preferencePaneBundle] == [updater hostBundle], @"Sparkle is not using prefpane bundle");
    NSLog(@"Loaded Blackout v%@ (%@)", [self version], [self buildNumber]);
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    NSLog(@"Blackout is shutting down");
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationWillTerminate object:[self notificationIdentifier]];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Notification Handlers

- (void)terminate:(NSNotification *)note
{
    [NSApp terminate:self];
}

- (void)updateHotkeys:(NSNotification *)note
{
    NSLog(@"Terminating to update hotkeys");
}

- (void)update:(NSNotification *)note
{
    NSLog(@"Checking for updates");
    [updater checkForUpdates:self];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationDidCheckForUpdate object:[self notificationIdentifier]];
}

#pragma mark Sparkle Delegate

- (void)updater:(SUUpdater *)theUpdater didFindValidUpdate:(SUAppcastItem *)update
{
    NSLog(@"Sparkle found an update");
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationFoundUpdate object:[self notificationIdentifier]];
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)theUpdater
{
    NSLog(@"Sparkle did not find an update");
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationDidNotFindUpdate object:[self notificationIdentifier]];
}

- (void)updater:(SUUpdater *)theUpdater willInstallUpdate:(SUAppcastItem *)update
{
    NSLog(@"Sparkle is going to update Blackout.prefPane");
}

- (void)updaterWillRelaunchApp:(SUUpdater *)theUpdater
{
    NSLog(@"Sparkle updated app. Relaunch imminent.");
}

@end
