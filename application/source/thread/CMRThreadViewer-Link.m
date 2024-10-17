//
//  CMRThreadViewer-Link.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/11/19.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"
#import "CMRThreadLinkProcessor.h"
#import "CMRMessageAttributesTemplate.h"
#import "CMRThreadLayout.h"
#import "SGHTMLView.h"
#import "CMXPopUpWindowManager.h"
#import "CMRReplyMessenger.h"
#import "BSSpamJudge.h"
#import "CMRSpamFilter.h"
#import "CMRThreadView.h"
#import "SGLinkCommand.h"
#import "SGDownloadLinkCommand.h"
#import "BSAsciiArtDetector.h"
#import "DatabaseManager.h"
#import "missing.h"
#import <SGAppKit/NSWorkspace-SGExtensions.h>
#import "NSCharacterSet+CMXAdditions.h"
#import "BSInnerLinkValueRep.h"


#define kBeProfileLinkTemplateKey	@"System - be2ch Profile URL"

// for debugging only
#define UTIL_DEBUGGING				0
#import "UTILDebugging.h"


@interface CMRThreadViewer (PopUpSupport)
- (NSAttributedString *) attributedStringWithLinkContext : (id) aLink;
- (BOOL)tryShowPopUpWindowWithLink:(id)aLink forObject:(id)object locationHint:(NSPoint)loc;
- (BOOL) tryShowPopUpWindowWithLink : (id     ) aLink
                       locationHint : (NSPoint) loc;
- (BOOL) tryShowPopUpWindowSubstringWithRange : (NSRange		) subrange
								inTextStorage : (NSTextStorage *) storage
								 locationHint : (NSPoint		) loc;

- (BOOL)isMessageLink:(id)aLink messageIndexes:(NSIndexSet **)indexesPtr isLocalAbonePreviewLink:(BOOL *)boolPtr;
- (NSIndexSet *)isStandardMessageLink:(id)aLink;
@end


@implementation CMRThreadViewer (PopUpSupport)
- (NSAttributedString *)attributedStringWithLinkContext:(id)aLink
{
	static NSMutableAttributedString *kBuffer = nil;
	
	NSString		*address_;
	NSString		*logPath_ = nil;
	NSString		*boardName_ = nil;	// added in PrincessBride and later.
	
	if (!aLink) {
        return nil;
    }
	if (!kBuffer) {
		kBuffer = [[NSMutableAttributedString alloc] init];
    }
	[kBuffer deleteCharactersInRange:[kBuffer range]];

	address_ = [[aLink stringValue] stringByDeletingURLScheme:@"mailto"];
	if (address_) {
		NSDictionary *attributes_;

		attributes_ = [[CMRMessageAttributesTemplate sharedTemplate] attributesForText];
		[[kBuffer mutableString] appendString:address_];
		[kBuffer setAttributes:attributes_ range:[kBuffer range]]; 
	} else if ([CMRThreadLinkProcessor parseThreadLink:aLink boardName:&boardName_ boardURL:NULL filepath:&logPath_]) {
		NSDictionary			*dict_;
		NSAttributedString		*template_;
		NSString				*title_;
		
		dict_ = [[[NSDictionary alloc] initWithContentsOfFile:logPath_] autorelease];
		if (!dict_) {
			// データベース上にあるか
			NSString *threadID = [[logPath_ stringByDeletingPathExtension] lastPathComponent];
			NSString *threadTitle = [[DatabaseManager defaultManager] threadTitleFromBoardName:boardName_ threadIdentifier:threadID];
			if (threadTitle) {
				title_ = [NSString stringWithFormat:@"%@ %C %@", threadTitle, (unichar)0x2014, boardName_];
			} else {
				title_ = boardName_;
			}
		} else {
			title_ = [NSString stringWithFormat:@"%@ %C %@", [dict_ objectForKey:CMRThreadTitleKey], (unichar)0x2014, boardName_];
        }
        template_ = [[[NSAttributedString alloc] initWithString:title_] autorelease];
        if (!template_) {
            goto ErrInvalidLink;
        }
        [kBuffer setAttributedString:template_];
	} else if ([CMRThreadLinkProcessor parseBoardLink:aLink boardName:&boardName_ boardURL:NULL]) {
		[kBuffer setAttributedString:[[[NSAttributedString alloc] initWithString:boardName_] autorelease]];
	} else {
		NSIndexSet	*indexes;
		NSAttributedString *message_;
        BOOL isLocalAbone = YES;

		if (![self isMessageLink:aLink messageIndexes:&indexes isLocalAbonePreviewLink:&isLocalAbone]) {
            goto ErrInvalidLink;
        }
		message_ = isLocalAbone ? [[self threadLayout] contentsForIndexes:indexes] : [[self threadLayout] localAbonedContentsForIndexes:indexes];
		if (message_) {
            [kBuffer appendAttributedString:message_];
        }
	}

	return kBuffer;

ErrInvalidLink:
	return nil;
}

