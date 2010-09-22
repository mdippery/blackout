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
#import "BOUserDefaults.h"

#define BOLog(fmt, args...)             NSLog(@"Blackout|" fmt, ## args)


@interface BOPreferencePane ()
- (void)initNotifications;
- (BOOL)isBlackoutRunning_Leopard;
- (void)updateRunningState:(BOOL)state;
- (void)updateKeyCombo;
- (void)updateLoginItemState;
- (void)disableControlsWithLabel:(NSString *)labelKey;
- (void)stopUpdateAnimation;
- (void)launchBlackout;
- (void)terminateBlackout;
- (void)checkBlackoutIsRunning;
- (NSString *)retrieveBundleIdentifierFromNotification:(NSNotification *)note;
- (void)applicationDidLaunch:(NSNotification *)note;
- (void)applicationDidTerminate:(NSNotification *)note;
- (void)checkedForUpdate:(NSNotification *)note;
- (void)foundUpdate:(NSNotification *)note;
- (void)didNotFindUpdate:(NSNotification *)note;
@end


@implementation BOPreferencePane

- (id)initWithBundle:(NSBundle *)bundle
{
    if ((self = [super initWithBundle:bundle])) {
        NSAssert(bundle == [BOBundle preferencePaneBundle], @"Initialization bundle is not global preferences bundle");
        [self initNotifications];
    }
    return self;
}

- (void)initNotifications
{
    NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
    [dnc addObserver:self selector:@selector(checkedForUpdate:) name:BOApplicationDidCheckForUpdate object:nil];
    [dnc addObserver:self selector:@selector(foundUpdate:) name:BOApplicationFoundUpdate object:nil];
    [dnc addObserver:self selector:@selector(didNotFindUpdate:) name:BOApplicationDidNotFindUpdate object:nil];
    NSNotificationCenter *wsnc = [[NSWorkspace sharedWorkspace] notificationCenter];
    [wsnc addObserver:self selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
    [wsnc addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
    BOLog(@"Registered for notifications");
}

- (void)awakeFromNib
{
    NSString *version = [NSString stringWithFormat:@"%@ v%@ (%@)", [self name], [self version], [self build]];
    [versionLabel setStringValue:version];
    [copyrightLabel setStringValue:[self copyright]];
    
    [self updateRunningState:[self isBlackoutRunning]];
    [self updateKeyCombo];
    [self updateLoginItemState];
    [updateCheckbox setState:[[BOUserDefaults sharedUserDefaults] shouldUpdateAutomatically]];
}

- (void)dealloc
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [super dealloc];
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
    return [[BOBundle preferencePaneBundle] localizedStringForKey:@"NSHumanReadableCopyright" value:@"" table:@"InfoPlist"];
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

- (BOOL)isBlackoutRunning_Leopard
{
    ProcessSerialNumber psn = {0, kNoProcess};
    
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

- (BOOL)isBlackoutRunning
{
    id runningAppClass = NSClassFromString(@"NSRunningApplication");
    if (runningAppClass != nil) {
        BOLog(@"Checking running application with Snow Leopard");
        return [[runningAppClass runningApplicationsWithBundleIdentifier:[[BOBundle helperBundle] bundleIdentifier]] count] > 0;
    } else {
        BOLog(@"Checking running application with Leopard");
        return [self isBlackoutRunning_Leopard];
    }
}

#pragma mark UI State

- (void)updateRunningState:(BOOL)state
{
    if (state) {
        [runningLabel setStringValue:NSLocalizedString(@"Blackout is running.", nil)];
        [startButton setTitle:NSLocalizedString(@"Stop Blackout", nil)];
        [updateButton setEnabled:YES];
    } else {
        [runningLabel setStringValue:NSLocalizedString(@"Blackout is stopped.", nil)];
        [startButton setTitle:NSLocalizedString(@"Start Blackout", nil)];
        [updateButton setEnabled:NO];
    }
}

- (void)updateKeyCombo
{
    [shortcutRecorder setKeyCombo:[[BOUserDefaults sharedUserDefaults] hotkey]];
}

- (void)updateLoginItemState
{
    [loginItemsCheckbox setState:[[BOUserDefaults sharedUserDefaults] startAtLogin]];
}

- (void)disableControlsWithLabel:(NSString *)labelKey
{
    [startButton setEnabled:NO];
    [launchIndicator startAnimation:self];
    [runningLabel setStringValue:NSLocalizedString(labelKey, nil)];
}

- (void)stopUpdateAnimation
{
    [updateIndicator stopAnimation:self];
    [updateButton setEnabled:YES];
}

#pragma mark Interface

- (void)checkBlackoutIsRunning
{
    [self updateRunningState:[self isBlackoutRunning]];
    [launchIndicator stopAnimation:self];
    [startButton setEnabled:YES];
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
    BOUserDefaults *defaults = [BOUserDefaults sharedUserDefaults];
    [defaults setStartAtLogin:![defaults startAtLogin]];
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
    [[BOUserDefaults sharedUserDefaults] setShouldUpdateAutomatically:[sender state] == NSOnState];
}

#pragma mark Shortcut Recorder Delegate

- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    [[BOUserDefaults sharedUserDefaults] setKeyCombo:newKeyCombo];
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:BOApplicationShouldUpdateHotkeys
                                                                   object:[self notificationIdentifier]];
}

#pragma mark Notification Handlers

- (NSString *)retrieveBundleIdentifierFromNotification:(NSNotification *)note
{
    id runningApp = [[note userInfo] objectForKey:NSWorkspaceApplicationKey];
    if (runningApp == nil) {
        BOLog(@"Retrieving key for Leopard");
        return [[note userInfo] objectForKey:@"NSApplicationBundleIdentifier"];
    } else {
        BOLog(@"Retrieving key for Snow Leopard");
        return [runningApp bundleIdentifier];
    }
}

- (void)applicationDidLaunch:(NSNotification *)note
{
    if ([[self retrieveBundleIdentifierFromNotification:note] isEqualToString:[[BOBundle helperBundle] bundleIdentifier]]) {
        BOLog(@"Noticed that Blackout.app is now running");
    }
}

- (void)applicationDidTerminate:(NSNotification *)note
{
    if ([[self retrieveBundleIdentifierFromNotification:note] isEqualToString:[[BOBundle helperBundle] bundleIdentifier]]) {
        BOLog(@"Noticed that Blackout.app has terminated");
    }
}

- (void)checkedForUpdate:(NSNotification *)note
{
    [self stopUpdateAnimation];
}

- (void)foundUpdate:(NSNotification *)note
{
    [self stopUpdateAnimation];
    BOLog(@"Update is available");
}

- (void)didNotFindUpdate:(NSNotification *)note
{
    [self stopUpdateAnimation];
    BOLog(@"No updates available");
}

@end
