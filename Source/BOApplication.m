/*
 * Copyright (C) 2010-2019 Michael Dippery <michael@monkey-robot.com>
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
#import <ServiceManagement/ServiceManagement.h>
#import "BOApplication.h"
#import "NSEvent+ModifierKeys.h"


#define YESORNO(b)  (b ? @"YES" : @"NO")


static NSString * const BOHotkeyCodeKey = @"HotkeyCode";
static NSString * const BOHotkeyModifierKey = @"HotkeyModifiers";
static NSString * const BOGreetingDisplayKey = @"GreetingDisplayed";
static NSString * const BOLoginItemKey = @"IsLoginItem";
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


#pragma mark -

@interface BOApplication ()
- (BOOL)hasShownGreeting;
- (void)markGreetingShown;
@end


@implementation BOApplication

#pragma mark - Lifecyle

+ (void)initialize
{
    NSString *defaultsPlist = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSAssert(defaultsPlist != nil, @"Path to UserDefaults.plist could not be retrieved");
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPlist];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)dealloc
{
    [_preferencesWindow release];
    [_shortcutControl release];
    [_loginItemButton release];
    [_statusMenu release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [[self loginItemButton] setState:[self isLoginItem] ? NSControlStateValueOn : NSControlStateValueOff];
}

#pragma mark - Properties

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
    return [[NSUserDefaults standardUserDefaults] boolForKey:BOLoginItemKey];
}

- (void)setIsLoginItem:(BOOL)isLoginItem
{
    [[NSUserDefaults standardUserDefaults] setBool:isLoginItem forKey:BOLoginItemKey];
}

- (BOCarbonKeyCombo)carbonKeyCombo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger hotkeyCode = [defaults integerForKey:BOHotkeyCodeKey];
    NSInteger hotkeyModifiers = [defaults integerForKey:BOHotkeyModifierKey];

    BOCarbonKeyCombo combo;
    combo.code = hotkeyCode;
    combo.flags = hotkeyModifiers;

    return combo;
}

- (void)setCarbonKeyCombo:(BOCarbonKeyCombo)combo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger hotkeyCode = combo.code;
    NSInteger hotkeyModifiers = combo.flags;

    [defaults setInteger:hotkeyCode forKey:BOHotkeyCodeKey];
    [defaults setInteger:hotkeyModifiers forKey:BOHotkeyModifierKey];
}

- (BOCocoaKeyCombo)cocoaKeyCombo
{
    BOCarbonKeyCombo carbonCombo = [self carbonKeyCombo];

    BOCocoaKeyCombo combo;
    combo.code = carbonCombo.code;
    combo.flags = [[self shortcutControl] carbonToCocoaFlags:carbonCombo.flags];

    return combo;
}

- (void)setCocoaKeyCombo:(BOCocoaKeyCombo)combo
{
    NSAssert([self shortcutControl] != nil, @"shortcutControl is nil");
    BOCarbonKeyCombo newCombo;
    newCombo.code = combo.code;
    newCombo.flags = [[self shortcutControl] cocoaToCarbonFlags:combo.flags];

    [self setCarbonKeyCombo:newCombo];
}

#pragma mark - Application

- (void)registerGlobalHotkey:(id)sender;
{
    // Source: http://dbachrach.com/blog/2005/11/program-global-hotkeys-in-cocoa-easily/
    
    EventHotKeyID hotKeyID;
    EventTypeSpec eventType;
    
    hotKeyID.signature = 'blo1';
    hotKeyID.id = 1;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    
    BOCarbonKeyCombo combo = [self carbonKeyCombo];
    
    InstallApplicationEventHandler(BOHotkeyHandler, 1, &eventType, self, NULL);
    RegisterEventHotKey(combo.code, combo.flags, hotKeyID, GetApplicationEventTarget(), 0, &hotkeyHandler);
    NSLog(@"Registered global hotkey: code = %ld, mods = %ld, ref = %p", (long) combo.code, (long) combo.flags, hotkeyHandler);
}

- (void)unregisterGlobalHotkey:(id)sender
{
    NSLog(@"Removing old hot key (%p)", hotkeyHandler);
    UnregisterEventHotKey(hotkeyHandler);
    hotkeyHandler = NULL;
}

- (void)activateScreenSaver:(id)sender
{
    NSLog(@"Activating screen saver");
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

#pragma mark - User Interface

- (IBAction)showPreferencesWindow:(id)sender
{
    [[self shortcutControl] setKeyCombo:[self cocoaKeyCombo]];
    [[self preferencesWindow] makeKeyAndOrderFront:self];
}

- (IBAction)closePreferencesWindow:(id)sender
{
    [[self preferencesWindow] close];
}

- (IBAction)toggleLoginItem:(id)sender
{
    BOOL state = [sender state] == NSControlStateValueOn;
    NSLog(@"Toggling login item status to %@", YESORNO(state));

    NSString *helperID = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@"Launcher"];
    NSLog(@"Loading helper application with ID %@", helperID);
    BOOL res = SMLoginItemSetEnabled((CFStringRef) helperID, state);
    NSLog(@"SMLoginItemSetEnabled? %@", YESORNO(res));

    if (res) {
        [self setIsLoginItem:state];
    }
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
    NSLog(@"Changing key combo to %@", [aRecorder keyComboString]);
    [self setCocoaKeyCombo:newKeyCombo];
    [self unregisterGlobalHotkey:self];
    [self registerGlobalHotkey:self];
}

#pragma mark - NSApp Delegate

- (BOOL)hasShownGreeting
{
    if ([[[self environment] objectForKey:@"BLACKOUT_ALWAYS_SHOW_GREETING"] isEqualToString:@"true"]) {
        return NO;
    }

    return [[NSUserDefaults standardUserDefaults] objectForKey:BOGreetingDisplayKey] != nil;
}

- (void)markGreetingShown
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:BOGreetingDisplayKey];
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    NSLog(@"Loaded Blackout v%@ (%@)", [self version], [self build]);

    [self registerGlobalHotkey:self];

    if ([NSEvent optionKey] || ![self hasShownGreeting]) {
        [self showPreferencesWindow:self];
        [self markGreetingShown];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self showPreferencesWindow:self];
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    NSLog(@"Blackout is shutting down");
}

@end
