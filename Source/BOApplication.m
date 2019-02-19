/*
 * Copyright (C) 2010 Michael Dippery <michael@monkey-robot.com>
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

#import <Carbon/Carbon.h>
#import "BOApplication.h"
#import "NSEvent+ModifierKeys.h"


static NSString * const BOHotkeyCodeKey = @"HotkeyCode";
static NSString * const BOHotkeyModifierKey = @"HotkeyModifiers";
static NSString * const BOGreetingDisplayKey = @"GreetingDisplayed";
static const NSTimeInterval screensaverDelay = 0.5;


static OSStatus BOHotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
    // Delay screen saver activation for a half-second -- otherwise
    // it gets kicked off almost immediately.
    NSLog(@"Invoked hotkey");
    [(BOApplication *)userData performSelector:@selector(activateScreenSaver:)
                                    withObject:(BOApplication *)userData
                                    afterDelay:screensaverDelay];
    return noErr;
}


@interface BOApplication ()
- (BOOL)hasShownGreeting;
- (void)showPreferences;
- (void)markGreetingShown;
@end


@implementation BOApplication

#pragma mark Lifecyle

+ (void)initialize
{
    NSString *defaultsPlist = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSAssert(defaultsPlist != nil, @"Path to Defaults.plist could not be retrieved");
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPlist];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)dealloc
{
    [_preferencesWindow release];
    [_shortcutControl release];
    [_loginItemButton release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    SRRecorderControl *shortcutControl = [self shortcutControl];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger hotkeyCode = [defaults integerForKey:BOHotkeyCodeKey];
    NSInteger hotkeyModifiers = [defaults integerForKey:BOHotkeyModifierKey];
    KeyCombo combo;
    combo.code = hotkeyCode;
    combo.flags = [shortcutControl carbonToCocoaFlags:hotkeyModifiers];
    [shortcutControl setKeyCombo:combo];
    NSLog(@"Current key combo: %@", [shortcutControl keyComboString]);

    [[self loginItemButton] setState:[self isLoginItem] ? NSControlStateValueOn : NSControlStateValueOff];
}

#pragma mark Properties

- (NSString *)version
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)build
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (NSDictionary *)environment
{
    return [[NSProcessInfo processInfo] environment];
}

- (BOOL)isLoginItem
{
    // TODO: Calculate if Blackout is login item already
    return NO;
}

#pragma mark Application

- (void)registerGlobalHotkey:(id)sender;
{
    // Source: http://dbachrach.com/blog/2005/11/program-global-hotkeys-in-cocoa-easily/
    
    EventHotKeyID hotKeyID;
    EventTypeSpec eventType;
    
    hotKeyID.signature = 'blo1';
    hotKeyID.id = 1;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger hotkeyCode = [defaults integerForKey:BOHotkeyCodeKey];
    NSInteger hotkeyModifiers = [defaults integerForKey:BOHotkeyModifierKey];
    
    InstallApplicationEventHandler(BOHotkeyHandler, 1, &eventType, self, NULL);
    RegisterEventHotKey(hotkeyCode, hotkeyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotkeyHandler);
    NSLog(@"Registered global hotkey: code = %ld, mods = %ld", (long) hotkeyCode, (long) hotkeyModifiers);
}

- (void)activateScreenSaver:(id)sender
{
    NSLog(@"Activating screen saver");
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

#pragma mark User Interface

- (IBAction)closePreferencesWindow:(id)sender
{
    [[self preferencesWindow] close];
}

- (IBAction)toggleLoginItem:(id)sender
{
    // TODO: Set login item status
    NSString *state = [sender state] == NSControlStateValueOn ? @"YES" : @"NO";
    NSLog(@"Toggling login item status: %@", state);
}

#pragma mark NSApp Delegate

- (BOOL)hasShownGreeting
{
    if ([[[self environment] objectForKey:@"BLACKOUT_ALWAYS_SHOW_GREETING"] isEqualToString:@"true"]) {
        return NO;
    }

    return [[NSUserDefaults standardUserDefaults] objectForKey:BOGreetingDisplayKey] != nil;
}

- (void)showPreferences
{
    [[self preferencesWindow] makeKeyAndOrderFront:self];
}

- (void)markGreetingShown
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:BOGreetingDisplayKey];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    [self registerGlobalHotkey:self];
    NSLog(@"Loaded Blackout v%@ (%@)", [self version], [self build]);

    if ([NSEvent optionKey] || ![self hasShownGreeting]) {
        [self showPreferences];
        [self markGreetingShown];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self showPreferences];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    NSLog(@"Blackout is shutting down");
}

@end
