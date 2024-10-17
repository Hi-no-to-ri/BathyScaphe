//
//  CMRThreadViewer-Action.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/13.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"

#import "CMRThreadsList.h"
#import "SGLinkCommand.h"
#import "CMRReplyMessenger.h"
#import "CMRReplyDocumentFileManager.h"
#import "CMRThreadLayout.h"
#import "CMXPopUpWindowManager.h"
#import "BSBoardInfoInspector.h"
//#import "TextFinder.h"
#import "BoardManager.h"

#import "CMRSpamFilter.h"
#import "BSNGExpression.h"
#import "BSSearchOptions.h"
#import "BSThreadLinkerCorePasser.h"
#import "DatabaseManager.h"

// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"


@implementation CMRThreadViewer(ActionSupport)
- (CMRReplyMessenger *)replyMessenger
{
	UTILAssertNotNil([self path]);
	CMRReplyMessenger *document;
	NSURL	*replyDocURL;
	NSError *error;

	NSDocumentController *docController = [NSDocumentController sharedDocumentController];
	CMRReplyDocumentFileManager *replyDocManager = [CMRReplyDocumentFileManager defaultManager];

	NSString *replyDocPath = [replyDocManager replyDocumentFilepathWithLogPath:[self path] createIfNeeded:YES];
	replyDocURL = [NSURL fileURLWithPath:replyDocPath];

	document = [docController documentForURL:replyDocURL];
	if (document) return document;

	[replyDocManager createDocumentFileIfNeededAtPath:replyDocPath contentInfo:[self selectedThread]];
	document = [docController openDocumentWithContentsOfURL:replyDocURL display:YES error:&error];
	if (document) {
//		[self addMessenger:document];
		return document;
	}
	if (error) {
		NSAlert *alert = [NSAlert alertWithError:error];
		[alert runModal];
	}
	// Error while creating CMRReplyMessenger instance.
	return nil;
}

- (void)addMessenger:(CMRReplyMessenger *)aMessenger
{
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(replyMessengerDidFinishPosting:)
			   name:CMRReplyMessengerDidFinishPostingNotification
			 object:aMessenger];
}

- (void)replyMessengerDidFinishPosting:(NSNotification *)aNotification
{
	NSSound		*replyFinishedSound;
	NSString	*replyFinishedSoundName;

	UTILAssertNotificationName(aNotification, CMRReplyMessengerDidFinishPostingNotification);
    id threadIdentifierOfMine = [self threadIdentifier];
    if (!threadIdentifierOfMine) {
        return;
    }

    NSDictionary *userInfo = [aNotification userInfo];
    id threadIdentifierOfMessenger = [userInfo objectForKey:kUserInfoPostedThreadIdentifierKey];
    
    if (![threadIdentifierOfMessenger isEqual:threadIdentifierOfMine]) {
        return; // このスレッドに対する書き込みではない
    }

	replyFinishedSoundName = [CMRPref replyDidFinishSound];
	if (replyFinishedSoundName && ![replyFinishedSoundName isEqualToString:@""]) {
		replyFinishedSound = [NSSound soundNamed:replyFinishedSoundName];
	} else {
		replyFinishedSound = nil;
	}
	
	[replyFinishedSound play];

	[self reloadIfOnlineMode:nil];
}

- (void)removeMessenger:(CMRReplyMessenger *)aMessenger
{
	[[NSNotificationCenter defaultCenter]
		removeObserver:self
				  name:CMRReplyMessengerDidFinishPostingNotification
			    object:aMessenger];
}

- (void)openThreadsInThreadWindow:(NSArray *)threads
{
	// subclass should override this method
}
@end


@implementation CMRThreadViewer(Action)
- (NSArray *)targetThreadsForAction:(SEL)action sender:(id)sender
{
	return [self selectedThreads];
}

- (NSArray *)targetBoardsForAction:(SEL)action sender:(id)sender
{
    NSURL *boardURL = [self boardURL];
    return boardURL ? [NSArray arrayWithObject:boardURL] : [NSArray array];
}

