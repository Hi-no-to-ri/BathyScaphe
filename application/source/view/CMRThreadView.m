//
//  CMRThreadView.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/09/07.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadView_p.h"
#import "CMXMenuHolder.h"
#import "TextFinder.h"
#import "AppDefaults.h"
#import <Carbon/Carbon.h>
#import "SGContextHelpPanel.h"

static NSString *const kDefaultMenuNibName = @"CMRThreadMenu";
static NSString *const kMessageMenuNibName = @"CMXMessageMenu";

static NSString *const kPoofNotificationName = @"CMRThreadViewDidInvisibleAboneNotification";
static NSString *const kPoofLocationKey = @"Location";

static NSString *mActionGetKeysForTag[] = {
	@"isLocalAboned",		// kLocalAboneTag
	@"isInvisibleAboned",	// kInvisibleAboneTag
	@"isAsciiArt",			// kAsciiArtTag
	@"hasBookmark",			// kBookmarkTag
	@"isSpam",				// kSpamTag
};


@implementation CMRThreadView
- (id)initWithFrame:(NSRect)aFrame textContainer:(NSTextContainer *)aTextContainer
{
	if (self = [super initWithFrame:aFrame textContainer:aTextContainer]) {
		m_lastCharIndex = NSNotFound;

		[self registerForDraggedTypes:[NSArray arrayWithObject:BSPasteboardTypeThreadSignature]];
		draggingHilited = NO;
		draggingTimer = 0.0;

        magnifyingNow = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showPoofAnimationWhenIdle:)
                                                     name:kPoofNotificationName
                                                   object:self];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kPoofNotificationName object:self];
	NSUndoManager *undoManager = [[self window] undoManager];
	[undoManager removeAllActions];
	[super dealloc];
}

- (void)beginGestureWithEvent:(NSEvent *)event
{
    if (![CMRPref multitouchGestureEnabled]) {
        [super beginGestureWithEvent:event];
        return;
    }

    magnifyingNow = YES;
    rotatingNow = YES;
    rotateEnoughFlag = NO;
    magnifyEnoughFlag = NO;
    rotateSum = 0;
    magnifySum = 0;
}

- (void)endGestureWithEvent:(NSEvent *) event
{
    if (![CMRPref multitouchGestureEnabled]) {
        [super endGestureWithEvent:event];
        return;
    }

    if (magnifyingNow) {
        magnifyingNow = NO;
        magnifySum = 0;
    }

    if (rotatingNow && rotateEnoughFlag) {
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(view:didFinishRotating:)]) {
            [delegate view:self didFinishRotating:rotateSum];
        }
        rotatingNow = NO;
    }
}

- (void)magnifyWithEvent:(NSEvent *)event
{
    if (![CMRPref multitouchGestureEnabled]) {
        [super magnifyWithEvent:event];
        return;
    }

    if (!magnifyingNow) {
        return;
    }

    magnifySum += [event magnification];
    if (!magnifyEnoughFlag && (fabsf(magnifySum) > 0.5)) {
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(threadView:magnifyEnough:)]) {
            [delegate threadView:self magnifyEnough:magnifySum];
        }
        magnifyEnoughFlag = YES;
    }
}

- (void)rotateWithEvent:(NSEvent *)event
{
    if (![CMRPref multitouchGestureEnabled]) {
        [super rotateWithEvent:event];
        return;
    }

    if (!rotatingNow) {
        return;
    }
    
    rotateSum += [event rotation];
    if (fabsf(rotateSum) > 15 && !rotateEnoughFlag) {
        id delegate = [self delegate];
        if (delegate && [delegate respondsToSelector:@selector(view:rotateEnough:)]) {
            [delegate view:self rotateEnough:rotateSum];
        }
        rotateEnoughFlag = YES;
    }
}

- (void)swipeWithEvent:(NSEvent *)event
{
    if (![CMRPref multitouchGestureEnabled]) {
        [super swipeWithEvent:event];
        return;
    }
    
    id delegate = [self delegate];
    if (delegate && [delegate respondsToSelector:@selector(threadView:swipeWithEvent:)]) {
        [delegate threadView:self swipeWithEvent:event];
    }
}

- (BOOL)acceptsFirstResponder
{
    id delegate = [self delegate];
    if (delegate && [delegate respondsToSelector:@selector(acceptsFirstResponderForView:)]) {
        return [delegate acceptsFirstResponderForView:self];
    }
    return [super acceptsFirstResponder];
}

#pragma mark Drawing
// ライブリサイズ中のレイアウト再計算を抑制する
//- (void)viewWillStartLiveResize
//{
//	[(BSLayoutManager *)[self layoutManager] setTextContainerInLiveResize:YES];
//	[super viewWillStartLiveResize];
//}

//- (void)viewDidEndLiveResize
//{
//	[(BSLayoutManager *)[self layoutManager] setTextContainerInLiveResize:NO];
//	[[self layoutManager] textContainerChangedGeometry:[self textContainer]];
//	[super viewDidEndLiveResize];
//}

- (void)updateRuler
{
	// Ruler の更新をブロックする。
}

+ (BOOL)isCompatibleWithResponsiveScrolling
{
    return NO;
}