- (BOOL)tryShowPopUpWindowWithLink:(id)aLink forObject:(id)object locationHint:(NSPoint)loc
{
	NSAttributedString		*context_;

	context_ = [self attributedStringWithLinkContext:aLink];
	if (!context_ || [context_ length] == 0) {
		return NO;
	}
	
	[CMRPopUpMgr showPopUpWindowWithContext:context_ forObject:(object ?: aLink) owner:self locationHint:loc];

	return YES;
}

- (BOOL)tryShowPopUpWindowWithLink:(id)aLink locationHint:(NSPoint)loc
{
    return [self tryShowPopUpWindowWithLink:aLink forObject:nil locationHint:loc];
}

- (BOOL)tryShowPopUpWindowSubstringWithRange:(NSRange)subrange inTextStorage:(NSTextStorage *)storage locationHint:(NSPoint)loc
{
	NSString *linkstr_;
    BSInnerLinkValueRep *linkRep;
	
	if (subrange.length == 0) {
        return NO;
    }
	if (!storage) {
        return NO;
	}
    if (NSMaxRange(subrange) >= [storage length]) {
        return NO;
	}

	linkstr_ = [[storage string] substringWithRange:subrange];
	linkRep = [[[BSInnerLinkValueRep alloc] initWithOriginalString:linkstr_] autorelease];
	
	return [self tryShowPopUpWindowWithLink:linkRep locationHint:loc];
}

- (NSIndexSet *)isStandardMessageLink:(id)aLink
{
	NSURL			*link_;
	CMRHostHandler	*handler_;
	NSString		*bbs_;
	NSString		*key_;
	
	NSUInteger	stIndex_;
	NSUInteger	endIndex_;
	NSRange			moveRange_;
	
	link_ = [NSURL URLWithLink:aLink];
	handler_ = [CMRHostHandler hostHandlerForURL:link_];
	if (!handler_) return nil;
	
	if (![handler_ parseParametersWithReadURL:link_
										  bbs:&bbs_
										  key:&key_
										start:&stIndex_
										   to:&endIndex_
									showFirst:NULL]) {
		return nil;
	}
	
	if (NSNotFound != stIndex_) {
		moveRange_.location = stIndex_ -1;
		moveRange_.length = (endIndex_ - stIndex_) +1;
	} else {
		return nil;		
	}
	
	// 同じ掲示板の同じスレッドならメッセージ移動処理
	if ([[self bbsIdentifier] isEqualToString:bbs_] && [[self datIdentifier] isEqualToString:key_]) {
		return [NSIndexSet indexSetWithIndexesInRange:moveRange_];
	}
	
	return nil;
}

- (BOOL)isMessageLink:(id)aLink messageIndexes:(NSIndexSet **)indexesPtr isLocalAbonePreviewLink:(BOOL *)boolPtr
{
	NSIndexSet		*indexes;
	if (!aLink) return NO;

	if ([CMRThreadLinkProcessor isMessageLinkUsingLocalScheme:aLink messageIndexes:indexesPtr localAbonePreviewLink:boolPtr]) {
		return YES;
	} else if ((indexes = [self isStandardMessageLink:aLink])) {
		if (indexesPtr != NULL) *indexesPtr = indexes;
        if (boolPtr != NULL) *boolPtr = NO;
		return YES;
	}

	return NO;
}
@end

#pragma mark -

