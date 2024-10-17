//
//  CMRThreadLayout.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/08.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadLayout_p.h"
#import "CMRMessageAttributesStyling.h"
#import "CMRMessageAttributesTemplate_p.h"
#import "CMRAttributedMessageComposer.h"
#import "BSThreadComposingOperation.h"
#import "BSSSSPIconManager.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"



@implementation CMRThreadLayout
- (id)initWithTextView:(NSTextView *)aTextView
{
	UTILAssertKindOfClass(aTextView, CMRThreadView);
	if (self = [self init]) {
		[self setTextView:(CMRThreadView *)aTextView];
	}
	return self;
}

- (id)init
{
	if (self = [super init]) {
		_messagesLock = [[NSLock alloc] init];

		// initialize local buffers
        _messageRanges = [[DTRangesArray alloc] init];
		_messageBuffer = [[CMRThreadMessageBuffer alloc] init];

		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(threadMessageDidChangeAttribute:)
                                                     name:CMRThreadMessageDidChangeAttributeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beIconImageDidUpdate:) name:BSSSSPIconPlaceholderDidUpdateNotification object:[BSSSSPIconManager defaultManager]];
        m_operationQueue = [[NSOperationQueue alloc] init];
        m_countedSet = [[NSCountedSet alloc] init];
        m_reverseReferencesCountedSet = [[NSCountedSet alloc] init];
    }
	return self;
}

- (void)dealloc
{
//    [m_operationQueue cancelAllOperations];
    [m_operationQueue release];
	UTIL_DEBUG_METHOD;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [m_countedSet release];
    [m_reverseReferencesCountedSet release];

	[_textView release];
	[_messagesLock release];
	[_messageRanges release];
	[_messageBuffer release];

	[super dealloc];
}

- (BOOL)isMessagesEdited
{
    return _isMessagesEdited;
}

- (void)setMessagesEdited:(BOOL)flag
{
    _isMessagesEdited = flag;
}

- (void)doDeleteAllMessages
{
	NSTextStorage *contents_;
	NSUInteger length_;

	contents_ = [self textStorage];

	// --------- Delete All Contents ---------
	length_ = [contents_ length];
	if (length_ > 0) {
		NSRange			contentRng_;
        contentRng_ = NSMakeRange(0, length_);
		[contents_ beginEditing];
		[contents_ deleteCharactersInRange:contentRng_];
		[contents_ endEditing];
	}

	// --------- Delete Message Ranges ---------
	[_messagesLock lock];
    [_messageRanges release];
    _messageRanges = [[DTRangesArray alloc] init];
	[[self messageBuffer] removeAll];
	[_messagesLock unlock];
    
    //
    [[self countedSet] removeAllObjects];
    [[self reverseReferencesCountedSet] removeAllObjects];

	[self setMessagesEdited:NO];
}

- (BOOL)isInProgress
{
    return [m_operationQueue operationCount] > 0;
}

- (void)clear
{
    [[self operationQueue] cancelAllOperations];
//    [[self operationQueue] waitUntilAllOperationsAreFinished]; // deadlock

    [self doDeleteAllMessages];
}

- (void)clear:(id)object
{
    [self doDeleteAllMessages];
    [object performSelector:@selector(threadClearTaskDidFinish:) withObject:nil];
}

- (void)disposeLayoutContext
{
	UTIL_DEBUG_METHOD;
/*
	in the case of ThreadViewer: this method will be invoked when window closing,
	document removing, threadViewer closing. but that time, TextView may be
	activate, so we remove it's layout manager from contents.
*/	
	[[[self layoutManager] retain] autorelease];
	[[self textStorage] removeLayoutManager:[self layoutManager]];

	[self doDeleteAllMessages];
}

- (NSOperationQueue *)operationQueue
{
    return m_operationQueue;
}

- (void)addOperation:(NSOperation *)operation
{
    [[self operationQueue] addOperation:operation];
}

/*- (void)push:(id<CMRThreadLayoutTask>)aTask
{
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:aTask selector:@selector(executeWithLayout:) object:self];
    [m_operationQueue addOperation:op];
    [op release];
}*/

- (void)ensureLayoutForThreadView
{
    if ([[self layoutManager] hasNonContiguousLayout]) {
        [[self layoutManager] ensureLayoutForTextContainer:[self textContainer]];
    }
}
@end


@implementation CMRThreadLayout(Accessor)
- (CMRThreadView *)textView
{
	return _textView;
}