- (BOOL)isOpaque
{
    return ![[self window] isPopUpWindow];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];

	if (draggingHilited) {
        [[NSColor selectedTextBackgroundColor] set];
        NSFrameRectWithWidth([self visibleRect], 3.0);
	}
}

- (NSRect)boundingRectForMessageAtIndex:(NSUInteger)index
{
	NSRange charRange = [[self threadLayout] rangeAtMessageIndex:index];
	return [self boundingRectForCharacterInRange:charRange];
}

#pragma mark Accessors
- (CMRThreadSignature *)threadSignature
{
	id delegate_ = [self delegate];
	if (!delegate_ || ![delegate_ respondsToSelector:@selector(threadSignatureForView:)]) return nil;
	
	return [delegate_ threadSignatureForView:self];
}

- (CMRThreadLayout *)threadLayout
{
	id		delegate_ = [self delegate];
	if (!delegate_ || ![delegate_ respondsToSelector:@selector(threadLayoutForView:)]) return nil;

	return [delegate_ threadLayoutForView:self];
}

- (NSUInteger)previousMessageIndexOfCharIndex:(NSUInteger)charIndex
{
	NSTextStorage	*storage_ = [self textStorage];
	NSRange			range_;
	NSRange			effectiveRange_;
	NSUInteger		index_;
	id				v;
	
	if (NSNotFound == charIndex || charIndex >= [storage_ length])
		return NSNotFound;
	
	index_ = charIndex;
	while (1) {
		range_ = NSMakeRange(0, index_ +1);
		v = [storage_ attribute:CMRMessageIndexAttributeName
						atIndex:index_
		  longestEffectiveRange:&effectiveRange_
						inRange:range_];
		if (v) {
			return [v unsignedIntegerValue];
		}
		if (0 == effectiveRange_.location)
			break;
		
		index_ = effectiveRange_.location -1;
	}
	return NSNotFound;
}

- (NSIndexSet *)messageIndexesForRange:(NSRange)range_
{
	NSTextStorage	*storage_ = [self textStorage];	

	if (NSNotFound == range_.location) {
        return nil;
    }
    
    NSUInteger maxRange = NSMaxRange(range_);
    NSUInteger storageLength = [storage_ length];
    
    if (maxRange > storageLength) {
        if ((range_.length == 1) && (maxRange > 1) && (maxRange - 1 == storageLength)) {
            range_.location -= 1;
        } else {
            return nil;
        }
	}

	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	NSUInteger		charIndex_;
	id				v;
	NSRange			effectiveRange_;

	charIndex_ = range_.location;
	while (charIndex_ < NSMaxRange(range_)) {
		v = [storage_ attribute:CMRMessageIndexAttributeName
						atIndex:charIndex_
		  longestEffectiveRange:&effectiveRange_
						inRange:range_];
		if (v) {
			[indexSet addIndex:[v unsignedIntegerValue]];
		}
		charIndex_ = NSMaxRange(effectiveRange_);
	}

	NSUInteger prevMsgIdx = [self previousMessageIndexOfCharIndex:range_.location];
	if (prevMsgIdx != NSNotFound) {
		[indexSet addIndex:prevMsgIdx];
	}

	if ([indexSet count] == 0) {
		return nil;
	} else {
		return indexSet;
	}
}

- (NSIndexSet *)messageIndexesAtClickedPoint
{
	NSRange range_ = NSMakeRange(m_lastCharIndex, 1);
	return [self messageIndexesForRange:range_];
}

/*
 * Available in Twincam Angel.
 * 選択範囲にかかるレスの indexes (これは見かけのレス番号より1小さい値である) を NSIndexSet で返す。
 * 選択範囲がないときは、コンテクストメニューの表示位置にあるレスの index を。
 * このとき、非表示状態のレス index は含まれない。
 */
- (NSIndexSet *)selectedMessageIndexes
{
	NSRange			range_ = [self selectedRange];
	if (range_.length == 0) {
		range_.location = m_lastCharIndex;
		range_.length = 1;
	}
	return [self messageIndexesForRange:range_];
}

- (id<CMRThreadViewDelegate>)delegate
{
    return (id<CMRThreadViewDelegate>)[super delegate];
}

- (void)setDelegate:(id<CMRThreadViewDelegate>)aDelegate
{
    [super setDelegate:aDelegate];
}