@implementation CMRThreadViewer (NSTextViewDelegate)
- (void)openMessagesWithIndexes:(NSIndexSet *)indexes
{
	if (!indexes || [indexes count] == 0) {
        return;
    }

    NSURL *boardURL = [self boardURL];
    CMRHostHandler *handler = [CMRHostHandler hostHandlerForURL:[self boardURL]];
	NSURL *url = [handler readURLWithBoard:boardURL datName:[self datIdentifier] start:[indexes firstIndex]+1 end:[indexes lastIndex]+1 nofirst:YES];

    if (url) {
        [[NSWorkspace sharedWorkspace] openURL:url inBackground:[CMRPref openInBg]];
	}
}

#pragma mark Previewing (or Downloading) Link
static inline NSString *urlPathExtension(NSURL *url)
{
	CFStringRef extensionRef = CFURLCopyPathExtension((CFURLRef)url);
	if (!extensionRef) {
		return nil;
	}
	NSString *extension = [(NSString *)extensionRef lowercaseString];
	CFRelease(extensionRef);
	return extension;
}

- (NSDictionary *)refererThreadInfoForLinkDownloader
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[self title], kRefererTitleKey, [[self threadURL] absoluteString], kRefererURLKey, NULL];
}

- (BOOL)previewOrDownloadURL:(NSURL *)url
{
    if (!url || [[url scheme] isEqualToString:@"mailto"]) {
        return NO;
    }

	NSArray		*extensions = [CMRPref linkDownloaderExtensionTypes];
	NSString	*linkExtension = urlPathExtension(url);

	if (linkExtension && [extensions containsObject:linkExtension]) {
		SGDownloadLinkCommand *dlCmd = [SGDownloadLinkCommand functorWithObject:[url absoluteString]];
		[dlCmd setRefererThreadInfo:[self refererThreadInfoForLinkDownloader]];
		[dlCmd execute:self];
		return YES;
	}


    id<BSLinkPreviewing> previewer = [CMRPref sharedLinkPreviewer];
    if (previewer) {
        return [previewer validateLink:url] ? [previewer previewLink:url] : NO;
    }
    return NO;
}

- (void)openURLsWithAppStore:(NSArray *)array
{
    [[NSWorkspace sharedWorkspace] openURLs:array
                    withAppBundleIdentifier:@"com.apple.appstore"
                                    options:NSWorkspaceLaunchDefault
             additionalEventParamDescriptor:nil
                          launchIdentifiers:NULL];
}

- (BOOL)handleExternalLink:(id)aLink forView:(NSView *)aView
{
	BOOL			shouldPreviewWithNoModifierKey = [CMRPref previewLinkWithNoModifierKey];
	BOOL			isOptionKeyPressed;
	BOOL			isFileURL;
	NSURL			*url = [NSURL URLWithLink:aLink];
	NSEvent			*theEvent;
	
	theEvent = [[aView window] currentEvent];
	UTILAssertNotNil(theEvent);

	isOptionKeyPressed = (([theEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask);
	isFileURL = [url isFileURL];

    if ([CMRPref convertsHttpToItmsIfNeeded] && [[url host] isEqualToString:@"itunes.apple.com"]) {
        NSMutableString *tmp = [[url absoluteString] mutableCopy];
        if ([tmp hasSuffix:@"?mt=12"]) { // Mac App Store URL ?
            [tmp replaceCharactersInRange:NSMakeRange(0,4) withString:@"macappstore"];
            NSURL *newURL2 = [NSURL URLWithString:tmp];
            [tmp release];

            // App Store.app が既に起動しているかどうか？
            NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
            id hoge = [runningApps valueForKey:@"bundleIdentifier"];
            if ([hoge containsObject:@"com.apple.appstore"]) {
                // 既に起動しているなら直ちに開かせる
                [self openURLsWithAppStore:[NSArray arrayWithObject:newURL2]];
                return YES;
            } else {
                // App Store.app の起動を試みる
                BOOL launched = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.appstore"
                                                                                     options:NSWorkspaceLaunchWithoutActivation
                                                              additionalEventParamDescriptor:nil
                                                                            launchIdentifier:NULL];
                if (launched) {
                    // 起動できたら、遅延実行で当該アプリのページを開かせる（遅延させないとうまくいかない）
                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                    [alert setAlertStyle:NSInformationalAlertStyle];
                    [alert setMessageText:[self localizedString:@"App Store Waiting Msg"]];
                    [alert setInformativeText:[self localizedString:@"App Store Waiting Info"]];
                    [alert addButtonWithTitle:[self localizedString:@"App Store Continue"]];
                    [alert addButtonWithTitle:[self localizedString:@"App Store Cancel"]];
                    if ([alert runModal] == NSAlertFirstButtonReturn) {
                        [self openURLsWithAppStore:[NSArray arrayWithObject:newURL2]];
                    }
                    return YES;
                } else {
                    // App Store.app が存在しない環境か、他の何らかの理由で起動に失敗。URL を通常通り Web ブラウザで開かせる。
                    return [[NSWorkspace sharedWorkspace] openURL:url inBackground:[CMRPref openInBg]];
                }
            }
        } else {
            [tmp replaceCharactersInRange:NSMakeRange(0,4) withString:@"itms"];
            NSURL *newURL = [NSURL URLWithString:tmp];
            [tmp release];
            [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:newURL]
                withAppBundleIdentifier:@"com.apple.iTunes"
                options:NSWorkspaceLaunchDefault
                additionalEventParamDescriptor:nil launchIdentifiers:NULL];
            return YES;
        }
    }

	if (shouldPreviewWithNoModifierKey) {
		if (!isOptionKeyPressed && !isFileURL) {
			if ([self previewOrDownloadURL:url]) return YES;
		}
	} else {
		if (isOptionKeyPressed && !isFileURL) {
			if ([self previewOrDownloadURL:url]) return YES;
		}
	}
	return [[NSWorkspace sharedWorkspace] openURL:url inBackground:[CMRPref openInBg]];
}