#pragma mark Reloading thread
- (void)reloadThread
{
	[self downloadThread:[[self threadAttributes] threadSignature]
				   title:[self title]
			   nextIndex:[[self threadLayout] numberOfReadedMessages]];
}
- (IBAction)reloadThread:(id)sender
{
    //	NSEnumerator		*Iter_;
    //	NSDictionary		*threadAttributes_;

    //    Iter_ = [[self targetThreadsForAction:_cmd sender:sender] objectEnumerator];
    //	while (threadAttributes_ = [Iter_ nextObject]) {
    for (NSDictionary *threadAttributes_ in [self targetThreadsForAction:_cmd sender:sender]) {
		NSString			*path_;
		NSString			*title_;
		NSUInteger		curNumOfMsgs_;
		CMRThreadSignature	*threadSignature_;
		
		path_ =  [CMRThreadAttributes pathFromDictionary:threadAttributes_];
		title_ = [threadAttributes_ objectForKey:CMRThreadTitleKey];
        id tmp = [threadAttributes_ objectForKey:CMRThreadLastLoadedNumberKey];
        if ([tmp isKindOfClass:[NSNumber class]]) {
            curNumOfMsgs_ = [(NSNumber *)tmp unsignedIntegerValue];
        } else if ([tmp isKindOfClass:[NSString class]]) {
            curNumOfMsgs_ = [(NSString *)tmp integerValue];
        } else {
            curNumOfMsgs_ = 0;
        }
		threadSignature_ = [CMRThreadSignature threadSignatureFromFilepath:path_];

		if ([[self threadIdentifier] isEqual:threadSignature_]) {
			if ([self checkCanGenarateContents]) {
				[self reloadThread];
			}
			continue;
		}

        // スレッドが既に別ウインドウで開いている場合は、そのウインドウを管轄する CMRThreadViewer に -reloadThread: を実行させる
        NSDocument *doc = [[CMRDocumentController sharedDocumentController] documentAlreadyOpenForURL:[NSURL fileURLWithPath:path_]];
        if (doc && (doc != [self document])) {
            [[[doc windowControllers] lastObject] reloadThread:self];
            continue;
        }

		[self downloadThread:threadSignature_ title:title_ nextIndex:curNumOfMsgs_];
	}
}

- (IBAction)reloadIfOnlineMode:(id)sender
{	
    if (![self shouldShowContents]) {
        return;
    }
    if (![CMRPref isOnlineMode]) {
        if (![self isRetrieving]) {
            return;
        }
    }
	[self reloadThread];
}

#pragma mark Copy Thread Info
- (NSPoint)locationForInformationPopUp
{
	id			docView_;
	NSPoint		loc;
	
	docView_ = [[self textView] enclosingScrollView];
	docView_ = [docView_ contentView];
	
	loc = [docView_ frame].origin;
	loc.y = NSMaxY([docView_ frame]);
	
	docView_ = [[self textView] enclosingScrollView];
	loc = [docView_ convertPoint:loc toView:nil];
    loc = [[docView_ window] convertRectToScreen:NSMakeRect(loc.x, loc.y, 0, 0)].origin;
	return loc;
}

- (IBAction)copyThreadAttributes:(id)sender
{
	NSArray *array_ = [self targetThreadsForAction:_cmd sender:sender];

	NSMutableString	*tmp;
//	NSURL			*url_ = nil;
	NSPasteboard	*pboard_ = [NSPasteboard generalPasteboard];
//	NSArray			*types_;
	
	tmp = SGTemporaryString();

	[CMRThreadAttributes fillBuffer:tmp withThreadInfoForCopying:array_];
//	url_ = [CMRThreadAttributes threadURLFromDictionary:[array_ lastObject]];
	
//	types_ = [NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil];
//	[pboard_ declareTypes:types_ owner:nil];
	
//	[url_ writeToPasteboard:pboard_];
//	[pboard_ setString:tmp forType:NSStringPboardType];
    [pboard_ clearContents];
    [pboard_ writeObjects:[NSArray arrayWithObject:tmp]];
	
	[tmp deleteCharactersInRange:[tmp range]];
}