#pragma mark Contextual Menu
- (BOOL)mouseClicked:(NSEvent *)theEvent atIndex:(NSUInteger)charIndex
{
	NSRange	effectiveRange_;
	id		v;
	id		delegate_ = [self delegate];
	SEL		selector_ = @selector(threadView:mouseClicked:atIndex:messageIndex:);
	
	if ([super mouseClicked:theEvent atIndex:charIndex]) return YES;
    
    if ([CMRPref popupTriggerType] == BSPopupByMouseClick) {
        v = [[self textStorage] attribute:BSMessageIDAttributeName atIndex:charIndex effectiveRange:&effectiveRange_];
        if (v) {
            BOOL isOnIDField;
            id v2 = [[self textStorage] attribute:BSMessageKeyAttributeName atIndex:charIndex effectiveRange:NULL];
            isOnIDField = (v2 && [v2 isEqualToString:BSMessageKeyAttributeIDField]) ? YES : NO;
            return [[self delegate] threadView:self mouseClicked:theEvent atIndex:charIndex userData:@{SGHTMLViewLinkUserDataAttributeNameKey: BSMessageIDAttributeName, SGHTMLViewLinkUserDataLinkValueKey: v, SGHTMLViewLinkUserDataFieldHintKey: [NSNumber numberWithBool:isOnIDField]}];
        }
        v = [[self textStorage] attribute:BSMessageReferencedCountAttributeName atIndex:charIndex effectiveRange:&effectiveRange_];
        if (v) {
            return [[self delegate] threadView:self mouseClicked:theEvent atIndex:charIndex userData:@{SGHTMLViewLinkUserDataAttributeNameKey: BSMessageReferencedCountAttributeName, SGHTMLViewLinkUserDataLinkValueKey: v}];
        }
    }
	
	v = [[self textStorage] attribute:CMRMessageIndexAttributeName atIndex:charIndex effectiveRange:&effectiveRange_];
	if (!v) return NO;
	UTILAssertRespondsTo(v, @selector(unsignedIntegerValue));
	
	if (delegate_ && [delegate_ respondsToSelector:selector_]) {
		return [delegate_ threadView:self mouseClicked:theEvent atIndex:charIndex messageIndex:[v unsignedIntegerValue]];
	}
	return NO;
}

static inline void setupMenuItemsRepresentedObject(NSMenu *aMenu, id anObject) 
{
//    NSEnumerator		*iter_;
//    NSMenuItem			*item_;
//    
//    iter_ = [[aMenu itemArray] objectEnumerator];
//    while (item_ = [iter_ nextObject]) {
    for (NSMenuItem *item_ in [aMenu itemArray]) {
		[item_ setRepresentedObject:anObject];
		[item_ setEnabled:YES];
		
		if ([item_ hasSubmenu]) {
			setupMenuItemsRepresentedObject([item_ submenu], anObject);
		}
	}
}

+ (NSMenu *)messageMenu
{
	static NSMenu *kMessageMenu = nil;
	
	if (!kMessageMenu) {
		kMessageMenu = [[CMXMenuHolder menuFromBundle:[NSBundle mainBundle] nibName:kMessageMenuNibName] copy];
	}
	return kMessageMenu;
}

+ (void)setMenuItemTitleFromKeyValueTemplate:(NSString *)key itemAction:(SEL)selector atMenu:(NSMenu *)menu
{
    NSString *title = SGTemplateResource(key);
    if (!key) {
        return;
    }
    NSInteger itemIndex = [menu indexOfItemWithTarget:nil andAction:selector];
    if (itemIndex != -1) {
        NSMenuItem *item = [menu itemAtIndex:itemIndex];
        [item setTitle:title];
    }
}

+ (void)removeSpotlightMenuItemIfNeeded:(NSMenu *)menu
{
    BOOL shown = SGTemplateBool(@"Thread - SpotlightMenuItemTitleShown");
    if (!shown) {
        NSInteger itemIndex = [menu indexOfItemWithTarget:nil andAction:@selector(bs_searchInSpotlight:)];
        if (itemIndex != -1) {
            [menu removeItemAtIndex:itemIndex];
        }
    }
}

+ (NSMenu *)defaultMenu
{
	static NSMenu *kDefaultMenu_ = nil;

	if (!kDefaultMenu_) {
		kDefaultMenu_ = [[CMXMenuHolder menuFromBundle:[NSBundle mainBundle] nibName:kDefaultMenuNibName] copy];
        
        // 検索系メニューアイテムのタイトルを KeyValueTemplates.plist でカスタマイズできるように
        [self setMenuItemTitleFromKeyValueTemplate:@"Thread - GoogleMenuItemTitle" itemAction:@selector(googleSearch:) atMenu:kDefaultMenu_];
        [self setMenuItemTitleFromKeyValueTemplate:@"Thread - WikipediaMenuItemTitle" itemAction:@selector(openWithWikipedia:) atMenu:kDefaultMenu_];
        
        // サービスメニューのコンテキストメニュー項目と重複するのが嫌な人のために
        [self removeSpotlightMenuItemIfNeeded:kDefaultMenu_];
	}
	return kDefaultMenu_;
}

+ (NSMenuItem *)genericCopyItem
{
	static NSMenuItem *cachedItem = nil;
	if (!cachedItem) {
		NSString *title = NSLocalizedStringFromTable(@"Copy Contextual Menu Item", @"HTMLView", nil);
		cachedItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(copy:) keyEquivalent:@""];
	}
	return cachedItem;
}

+ (NSMenu *)multipleLineSelectionWithinSingleMessageMenu
{
	static NSMenu *kCopyOnlyMenu = nil;
	if (!kCopyOnlyMenu) {
		kCopyOnlyMenu = [[NSMenu alloc] initWithTitle:@""];
		[kCopyOnlyMenu insertItem:[self genericCopyItem] atIndex:0];
	}
	return kCopyOnlyMenu;
}

