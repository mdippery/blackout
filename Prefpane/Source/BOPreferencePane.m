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

#import "BONotifications.h"
#import "BOKeys.h"


@interface BOPreferencePane ()
- (NSBundle *)bundle;
- (NSString *)notificationIdentifier;
- (void)setStateRunning;
- (void)setStateStopped;
- (void)setStateOpenAtLogin:(BOOL)openAtLogin;
- (void)updateKeyCombo;
- (void)launchBlackout;
- (void)terminateBlackout;
- (void)checkBlackoutIsRunning;
@end


@implementation BOPreferencePane

- (void)awakeFromNib
{
    if ([self isBlackoutRunning]) {
        [self setStateRunning];
    } else {
        [self setStateStopped];
    }
    [self updateKeyCombo];
}

- (NSBundle *)bundle
{
    return [NSBundle bundleForClass:[self class]];
}

- (NSString *)notificationIdentifier
{
    return [[[self bundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
}

- (void)setStateRunning
{
    [runningLabel setStringValue:NSLocalizedString(@"Blackout is running.", nil)];
    [startButton setTitle:NSLocalizedString(@"Stop Blackout", nil)];
    [startButton setAction:@selector(stopBlackout:)];
}

- (void)setStateStopped
{
    [runningLabel setStringValue:NSLocalizedString(@"Blackout is stopped.", nil)];
    [startButton setTitle:NSLocalizedString(@"Start Blackout", nil)];
    [startButton setAction:@selector(startBlackout:)];
}

- (void)setStateOpenAtLogin:(BOOL)isLoginItem
{
    if (isLoginItem) {
        [loginItemsCheckbox setAction:@selector(removeFromLoginItems:)];
    } else {
        [loginItemsCheckbox setAction:@selector(addToLoginItems:)];
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

- (NSString *)blackoutHelperPath
{
    return [[self bundle] pathForResource:@"Blackout" ofType:@"app"];
}

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

- (IBAction)startBlackout:(id)sender
{
    [startButton setEnabled:NO];
    [launchIndicator startAnimation:self];
    [runningLabel setStringValue:NSLocalizedString(@"Launching Blackout...", nil)];
    [self launchBlackout];
    [self performSelector:@selector(checkBlackoutIsRunning) withObject:nil afterDelay:4.0];
}

- (IBAction)stopBlackout:(id)sender
{
    [startButton setEnabled:NO];
    [launchIndicator startAnimation:self];
    [runningLabel setStringValue:NSLocalizedString(@"Stopping Blackout...", nil)];
    [self terminateBlackout];
    [self performSelector:@selector(checkBlackoutIsRunning) withObject:nil afterDelay:4.0];
}

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

- (void)checkBlackoutIsRunning
{
    if ([self isBlackoutRunning]) {
        [self setStateRunning];
        [launchIndicator stopAnimation:self];
        [startButton setEnabled:YES];
    } else {
        [self setStateStopped];
        [launchIndicator stopAnimation:self];
        [startButton setEnabled:YES];
    }
}

- (IBAction)addToLoginItems:(id)sender
{
    // Source: http://cocoatutorial.grapewave.com/2010/02/creating-andor-removing-a-login-item/
    
    CFURLRef appPath = (CFURLRef) [NSURL fileURLWithPath:[self blackoutHelperPath]];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, appPath, NULL, NULL);
        NSLog(@"Added Blackout to login items");
        if (item) CFRelease(item);
    }
    
    [self setStateOpenAtLogin:YES];
}

- (IBAction)removeFromLoginItems:(id)sender
{
    // Source: http://cocoatutorial.grapewave.com/2010/02/creating-andor-removing-a-login-item/
    
    CFURLRef appPath = (CFURLRef) [NSURL fileURLWithPath:[self blackoutHelperPath]];
    LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItems) {
        UInt32 seedValue;
        NSArray *loginItemsList = (NSArray *) LSSharedFileListCopySnapshot(loginItems, &seedValue);
        for (NSUInteger i = 0; i < [loginItemsList count]; i++) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef) [loginItemsList objectAtIndex:i];
            if (LSSharedFileListItemResolve(item, 0, (CFURLRef *) &appPath, NULL) == noErr) {
                if ([[(NSURL *) appPath path] isEqualToString:[self blackoutHelperPath]]) {
                    LSSharedFileListItemRemove(loginItems, item);
                    NSLog(@"Removed Blackout from login items");
                }
            }
        }
        [loginItemsList release];
    }
    
    [self setStateOpenAtLogin:NO];
}

#pragma mark Shortcut Recorder

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

@end
