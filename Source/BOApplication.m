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
#import "NSEvent+Blackout.h"
#import "NSImage+Convenience.h"


@interface BOApplication ()
@property (readonly) NSImage *statusMenuImage;
@property (readonly) NSImage *alternateStatusMenuImage;
- (IBAction)activateScreenSaverOrMenu:(id)sender;
@end


@implementation BOApplication

@dynamic statusMenuImage;
@dynamic alternateStatusMenuImage;

- (void)awakeFromNib
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    statusItem = [[bar statusItemWithLength:NSSquareStatusItemLength] retain];
    [statusItem setImage:[self statusMenuImage]];
    [statusItem setAlternateImage:[self alternateStatusMenuImage]];
    [statusItem setHighlightMode:YES];
    [statusItem setAction:@selector(activateScreenSaverOrMenu:)];
}

- (void)dealloc
{
    [statusItem release];
    [super dealloc];
}

- (NSImage *)statusMenuImage
{
    NSString *imgPath = [[NSBundle mainBundle] pathForResource:@"Moon" ofType:@"png"];
    return [NSImage imageWithContentsOfFile:imgPath];
}

- (NSImage *)alternateStatusMenuImage
{
    return [self statusMenuImage];
}

- (IBAction)activateScreenSaverOrMenu:(id)sender
{
    if ([NSEvent isCommandKeyDown] || [NSEvent isControlKeyDown]) {
        [self activateMenu:sender];
    } else {
        [self activateScreenSaver:sender];
    }
}

- (IBAction)activateMenu:(id)sender
{
    [statusItem popUpStatusItemMenu:mainMenu];
}

- (IBAction)activateScreenSaver:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchApplication:@"ScreenSaverEngine"];
}

@end