- (BOOL)containsMultipleLinesInRange:(NSRange)range
{
    if (range.length < 1) { // ありえないと思うけど…
        return NO;
    }
    NSRange checkRange = [[self string] lineRangeForRange:NSMakeRange(range.location, 1)];
    if (NSMaxRange(checkRange) == NSMaxRange(range)) { // 高々一行（末尾は改行文字を含むかもしれない）
        return NO;
    } else if (NSEqualRanges(NSIntersectionRange(checkRange, range), range)) { // 行内に完全に包含される→単一行内
        return NO;
    }
    return YES; // 複数行
}

- (NSMenuItem *)copyLinksMenuItemForRange:(NSRange)range
{
    NSArray *array = [self linksArrayForRange:range];
    if (!array) {
        return nil;
    } else {
        // #warning 64BIT: Check formatting arguments
        // 2010-05-13 tsawada2 修正済
        NSString *foo = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Copy %lu Links", kLocalizableFile, @""), (unsigned long)[array count]];
        NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:foo action:@selector(copyLinksInSelection:) keyEquivalent:@""];
        return [newItem autorelease];
    }
}

- (NSMenuItem *)openLinksMenuItemForRange:(NSRange)range
{
	NSArray *array = [self linksArrayForRange:range];
	if (!array) {
		return nil;
	} else {
// #warning 64BIT: Check formatting arguments
// 2010-05-13 tsawada2 修正済
		NSString *foo = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Open %lu Links", kLocalizableFile, @""), (unsigned long)[array count]];
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:foo action:@selector(openLinksInSelection:) keyEquivalent:@""];
		return [newItem autorelease];
	}
}