- (void)setTextView:(CMRThreadView *)aTextView
{
    [aTextView retain];
    [_textView release];
    _textView = aTextView;
}

- (NSLayoutManager *)layoutManager
{
	return [[self textView] layoutManager];
}

- (NSTextContainer *)textContainer
{
	return [[self textView] textContainer];
}

- (NSTextStorage *)textStorage
{
	return [[self textView] textStorage];
}

- (NSScrollView *)scrollView
{
	return [[self textView] enclosingScrollView];
}

- (CMRThreadMessage *)messageAtIndex:(NSUInteger)anIndex
{
	return [[self messageBuffer] messageAtIndex:anIndex];
}

- (NSArray *)messagesAtIndexes:(NSIndexSet *)indexes
{
    return [[self messageBuffer] messagesAtIndexes:indexes];
}

- (BOOL)onlySingleMessageInRange:(NSRange)range
{
	NSUInteger index1, index2;

	index1 = [self messageIndexForRange:range];
	index2 = [self lastMessageIndexForRange:range];
	return (index1 == index2);
}

- (void)threadMessageDidChangeAttribute:(NSNotification *)theNotification
{
	CMRThreadMessage	*message;
	NSUInteger			mIndex;
	
	UTILAssertNotificationName(
		theNotification,
		CMRThreadMessageDidChangeAttributeNotification);
	
	message = [theNotification object];
	if ((mIndex = [[self messageBuffer] indexOfMessage:message]) != NSNotFound) {
		[self updateMessageAtIndex:mIndex];
	}
}

- (void)updateMessageAtIndex:(NSUInteger)anIndex
{
	NSMutableAttributedString		*textBuffer_;
	CMRAttributedMessageComposer	*composer_;
	CMRThreadMessage				*m;
	NSRange							mesRange_;
	NSInteger						changeInLength_ = 0;

	if (NSNotFound == anIndex || [self firstUnlaidMessageIndex] <= anIndex) {
		return;
    }

	[_messagesLock lock];
	do {
		m = [[self messageBuffer] messageAtIndex:anIndex];
		mesRange_ = [[self messageRanges] rangeAtIndex:anIndex];
		// 非表示のレスは生成しない
		if (![m isVisible]) {
			if (mesRange_.length != 0) {
				changeInLength_ = -(mesRange_.length);
				[[self textStorage] deleteCharactersInRange:mesRange_];
			}
			break;
		}
        
		composer_ = [[CMRAttributedMessageComposer alloc] init];
		textBuffer_ = [[NSMutableAttributedString alloc] init];
		
		[composer_ setComposingMask:CMRInvisibleMask compose:NO];
		[composer_ setContentsStorage:textBuffer_];

		[composer_ composeThreadMessage:m];
		changeInLength_ = [textBuffer_ length] - mesRange_.length;

		[[self textStorage] replaceCharactersInRange:mesRange_ withAttributedString:textBuffer_];
		
		[textBuffer_ release];
		[composer_ release];
		textBuffer_ = nil;
		composer_ = nil;

	} while (0);

	if (changeInLength_ != 0) {
		mesRange_.length += changeInLength_;
        [[self messageRanges] bs_extendRangeAtIndex:anIndex forLength:changeInLength_];
	}

    // 再度逆参照マーカーを挿入
    if ([CMRPref showsReferencedMarker]) {
        [self insertReferencedCountStrings:[self textStorage] range:mesRange_];
    }
	[_messagesLock unlock];
    
    if ([CMRPref shouldColorIDString]) {
        [self colorizeIDImpl:[self textStorage] range:mesRange_ layoutManager:[self layoutManager]];
    }
    [self setMessagesEdited:YES];
}

- (void)changeAllMessageAttributes:(BOOL)onOffFlag flags:(UInt32)mask
{
	[[self messageBuffer] changeAllMessageAttributes:onOffFlag flags:mask];
}

- (NSUInteger)numberOfMessageAttributes:(UInt32)mask
{
	NSUInteger			count_ = 0;

    for (CMRThreadMessage *message in [self allMessages]) {
        if (mask & [message flags]) {
            count_++;
        }
    }
    
	return count_;
}

- (DTRangesArray *)messageRanges
{
	return _messageRanges;
}

- (void)setMessageRanges:(DTRangesArray *)array
{
    [array retain];
    [_messageRanges release];
    _messageRanges = array;
}