#pragma mark NSTextView Delegate
- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)aLink atIndex:(NSUInteger)charIndex
{
	NSString		*boardName_;
	NSURL			*boardURL_;
	NSString		*filepath_;
    NSString *host_;
	NSString		*beParam_;
	NSIndexSet		*indexes;
    BOOL    isNotAnchor = NO;

	// 同じスレッドのレスへのアンカー
    // ローカルあぼーんの「レスを表示」リンクは除外する（isNotAnchor フラグによって）
    if ([self isMessageLink:aLink messageIndexes:&indexes isLocalAbonePreviewLink:&isNotAnchor]) {
        if (!isNotAnchor) {
            NSInteger action = [CMRPref threadViewerLinkType];
            if ([indexes firstIndex] != NSNotFound) {
                switch (action) {
                case ThreadViewerMoveToIndexLinkType:
                    [self scrollMessageAtIndex:[indexes firstIndex]];
                    break;
                case ThreadViewerOpenBrowserLinkType:
                    [self openMessagesWithIndexes:indexes];
                    break;
                case ThreadViewerResPopUpLinkType:
                    break;
                default:
                    break;
                }
            }
        }
        return YES;
	}

	// be Profile
	if ([CMRThreadLinkProcessor isBeProfileLinkUsingLocalScheme:aLink linkParam:&beParam_]) {
		NSString	*template_ = SGTemplateResource(kBeProfileLinkTemplateKey);
		NSString	*thURL_ = [[self threadURL] absoluteString];
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 検証済
		NSString	*tmpURL_ = [NSString stringWithFormat:template_, beParam_, thURL_];

		NSURL	*accessURL_ = [NSURL URLWithString:tmpURL_];
		
		return [[NSWorkspace sharedWorkspace] openURL:accessURL_ inBackground:[CMRPref openInBg]];
	}

	// 2ch thread
	if ([CMRThreadLinkProcessor parseThreadLink:aLink boardName:&boardName_ boardURL:&boardURL_ filepath:&filepath_ parsedHost:&host_]) {
		CMRDocumentFileManager	*dm;
		NSDictionary			*contentInfo_;
		NSString				*datIdentifier_;
		
		dm = [CMRDocumentFileManager defaultManager];
		datIdentifier_ = [dm datIdentifierWithLogPath:filepath_];
		contentInfo_ = [NSDictionary dictionaryWithObjectsAndKeys:
							[boardURL_ absoluteString], BoardPlistURLKey,
							boardName_, ThreadPlistBoardNameKey,
							datIdentifier_, ThreadPlistIdentifierKey,
                            host_, @"candidateHost",
							nil];

		[dm ensureDirectoryExistsWithBoardName:boardName_];
		return [[CMRDocumentController sharedDocumentController] showDocumentWithContentOfFile:[NSURL fileURLWithPath:filepath_] boardInfo:contentInfo_];
	}
	
	// 2ch (or other) BBS
	if ([CMRThreadLinkProcessor parseBoardLink:aLink boardName:&boardName_ boardURL:&boardURL_]) {
		[[NSApp delegate] showThreadsListForBoard:boardName_ selectThread:nil addToListIfNeeded:YES];
		return YES;
	}

	// 外部リンクと判断
	return [self handleExternalLink:aLink forView:textView];
}