- (NSMenuItem *)previewLinksMenuItemForRange:(NSRange)range
{
    id previewer = [CMRPref sharedLinkPreviewer];

    UTILAssertNotNil(previewer);
    if (![previewer respondsToSelector:@selector(previewLinks:)]) {
        return nil;
    }

	NSArray *array = [self previewlinksArrayForRange:range];
	if (!array) {
		return nil;
	} else {
// #warning 64BIT: Check formatting arguments
// 2010-05-13 tsawada2 修正済
		NSString *foo = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Preview %lu Links", kLocalizableFile, @""), (unsigned long)[array count]];
		NSMenuItem *newItem = [[NSMenuItem alloc] initWithTitle:foo action:@selector(previewLinksInSelection:) keyEquivalent:@""];
		return [newItem autorelease];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSPoint		mouseLocation_;
	NSRange		selectedTextRange = [self selectedRange];
	
	m_lastCharIndex = NSNotFound;

    mouseLocation_ = [theEvent locationInWindow];
    mouseLocation_ = [[self window] convertRectToScreen:NSMakeRect(mouseLocation_.x, mouseLocation_.y, 0, 0)].origin;
    m_lastCharIndex = [self characterIndexForPoint:mouseLocation_];

	// マウスポインタが選択されたテキストの、その選択領域に入っているなら、選択テキスト用の（簡潔な）コンテキストメニューを返す。
	if (NSLocationInRange(m_lastCharIndex, selectedTextRange)) {
        NSRange effectiveRange_;
        id link_ = [[self textStorage] attribute:NSLinkAttributeName atIndex:m_lastCharIndex effectiveRange:&effectiveRange_];
        if (NSEqualRanges(selectedTextRange, effectiveRange_) && [self validateLinkByFiltering:link_]) {
            return [super linkMenuWithLink:link_];
        }

		NSIndexSet	*selectedIndexes = [self selectedMessageIndexes];
		NSMenu		*returningMenu;
		NSMenuItem	*openLinksItem;
		NSMenuItem	*foo;
		UTILAssertNotNil(selectedIndexes);

		if ([selectedIndexes count] == 1) {
			if ([self containsMultipleLinesInRange:selectedTextRange]) {
				returningMenu = [[self class] multipleLineSelectionWithinSingleMessageMenu];
			} else {
				returningMenu = [[self class] defaultMenu];
			}
			if ((openLinksItem = [self openLinksMenuItemForRange:selectedTextRange])) {
				returningMenu = [[returningMenu copy] autorelease];
				[returningMenu addItem:[NSMenuItem separatorItem]];
                [returningMenu addItem:[self copyLinksMenuItemForRange:selectedTextRange]]; // openLinksItem が存在するなら、こちらも必ずある
				[returningMenu addItem:openLinksItem];
				if ((foo = [self previewLinksMenuItemForRange:selectedTextRange])) {
					[returningMenu addItem:foo];
				}
			}
			return returningMenu;
		} else {
			NSMenu *menu = [[self messageMenuWithMessageIndexes:selectedIndexes] copy];
			NSMenuItem *item = [[[self class] genericCopyItem] copy];
			[menu removeItemAtIndex:1];
			[menu removeItemAtIndex:0];
			[menu insertItem:item atIndex:0];
			[item release];
			if ((openLinksItem = [self openLinksMenuItemForRange:selectedTextRange])) {
				[menu addItem:[NSMenuItem separatorItem]];
                [menu addItem:[self copyLinksMenuItemForRange:selectedTextRange]];
				[menu addItem:openLinksItem];
				if ((foo = [self previewLinksMenuItemForRange:selectedTextRange])) {
					[menu addItem:foo];
				}
			}
			return [menu autorelease];
		}
	}

	// そうでなければ、スーパークラスで判断してもらう（see SGHTMLView.m)。
	return [super menuForEvent:theEvent];
}

- (NSMenu *)messageMenuWithMessageIndex:(NSUInteger)aMessageIndex
{
	return [self messageMenuWithMessageIndexes:[NSIndexSet indexSetWithIndex:aMessageIndex]];
}

- (NSMenu *)messageMenuWithMessageIndexes:(NSIndexSet *)indexes
{	
	NSMenu				*menu_ = [[self class] messageMenu];
    //	NSMenuItem			*item_;
	NSUInteger	size = [indexes lastIndex]+1;
    //	NSEnumerator	*iter_;
	
	if (size > [[self threadLayout] numberOfReadedMessages]) return nil;
	
	// RepresentedObjectの設定
	setupMenuItemsRepresentedObject(menu_, indexes);
	
	// 状態の設定
    //	iter_ = [[menu_ itemArray] objectEnumerator];
    //	while (item_ = [iter_ nextObject]) {
    for (NSMenuItem *item_ in [menu_ itemArray]) {
		NSInteger				tag   = [item_ tag];
		
		if (tag < 0) continue;
		
// #warning 64BIT: Check formatting arguments
// 2010-05-13 tsawada2 修正済
		NSAssert1(
			UTILNumberOfCArray(mActionGetKeysForTag) > tag,
			@"[item tag] was invalid(%ld)", (long)tag);
		
		[self setUpMessageActionMenuItem:item_
							  forIndexes:indexes
					   withAttributeName:mActionGetKeysForTag[tag]];
	}
	
	return menu_;
}

#pragma mark Message Menu Action
- (NSIndexSet *)representedIndexesWithSender:(id)sender
{
	id	v = [sender representedObject];

	if (!v) {	// 選択されたレス、このあと内容が変更されるかもしれない
		v = [self selectedMessageIndexes];
	} else {	// 通常はこっち (representedObject はしっかりセットしておくべし)
		UTILAssertKindOfClass(v, NSIndexSet);
	}
	return v;
}

// スパムフィルタへの登録
- (void)messageRegister:(CMRThreadMessage *)aMessage registerFlag:(BOOL)flag
{
	id		delegate_ = [self delegate];
	if (!delegate_ || ![delegate_ respondsToSelector:@selector(threadView:spam:messageRegister:)]) return;
	
	[delegate_ threadView:self spam:aMessage messageRegister:flag];
}

/* 属性の変更 */
- (void)toggleMessageAttribute:(NSInteger)senderTag atIndexes:(NSIndexSet *)indexes
{
    CMRThreadLayout *layout = [self threadLayout];
    NSArray *messages;
    NSUndoManager *undoMgr = [[self window] undoManager];
    if (!layout) {
        return;
    }
    if (!indexes || [indexes count] > [layout numberOfReadedMessages]) {
        return;
    }

    messages = [layout messagesAtIndexes:indexes];
    if (!messages) {
        return;
    }

    for (CMRThreadMessage *message in messages) {
        [message setPostsAttributeChangedNotifications:NO];
        switch (senderTag) {
        case kLocalAboneTag:
            [message setLocalAboned:![message isLocalAboned] undoManager:undoMgr];
            break;
        case kInvisibleAboneTag:
            [message setInvisibleAboned:![message isInvisibleAboned] undoManager:undoMgr];
            break;
        case kAsciiArtTag:
            [message setAsciiArt:![message isAsciiArt] undoManager:undoMgr];
            break;
        case kBookmarkTag:
            [message setHasBookmark:![message hasBookmark] undoManager:undoMgr];
            break;
        case kSpamTag:
        {
            BOOL isSpam_ = (![message isSpam]);
            // 迷惑レスを手動で設定した場合は
            // フィルタに登録する
            [self messageRegister:message registerFlag:isSpam_];
            [message setSpam:isSpam_ undoManager:undoMgr];
            break;
        }
        default :
            UTILUnknownSwitchCase(senderTag);
            break;
        }
    }

    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [layout updateMessageAtIndex:idx];
    }];
    // 元に戻しておかないと undo 時などに困る
    [messages makeObjectsPerformSelector:@selector(setPostsAttributeChangedNotifications:) withObject:[NSNumber numberWithBool:YES]];
}

//- (CMRThreadMessage *)toggleMessageAttributesAtIndex:(NSUInteger)anIndex senderTag:(NSInteger)aSenderTag
//{
//	CMRThreadLayout		*layout = [self threadLayout];
//	CMRThreadMessage	*m;
//	NSUndoManager		*um = [[self window] undoManager];
//	if (!layout || anIndex >= [layout numberOfReadedMessages]) return nil;
//	
//	m = [layout messageAtIndex:anIndex];
//	
//	switch (aSenderTag) {
//	case kLocalAboneTag:
//		[m setLocalAboned:![m isLocalAboned] undoManager:um];
//		break;
//	case kInvisibleAboneTag:
//		[m setInvisibleAboned:![m isInvisibleAboned] undoManager:um];
//		break;
//	case kAsciiArtTag:
//		[m setAsciiArt:![m isAsciiArt] undoManager:um];
//		break;
//	case kBookmarkTag:
//		/* 現バージョンでは複数のブックマークは利用しない */
//		[m setHasBookmark:![m hasBookmark] undoManager:um];
//		break;
//	case kSpamTag:{
//		BOOL	isSpam_ = (NO == [m isSpam]);
//		// 迷惑レスを手動で設定した場合は
//		// フィルタに登録する
//		[self messageRegister:m registerFlag:isSpam_];
//		[m setSpam:isSpam_ undoManager:um];
//		break;
//	}
//	default :
//		UTILUnknownSwitchCase(aSenderTag);
//		break;
//	}
//	return m;
//}
@end


