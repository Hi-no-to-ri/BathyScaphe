//
//  SGHTMLView-Link.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/06/12.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SGHTMLView_p.h"
#import "CMRAttachmentCell.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"



@implementation SGHTMLView(Link)
- (NSTrackingArea *)visibleArea
{
    return bs_visibleArea;
}

- (void)resetCursorRectsImp
{
	if (![self window]) {
        return;
    }

	[self removeAllLinkTrackingRects];
	[self resetTrackingVisibleRect];
    
    NSRect rect = [self visibleRect];
	[self updateAnchoredRectsInBounds:rect forAttribute:NSLinkAttributeName];
//	[self updateAnchoredRectsInBounds:rect forAttribute:NSAttachmentAttributeName];
	[self updateAnchoredRectsInBounds:rect forAttribute:CMRMessageIndexAttributeName];
    
//    [self updateAnchoredRectsInBounds:rect forAttribute:BSMessageIDAttributeName];
    [self updateAnchoredRectsForIDAttributesInBounds:rect];
    [self updateAnchoredRectsInBounds:rect forAttribute:BSMessageReferencedCountAttributeName];
}

/*** Event Handling ***/
- (void)responseMouseEvent:(NSEvent *)theEvent mouseEntered:(BOOL)isEntered
{
	if ((isEntered ? NSMouseEntered : NSMouseExited) != [theEvent type]) {
		return;
	}

    NSTrackingArea *area = [theEvent trackingArea];
    if (!area) {
        return;
    }

    // View
    if ([area isEqual:[self visibleArea]]) {
		[self mouseEventInVisibleRect:theEvent entered:isEntered];
		return;
	}
    
    // マウスポインタがテキストビューの外側にある場合（ありうる）は無視する
    NSPoint mousePoint = [theEvent locationInWindow];
    NSPoint convertedPoint = [self convertPoint:mousePoint fromView:nil];
    if (![self mouse:convertedPoint inRect:[self visibleRect]]) {
        return;
    }
    
    [self processMouseOverEvent:theEvent trackingArea:area mouseEntered:isEntered];
}

- (BOOL)shouldUpdateAnchoredRectsInBounds:(NSRect)aBounds
{
	return !([[self textStorage] isEmpty] || [self inLiveResize]);
}

- (void)updateAnchoredRectsInBounds:(NSRect)aBounds forAttribute:(NSString *)attributeName
{
	NSTextStorage		*storage_	= [self textStorage];
	NSLayoutManager		*lm			= [self layoutManager];
	NSTextContainer		*container_	= [self textContainer];

	NSUInteger			toIndex_;
	NSUInteger			charIndex_;
	NSRange				glyphRange_;
	NSRange				charRange_;
	NSRange				linkRange_;
	id					v = nil;

    CGFloat dX = [self textContainerInset].width;
    CGFloat dY = [self textContainerInset].height;

	if (![self shouldUpdateAnchoredRectsInBounds:aBounds]) {
		return;
    }

	glyphRange_ = [lm glyphRangeForBoundingRectWithoutAdditionalLayout:aBounds inTextContainer:container_];
	charRange_ = [lm characterRangeForGlyphRange:glyphRange_ actualGlyphRange:NULL];
	charIndex_ = charRange_.location;
	toIndex_ = NSMaxRange(charRange_);
	if (0 == toIndex_) {
        return;
	}

	while (charIndex_ < toIndex_) {
		v = [storage_ attribute:attributeName
						atIndex:charIndex_
		  longestEffectiveRange:&linkRange_
						inRange:charRange_];

		do {
            if (v) {
                NSRange			actualRange_;
                NSRectArray		rects_;
                NSUInteger		i, rectCount_;

                glyphRange_ = [lm glyphRangeForCharacterRange:linkRange_ actualCharacterRange:&actualRange_];

                linkRange_ = actualRange_;

                rects_ = [lm rectArrayForGlyphRange:glyphRange_
                           withinSelectedGlyphRange:kNFRange
                                    inTextContainer:container_
                                          rectCount:&rectCount_];
                for (i = 0; i < rectCount_; i++) {
                    NSRect foo = rects_[i];
                    foo.origin.x += dX;
                    foo.origin.y += dY;
                    [self addLinkTrackingArea:foo link:v attributeName:attributeName];
                }
            }
		} while (0);

		charIndex_ = NSMaxRange(linkRange_);
	}
}