- (void)addMessageRange:(NSRange)range
{
	[_messagesLock lock];
    [[self messageRanges] addRange:range];
	[_messagesLock unlock];
}

- (void)slideMessageRanges:(NSInteger)changeInLength fromLocation:(NSUInteger)fromLocation
{
    [[self messageRanges] bs_slideLineRangesForLength:changeInLength fromLocation:fromLocation];
}

- (void)slideMessageRanges:(DTRangesArray *)ranges forLength:(NSInteger)changeInLength firstTargetMessageIndex:(NSUInteger)baseIndex
{
    [ranges bs_slideLineRangesForLength:changeInLength firstTargetIndex:baseIndex];
}

- (void)slideMessageRanges:(NSInteger)changeInLength firstTargetMessageIndex:(NSUInteger)baseIndex
{
    [self slideMessageRanges:[self messageRanges] forLength:changeInLength firstTargetMessageIndex:baseIndex];
}

- (void)extendMessageRange:(NSInteger)extensionLength forMessageIndex:(NSUInteger)baseIndex
{
    [[self messageRanges] bs_extendRangeAtIndex:baseIndex forLength:extensionLength];
}

- (CMRThreadMessageBuffer *)messageBuffer
{
	return _messageBuffer;
}

- (NSArray *)allMessages
{
    return [[self messageBuffer] messages];
}

- (void)addMessagesFromBuffer:(CMRThreadMessageBuffer *)otherBuffer
{
	if (!otherBuffer) {
		return;
	}
	[_messagesLock lock];
	[[self messageBuffer] addMessagesFromBuffer:otherBuffer];

    [[otherBuffer messages] makeObjectsPerformSelector:@selector(setPostsAttributeChangedNotifications:) withObject:[NSNumber numberWithBool:YES]];

	[_messagesLock unlock];
}

- (NSCountedSet *)countedSet
{
    return m_countedSet;
}

- (void)setCountedSet:(NSCountedSet *)set
{
    [set retain];
    [m_countedSet release];
    m_countedSet = set;
}

- (NSCountedSet *)reverseReferencesCountedSet
{
    return m_reverseReferencesCountedSet;
}

- (void)setReverseReferencesCountedSet:(NSCountedSet *)set
{
    [set retain];
    [m_reverseReferencesCountedSet release];
    m_reverseReferencesCountedSet = set;
}
@end


@implementation CMRThreadLayout(DocuemntVisibleRect)
- (NSUInteger)firstMessageIndexForDocumentVisibleRect
{
	NSRange visibleRange_;
	
	visibleRange_ = [[self textView] characterRangeForDocumentVisibleRect];
	
	// 各レスの最後には空行が含まれるため、表示されている範囲を
	// そのまま渡すと見た目との齟齬が気になる。
	// よって、位置を改行ひとつ分ずらす。
	if (visibleRange_.length > 1) {
	  visibleRange_.location += 1;
	  visibleRange_.length -= 1;	//範囲チェックを省く簡便のため
	}

	return [self messageIndexForRange:visibleRange_];
}

- (NSUInteger)lastMessageIndexForDocumentVisibleRect
{
	NSRange visibleRange_;
	
	visibleRange_ = [[self textView] characterRangeForDocumentVisibleRect];
	
	if (visibleRange_.length > 1) {
	  visibleRange_.location += 1;
	  visibleRange_.length -= 1;
	}

    // とりあえずの修正、1.6.2 以降でもっときちんと
	return [self lastMessageIndexForRangeSilverGull:visibleRange_];
}