#pragma mark CMRThreadView delegate
- (CMRThreadSignature *)threadSignatureForView:(CMRThreadView *)aView
{
	return [[self threadAttributes] threadSignature];
}

- (CMRThreadLayout *)threadLayoutForView:(CMRThreadView *)aView
{
	return [self threadLayout];
}

- (void)threadView:(CMRThreadView *)aView replyTo:(NSIndexSet *)messageIndexes
{
    CMRReplyMessenger *document = [self plainReply:aView];
    if (!document) {
        return;
    }
    // 選択テキストがある場合は、すでに -reply: 内で（アンカー付きで）引用されているはずなので
    // アンカーを付与しない
    BOOL shouldAppendAnchor = YES;
    NSRange selectedRange = [aView selectedRange];
    if (selectedRange.location != NSNotFound) {
        NSUInteger index = [[self threadLayout] messageIndexForRange:selectedRange];
        if (index != NSNotFound) {
            if ([messageIndexes containsIndex:index]) {
                [self quoteWithMessenger:document];
                shouldAppendAnchor = NO;
            }
        }
    }
    if (shouldAppendAnchor) {
        [document append:@"" quote:NO replyTo:[messageIndexes firstIndex]];
    }
}

- (void)threadView:(CMRThreadView *)aView reverseAnchorPopUp:(NSUInteger)targetIndex forObject:(id)object locationHint:(NSPoint)location_
{
	NSAttributedString *contents_;
	contents_ = [[self threadLayout] contentsForTargetIndex:targetIndex
											 composingMask:CMRInvisibleAbonedMask
												   compose:NO
											attributesMask:(CMRLocalAbonedMask|CMRSpamMask)];
	if (!contents_ || [contents_ length] == 0) {
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 修正済
		NSString *notFoundString = [NSString stringWithFormat:[self localizedString: @"GyakuSansyou Not Found"], (unsigned long)(targetIndex+1)];
		contents_ = [[[NSAttributedString alloc] initWithString:notFoundString] autorelease];
	}

	[CMRPopUpMgr showPopUpWindowWithContext:contents_
								  forObject:(object ?:[self threadIdentifier])
									  owner:self
							   locationHint:location_];
}

- (void)threadView:(CMRThreadView *)aView reverseAnchorPopUp:(NSUInteger)targetIndex locationHint:(NSPoint)location_
{
    [self threadView:aView reverseAnchorPopUp:targetIndex forObject:nil locationHint:location_];
}

// AA Filter
- (IBAction)runAsciiArtDetector:(id)sender
{
	CMRThreadLayout			*layout;
	CMRThreadSignature		*threadID;
	
	layout = [self threadLayout];
	threadID = [[self threadAttributes] threadSignature];
	if (!layout || !threadID) {
		return;
	}
	[[BSAsciiArtDetector sharedInstance] runDetectorWithMessages:[layout messageBuffer] with:threadID allowConcurrency:NO];
}

// Spam Filter
- (IBAction)runSpamFilter:(id)sender
{
	CMRThreadLayout			*layout;
	CMRThreadSignature		*threadID;
	
	layout = [self threadLayout];
	threadID = [[self threadAttributes] threadSignature];
	if (!layout || !threadID) {
		return;
	}

    NSIndexSet *indexes;
    BSSpamJudge *judge = [[[BSSpamJudge alloc] initWithThreadSignature:threadID] autorelease];
    [judge judgeMessages:[layout messageBuffer] spamIndexes:&indexes];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [layout updateMessageAtIndex:idx];
    }];
}