@implementation CMRThreadView(Action)
- (void)openUpToFiveLinksInSelection:(NSArray *)array
{
    [[NSWorkspace sharedWorkspace] openURLs:array inBackground:[CMRPref openInBg]];
}

- (void)previewUpToFiveLinksInSelection:(NSArray *)array
{
    id<BSLinkPreviewing> previewer = [CMRPref sharedLinkPreviewer];
    if (previewer && [(id)previewer respondsToSelector:@selector(previewLinks:)]) {
        [(id)previewer previewLinks:array];
    }
}

- (void)perFiveLinks:(NSArray *)baseArray operation:(SEL)operation
{
/*    if ([baseArray count] > 100) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert setMessageText:@"You seem to open over 100 links at once. Are you sure you want to continue?"];
        [alert setInformativeText:@"This operation may cause freeze or high CPU usage."];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Continue"];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            return;
        }
    }*/
    int times = [baseArray count] / 3;
    for (int i = 0; i < times; i++) {
        [self performSelector:operation withObject:[baseArray subarrayWithRange:NSMakeRange(i * 3, 3)] afterDelay:(i * 1.5)];
    }
    if ([baseArray count] % 3 != 0) {
        [self performSelector:operation withObject:[baseArray subarrayWithRange:NSMakeRange(times * 3, ([baseArray count] % 3))] afterDelay:(times * 1.5)];
    }
}
                 
- (IBAction)copyLinksInSelection:(id)sender
{
    NSArray *URLs = [self linksArrayForRange:[self selectedRange]];
    NSArray *URLStrings = [URLs valueForKey:@"absoluteString"];
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard clearContents];
    [pboard writeObjects:URLStrings];
}

- (IBAction)openLinksInSelection:(id)sender
{
	NSArray *URLs = [self linksArrayForRange:[self selectedRange]];
    [self perFiveLinks:URLs operation:@selector(openUpToFiveLinksInSelection:)];
}

- (IBAction)previewLinksInSelection:(id)sender
{
	NSArray *URLs = [self previewlinksArrayForRange:[self selectedRange]];
    [self perFiveLinks:URLs operation:@selector(previewUpToFiveLinksInSelection:)];
}

/* レスのコピー */
- (IBAction)messageCopy:(id)sender
{
/*	NSPasteboard		*pboard_ = [NSPasteboard generalPasteboard];
	NSArray				*types;
	CMRThreadLayout		*layout = [self threadLayout];
	NSAttributedString	*contents;
	NSIndexSet			*indexes;
	id					rep;
	
	if (!layout) return;

	rep = [sender representedObject];
	if (rep && [rep isKindOfClass:[NSIndexSet class]]) {
		indexes = rep;
	} else {
		indexes = [self selectedMessageIndexes];
	}

	contents = [layout contentsForIndexes:indexes composingMask:CMRInvisibleAbonedMask compose:NO attributesMask:(CMRLocalAbonedMask|CMRSpamMask)];
	if (!contents) return; 
	
	types = [NSArray arrayWithObjects:NSRTFPboardType, NSStringPboardType, nil];	
	[pboard_ declareTypes:types owner:nil];

	[contents writeToPasteboard:pboard_];*/
}

/* レスに返信 */
- (IBAction)messageReply:(id)sender
{
	id				delegate_ = [self delegate];
	if (!delegate_ || ![delegate_ respondsToSelector:@selector(threadView:replyTo:)]) {
        return;
    }
	
	NSIndexSet *mIndexes = [self representedIndexesWithSender:sender];
	if (!mIndexes) {
        return;
    }
	[delegate_ threadView:self replyTo:mIndexes];
}

- (NSPoint)pointForIndex:(NSUInteger)messageIndex
{
	NSRange	range = [[self threadLayout] rangeAtMessageIndex:messageIndex];
	NSRect	rect = [self boundingRectForCharacterInRange:range];
	NSPoint	point = NSMakePoint(NSMidX(rect), NSMidY(rect));
	point = [self convertPoint:point toView:nil];
    point = [[self window] convertRectToScreen:NSMakeRect(point.x, point.y, 0, 0)].origin;
	return point;
}

static BOOL shouldPoof(NSInteger state, NSInteger actionType)
{
	if (state == NSOnState) return NO;
	if (![CMRPref showsPoofAnimationOnInvisibleAbone]) return NO;

	if (actionType == kInvisibleAboneTag) return YES;
	if (actionType == kSpamTag && [CMRPref spamFilterBehavior] == kSpamFilterInvisibleAbonedBehavior) return YES;

	return NO;
}

