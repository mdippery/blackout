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

#import "BOPreferencePane.h"

#import <CoreServices/CoreServices.h>

#import "BOBundle.h"
#import "BONotifications.h"
#import "BOKeys.h"

#define BOLog(fmt, args...)     NSLog(@"Blackout|" fmt, ## args)


@interface BOPreferencePane ()
- (BOOL)shouldUpdateAutomatically;
- (LSSharedFileListItemRef) loginItem:(id *)items;
- (BOOL)isLoginItem;
- (void)updateRunningState:(BOOL)state;
- (void)updateKeyCombo;
- (void)updateLoginItemState;
- (void)disableControlsWithLabel:(NSString *)labelKey;
- (void)launchBlackout;
- (void)terminateBlackout;
- (void)checkBlackoutIsRunning;
- (void)addToLoginItems;
- (void)removeFromLoginItems;
- (void)checkedForUpdate:(NSNotification *)note;
@end


@implementation BOPreferencePane

- (void)awakeFromNib
{
    NSString *version = [NSString stringWithFormat:@"%@ v%@ (%@)", [self name], [self version], [self build]];
    [versionLabel setStringValue:version];
    [copyrightLabel setStringValue:[self copyright]];
    
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(checkedForUpdate:) name:BOApplicationDidCheckForUpdate object:nil];
    
    [self updateRunningState:[self isBlackoutRunning]];
    [self updateKeyCombo];
    [self updateLoginItemState];
    [updateCheckbox setState:[self shouldUpdateAutomatically]];
}

