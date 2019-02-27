//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006-2011 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim


//----------------------------------------------------------
// SRCarbonToCocoaFlags()
//----------------------------------------------------------
NSUInteger SRCarbonToCocoaFlags( NSUInteger carbonFlags )
{
    NSUInteger cocoaFlags = ShortcutRecorderEmptyFlags;

    if (carbonFlags & cmdKey) cocoaFlags |= NSCommandKeyMask;
    if (carbonFlags & optionKey) cocoaFlags |= NSAlternateKeyMask;
    if (carbonFlags & controlKey) cocoaFlags |= NSControlKeyMask;
    if (carbonFlags & shiftKey) cocoaFlags |= NSShiftKeyMask;
    if (carbonFlags & NSFunctionKeyMask) cocoaFlags += NSFunctionKeyMask;

    return cocoaFlags;
}

//----------------------------------------------------------
// SRCocoaToCarbonFlags()
//----------------------------------------------------------
NSUInteger SRCocoaToCarbonFlags( NSUInteger cocoaFlags )
{
    NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;

    if (cocoaFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
    if (cocoaFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
    if (cocoaFlags & NSControlKeyMask) carbonFlags |= controlKey;
    if (cocoaFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
    if (cocoaFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;

    return carbonFlags;
}