- (IBAction)changeMessageAttributes:(id)sender
{
//	NSEnumerator	*mIndexEnum_;
//	NSNumber		*mIndex;
	NSUInteger  firstIndex;
	NSInteger   actionType = [sender tag];
	NSIndexSet  *mIndexes = [self representedIndexesWithSender:sender];

	if (!mIndexes) {
        return;
    }
	firstIndex = [mIndexes firstIndex];
//	mIndexEnum_ = indexEnumeratorWithIndexes(mIndexes);
//
//	while (mIndex = [mIndexEnum_ nextObject]) {
//		[self toggleMessageAttributesAtIndex:[mIndex unsignedIntegerValue] senderTag:actionType];
//	}
    [self toggleMessageAttribute:actionType atIndexes:mIndexes];

    if (shouldPoof([sender state], actionType)) {
        NSDictionary *info = [NSDictionary dictionaryWithObject:[NSValue valueWithPoint:[self pointForIndex:firstIndex]] forKey:kPoofLocationKey];
        NSNotification *notification = [NSNotification notificationWithName:kPoofNotificationName object:self userInfo:info];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification postingStyle:NSPostWhenIdle];
    }
}

- (void)showPoofAnimationWhenIdle:(NSNotification *)notification
{
    NSValue *value = [[notification userInfo] objectForKey:kPoofLocationKey];
    NSPoint point = [value pointValue];
    NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, point, NSMakeSize(128,128), nil, NULL, nil);
}

- (IBAction)messageGyakuSansyouPopUp:(id)sender
{
	id				delegate_ = [self delegate];
	if (!delegate_ || ![delegate_ respondsToSelector:@selector(threadView:reverseAnchorPopUp:locationHint:)]) return;

	NSIndexSet		*mIndexes;
	mIndexes = [self representedIndexesWithSender:sender];
	if (!mIndexes) return;

	NSUInteger mIndexNum = [mIndexes firstIndex];
	NSRect  rect_ = [self boundingRectForMessageAtIndex:mIndexNum];
	NSPoint	point_ = NSMakePoint(NSMinX(rect_), NSMinY(rect_));

	point_ = [self convertPoint:point_ toView:nil];
    point_ = [[self window] convertRectToScreen:NSMakeRect(point_.x, point_.y, 0, 0)].origin;
	
	[delegate_ threadView:self reverseAnchorPopUp:mIndexNum locationHint:point_];
}

#pragma mark Google, Wikipedia
- (NSString *)selectedSubstringWithURLEncoded
{
	NSString *string;
	NSString *encodedString;

	string = [[self string] substringWithRange:[self selectedRange]];
	encodedString = [string stringByURLEncodingUsingEncoding:NSUTF8StringEncoding];

	if (!encodedString || [encodedString isEqualToString:@""]) return nil;
	return encodedString;
}

- (void)openURLWithQueryTemplateForKey:(NSString *)key
{
	NSString *string;
	id	query;
	NSMutableString *urlBase;

	string = [self selectedSubstringWithURLEncoded];
	if (!string) return;

	query = SGTemplateResource(key);
	UTILAssertNotNil(query);

	urlBase = [NSMutableString stringWithString:query];
	[urlBase replaceCharacters:kQueryValiableKey toString:string];

	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlBase]];
}

- (IBAction)openWithWikipedia:(id)sender
{
	[self openURLWithQueryTemplateForKey:kPropertyListWikipediaQueryKey];
}