- (IBAction)copySelectedResURL:(id)sender
{
	NSRange			selectedRange_;
	NSUInteger		index_;
	NSUInteger		last_;

	NSURL			*resURL_;
	CMRHostHandler	*handler_;
	
	if (![self threadAttributes]) return;
	selectedRange_ = [[self textView] selectedRange];
	if (selectedRange_.length == 0) return;
	
	handler_ = [CMRHostHandler hostHandlerForURL:[self boardURL]];
	if (!handler_) return;
	
	index_ = [[self threadLayout] messageIndexForRange:selectedRange_];
	last_ = [[self threadLayout] lastMessageIndexForRange:selectedRange_];
	if (NSNotFound == index_ || NSNotFound == last_) {
		NSBeep();
		return;
	}
	
	index_++;
	last_++;
	resURL_ = [handler_ readURLWithBoard:[self boardURL] datName:[self datIdentifier] start:index_ end:last_ nofirst:NO];
	if (!resURL_) return;
	
	[[SGCopyLinkCommand functorWithObject:resURL_] execute:self];
}

#pragma mark Other IBActions
- (IBAction)showThreadFromHistoryMenu:(id)sender // Overrides CMRAppDelegate's one.
{
	UTILAssertRespondsTo(sender, @selector(representedObject));

	if (![self shouldShowContents] || ([NSEvent modifierFlags] & NSCommandKeyMask)) {
		// 新規ウインドウで開くべし。CMRAppDelegate に転送。
		[[NSApp delegate] showThreadFromHistoryMenu:sender];
		return;
	}
	[self setThreadContentWithThreadIdentifier:[sender representedObject]];
}

// Save window frame
- (IBAction)saveAsDefaultFrame:(id)sender
{
	[CMRPref setWindowDefaultFrameString:[[self window] stringWithSavedFrame]];
}

- (void)quoteWithMessenger:(CMRReplyMessenger *)aMessenger
{
	NSUInteger		index_;
	NSRange			selectedRange_;
	NSString		*contents_;
	
	// 引用
//	if ([[aMessenger replyMessage] length] != 0) return;
	
	selectedRange_ = [[self textView] selectedRange];
	if (0 == selectedRange_.length) return;
	index_ = [[self threadLayout] messageIndexForRange:selectedRange_];
	if (NSNotFound == index_) return;
	
	contents_ = [[[self textView] string] substringWithRange:selectedRange_];
	[aMessenger append:contents_ quote:YES replyTo:index_];
}

- (CMRReplyMessenger *)plainReply:(id)sender
{
	if (![self path]) return nil;
	CMRReplyMessenger *document = [self replyMessenger];

	if (!document) return nil;

	[document showWindows];
    return document;
}

- (IBAction)reply:(id)sender
{
    CMRReplyMessenger *document = [self plainReply:sender];
	if (document) {
        [self quoteWithMessenger:document];
    }
}

- (IBAction)openBBSInBrowser:(id)sender
{
    NSArray *urls = [self targetBoardsForAction:_cmd sender:sender];
    if ([urls count] == 0) {
        return;
    }
    BOOL inBg = [CMRPref openInBg];
    [[NSWorkspace sharedWorkspace] openURLs:urls inBackground:inBg];
}

- (IBAction)showBoardInspectorPanel:(id)sender
{
    NSArray *urls = [self targetBoardsForAction:_cmd sender:sender];
    if ([urls count] == 0) {
        return;
    }
    NSURL *url = [urls lastObject];
    NSString *boardName = [[BoardManager defaultManager] boardNameForURL:url];
    if (!boardName) {
        return;
    }
    [[BSBoardInfoInspector sharedInstance] showInspectorForTargetBoard:boardName];
}

- (IBAction)showLocalRules:(id)sender
{
    NSEnumerator *iter = [[self targetBoardsForAction:_cmd sender:sender] objectEnumerator];
    BoardManager *bm = [BoardManager defaultManager];
    NSURL *boardURL;
    NSString *boardName;
    id controller;
    while (boardURL = [iter nextObject]) {
        boardName = [bm boardNameForURL:boardURL];
        if (!boardName) {
            continue;
        }
        controller = [bm localRulesPanelControllerForBoardName:boardName];
        [controller showWindow:self];
    }
}

