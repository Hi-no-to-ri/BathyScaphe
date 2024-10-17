//
//  CMRThreadView.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/09/07.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "SGHTMLView.h"
#import "BSRotateGestureAccepting.h"

@class CMRThreadLayout;
@class CMRThreadSignature;
@class CMRThreadMessage;

@protocol CMRThreadViewDelegate;

@interface CMRThreadView : SGHTMLView {
@private
    NSUInteger        m_lastCharIndex; // For -menuForEvent:

    BOOL            draggingHilited;
    NSTimeInterval  draggingTimer;

    BOOL magnifyingNow;
    BOOL rotatingNow;
    BOOL rotateEnoughFlag;
    BOOL magnifyEnoughFlag;
    CGFloat rotateSum;
    CGFloat magnifySum;
}

- (id<CMRThreadViewDelegate>)delegate;
- (void)setDelegate:(id<CMRThreadViewDelegate>)aDelegate;

// delegate's layout
- (CMRThreadLayout *)threadLayout;

// Available in Twincam Angel and later.
- (NSIndexSet *)messageIndexesForRange:(NSRange)range_;
- (NSIndexSet *)messageIndexesAtClickedPoint;
- (NSIndexSet *)selectedMessageIndexes;

+ (NSMenu *)messageMenu;
- (NSMenu *)messageMenuWithMessageIndex:(NSUInteger)aMessageIndex;
- (NSMenu *)messageMenuWithMessageIndexes:(NSIndexSet *)indexes;
@end


@protocol CMRThreadViewDelegate<BSRotateGestureAccepting, SGHTMLViewDelegate, NSTextViewDelegate, NSObject>
@required
- (void)tryToAddNGWord:(NSString *)string;
- (void)extractUsingString:(NSString *)string;
- (void)insertReferencedMarkersForPopupContents:(NSTextView *)textView;
- (void)colorizeID:(NSTextView *)textView;

@optional
- (CMRThreadSignature *)threadSignatureForView:(CMRThreadView *)aView;
- (CMRThreadLayout *)threadLayoutForView:(CMRThreadView *)aView;

// Message Reply
- (void)threadView:(CMRThreadView *)aView replyTo:(NSIndexSet *)messageIndexes; // Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
// Gyakusansyou Popup
- (void)threadView:(CMRThreadView *)aView reverseAnchorPopUp:(NSUInteger)targetIndex locationHint:(NSPoint)location_;
- (void)threadView:(CMRThreadView *)aView reverseAnchorPopUp:(NSUInteger)targetIndex forObject:(id)object locationHint:(NSPoint)location_; // Available in Matatabi-Step and later.

// Spam Filter
- (void)threadView:(CMRThreadView *)aView spam:(CMRThreadMessage *)aMessage messageRegister:(BOOL)registerFlag;

- (BOOL)threadView:(CMRThreadView *)aView mouseClicked:(NSEvent *)theEvent atIndex:(NSUInteger)charIndex messageIndex:(NSUInteger)aMessageIndex;
- (BOOL)threadView:(CMRThreadView *)aView mouseClicked:(NSEvent *)theEvent atIndex:(NSUInteger)charIndex userData:(id)userData; // Available in Matatabi-Step and later.

// ReinforceII Addition - Drag & Drop behavior util
- (void)setThreadContentWithThreadIdentifier:(id)aThreadIdentifier;

- (BOOL)threadView:(CMRThreadView *)aView swipeWithEvent:(NSEvent *)theEvent; // Available in BathyScaphe 1.7 "Prima Aspalas" and later.

// Available in BathyScaphe 2.0 "Final Moratorium" and later.
- (void)threadView:(CMRThreadView *)aView magnifyEnough:(CGFloat)additionalScaleFactor;

- (BOOL)acceptsFirstResponderForView:(CMRThreadView *)aView;
@end