- (IBAction)googleSearch:(id)sender
{
    NSString *string = [[self string] substringWithRange:[self selectedRange]];
    if (![string isEmpty]) {
        NSPasteboard *pasteboard = [NSPasteboard pasteboardWithName:NSFindPboard];
        [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        [pasteboard setString:string forType:NSStringPboardType];
    }
	[self openURLWithQueryTemplateForKey:kPropertyListGoogleQueryKey];
}

- (IBAction)bs_lookupInDictionary:(id)sender
{
	NSRange		selectedTextRange;
	
	selectedTextRange = [self selectedRange];
	UTILRequireCondition(selectedTextRange.length != 0, ErrNoSelection);

    [self bs_lookupInDictionaryWithRange:selectedTextRange];
    
ErrNoSelection:
	return;
}

- (IBAction)bs_searchInSpotlight:(id)sender
{
	NSRange		selectedTextRange;
	
	selectedTextRange = [self selectedRange];
	UTILRequireCondition(selectedTextRange.length != 0, ErrNoSelection);

    NSString *query = [[self string] substringWithRange:selectedTextRange];
//    HISearchWindowShow((CFStringRef)query, kNilOptions); 
    [[NSWorkspace sharedWorkspace] showSearchResultsForQueryString:query];
ErrNoSelection:
	return;
}

- (IBAction)findTextInSelection:(id)sender
{
	NSRange		selectedTextRange;
	NSString	*selection;
	TextFinder	*finder_ = [TextFinder standardTextFinder];
	
	selectedTextRange = [self selectedRange];
	UTILRequireCondition(selectedTextRange.length != 0, ErrNoSelection);

	selection = [[self string] substringWithRange:selectedTextRange];

	[finder_ showWindow:sender];
	[finder_ setFindString:selection];

ErrNoSelection:
	return;
}

#pragma mark Menu Validation
- (BOOL)setUpMessageActionMenuItem:(NSMenuItem *)theItem forIndexes:(NSIndexSet *)indexSet withAttributeName:(NSString *)aName
{
//	NSEnumerator		*anIndexEnum = indexEnumeratorWithIndexes(indexSet);
//	CMRThreadLayout		*L = [self threadLayout];
//	CMRThreadMessage	*m;
//	id					v     = nil;
//	id					prev  = nil;
//	NSInteger					state = NSOffState;
//	NSNumber			*mIndex;
//
//	while (mIndex = [anIndexEnum nextObject]) {
//		m = [L messageAtIndex:[mIndex unsignedIntegerValue]];
//		v = [m valueForKey:aName];
//		UTILAssertRespondsTo(v, @selector(boolValue));
//		
//		if (prev && ([prev boolValue] != [v boolValue])) {
//			state = NSMixedState;
//			break;
//		}
//
//		state = [v boolValue] ? NSOnState : NSOffState;
//		prev = v;
//	}
//	if (!prev) return NO;
//
//	[theItem setState:state];
//	return YES;
    CMRThreadLayout *layout = [self threadLayout];
    NSArray *boolObjects;
    NSInteger state = NSOffState;
    id prevObject = nil;

    boolObjects = [[layout messagesAtIndexes:indexSet] valueForKey:aName];
    if (!boolObjects || [boolObjects count] == 0) {
        return NO;
    }
    for (id boolObject in boolObjects) {
        UTILAssertRespondsTo(boolObject, @selector(boolValue));
        BOOL attr = [boolObject boolValue];
        if (prevObject && ([prevObject boolValue] != attr)) {
            state = NSMixedState;
            break;
        }
        state = attr ? NSOnState : NSOffState;
        prevObject = boolObject;
    }
    [theItem setState:state];
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)theItem
{
	SEL				action_ = [theItem action];
	
	if (action_ == @selector(googleSearch:) || action_ == @selector(openWithWikipedia:) || action_ == @selector(findTextInSelection:)) {
		return ([self selectedRange].length > 0);
	}

	NSIndexSet		*indexSet = [self messageIndexesAtClickedPoint];
	[theItem setRepresentedObject:indexSet];

	if (action_ == @selector(messageReply:) || action_ == @selector(messageGyakuSansyouPopUp:) || action_ == @selector(messageCopy:)) {
		return (indexSet != nil);
	}

	if (action_ == @selector(changeMessageAttributes:)) {
		NSInteger		tag   = [theItem tag];
// #warning 64BIT: Check formatting arguments
// 2010-05-13 tsawada2 修正済
		NSAssert1(UTILNumberOfCArray(mActionGetKeysForTag) > tag, @"[item tag] was invalid(%ld)", (long)tag);
		
		return [self setUpMessageActionMenuItem:theItem forIndexes:indexSet withAttributeName:mActionGetKeysForTag[tag]];
	}

	return [super validateMenuItem:theItem];
}
@end

// サービスメニュー経由でテキストを渡す場合のクラッシュを解決
// 341@CocoMonar 24(25)th thread の修正をベースに
// さらに独自の味付け
@implementation CMRThreadView(NSPasteboard)
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types
{
    if ([types containsObject:NSRTFDPboardType]) {
        // 元々渡される types には NSRTFDPboardType が含まれる。しかしこれが受け渡し時に問題を引き起こすようだ
        // そこで、NSRTFDPboardType を含まない別の array にすり替える
        NSMutableArray *mArray = [types mutableCopy];
        [mArray removeObject:NSRTFDPboardType];
        NSArray *newArray = [NSArray arrayWithArray:mArray];
        [mArray release];
        return [super writeSelectionToPasteboard:pboard types:newArray];
    }
    
    return [super writeSelectionToPasteboard:pboard types:types];
}

// コピー時に NSAttachmentCharacter を除去する
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    if ([type isEqualToString:NSRTFPboardType]) {
        NSAttributedString *attr = [self attributedSubstringFromRange:[self selectedRange]];
        NSMutableAttributedString *mAttr = [[attr mutableCopy] autorelease];
        [[mAttr mutableString] replaceCharacters:[NSString stringWithCharacter:NSAttachmentCharacter] toString:@""];
        NSAttributedString *tmp = [[[NSAttributedString alloc] initWithAttributedString:mAttr] autorelease];
        return [pboard setData:[tmp RTFFromRange:NSMakeRange(0, [tmp length]) documentAttributes:nil] forType:type];

    } else if ([type isEqualToString:NSStringPboardType]) {
        NSString *substring = [[self string] substringWithRange:[self selectedRange]];
        NSMutableString *string;

        // 単一行からなる http, https の URL 文字列では、パーセントエスケープしてあげる
        if ([substring hasPrefix:@"http://"] || [substring hasPrefix:@"https://"]) {
            NSRange lineRange = [substring lineRangeForRange:NSMakeRange(0, 1)];
            if (NSMaxRange(lineRange) == [substring length]) {
                string = [[substring stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
            } else {
                string = [substring mutableCopy];
            }
        } else {
            string = [substring mutableCopy];
        }
        
        string = [string autorelease];

        [string replaceCharacters:[NSString stringWithCharacter:NSAttachmentCharacter] toString:@""];
        NSString *pboardString = [NSString stringWithString:string];
        return [pboard setString:pboardString forType:type];
    }

    return [super writeSelectionToPasteboard:pboard type:type];
}
@end