- (void)scrollMessageWithRange:(NSRange)aRange
{
	CMRThreadView	*textView = [self textView];
    BOOL needsAdjust = ![CMRPref oldMessageScrollingBehavior];

//    if (needsAdjust) {
        // 2010-08-15 tsawada2
        // non-contiguous layout でこのおまじないが効く
        [textView scrollRangeToVisible:aRange];
 //   }
	NSRect			characterBoundingRect;
	NSRect			newVisibleRect;
    NSRect          currentVisibleRect;
	NSPoint			newOrigin;
	NSClipView		*clipView;
	
	if (NSNotFound == aRange.location || 0 == aRange.length) {
		NSBeep();
		return;
	}
	
	characterBoundingRect = [textView boundingRectForCharacterInRange:aRange];
	if (NSEqualRects(NSZeroRect, characterBoundingRect)) {
        return;
	}

	clipView = [[self scrollView] contentView];
	currentVisibleRect = [clipView documentVisibleRect];

	newOrigin = [textView bounds].origin;
	newOrigin.y = characterBoundingRect.origin.y;	

    newVisibleRect = currentVisibleRect;
	newVisibleRect.origin = newOrigin;

	if (!NSEqualRects(newVisibleRect, currentVisibleRect)) {
		// 表示予定領域(newVisibleRect)のGlyphがレイアウトされていることを保証する
        [[self layoutManager] ensureLayoutForBoundingRect:newVisibleRect inTextContainer:[self textContainer]];
		// ----------------------------------------
		// Simulate user scroll
		// ----------------------------------------
        if (needsAdjust) {
            newVisibleRect.origin = [clipView constrainScrollPoint:newOrigin];
        }
		newVisibleRect = [[clipView documentView] adjustScroll:newVisibleRect];

		[clipView scrollToPoint:newVisibleRect.origin];
		[[self scrollView] reflectScrolledClipView:clipView];
	}
}

- (IBAction)scrollToLastUpdatedIndex:(id)sender
{
	[self scrollMessageWithRange:[self firstLastUpdatedHeaderAttachmentRange]];
}

- (void)scrollMessageAtIndex:(NSUInteger)anIndex
{
	if (NSNotFound == anIndex || [self firstUnlaidMessageIndex] <= anIndex) {
		return;
    }

	[self scrollMessageWithRange:[self rangeAtMessageIndex:anIndex]];
}
@end


@implementation CMRThreadLayout(Attachment)
- (NSDate *)lastUpdatedDateFromHeaderAttachment
{
	return [self lastUpdatedDateFromFirstHeaderAttachmentEffectiveRange:NULL];
}

- (NSRange)firstLastUpdatedHeaderAttachmentRange
{
	NSRange effectiveRange_;

	[self lastUpdatedDateFromFirstHeaderAttachmentEffectiveRange:&effectiveRange_];
	return effectiveRange_;
}

- (NSDate *)lastUpdatedDateFromFirstHeaderAttachmentEffectiveRange:(NSRangePointer)effectiveRange
{
	NSTextStorage	*content_ = [self textStorage];
	NSUInteger		charIndex_;
	NSUInteger		toIndex_;
	NSRange			charRng_;
	NSRange			range_;
	id				value_ = nil;

	charRng_ = NSMakeRange(0, [content_ length]);
	charIndex_ = charRng_.location;
	toIndex_   = NSMaxRange(charRng_);

	while (charIndex_ < toIndex_) {
		value_ = [content_ attribute:CMRMessageLastUpdatedHeaderAttributeName
							 atIndex:charIndex_
			   longestEffectiveRange:&range_
							 inRange:charRng_];
		if (value_) {
			if (effectiveRange != NULL) {
                *effectiveRange = range_;
			}
			if (![value_ isKindOfClass:[NSDate class]]) {
                return nil;
            }
			return (NSDate *)value_;
		}
		charIndex_ = NSMaxRange(range_);
	}
	if (effectiveRange != NULL) {
        *effectiveRange = NSMakeRange(NSNotFound, 0);
    }
	return nil;
}

- (void)appendLastUpdatedHeader:(BOOL)flag
{
	NSAttributedString	*header_;
	NSRange				range_;
	id					templateMgr = [CMRMessageAttributesTemplate sharedTemplate];
	NSTextStorage		*tS_ = [self textStorage];

	header_ = [templateMgr lastUpdatedHeaderAttachment];
	if (!header_) { 
		return;
    }

    if (flag) {
        [tS_ beginEditing];
    }

	range_.location = [tS_ length];
	[tS_ appendAttributedString:header_];
	range_.length = [tS_ length] - range_.location;
	// 現在の日付を属性として追加
	[tS_ addAttribute:CMRMessageLastUpdatedHeaderAttributeName value:[NSDate date] range:range_];

    if (flag) {
        [tS_ endEditing];
    }
}

- (void)appendLastUpdatedHeader
{
    [self appendLastUpdatedHeader:YES];
}

- (void)clearLastUpdatedHeader:(BOOL)flag
{
	NSRange headerRange_;
	NSTextStorage *tS_ = [self textStorage];

	headerRange_ = [self firstLastUpdatedHeaderAttachmentRange];
	if (NSNotFound == headerRange_.location) {
        return;
    }
	[self slideMessageRanges:-(headerRange_.length) fromLocation:NSMaxRange(headerRange_)];

    if (flag) {
        [tS_ beginEditing];
    }
	[tS_ deleteCharactersInRange:headerRange_];
    if (flag) {
        [tS_ endEditing];
    }
}