- (IBAction)addFavorites:(id)sender
{
	NSArray *selectedThreads;	
	CMRFavoritesManager *fm = [CMRFavoritesManager defaultManager];
	selectedThreads = [self targetThreadsForAction:_cmd sender:sender];

    if (!selectedThreads || ([selectedThreads count] == 0)) {
        return;
    }

//    CMRFavoritesOperation op = [self favoritesOperationForThreads:selectedThreads];
//    if (op == CMRFavoritesOperationNone) {
//        return;
//    }

//    SEL operationSelector;
//    operationSelector = (op == CMRFavoritesOperationLink) ? @selector(addFavoriteWithSignature:)
//                                                          : @selector(removeFromFavoritesWithSignature:);
    NSString *path;
    CMRThreadSignature *signature;

    for (NSDictionary *threadAttributes in selectedThreads) {
		path = [CMRThreadAttributes pathFromDictionary:threadAttributes];
		UTILAssertNotNil(path);
        CMRFavoritesOperation op = [fm availableOperationWithPath:path];
        if (op == CMRFavoritesOperationNone) {
            continue;
        }
 //       SEL operationSelector = (op == CMRFavoritesOperationLink) ? @selector(addFavoriteWithSignature:) : @selector(removeFromFavoritesWithSignature:);
        SEL operationSelector = (op == CMRFavoritesOperationLink) ? @selector(addFavoritesWithSignatureWithoutNotify:) : @selector(removeFromFavoritesWithSignatureWithoutNotify:);
		signature = [CMRThreadSignature threadSignatureFromFilepath:path];
		UTILAssertNotNil(signature);
        [fm performSelector:operationSelector withObject:signature];
    }
    
    // 通知は最後に一度だけ発行
    [fm notifyFavoritesDidChange];
}

// make text area to be first responder
- (IBAction)focus:(id)sender
{
    [[self window] makeFirstResponder:[[self textView] enclosingScrollView]];
}

- (IBAction)shareThreadInfo:(id)sender
{
    if (![sender respondsToSelector:@selector(bounds)]) {
        return; // 「テキストのみ」ツールバー対策、暫定
    }
	NSArray *array_ = [self targetThreadsForAction:_cmd sender:sender];
    
	NSMutableString	*tmp = [NSMutableString string];
	[CMRThreadAttributes fillBuffer:tmp withThreadInfoForCopying:array_];
    
    NSArray *items = [NSArray arrayWithObject:tmp];
    id picker = [[[NSClassFromString(@"NSSharingServicePicker") alloc] initWithItems:items] autorelease];
    [picker setDelegate:self];
    [picker showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMinYEdge];
}

- (NSWindow *)sharingService:(id)sharingService sourceWindowForShareItems:(NSArray *)items sharingContentScope:(NSInteger *)sharingContentScope
{
    *sharingContentScope = 2;
    return [self window];
}

- (id)sharingServicePicker:(id)sharingServicePicker delegateForSharingService:(id)sharingService
{
    return self;
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if (![[menu title] isEqualToString:@"Share"]) { // See CMRThreadViewerTbDelegate.m
        return;
    }

    // clear out in case we can no longer provide this service
    [menu removeAllItems];
    
	NSArray *array_ = [self targetThreadsForAction:_cmd sender:menu];
	NSMutableString	*tmp = [NSMutableString string];
	[CMRThreadAttributes fillBuffer:tmp withThreadInfoForCopying:array_];
    
    NSArray *items = [NSArray arrayWithObject:tmp];
    
    // rebuild the menu
    NSArray *sharingService = [NSClassFromString(@"NSSharingService") sharingServicesForItems:items];
    for (id currentService in sharingService) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[currentService title] action:@selector(shareThreadInfoFromMenuItem:) keyEquivalent:@""];
        item.image = [currentService image];
        item.representedObject = currentService;
        [menu addItem:item];
        [item release];
    }
}