- (void)updateAnchoredRectsForIDAttributesInBounds:(NSRect)aBounds
{
    NSTextStorage		*storage_	= [self textStorage];
    NSLayoutManager		*lm			= [self layoutManager];
    NSTextContainer		*container_	= [self textContainer];
    
    NSUInteger			toIndex_;
    NSUInteger			charIndex_;
    NSRange				glyphRange_;
    NSRange				charRange_;
    NSRange				linkRange_;
    id					v = nil;
    NSDictionary        *values = nil;
    
    CGFloat dX = [self textContainerInset].width;
    CGFloat dY = [self textContainerInset].height;
    
    if (![self shouldUpdateAnchoredRectsInBounds:aBounds]) {
        return;
    }
    
    glyphRange_ = [lm glyphRangeForBoundingRectWithoutAdditionalLayout:aBounds inTextContainer:container_];
    charRange_ = [lm characterRangeForGlyphRange:glyphRange_ actualGlyphRange:NULL];
    charIndex_ = charRange_.location;
    toIndex_ = NSMaxRange(charRange_);
    if (0 == toIndex_) {
        return;
    }
    @autoreleasepool {
        while (charIndex_ < toIndex_) {
            values = [storage_ attributesAtIndex:charIndex_ longestEffectiveRange:&linkRange_ inRange:charRange_];
            
            do {
                if ((v = [values objectForKey:BSMessageIDAttributeName])) {
                    NSRange			actualRange_;
                    NSRectArray		rects_;
                    NSUInteger		i, rectCount_;
                    
                    glyphRange_ = [lm glyphRangeForCharacterRange:linkRange_ actualCharacterRange:&actualRange_];
                    
                    linkRange_ = actualRange_;
                    
                    rects_ = [lm rectArrayForGlyphRange:glyphRange_
                               withinSelectedGlyphRange:kNFRange
                                        inTextContainer:container_
                                              rectCount:&rectCount_];
                    for (i = 0; i < rectCount_; i++) {
                        NSRect foo = rects_[i];
                        foo.origin.x += dX;
                        foo.origin.y += dY;
                        [self addLinkTrackingArea:foo link:v isOnIDField:([[values objectForKey:BSMessageKeyAttributeName] isEqualToString:BSMessageKeyAttributeIDField])];
                    }
                }
            } while (0);
            
            charIndex_ = NSMaxRange(linkRange_);
        }
    }
}

- (void)setVisibleArea:(NSTrackingArea *)area
{
    [area retain];
    [bs_visibleArea release];
    bs_visibleArea = area;
}

- (void)resetTrackingVisibleRect
{
    if ([self visibleArea]) {
        [self removeTrackingArea:[self visibleArea]];
    }
    // ポップアップはアプリケーション非アクティブ時には見えないのだから、NSTrackingActiveInActiveApp で十分なはず。
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self visibleRect]
                                                        options:(NSTrackingMouseEnteredAndExited|NSTrackingActiveInActiveApp|NSTrackingInVisibleRect)
                                                          owner:self
                                                       userInfo:nil];
    [self setVisibleArea:area];
    [area release];
    [self addTrackingArea:[self visibleArea]];
}

- (void)addLinkTrackingArea:(NSRect)aRect link:(id)aLink isOnIDField:(BOOL)onIDField
{
    NSTrackingArea *area;
    area = [[NSTrackingArea alloc] initWithRect:aRect
                                        options:(NSTrackingMouseEnteredAndExited|NSTrackingCursorUpdate|NSTrackingActiveInActiveApp)
                                          owner:self
                                       userInfo:@{SGHTMLViewLinkUserDataLinkValueKey: aLink, SGHTMLViewLinkUserDataAttributeNameKey: BSMessageIDAttributeName, SGHTMLViewLinkUserDataFieldHintKey: [NSNumber numberWithBool:onIDField]}];
    [self addTrackingArea:area];
    [area release];
}