- (NSString *)name
{
    return [[[BOBundle preferencePaneBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

- (NSString *)build
{
    return [[[BOBundle preferencePaneBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSString *)version
{
    return [[[BOBundle preferencePaneBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)copyright
{
    return NSLocalizedStringFromTableInBundle(@"NSHumanReadableCopyright", @"InfoPlist", [BOBundle preferencePaneBundle], nil);
}

- (NSString *)notificationIdentifier
{
    return [[BOBundle preferencePaneBundle] bundleIdentifier];
}

- (NSString *)blackoutHelperPath
{
    return [[BOBundle preferencePaneBundle] pathForResource:@"Blackout" ofType:@"app"];
}

#pragma mark Process Control

- (void)launchBlackout
{
    static NSWorkspaceLaunchOptions opts = NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync;
    NSURL *url = [NSURL fileURLWithPath:[self blackoutHelperPath]];
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:url]
                    withAppBundleIdentifier:nil
                                    options:opts
             additionalEventParamDescriptor:nil
                          launchIdentifiers:NULL];
}

- (void)terminateBlackout
{
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationShouldTerminate object:[self notificationIdentifier]];
}

#pragma mark Status

- (BOOL)isBlackoutRunning
{
    ProcessSerialNumber psn = {0, kNoProcess };
    
    while (GetNextProcess(&psn) == noErr) {
        NSDictionary *info = [NSMakeCollectable(ProcessInformationCopyDictionary(&psn, kProcessDictionaryIncludeAllInformationMask)) autorelease];
        if (info) {
            NSString *bundlePath = [info objectForKey:@"BundlePath"];
            NSString *bundleID = [info objectForKey:(NSString *) kCFBundleIdentifierKey];
            if (bundlePath && bundleID) {
                if ([bundleID isEqualToString:@"com.monkey-robot.Blackout"]) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

- (BOOL)shouldUpdateAutomatically
{
    NSString *ident = [[BOBundle preferencePaneBundle] bundleIdentifier];
    //BOLog(@"Checking preferences: %@", ident);
    id userPref = [NSMakeCollectable(CFPreferencesCopyAppValue(CFSTR("SUEnableAutomaticChecks"), (CFStringRef) ident)) autorelease];
    if (userPref) {
        //BOLog(@"Pulled auto update pref from preferences");
        return [userPref boolValue];
    } else {
        //BOLog(@"Checking Info.plist for auto update pref");
        NSDictionary *info = [[BOBundle preferencePaneBundle] infoDictionary];
        id appPref = [info objectForKey:@"SUEnableAutomaticChecks"];
        if (appPref) {
            //BOLog(@"Found auto update pref in Info.plist");
            return [appPref boolValue];
        } else {
            //BOLog(@"Could not find update pref, returning default (NO)");
            return NO;
        }
    }
}

- (LSSharedFileListItemRef)loginItem:(id *)items
{
    // Source: http://cocoatutorial.grapewave.com/2010/02/creating-andor-removing-a-login-item/
    
    LSSharedFileListItemRef theItem = NULL;
    CFURLRef appPath = (CFURLRef) [NSURL fileURLWithPath:[self blackoutHelperPath]];
    id loginItems = [NSMakeCollectable(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL)) autorelease];
    if (loginItems) {
        UInt32 seedValue;
        id loginItemsList = [NSMakeCollectable(LSSharedFileListCopySnapshot((LSSharedFileListRef) loginItems, &seedValue)) autorelease];
        for (NSUInteger i = 0; i < [loginItemsList count]; i++) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef) [loginItemsList objectAtIndex:i];
            if (LSSharedFileListItemResolve(item, 0, (CFURLRef *) &appPath, NULL) == noErr) {
                if ([[(NSURL *) appPath path] isEqualToString:[self blackoutHelperPath]]) {
                    theItem = item;
                    break;
                }
            }
        }
        //[loginItemsList release];
    }
    
    if (items) *items = loginItems;
    return theItem;
}

- (BOOL)isLoginItem
{
    return [self loginItem:nil] != NULL;
}

#pragma mark UI State

- (void)updateRunningState:(BOOL)state
{
    if (state) {
        [runningLabel setStringValue:NSLocalizedString(@"Blackout is running.", nil)];
        [startButton setTitle:NSLocalizedString(@"Stop Blackout", nil)];
        [updateButton setEnabled:YES];
        //[updateCheckbox setEnabled:YES];
    } else {
        [runningLabel setStringValue:NSLocalizedString(@"Blackout is stopped.", nil)];
        [startButton setTitle:NSLocalizedString(@"Start Blackout", nil)];
        [updateButton setEnabled:NO];
        //[updateCheckbox setEnabled:NO];
    }
}

- (void)updateKeyCombo
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger keys = [prefs integerForKey:BOKeyCodeNotificationKey];
    NSInteger mods = [prefs integerForKey:BOKeyFlagNotificationKey];
    
    if (keys == 0) keys = BODefaultKeyCode;
    if (mods == 0) mods = SRCarbonToCocoaFlags(BODefaultModifiers);
    
    KeyCombo keyCombo = SRMakeKeyCombo(keys, mods);
    [shortcutRecorder setKeyCombo:keyCombo];
}

- (void)updateLoginItemState
{
    [loginItemsCheckbox setState:[self isLoginItem]];
}

- (void)disableControlsWithLabel:(NSString *)labelKey
{
    [startButton setEnabled:NO];
    [launchIndicator startAnimation:self];
    [runningLabel setStringValue:NSLocalizedString(labelKey, nil)];
}

#pragma mark Interface

- (void)checkBlackoutIsRunning
{
    [self updateRunningState:[self isBlackoutRunning]];
    [launchIndicator stopAnimation:self];
    [startButton setEnabled:YES];
}

- (void)addToLoginItems
{
    // Source: http://cocoatutorial.grapewave.com/2010/02/creating-andor-removing-a-login-item/
    
    CFURLRef appPath = (CFURLRef) [NSURL fileURLWithPath:[self blackoutHelperPath]];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, appPath, NULL, NULL);
        NSLog(@"Added Blackout to login items");
        if (item) CFRelease(item);
    }
}

- (void)removeFromLoginItems
{
    id loginItems;
    LSSharedFileListItemRef item = [self loginItem:&loginItems];
    if (item) {
        LSSharedFileListItemRemove((LSSharedFileListRef) loginItems, item);
    }
}

- (IBAction)toggleStartStop:(id)sender
{
    if ([self isBlackoutRunning]) {
        [self disableControlsWithLabel:NSLocalizedString(@"Stopping Blackout...", nil)];
        [self terminateBlackout];
    } else {
        [self disableControlsWithLabel:NSLocalizedString(@"Launching Blackout...", nil)];
        [self launchBlackout];
    }
    [self performSelector:@selector(checkBlackoutIsRunning) withObject:nil afterDelay:4.0];
}

- (IBAction)toggleLoginItems:(id)sender
{
    if ([self isLoginItem]) {
        [self removeFromLoginItems];
    } else {
        [self addToLoginItems];
    }
}

- (IBAction)checkForUpdate:(id)sender
{
    BOLog(@"Checking for updates");
    [updateButton setEnabled:NO];
    [updateIndicator startAnimation:self];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationShouldCheckForUpdate
                                                                   object:[self notificationIdentifier]];
}

- (IBAction)toggleAutomaticUpdates:(id)sender
{
    CFBooleanRef state = [sender state] ? kCFBooleanTrue : kCFBooleanFalse;
    NSString *ident = [[BOBundle preferencePaneBundle] bundleIdentifier];
    CFPreferencesSetValue(CFSTR("SUEnableAutomaticChecks"), state, (CFStringRef) ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFPreferencesSynchronize((CFStringRef) ident, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    BOLog(@"Updated auto updates: %@", state);
}

#pragma mark Shortcut Recorder Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    NSNumber *code = [NSNumber numberWithUnsignedShort:newKeyCombo.code];
    NSNumber *flags = [NSNumber numberWithUnsignedInteger:SRCocoaToCarbonFlags(newKeyCombo.flags)];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                             code, BOKeyCodeNotificationKey,
                             flags, BOKeyFlagNotificationKey,
                             nil];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationShouldUpdateHotkeys
                                                                   object:[self notificationIdentifier]
                                                                 userInfo:info];
}

#pragma mark Notification Handlers

- (void)checkedForUpdate:(NSNotification *)note
{
    [updateIndicator stopAnimation:self];
    [updateButton setEnabled:YES];
    //BOLog(@"Checked for updates");
}

@end