/* CMRThreadViewerRunSpamFilterNotification */
- (void)threadViewerRunSpamFilter:(NSNotification *)theNotification
{
	UTILAssertNotificationName(theNotification, CMRThreadViewerRunSpamFilterNotification);
	
    id object = [theNotification object];
    if ((object == self) || (m_addNGExWindowController && (object == m_addNGExWindowController))) {
        if ([CMRPref spamFilterEnabled]) {
            [self runSpamFilter:nil];
        }        
    }
}

- (void)postRunSpamFilterNotification
{
	NSNotification *notification;
    NSNotificationQueue *queue = [NSNotificationQueue defaultQueue];
	
	notification = [NSNotification notificationWithName:CMRThreadViewerRunSpamFilterNotification object:self];
	[queue enqueueNotification:notification
                  postingStyle:NSPostWhenIdle
                  coalesceMask:NSNotificationCoalescingOnSender
                      forModes:nil];
}

- (void)threadView:(CMRThreadView *)aView spam:(CMRThreadMessage *)aMessage messageRegister:(BOOL)registerFlag
{
    BSMessageSampleRegistrant *registrant = [[self document] registrant];
	CMRThreadSignature		*threadID = [self threadSignatureForView:aView];
	
	if (!registrant || !aMessage || !threadID) {
        return;
    }
	if (registerFlag) {
        [registrant setDelegate:self];
        [registrant registerMessage:aMessage];
		[self postRunSpamFilterNotification];	// 新しいサンプルを追加した場合のみ自動的に起動
	} else {
        [registrant unregisterMessage:aMessage];
	}
}

- (BOOL)threadView:(CMRThreadView *)aView
	  mouseClicked:(NSEvent *)theEvent
		   atIndex:(NSUInteger)charIndex
	  messageIndex:(NSUInteger)aMessageIndex
{
    NSMenu	*menu_ = [aView messageMenuWithMessageIndex:aMessageIndex];
    [NSMenu popUpContextMenu:menu_ withEvent:theEvent forView:aView];
	return YES;
}

- (BOOL)threadView:(CMRThreadView *)aView mouseClicked:(NSEvent *)theEvent atIndex:(NSUInteger)charIndex userData:(id)userData
{
    NSPoint     mouseLocation_;
    
    mouseLocation_ = [theEvent locationInWindow];
    mouseLocation_ = [[aView window] convertRectToScreen:NSMakeRect(mouseLocation_.x, mouseLocation_.y, 0, 0)].origin;

    NSString *attributeName = [userData objectForKey:SGHTMLViewLinkUserDataAttributeNameKey];
    if ([attributeName isEqualToString:BSMessageReferencedCountAttributeName] && ([CMRPref popupTriggerType] == BSPopupByMouseClick)) {
        [self threadView:aView reverseAnchorPopUp:[[userData objectForKey:SGHTMLViewLinkUserDataLinkValueKey] unsignedIntegerValue] locationHint:mouseLocation_];
    } else if ([attributeName isEqualToString:BSMessageIDAttributeName] && ([CMRPref popupTriggerType] == BSPopupByMouseClick)) {
        id boolObj = [userData objectForKey:SGHTMLViewLinkUserDataFieldHintKey];
        BOOL fromIDField = boolObj ? [boolObj boolValue] : YES;
        [self extractMessagesWithIDString:[userData objectForKey:SGHTMLViewLinkUserDataLinkValueKey] fromIDField:fromIDField forObject:nil popUpLocation:mouseLocation_];
    }
    
    return YES;
}

#pragma mark Gesture Support
- (BOOL)threadView:(CMRThreadView *)aView swipeWithEvent:(NSEvent *)theEvent
{
	CGFloat dX = [theEvent deltaX];
    CGFloat dY = [theEvent deltaY];

	if (dX > 0) { // 右から左へスワイプ
        [self historyMenuPerformBack:aView];
	} else if (dX < 0) { // 左から右へスワイプ
        [self historyMenuPerformForward:aView];
	}

    if (dY != 0) { // 上下いずれかにスワイプ
        [self reply:aView];
    }

    return YES;
}

- (void)threadView:(CMRThreadView *)aView magnifyEnough:(CGFloat)additionalScaleFactor
{
    if (additionalScaleFactor > 0.5) {
        [self biggerText:self];
    } else if (additionalScaleFactor < -0.5) {
        [self smallerText:self];
    }
}