- (void)shareThreadInfoFromMenuItem:(id)sender
{
	NSArray *array_ = [self targetThreadsForAction:_cmd sender:sender];
	NSMutableString	*tmp = [NSMutableString string];
	[CMRThreadAttributes fillBuffer:tmp withThreadInfoForCopying:array_];
    
    NSArray *items = [NSArray arrayWithObject:tmp];
    
    id service = [sender representedObject];
    if (![service isKindOfClass:NSClassFromString(@"NSSharingService")]) {
        return; // just to make sure…
    }
    [service setDelegate:self];
    [service performWithItems:items];
}
/*
- (NSRect)sharingService:(id)sharingService sourceFrameOnScreenForShareItem:(id<NSPasteboardWriting>)item
{
    NSRect imageViewBounds = [[self scrollView] bounds];
    NSRect frame = [[self scrollView] convertRect:imageViewBounds toView:nil];
    frame.origin = [[[self scrollView] window] convertBaseToScreen:frame.origin];
    return frame;
}

- (NSImage *)sharingService:(id)sharingService
transitionImageForShareItem:(id <NSPasteboardWriting>)item
                contentRect:(NSRect *)contentRect
{
    NSBitmapImageRep* bitmap = [[self scrollView] bitmapImageRepForCachingDisplayInRect:[[self scrollView] bounds]];
    [[self scrollView] cacheDisplayInRect:[[self scrollView] bounds] toBitmapImageRep:bitmap];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmap];
    return [image autorelease];
}
*/
// Available in Twincam Angel and later.
- (void)checkIfUsesCorpusOptionOn
{
    if (![CMRPref spamFilterEnabled]) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:[self localizedString:@"SpamFilter Off Alert Title"]];
        [alert setInformativeText:[self localizedString:@"SpamFilter Off Alert Msg"]];
        [alert addButtonWithTitle:[self localizedString:@"SpamFilter Turn On Btn"]];
        [alert addButtonWithTitle:[self localizedString:@"SpamFilter Keep Off Btn"]];
        [alert setShowsHelp:YES];
        [alert setDelegate:[NSApp delegate]];
        [alert setHelpAnchor:[self localizedString:@"SpamFilter Off Alert HelpAnchor"]];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [CMRPref setSpamFilterEnabled:YES];
        }
    }
}

- (void)action:(SEL)actionSelector withSelectedText:(id)sender
{
    NSRange selectedRange_ = [[self textView] selectedRange];
    NSString *string_;
    
    string_ = [[[self textView] string] substringWithRange:selectedRange_];
    if (![[self threadLayout] onlySingleMessageInRange:selectedRange_]) {
        return;
    }
    
    // 渡す前に文字列をチェック
    NSUInteger length = [string_ length];
    if (length == 0) { // 無いと思うが…
        return;
    } else if (length == 1) { // 改行文字のみならば無視
        if ([string_ isEqualToString:@"\n"]) {
            return;
        }
    } else { // 最後が改行文字ならば除去
        if ([[string_ substringWithRange:NSMakeRange(length - 1, 1)] isEqualToString:@"\n"]) {
            string_ = [string_ substringToIndex:(length - 1)];
        }
    }

    [self performSelector:actionSelector withObject:string_];
}

- (IBAction)addToNGWords:(id)sender
{
/*	NSRange selectedRange_ = [[self textView] selectedRange];
	NSString *string_;
	
	string_ = [[[self textView] string] substringWithRange:selectedRange_];
	if (![[self threadLayout] onlySingleMessageInRange:selectedRange_]) {
        return;
    }
    [self tryToAddNGWord:string_];*/
    [self action:@selector(tryToAddNGWord:) withSelectedText:sender];
}

- (IBAction)extractUsingSelectedText:(id)sender
{	
/*	NSRange			selectedRange_ = [[self textView] selectedRange];
	NSString		*string_;

	if (![[self threadLayout] onlySingleMessageInRange:selectedRange_]) {
        return;
    }

	string_ = [[[self textView] string] substringWithRange:selectedRange_];
    [self extractUsingString:string_];*/
    [self action:@selector(extractUsingString:) withSelectedText:sender];
}