- (void)clearLastUpdatedHeader
{
    [self clearLastUpdatedHeader:YES];
}

- (void)insertLastUpdatedHeader
{
    [[self textStorage] beginEditing];
    [self clearLastUpdatedHeader:NO];
    [self appendLastUpdatedHeader:NO];
    [[self textStorage] endEditing];
}

- (void)clearReferencedCountStrings:(NSMutableAttributedString *)attrs range:(NSRange)sourceRange
{    
    [attrs enumerateAttribute:BSMessageReferencedCountAttributeName inRange:sourceRange options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            [attrs deleteCharactersInRange:range];
            [self extendMessageRange:-(range.length) forMessageIndex:[(NSNumber *)value unsignedIntegerValue]];
        }
    }];
}

- (void)insertReferencedCountStrings:(NSMutableAttributedString *)attrs range:(NSRange)range
{
    [self insertReferencedCountStrings:attrs range:range adjustRange:YES];
}

- (void)insertReferencedCountStrings:(NSMutableAttributedString *)attrs range:(NSRange)range adjustRange:(BOOL)flag
{
    NSUInteger charIndex_ = range.location;
    id indexNumber;
    NSRange insertionRange;
    
    CMRMessageAttributesTemplate *template = [CMRMessageAttributesTemplate sharedTemplate];
    NSCountedSet *set = [self reverseReferencesCountedSet];
    
    while (1) {
        if (charIndex_ >= NSMaxRange(range)) {
            break;
        }
        
        NSUInteger adjustLength = 0;
        indexNumber = [attrs attribute:CMRMessageIndexAttributeName atIndex:charIndex_ longestEffectiveRange:&insertionRange inRange:range];
        
        if (indexNumber) {
            NSUInteger referencedCount = [set countForObject:indexNumber];
            if (referencedCount > 0) {
                NSAttributedString *markerString = [template referencedMarkerStringForMessageIndex:indexNumber referencedCount:referencedCount];
                adjustLength = [markerString length];
                [attrs insertAttributedString:markerString atIndex:NSMaxRange(insertionRange)+1];
                if (flag) {
                    [self extendMessageRange:adjustLength forMessageIndex:[indexNumber unsignedIntegerValue]];
                }
            }
        }
        charIndex_ = NSMaxRange(insertionRange) + adjustLength;
        range.length += adjustLength;
    }
}

/*- (void)updateReferencedCountMarkers
{
    [[self textStorage] beginEditing];
    [self clearReferencedCountStrings:[self textStorage] range:NSMakeRange(0, [[self textStorage] length])];
    [self insertReferencedCountStrings:[self textStorage] range:NSMakeRange(0, [[self textStorage] length])];
    [[self textStorage] endEditing];
}*/

- (void)beIconImageDidUpdate:(NSNotification *)notification
{
    [[self textView] setNeedsDisplayInRect:[[self textView] visibleRect]];
}

- (void)updateReferencedCountMarkersAtIndexes:(NSIndexSet *)indexes
{
    if (!indexes) {
        return;
    }

    NSTextStorage *attrStr = [self textStorage];
    CMRMessageAttributesTemplate *template = [CMRMessageAttributesTemplate sharedTemplate];
    NSCountedSet *set = [self reverseReferencesCountedSet];
    NSUInteger firstUnlaidIdx = [self firstUnlaidMessageIndex];

    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx >= firstUnlaidIdx) {
            return;
        }

        NSRange range = [self rangeAtMessageIndex:idx];
        if (range.length == 0) {
            return;
        }
        if (range.location >= [attrStr length]) {
            return;
        }

        NSUInteger adjustLength = 0;
        NSNumber *n = [NSNumber numberWithUnsignedInteger:idx];
        NSUInteger referencedCount = [set countForObject:n];
        NSRange currentMarkerRange;
        NSAttributedString *markerString = [template referencedMarkerStringForMessageIndex:n referencedCount:referencedCount];
        adjustLength = [markerString length];
        
        NSUInteger charIndex = range.location;
        NSUInteger toIndex = NSMaxRange(range);
        
        while (1) {
            if (charIndex >= toIndex) {
                break;
            }

            id currentMarkerValue = [attrStr attribute:BSMessageReferencedCountAttributeName atIndex:charIndex longestEffectiveRange:&currentMarkerRange inRange:range];
            if (currentMarkerValue) {
                // 既存の逆参照マーカーを発見：置き換える。
                NSUInteger bar = currentMarkerRange.length;
                NSUInteger delta = adjustLength - bar;
                [attrStr replaceCharactersInRange:currentMarkerRange withAttributedString:markerString];
                if (delta > 0) {
                    [self extendMessageRange:delta forMessageIndex:idx];
                }
                return;
            }
            charIndex = NSMaxRange(currentMarkerRange);
        }
        
        // 逆参照マーカーは存在しない：挿入する。
        id indexNumber;
        NSRange insertionRange;
        // range.location ですぐにマッチするはずなので while ループしなくても平気
        indexNumber = [attrStr attribute:CMRMessageIndexAttributeName atIndex:range.location longestEffectiveRange:&insertionRange inRange:range];
        
        if (indexNumber) {
            [attrStr insertAttributedString:markerString atIndex:NSMaxRange(insertionRange)+1];
            [self extendMessageRange:adjustLength forMessageIndex:idx];
        }
    }];
}