- (void)view:(NSView *)aView rotateEnough:(CGFloat)rotatedDegree
{
    BSTitleRulerView *ruler = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];
    
    [ruler setCurrentMode:[[self class] rulerModeForInformDatOchi]];
    [ruler setInfoStr:[self localizedString:@"titleRuler info rotate gesture title"]];
    [[self scrollView] setRulersVisible:YES];
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(cleanUpTitleRuler:) userInfo:nil repeats:NO];
}

- (void)view:(NSView *)aView didFinishRotating:(CGFloat)rotatedDegree
{
    [self reloadThread:self];
}
    
- (BOOL)acceptsFirstResponderForView:(CMRThreadView *)aView
{
    return [self shouldShowContents];
}

#pragma mark SGHTMLView delegate
- (NSArray *)HTMLViewFilteringLinkSchemes:(SGHTMLView *)aView
{
	// "cmonar:", "mailto:", "cmbe:", "sssp:" をフィルタ
	static NSArray *cachedLinkSchemes = nil;
	if (!cachedLinkSchemes) {
		cachedLinkSchemes = [[NSArray alloc] initWithObjects:CMRAttributeInnerLinkScheme, CMRAttributesBeProfileLinkScheme, @"mailto", BSSsspLinkScheme, nil];
	}
	return cachedLinkSchemes;
}

- (void)HTMLView:(SGHTMLView *)aView mouseEnteredInTrackingArea:(NSTrackingArea *)area withEvent:(NSEvent *)anEvent
{
    NSRect aRect = [area rect];
	NSPoint location_;
    NSString *attributeName = [[area userInfo] objectForKey:SGHTMLViewLinkUserDataAttributeNameKey];
	
	location_ = NSEqualRects(aRect, NSZeroRect) ? [anEvent locationInWindow] : aRect.origin;
	location_ = [aView convertPoint:location_ toView:nil];
    location_ = [[aView window] convertRectToScreen:NSMakeRect(location_.x, location_.y, 0, 0)].origin;
	location_.y -= 1.0f;
    
    if ([attributeName isEqualToString:NSLinkAttributeName]) {
        [self tryShowPopUpWindowWithLink:[[area userInfo] objectForKey:SGHTMLViewLinkUserDataLinkValueKey] forObject:[area userInfo] locationHint:location_];
    } else if ([attributeName isEqualToString:BSMessageReferencedCountAttributeName] && ([CMRPref popupTriggerType] == BSPopupByMouseOver)) {
        [self threadView:(CMRThreadView *)aView reverseAnchorPopUp:[[[area userInfo] objectForKey:SGHTMLViewLinkUserDataLinkValueKey] unsignedIntegerValue] forObject:[area userInfo] locationHint:location_];
    } else if ([attributeName isEqualToString:BSMessageIDAttributeName] && ([CMRPref popupTriggerType] == BSPopupByMouseOver)) {
        id boolObj = [[area userInfo] objectForKey:SGHTMLViewLinkUserDataFieldHintKey];
        BOOL fromIDField = boolObj ? [boolObj boolValue] : YES;
        [self extractMessagesWithIDString:[[area userInfo] objectForKey:SGHTMLViewLinkUserDataLinkValueKey] fromIDField:fromIDField forObject:[area userInfo] popUpLocation:location_];
    }
}

- (void)HTMLView:(SGHTMLView *)aView mouseExitedFromTrackingArea:(NSTrackingArea *)area withEvent:(NSEvent *)anEvent
{
    // TODO Enter 側の対応必要
    [CMRPopUpMgr performClosePopUpWindowForObject:[area userInfo]];
}

