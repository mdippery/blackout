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
#import "NSEvent+ModifierKeys.h"
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <Carbon/Carbon.h>


static OSStatus BOHotkeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
    // Delay screen saver activation for a half-second -- otherwise
    // it gets kicked off almost immediately.
    [(BOApplication *)userData performSelector:@selector(activateScreenSaver:) withObject:(BOApplication *)userData afterDelay:0.5];
    return noErr;
}


@interface BOApplication ()
- (void)showPreferences;
@end


@implementation BOApplication

+ (void)initialize
{
    NSString *defaultsPlist = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSAssert(defaultsPlist != nil, @"Path to Defaults.plist could not be retrieved");
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPlist];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (NSString *)version
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

- (NSString *)buildNumber
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

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
    NSInteger hotkeyCode = [defaults integerForKey:@"Hotkey Code"];
    NSInteger hotkeyModifiers = [defaults integerForKey:@"Hotkey Modifiers"];
    
    InstallApplicationEventHandler(BOHotkeyHandler, 1, &eventType, self, NULL);
    RegisterEventHotKey(hotkeyCode, hotkeyModifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotkeyHandler);
    NSLog(@"Registered global hotkey: code = %ld, mods = %ld", (long) hotkeyCode, (long) hotkeyModifiers);
}

- (void)activateScreenSaver:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

#pragma mark NSApp Delegate

- (void)showPreferences
{
    NSLog(@"Will show preferences window");
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
    [self registerGlobalHotkey:self];
    NSLog(@"Loaded Blackout v%@ (%@)", [self version], [self buildNumber]);
    
    if ([NSEvent optionKey]) {
        [self showPreferences];
    }
}

- (void)applicationWillTerminate:(NSNotification *)note
{
    NSLog(@"Blackout is shutting down");
}

@end