- (void)colorizeIDImpl:(NSAttributedString *)attrs range:(NSRange)range layoutManager:(NSLayoutManager *)layoutManager
{
    NSUInteger charIndex_ = range.location;
    NSUInteger toIndex_ = NSMaxRange(range);
    id idString;
    NSRange coloringRange;
    
    while (1) {
        if (charIndex_ >= toIndex_) {
            break;
        }
        
        idString = [attrs attribute:BSMessageIDAttributeName atIndex:charIndex_ longestEffectiveRange:&coloringRange inRange:range];
        
        if (idString) {
            NSUInteger countOfId = [[self countedSet] countForObject:idString];
            if ((countOfId > 1) && (countOfId < 5)) {
                [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:[[CMRPref threadViewTheme] informativeIDColor] forCharacterRange:coloringRange];
            } else if ((countOfId > 4) && (countOfId < 10)) {
                [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:[[CMRPref threadViewTheme] warningIDColor] forCharacterRange:coloringRange];
            } else if (countOfId > 9) {
                [layoutManager addTemporaryAttribute:NSForegroundColorAttributeName value:[[CMRPref threadViewTheme] criticalIDColor] forCharacterRange:coloringRange];
            }
        }
        charIndex_ = NSMaxRange(coloringRange);
    }
}

- (void)mergeComposingResult:(BSThreadComposingOperation *)operation
{
    if ([NSThread isMainThread]) {
        if ([operation isCancelled]) {
            return;
        }
        NSUInteger delta = [[self textStorage] length];
        [[self messageRanges] bs_addRangesFromArray:[operation rangeBuffer] withSlidingLocation:delta];
        [self addMessagesFromBuffer:[operation messageBuffer]]; // 内部で lock - unlock やってるので囲まなくて良い
        
        if ([operation isCancelled]) {
            return;
        }
        if ([operation isKindOfClass:[BSThreadComposingOperation class]]) {
            [self setMessagesEdited:YES]; // 新たなメッセージがバッファに追加されたため
        }
        
        if ([operation isCancelled]) {
            return;
        }
        [self setCountedSet:operation.countedSet];
        
        if (operation.referenceMarkerEnabled) {
            if ([operation isCancelled]) {
                return;
            }
            [self setReverseReferencesCountedSet:operation.reverseReferencesCountedSet];
            if ([operation isCancelled]) {
                return;
            }
            [self insertReferencedCountStrings:[operation attrStrBuffer] range:NSMakeRange(0, [[operation attrStrBuffer] length])];
        }
    } else {
        [self performSelectorOnMainThread:_cmd withObject:operation waitUntilDone:YES];
    }
}

- (void)appendComposingAttrString:(BSThreadComposingOperation *)operation
{
    if ([NSThread isMainThread]) {
        if ([operation isCancelled]) {
            return;
        }
        [[self textStorage] beginEditing];
        if (operation.prevRefMarkerUpdateNeeded) {
            [self updateReferencedCountMarkersAtIndexes:operation.messageIndexesForRefMarkerUpdateNeeded];
        }
        [[self textStorage] appendAttributedString:[operation attrStrBuffer]];
        [[self textStorage] endEditing];
    } else {
        [self performSelectorOnMainThread:_cmd withObject:operation waitUntilDone:YES];
    }
}
@end