#pragma mark Scaling Text View
- (void)scaleTextView:(float)rate
{
	NSClipView *clipView_ = [[self scrollView] contentView];
	NSTextView *textView_ = [self textView];

	NSUInteger curIndex = [[self threadLayout] firstMessageIndexForDocumentVisibleRect];

	NSSize	curBoundsSize = [clipView_ bounds].size;	
	NSSize	curFrameSize = [textView_ frame].size;

	[clipView_ setBoundsSize:NSMakeSize(floor(curBoundsSize.width*rate), floor(curBoundsSize.height*rate))];
	[textView_ setFrameSize:NSMakeSize(floor(curFrameSize.width*rate), floor(curFrameSize.height*rate))];
/*
	[clipView_ setNeedsDisplay:YES]; // really need?

	[clipView_ setCopiesOnScroll:NO]; // これがキモ
	[[self threadLayout] scrollMessageAtIndex:curIndex]; // スクロール位置補正

	// テキストビューやクリップビューだけ再描画させても良さそうだが、
	// 時々ツールバーとの境界線が消えてしまうことがあるので、ウインドウごと再描画させる
	[[self window] display]; 
	[clipView_ setCopiesOnScroll:YES];*/

    // 計算する。正しい高さは textContainer のサイズから得る
    NSLayoutManager *layoutManager = [textView_ layoutManager];
    NSTextContainer *textContainer = [textView_ textContainer];
    
//    [layoutManager ensureLayoutForTextContainer:textContainer];
    [[self threadLayout] ensureLayoutForThreadView];
    NSSize textContainerSize = [layoutManager usedRectForTextContainer:textContainer].size;
    
    // 補正後のサイズにセット
    NSSize insetSize = [textView_ textContainerInset];
    textContainerSize.width += insetSize.width*2; // 横幅は [textView frame].size.width と一致するはず
    textContainerSize.height += insetSize.height*2;
    
    [textView_ setFrameSize:textContainerSize];
    
    [[self window] display];
    
	[[self threadLayout] scrollMessageAtIndex:curIndex]; // スクロール位置補正

    // 確実に -encodeRestorableStateWithCoder: を呼んでもらうために
    [self invalidateRestorableState];
}

- (void)resetTextViewScale:(float)rate
{
    NSClipView *clipView = [[self scrollView] contentView];
    NSTextView *textView = [self textView];

	NSUInteger curIndex = [[self threadLayout] firstMessageIndexForDocumentVisibleRect];

    NSSize newBoundsSize = [[self scrollView] contentSize];
    [clipView setBoundsSize:newBoundsSize];

    // この時点でのテキストビューの高さは、目安でしかない。補正する必要がある
    [textView setFrameSize:NSMakeSize(newBoundsSize.width, floor([textView frame].size.height * rate))];

    // 計算する。正しい高さは textContainer のサイズから得る
    NSLayoutManager *layoutManager = [textView layoutManager];
    NSTextContainer *textContainer = [textView textContainer];

//    [layoutManager ensureLayoutForTextContainer:textContainer];
    [[self threadLayout] ensureLayoutForThreadView];
    NSSize textContainerSize = [layoutManager usedRectForTextContainer:textContainer].size;
    
    // 補正後のサイズにセット
    NSSize insetSize = [textView textContainerInset];
    textContainerSize.width += insetSize.width*2; // 横幅は [textView frame].size.width と一致するはず
    textContainerSize.height += insetSize.height*2;
    
    [textView setFrameSize:textContainerSize];
    
    [[self window] display];

	[[self threadLayout] scrollMessageAtIndex:curIndex]; // スクロール位置補正
}

- (IBAction)biggerText:(id)sender
{
    m_scaleCount++;
	[self scaleTextView:0.8];
}

- (IBAction)smallerText:(id)sender
{
    m_scaleCount--;
	[self scaleTextView:1.25];
}

- (IBAction)actualSizeText:(id)sender
{
    float rate = (m_scaleCount > 0) ? 1.25 : 0.8;
    int hoge = abs(m_scaleCount);
    [self resetTextViewScale:(powf(rate, hoge))];
    m_scaleCount = 0;
}

- (IBAction)scaleSegmentedControlPushed:(id)sender
{
	NSInteger	i;
	i = [sender selectedSegment];

	if (i == -1) {
		NSLog(@"No selection?");
	} else if (i == 1) {
		[self biggerText:nil];
	} else {
		[self smallerText:nil];
	}
}

#pragma mark Passing-On
- (IBAction)passLinkerCoreFromLink:(id)sender
{
    CMRThreadSignature *fromThread = [sender representedObject];
    CMRThreadSignature *toThread = [self threadIdentifier];
    NSString *fromTitle = [[DatabaseManager defaultManager] threadTitleFromBoardName:[fromThread boardName] threadIdentifier:[fromThread identifier]];
    
    BSThreadLinkerCorePasser *passer = [self threadLinkerCorePasser];
    
    passer.fromThreadTitle = fromTitle;
    passer.fromThreadSignature = fromThread;
    passer.toThreadTitle = [self title];
    passer.toThreadSignature = toThread;
    [passer beginPassingLinkerCoreOnSheetForWindow:[self window]];
}
@end
