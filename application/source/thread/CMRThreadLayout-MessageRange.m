//
//  CMRThreadLayout-MessageRange.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/08.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadLayout_p.h"
#import "CMRAttributedMessageComposer.h"
#import "AppDefaults.h"


@implementation CMRThreadLayout(MessageRange)
- (NSUInteger)numberOfReadedMessages
{
	return [[self messageBuffer] count];
}

- (NSUInteger)firstUnlaidMessageIndex
{
	return [[self messageRanges] count];
}

- (BOOL)isCompleted
{
	return [self numberOfReadedMessages] == [self firstUnlaidMessageIndex];
}

- (NSRange)rangeAtMessageIndex:(NSUInteger)index
{
	return [[self messageRanges] rangeAtIndex:index];
}

- (NSUInteger)messageIndexForRange:(NSRange)aRange
{
    __block NSUInteger foundIndex = NSNotFound;
    [[self messageRanges] enumerateLineRangesUsingBlock:^(NSRange range, NSUInteger idx, BOOL *stop) {
        NSRange intersection = NSIntersectionRange(range, aRange);
        if (intersection.length != 0) {
            foundIndex = idx;
            *stop = YES;
        }
    }];
    return foundIndex;
}

- (NSUInteger)lastMessageIndexForRangeSilverGull:(NSRange)aRange
{
	NSUInteger count, index_;
	
    count = [[self messageRanges] count];
    if (count == 0) {
        return NSNotFound;
    } else {
        index_ = count-1;
    }
    NSRange		mesRng_;
    NSRange		intersection_;
    mesRng_ = [[self messageRanges] rangeAtIndex:index_]; // last object
    intersection_ = NSIntersectionRange(mesRng_, aRange);
    if (NSMaxRange(intersection_) == NSMaxRange(mesRng_)) {
        return index_;
    }

	return [self messageIndexForRange:aRange];
}

- (NSUInteger)lastMessageIndexForRange:(NSRange)aRange
{
    DTRangesArray *ranges = [self messageRanges];
    NSInteger last = [ranges count] - 1;
    if (last < 0) {
        return NSNotFound;
    }
    NSInteger i;

    for (i = last; i >= 0; i--) {
        NSRange range = [ranges rangeAtIndex:i];
        NSRange intersection = NSIntersectionRange(range, aRange);
        if (intersection.length != 0) {
            return i;
        }
    }
	return NSNotFound;
}

- (NSAttributedString *)contentsAtIndex:(NSUInteger)index
{
	return [self contentsForIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (NSAttributedString *)contentsForIndexes:(NSIndexSet *)indexes
                             composingMask:(UInt32)composingMask
                                   compose:(BOOL)doCompose
                            attributesMask:(UInt32)attributesMask
{
	NSUInteger				size = [indexes lastIndex]+1;
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	
	if (!indexes || [indexes count] == 0) {
        return nil;
    }
	if ([self firstUnlaidMessageIndex] < size) {
        return nil;
    }

	composer_ = [[CMRAttributedMessageComposer alloc] init];
	textBuffer_ = [[NSMutableAttributedString alloc] init];
	
	[composer_ setAttributesMask:attributesMask];
	[composer_ setComposingMask:composingMask compose:doCompose];
	[composer_ setContentsStorage:textBuffer_];

    // Concurrent は禁止！
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        CMRThreadMessage *message = [[self messageBuffer] messageAtIndex:idx];
        [composer_ composeThreadMessage:message];
    }];

	[composer_ release];
	return [textBuffer_ autorelease];
}

- (NSAttributedString *)contentsForTargetIndex:(NSUInteger)messageIndex
								 composingMask:(UInt32)composingMask
									   compose:(BOOL)doCompose
								attributesMask:(UInt32)attributesMask
{
	CMRThreadMessage	*m;
	NSUInteger	limit = [self firstUnlaidMessageIndex];
	NSUInteger	i;
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	
	if (limit == 0) return nil;

	composer_ = [[CMRAttributedMessageComposer alloc] init];
	textBuffer_ = [[NSMutableAttributedString alloc] init];
	
	[composer_ setAttributesMask:attributesMask];
	[composer_ setComposingMask:composingMask compose:doCompose];
//	[composer_ setComposingTargetIndex: messageIndex];
	[composer_ setContentsStorage:textBuffer_];
	
	for (i = 0; i < limit; i++) {
		m = [[self messageBuffer] messageAtIndex:i];
        if ([[m referencingIndexes] containsIndex:messageIndex]) {
            [composer_ composeThreadMessage:m];
        }
	}
	[composer_ release];
	return [textBuffer_ autorelease];
}