- (void)addLinkTrackingArea:(NSRect)aRect link:(id)aLink attributeName:(NSString *)name
{
    NSTrackingArea *area;
    area = [[NSTrackingArea alloc] initWithRect:aRect
                                        options:(NSTrackingMouseEnteredAndExited|NSTrackingCursorUpdate|NSTrackingActiveInActiveApp)
                                          owner:self
                                       userInfo:@{SGHTMLViewLinkUserDataLinkValueKey: aLink, SGHTMLViewLinkUserDataAttributeNameKey: name}];
    [self addTrackingArea:area];
    [area release];
}

- (void)cursorUpdate:(NSEvent *)event
{
    NSPoint mousePoint = [self convertPoint:[[self window] mouseLocationOutsideOfEventStream] fromView:nil];
    if ([self mouse:mousePoint inRect:[[event trackingArea] rect]]) {
        [[NSCursor pointingHandCursor] set];
    } else {
        [[NSCursor IBeamCursor] set];
    }
}

- (void)removeAllLinkTrackingRects
{
    NSArray *copied = [[self trackingAreas] copy];
    for (NSTrackingArea *area in copied) {
        [self removeTrackingArea:area];
    }
    [copied release];
}
@end


@implementation SGHTMLView(DelegateSupport)
- (void)processMouseOverEvent:(NSEvent *)theEvent trackingArea:(NSTrackingArea *)area mouseEntered:(BOOL)mouseEntered
{
    NSString *attributeName = [[area userInfo] objectForKey:SGHTMLViewLinkUserDataAttributeNameKey];
    
    /*if ([attributeName isEqualToString:NSAttachmentAttributeName]) {
		id cell_ = [[[area userInfo] objectForKey:SGHTMLViewLinkUserDataLinkValueKey] attachmentCell];
        
		// TextAttachement
		if (![cell_ wantsToTrackMouseForEvent:theEvent inRect:[area rect] ofView:self atCharacterIndex:NSNotFound]) {
			return;
		}
		[cell_ trackMouse:theEvent inRect:[area rect] ofView:self atCharacterIndex:NSNotFound untilMouseUp:NO];
		return;
    } else*/ if ([attributeName isEqualToString:CMRMessageIndexAttributeName]) {
        // Message Index: マウスオーバーには常に無反応
        return;
    }
    
    id<SGHTMLViewDelegate> delegate = [self delegate];
    if (!delegate) {
        return;
    }
    
    SEL selector = mouseEntered ? @selector(HTMLView:mouseEnteredInTrackingArea:withEvent:) : @selector(HTMLView:mouseExitedFromTrackingArea:withEvent:);
    if (![delegate respondsToSelector:selector]) {
        return;
    }
    
    // 他は、デリゲートに委譲
    if (mouseEntered) {
        [delegate HTMLView:self mouseEnteredInTrackingArea:area withEvent:theEvent];
    } else {
        [delegate HTMLView:self mouseExitedFromTrackingArea:area withEvent:theEvent];
    }
}

- (void)mouseEventInVisibleRect:(NSEvent *)anEvent entered:(BOOL)isMouseEntered
{
	UTILNotifyName(isMouseEntered ? SGHTMLViewMouseEnteredNotification : SGHTMLViewMouseExitedNotification);
}

- (BOOL)shouldHandleContinuousMouseDown:(NSEvent *)theEvent
{
    id<SGHTMLViewDelegate> delegate = [self delegate];
	if (!delegate || ![delegate respondsToSelector:@selector(HTMLView:shouldHandleContinuousMouseDown:)]) {
		return NO;
	}
	return [delegate HTMLView:self shouldHandleContinuousMouseDown:theEvent];
}

- (BOOL)handleContinuousMouseDown:(NSEvent *)theEvent
{
    id<SGHTMLViewDelegate> delegate = [self delegate];
	if (!delegate || ![delegate respondsToSelector:@selector(HTMLView:continuousMouseDown:)]) {
		return NO;
	}
	return [delegate HTMLView:self continuousMouseDown:theEvent];
}
@end
