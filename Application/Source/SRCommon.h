//
//  SRCommon.h
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick


#pragma mark -
#pragma mark Macros

#define ShortcutRecorderEmptyFlags 0

#pragma mark -
#pragma mark Typedefs

typedef struct _KeyCombo {
    NSUInteger flags; //  0 for no flags
    NSInteger code;   // -1 for no code
} KeyCombo;

#pragma mark -
#pragma mark Converting between Cocoa and Carbon modifier flags

extern NSUInteger SRCarbonToCocoaFlags( NSUInteger carbonFlags );
extern NSUInteger SRCocoaToCarbonFlags( NSUInteger cocoaFlags );