- (NSAttributedString *)contentsForIndexes:(NSIndexSet *)indexes
{
	if (kSpamFilterInvisibleAbonedBehavior == [CMRPref spamFilterBehavior]) {
		return [self contentsForIndexes:indexes
                          composingMask:CMRInvisibleAbonedMask
                                compose:NO
                         attributesMask:CMRLocalAbonedMask];
	} else {
		return [self contentsForIndexes:indexes
                          composingMask:CMRInvisibleAbonedMask
                                compose:NO
                         attributesMask:(CMRLocalAbonedMask|CMRSpamMask)];
	}
}

// ローカルあぼーんされた内容を見せない場合
- (NSAttributedString *)localAbonedContentsForIndexes:(NSIndexSet *)indexes
{
    return [self contentsForIndexes:indexes composingMask:CMRInvisibleAbonedMask compose:NO attributesMask:0];
}

#pragma mark Next/Prev
- (NSUInteger)nextMessageIndexOfIndex:(NSUInteger)index attribute:(UInt32)flags value:(BOOL)attributeIsSet
{
	NSUInteger i;
    NSUInteger cnt;
	CMRThreadMessage *m;
	
	if (NSNotFound == index) {
		return NSNotFound;
    }
	cnt = [self firstUnlaidMessageIndex];
	if (cnt <= index) {
		return NSNotFound;
    }
	for (i = index +1; i < cnt; i++) {
		m = [self messageAtIndex:i];
		if (attributeIsSet == (([m flags] & flags) != 0)) {
			return i;
        }
	}
	
	return NSNotFound;
}

- (NSUInteger)previousMessageIndexOfIndex:(NSUInteger)index attribute:(UInt32)flags value:(BOOL)attributeIsSet
{
    NSInteger i;
	CMRThreadMessage *m;
	
	if (NSNotFound == index) {
		return NSNotFound;
	}
	if (0 == index) {
		return NSNotFound;
	}
	for (i = (index - 1); i >= 0; i--) {
		m = [self messageAtIndex:i];
		if (attributeIsSet == (([m flags] & flags) != 0)) {
			return i;
        }
	}

	return NSNotFound;
}

- (NSUInteger)messageIndexOfLaterDate:(NSDate *)baseDate attribute:(UInt32)flags value:(BOOL)attributeIsSet
{
	NSUInteger i;
    NSUInteger cnt;
	CMRThreadMessage *m;
	id msgDate;
	
	if (!baseDate) {
		return NSNotFound;
    }

	cnt = [self numberOfReadedMessages];

	for (i = 0; i < cnt; i++) {
		m = [self messageAtIndex:i];
		msgDate = [m date];
		if (!msgDate || ![msgDate isKindOfClass:[NSDate class]]) {
            continue;
        }
		if (([(NSDate *)msgDate compare: baseDate] != NSOrderedAscending) && (attributeIsSet == (([m flags] & flags) != 0))) {
			return i;
		}
	}

	return NSNotFound;
}

#pragma mark Jumpable index
- (NSUInteger)nextVisibleMessageIndex
{
	return [self nextVisibleMessageIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

- (NSUInteger)previousVisibleMessageIndex
{
	return [self previousVisibleMessageIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

static UInt32 attributeMaskForVisibleMessageIndexDetection()
{
	if (kSpamFilterInvisibleAbonedBehavior == [CMRPref spamFilterBehavior]) {
		return (CMRInvisibleAbonedMask|CMRSpamMask);
	} else {
		return CMRInvisibleAbonedMask;
	}
}

- (NSUInteger) nextVisibleMessageIndexOfIndex:(NSUInteger) anIndex
{
	return [self nextMessageIndexOfIndex:anIndex 
							   attribute:attributeMaskForVisibleMessageIndexDetection()
								   value:NO];
}

- (NSUInteger)previousVisibleMessageIndexOfIndex:(NSUInteger)anIndex
{
	return [self previousMessageIndexOfIndex:anIndex 
								   attribute:attributeMaskForVisibleMessageIndexDetection()
									   value:NO];
}

#pragma mark Jumping to bookmarks
- (NSUInteger)nextBookmarkIndex
{
	return [self nextBookmarkIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

- (NSUInteger)previousBookmarkIndex
{
	return [self previousBookmarkIndexOfIndex:[self firstMessageIndexForDocumentVisibleRect]];
}

- (NSUInteger)nextBookmarkIndexOfIndex:(NSUInteger)anIndex
{
	return [self nextMessageIndexOfIndex:anIndex attribute:CMRBookmarkMask value:YES];
}

- (NSUInteger)previousBookmarkIndexOfIndex:(NSUInteger) anIndex
{
	return [self previousMessageIndexOfIndex:anIndex attribute:CMRBookmarkMask value:YES];
}

#pragma mark Jumping to Specific date's Message
- (NSUInteger)messageIndexOfLaterDate:(NSDate *)baseDate
{
	return [self messageIndexOfLaterDate:baseDate attribute:attributeMaskForVisibleMessageIndexDetection() value:NO];
}
@end
