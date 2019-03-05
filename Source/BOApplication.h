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

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/ShortcutRecorder.h>


typedef KeyCombo BOCocoaKeyCombo;

typedef struct
{
    NSInteger flags;
    NSInteger code;
}
BOCarbonKeyCombo;


@interface BOApplication : NSObject
{
@private
    EventHotKeyRef hotkeyHandler;
    NSStatusItem *statusItem;
}

@property (readonly) NSString *version;
@property (readonly) NSString *build;
@property (readonly) NSDictionary *environment;
@property (assign, nonatomic) BOOL isLoginItem;

@property (assign, nonatomic) BOCarbonKeyCombo carbonKeyCombo;
@property (assign, nonatomic) BOCocoaKeyCombo cocoaKeyCombo;

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) IBOutlet NSWindow *preferencesWindow;
@property (strong, nonatomic) IBOutlet SRRecorderControl *shortcutControl;
@property (strong, nonatomic) IBOutlet NSButton *loginItemButton;

- (NSImage *)statusMenuImageWithFrame:(NSRect)frame;

- (void)registerGlobalHotkey:(id)sender;
- (void)unregisterGlobalHotkey:(id)sender;
- (void)activateScreenSaver:(id)sender;

- (IBAction)showPreferencesWindow:(id)sender;
- (IBAction)toggleLoginItem:(id)sender;

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;

@end