// continuous mouseDown
- (BOOL)HTMLView:(SGHTMLView *)aView shouldHandleContinuousMouseDown:(NSEvent *)theEvent
{
	NSRange		selectedRange_;
	id			v;
	unichar		c;
	NSPoint		mouseLocation_;

	// ID ポップアップ
	mouseLocation_ = [aView convertPoint:[theEvent locationInWindow] fromView:nil];

	v = [aView attribute:BSMessageIDAttributeName atPoint:mouseLocation_ effectiveRange:NULL];

	if (v) return ([CMRPref popupTriggerType] == BSPopupByContinuousMouseDown); // 長押しトリガーの場合のみポップアップさせる

    // 逆参照ポップアップ
    v = [aView attribute:BSMessageReferencedCountAttributeName atPoint:mouseLocation_ effectiveRange:NULL];
    
    if (v) return ([CMRPref popupTriggerType] == BSPopupByContinuousMouseDown); // 長押しトリガーの場合のみポップアップさせる

	selectedRange_ = [aView selectedRange];
	if (0 == selectedRange_.length) return NO;

	// レス番号ではポップアップしない
	v = [[aView textStorage] attribute:CMRMessageIndexAttributeName 
							   atIndex:selectedRange_.location
						effectiveRange:NULL];
	if (v) return NO;
	
	c = [[aView string] characterAtIndex:selectedRange_.location];
	return [[NSCharacterSet numberCharacterSet_JP] characterIsMember:c];
}

- (BOOL)HTMLView:(SGHTMLView *)aView continuousMouseDown:(NSEvent *)theEvent
{
	NSPoint	mouseLoc_;
	BOOL	isInside_;
	id		value;
	
	UTILRequireCondition((aView && theEvent), default_implementation);

	mouseLoc_ = (NSPeriodic == [theEvent type])
		? [[aView window] convertScreenToBase:[theEvent locationInWindow]]
		: [theEvent locationInWindow];
	mouseLoc_ = [aView convertPoint:mouseLoc_ fromView:nil];
//	isInside_ = [aView mouse:mouseLoc_ inRect:[aView visibleRect]];
	
	value = [aView attribute:BSMessageIDAttributeName atPoint:mouseLoc_ effectiveRange:NULL];

	if (value) {
		// ID PopUp
        id value2 = [aView attribute:BSMessageKeyAttributeName atPoint:mouseLoc_ effectiveRange:NULL];
        [self extractMessagesWithIDString:(NSString *)value fromIDField:([value2 isEqualToString:BSMessageKeyAttributeIDField]) forObject:nil popUpLocation:[theEvent locationInWindow]];
    } else if ((value = [aView attribute:BSMessageReferencedCountAttributeName atPoint:mouseLoc_ effectiveRange:NULL])) {
        // 逆参照ポップアップ
        [self threadView:(CMRThreadView *)aView reverseAnchorPopUp:[(NSNumber *)value unsignedIntegerValue] locationHint:[theEvent locationInWindow]];
	} else {
		NSRange				selectedRange_;
		NSLayoutManager		*layoutManager_;
		NSRange				selectedGlyphRange_;
		NSRect				selection_;

		selectedRange_ = [aView selectedRange];
		UTILRequireCondition(selectedRange_.length, default_implementation);
		
		layoutManager_ = [aView layoutManager];
		UTILRequireCondition(layoutManager_, default_implementation);
		
		selectedGlyphRange_ = 
			[layoutManager_ glyphRangeForCharacterRange:selectedRange_
								   actualCharacterRange:NULL];
		UTILRequireCondition(selectedGlyphRange_.length, default_implementation);
		selection_ = 
			[layoutManager_ boundingRectForGlyphRange:selectedGlyphRange_
									  inTextContainer:[aView textContainer]];
		isInside_ = [aView mouse:mouseLoc_ inRect:selection_];
//		UTILRequireCondition(isInside_, default_implementation);
        // 暫定
        if (!isInside_) {
            //            return ([CMRPref mouseDownTrackingTime] > 0);
            return ([CMRPref popupTriggerType] == BSPopupByContinuousMouseDown);
        }

		mouseLoc_.y = [aView isFlipped] 
						? NSMinY(selection_)
						: NSMaxY(selection_);
		mouseLoc_ = [aView convertPoint:mouseLoc_ toView:nil];
        mouseLoc_ = [[aView window] convertRectToScreen:NSMakeRect(mouseLoc_.x, mouseLoc_.y, 0, 0)].origin;

		// テキストのドラッグを許すように、ここでは常にNOを返す。
		[self tryShowPopUpWindowSubstringWithRange:selectedRange_
									 inTextStorage:[aView textStorage]
									  locationHint:mouseLoc_];
	}
	return NO;
	
default_implementation:
	return YES;
}
@end
