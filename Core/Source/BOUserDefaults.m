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

#import "BOUserDefaults.h"

#import <ShortcutRecorder/ShortcutRecorder.h>

#import "BOBundle.h"

#define BOEscapeKeyCode     53
#define BOCommandShiftMask  (cmdKey | shiftKey)

#define BODefaultKeyCode    BOEscapeKeyCode
#define BODefaultModifiers  BOCommandShiftMask


static void BOPreferencesSetValue(NSString *key, CFPropertyListRef val)
{
    CFPreferencesSetValue((CFStringRef) key,
                          val,
                          (CFStringRef) [[BOBundle preferencePaneBundle] bundleIdentifier],
                          kCFPreferencesCurrentUser,
                          kCFPreferencesAnyHost);
}

static id BOPreferencesGetValue(NSString *key)
{
    CFPropertyListRef val = CFPreferencesCopyValue((CFStringRef) key,
                                                   (CFStringRef) [[BOBundle preferencePaneBundle] bundleIdentifier],
                                                   kCFPreferencesCurrentUser,
                                                   kCFPreferencesAnyHost);
    return [NSMakeCollectable(val) autorelease];
}

static BOOL BOPreferencesSynchronize(void)
{
    return CFPreferencesSynchronize((CFStringRef) [[BOBundle preferencePaneBundle] bundleIdentifier],
                                    kCFPreferencesCurrentUser,
                                    kCFPreferencesAnyHost);
}


@interface BOUserDefaults ()
- (LSSharedFileListItemRef)loginItem:(id *)items;
- (void)addToLoginItems;
- (void)removeFromLoginItems;
@end


static BOUserDefaults *shared = nil;

@implementation BOUserDefaults

+ (id)sharedUserDefaults
{
    @synchronized (self) {
        if (!shared) {
            shared = [[self alloc] init];
        }
    }
    return shared;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized (self) {
        if (!shared) {
            shared = [super allocWithZone:zone];
            return shared;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;
}

- (void) release {}

- (id)autorelease
{
    return self;
}

#pragma mark Properties

- (NSUInteger)hotkeyModifiers
{
    return [self hotkey].flags;
}

- (void)setHotkeyModifiers:(NSUInteger)modifiers
{
    NSNumber *mods = [NSNumber numberWithUnsignedInt:SRCocoaToCarbonFlags(modifiers)];
    BOPreferencesSetValue(@"Hotkey Modifier", (CFNumberRef) mods);
}

- (NSInteger)hotkeyCode
{
    return [self hotkey].code;
}

- (void)setHotkeyCode:(NSInteger)code
{
    BOPreferencesSetValue(@"Hotkey Keycode", (CFNumberRef) [NSNumber numberWithInteger:code]);
}

- (KeyCombo)hotkey
{
    NSInteger code = [BOPreferencesGetValue(@"Hotkey Keycode") integerValue];
    NSUInteger flags = [BOPreferencesGetValue(@"Hotkey Modifier") unsignedIntegerValue];
    if (code == 0) code = BODefaultKeyCode;
    if (flags == 0) flags = SRCarbonToCocoaFlags(BODefaultModifiers);
    return SRMakeKeyCombo(code, flags);
}

- (void)setHotkey:(KeyCombo)keyCombo
{
    [self setHotkeyModifiers:keyCombo.flags];
    [self setHotkeyCode:keyCombo.code];
}

- (BOOL)startAtLogin
{
    return [self loginItem:nil] != NULL;
}

- (void)setStartAtLogin:(BOOL)start
{
    if (start) {
        [self addToLoginItems];
    } else {
        [self removeFromLoginItems];
    }
}

- (BOOL)shouldUpdateAutomatically
{
    id userPref = BOPreferencesGetValue(@"SUEnableAutomaticChecks");
    if (userPref) {
        return [userPref boolValue];
    } else {
        NSDictionary *info = [[BOBundle preferencePaneBundle] infoDictionary];
        id appPref = [info objectForKey:@"SUEnableAutomaticChecks"];
        return appPref ? [appPref boolValue] : NO;
    }
}

- (void)setShouldUpdateAutomatically:(BOOL)doCheck
{
    CFBooleanRef state = doCheck ? kCFBooleanTrue : kCFBooleanFalse;
    BOPreferencesSetValue(@"SUEnableAutomaticChecks", state);
    BOPreferencesSynchronize();
}

#pragma mark Helpers

- (void)addToLoginItems
{
    // Source: http://cocoatutorial.grapewave.com/2010/02/creating-andor-removing-a-login-item/
    CFURLRef appPath = (CFURLRef) [NSURL fileURLWithPath:[self blackoutHelperPath]];
    id loginItems = [NSMakeCollectable(LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL)) autorelease];
    if (loginItems) {
        id item = [NSMakeCollectable(LSSharedFileListInsertItemURL((LSSharedFileListRef) loginItems, kLSSharedFileListItemLast, NULL, NULL, appPath, NULL, NULL)) autorelease];
        if (item) {
            NSLog(@"Added Blackout to login items");
        }
    }
}

- (void)removeFromLoginItems
{
    id loginItems;
    LSSharedFileListItemRef item = [self loginItem:&loginItems];
    if (item) LSSharedFileListItemRemove((LSSharedFileListRef) loginItems, item);
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
    }
    
    if (items) *items = loginItems;
    return theItem;
}

@end
