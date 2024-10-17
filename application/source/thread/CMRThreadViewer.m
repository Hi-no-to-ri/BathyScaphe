//
//  CMRThreadViewer.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/24.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"

#import "CMRThreadLayout.h"
#import "CMR2chDATReader.h"
#import "CMRThreadMessageBuffer.h"
#import "CMXPopUpWindowManager.h"
#import "BoardManager.h"
#import "CMRThreadPlistComposer.h"
#import "CMRNetGrobalLock.h"    // for Locking
#import "missing.h"
#import "BSAddNGExWindowController.h"
#import "BSThreadComposingOperation.h"
#import "BSThreadFileLoadingOperation.h"
#import "CMRAppDelegate.h"
#import <SGAppKit/BSTitleRulerView.h>

// for debugging only
#define UTIL_DEBUGGING		1
#import "UTILDebugging.h"

NSString *const CMRThreadViewerDidChangeThreadNotification  = @"CMRThreadViewerDidChangeThreadNotification";
NSString *const CMRThreadViewerRunSpamFilterNotification = @"CMRThreadViewerRunSpamFilterNotification";
NSString *const BSThreadViewerWillStartFindingNotification = @"BSThreadViewerWillStartFindingNotification";
NSString *const BSThreadViewerDidEndFindingNotification = @"BSThreadViewerDidEndFindingNotification";


@implementation CMRThreadViewer
@synthesize shouldResetScaling = m_shouldResetScaling;
- (id)init
{
	if (self = [super initWithWindowNibName:[self windowNibName]]) {
		[self setInvalidate:NO];
		[self setChangeThemeTaskIsInProgress:NO];
        
        m_shouldResetScaling = NO;

		if (![self loadComponents]) {
			[self release];
			return nil;
		}

		[self registerToNotificationCenter];
        [self addMessenger:nil];
		[self setShouldCascadeWindows:NO];
	}
	return self;
}

- (void)dealloc
{
	[CMRPopUpMgr closePopUpWindowForOwner:self];
    id delegate = [[self textView] delegate];
    if (delegate == self) {
        [[self textView] setDelegate:nil];
    }
	[[NSNotificationCenter defaultCenter] removeObserver:self];

//    [m_findBarViewController release];
    [m_addNGExWindowController release];
    [m_indexPanelController release];
    [m_passer release];
	[m_componentsView release];
	[m_undo release];
	[_layout release];
	[_history release];
	[super dealloc];
}

- (NSString *)windowNibName
{
	return @"CMRThreadViewer";
}

- (NSString *)titleForTitleBar
{
	NSString *bName_ = [self boardName];
	NSString *tTitle_ = [self title];

	if (!bName_ || !tTitle_) return nil;
	
	return [NSString stringWithFormat:@"%@ %C %@", tTitle_, (unichar)0x2014, bName_];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	NSString *alternateName = [self titleForTitleBar];

	return (alternateName ? alternateName : displayName);
}

- (void)document:(NSDocument *)aDocument willRemoveController:(NSWindowController *)aController
{
	if ([self document] != aDocument || self != (id)aController) {
        return;
	}
	[self removeFromNotificationCenter];
	[self removeMessenger:nil];
	[CMRPopUpMgr closePopUpWindowForOwner:self];

	[self disposeThreadAttributes];
	[[self threadLayout] disposeLayoutContext];
}

- (void)closeWindowOfAlert:(NSAlert *)alert downloaderFilePath:(NSString *)path
{
    [[alert window] orderOut:nil]; 
    [[self window] performClose:nil];
}

#pragma mark NSWindowRestoration
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeInt:m_scaleCount forKey:@"BS_TextViewScaleCount"];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];
    m_scaleCount = [coder decodeIntForKey:@"BS_TextViewScaleCount"];
    if (m_scaleCount != 0) {
        self.shouldResetScaling = YES;
    }
}

#pragma mark Loading Thread
static NSDictionary *boardInfoWithFilepath(NSString *filepath)
{
	NSString				*dat_;
	NSString				*bname_;
	CMRDocumentFileManager	*dFM_ = [CMRDocumentFileManager defaultManager];
	
	bname_ = [dFM_ boardNameWithLogPath:filepath];
	dat_ = [dFM_ datIdentifierWithLogPath:filepath];
	
	UTILCAssertNotNil(bname_);
	UTILCAssertNotNil(dat_);
	
	return [NSDictionary dictionaryWithObjectsAndKeys:bname_, ThreadPlistBoardNameKey, dat_, ThreadPlistIdentifierKey, nil];
}

- (void)setThreadContentWithThreadIdentifier:(id)aThreadIdentifier noteHistoryList:(NSInteger)relativeIndex
{
    NSString		*documentPath;
	NSURL			*fileURL;
	NSDocument		*document;

    if (![aThreadIdentifier isKindOfClass:[CMRThreadSignature class]]) return;
    
    if ([[self threadIdentifier] isEqual:aThreadIdentifier]) return;
    
    if (![aThreadIdentifier boardName]) return;
	
	documentPath = [aThreadIdentifier threadDocumentPath];
	fileURL = [NSURL fileURLWithPath:documentPath];	
	document = [[CMRDocumentController sharedDocumentController] documentAlreadyOpenForURL:fileURL];

	if (document) {
		[document showWindows];
		return;
	} else {
		NSDictionary	*boardInfo;	
		boardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[aThreadIdentifier boardName], ThreadPlistBoardNameKey,
															   [aThreadIdentifier identifier], ThreadPlistIdentifierKey, NULL];

		[self setThreadContentWithFilePath:documentPath boardInfo:boardInfo noteHistoryList:relativeIndex];
	}
}

- (void)setThreadContentWithFilePath:(NSString *)filepath boardInfo:(NSDictionary *)boardInfo noteHistoryList:(NSInteger)relativeIndex
{
	CMRThreadAttributes		*attrs_;
	
	// Browserの場合、スレッド表示部分を閉じていた場合は
	// スレッドをいちいち読み込まない。
	if (![self shouldShowContents]) return;

	if (!boardInfo || [boardInfo count] == 0) {
		boardInfo = boardInfoWithFilepath(filepath);
	}
	// 
	// loadFromContentsOfFile:で現在表示している内容は
	// 消去されるので、最後に読んだレス番号などはここで保存しておく。
	// 新しいCMRThreadAttributesを登録するとthreadWillCloseが呼ばれ、
	// 属性を書き戻す（＜かなり無駄）。
	// 
	attrs_ = [[CMRThreadAttributes alloc] initWithDictionary:boardInfo];
	[self setThreadAttributes:attrs_];
	[attrs_ release];
	
	// 自身の管理する履歴に登録、または移動
	[self noteHistoryThreadChanged:relativeIndex];
	[self loadFromContentsOfFile:filepath];
}

- (void)setThreadContentWithThreadIdentifier:(id)aThreadIdentifier
{
    [self setThreadContentWithThreadIdentifier:aThreadIdentifier noteHistoryList:0];
}

- (void)setThreadContentWithFilePath:(NSString *)filepath boardInfo:(NSDictionary *)boardInfo
{
    [self setThreadContentWithFilePath:filepath boardInfo:boardInfo noteHistoryList:0];
}

- (void)fileNotExistsAutoReloadIfNeeded
{
	if (![[self window] isVisible]) {
        [self showWindow:self];
    }

	[self didChangeThread];
	[[self threadLayout] clear];
	[self reloadIfOnlineMode:self];
}

- (void)loadFromContentsOfFile:(NSString *)filepath
{
	SGFileRef			*fileRef_;
	NSString			*actualPath_;
	
	fileRef_ = [SGFileRef fileRefWithPath:filepath];
	actualPath_ = [fileRef_ pathContentResolvingLinkIfNeeded];
	
	// 
	// ファイル参照は存在しないファイルには作られない
	// 
	if (!actualPath_) {
//		NSLog(@"actualPath check -- FILE NOT EXISTS");
		[self fileNotExistsAutoReloadIfNeeded];
	} else {
//		NSLog(@"actualPath check -- FILE DOES EXIST");

		[[self threadLayout] clear];

        BSThreadFileLoadingOperation *operation;
        operation = [[BSThreadFileLoadingOperation alloc] initWithURL:[NSURL fileURLWithPath:actualPath_]];
        operation.signature = [self threadIdentifier];
        operation.delegate = self;
        operation.countedSet = [[self threadLayout] countedSet];
        operation.reverseReferencesCountedSet = [[self threadLayout] reverseReferencesCountedSet];
        
        operation.referenceMarkerEnabled = [CMRPref showsReferencedMarker];
        [operation setCompletionBlock:^{
            [self performSelectorOnMainThread:@selector(threadComposingDidFinish:) withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
        }];
        
        [[CMRTaskManager defaultManager] taskWillStart:operation];
		
        [[self threadLayout] addOperation:operation];
        [operation release];
	}
}

- (void)mergeComposedResult:(BSThreadComposingOperation *)operation
{
    [[CMRTaskManager defaultManager] taskDidFinish:operation];
    [self setInvalidate:YES];

    if ([operation isCancelled]) {
        return;
    }

    [[self threadLayout] mergeComposingResult:operation];
    
    if ([operation isCancelled]) {
        return;
    }

    [[self threadLayout] appendComposingAttrString:operation];
    [self setInvalidate:NO];
}

- (void)didChangeThread
{
	UTILNotifyName(CMRThreadViewerDidChangeThreadNotification);
}

- (void)pushComposingTaskWithThreadReader:(CMRThreadContentsReader *)aReader
{
    BSThreadComposingOperation *operation;
	
    operation = [[BSThreadComposingOperation alloc] initWithThreadReader:aReader];

    operation.signature = [self threadIdentifier];
    operation.countedSet = [[self threadLayout] countedSet];
    operation.reverseReferencesCountedSet = [[self threadLayout] reverseReferencesCountedSet];
    operation.delegate = self;

    operation.spamJudgeEnabled = [CMRPref spamFilterEnabled];
    operation.isOnAAThread = [(CMRThreadDocument *)[self document] isAAThread];
    operation.aaJudgeEnabled = ([CMRPref asciiArtDetectorEnabled] || [[BoardManager defaultManager] treatsAsciiArtAsSpamAtBoard:[self boardName]]);
    operation.referenceMarkerEnabled = [CMRPref showsReferencedMarker];
    operation.prevRefMarkerUpdateNeeded = ([[[self threadLayout] messageBuffer] count] > 0);
    [operation setCompletionBlock:^{
        [self performSelectorOnMainThread:@selector(threadComposingDidFinish:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
    }];

    [[CMRTaskManager defaultManager] taskWillStart:operation];

    [[self threadLayout] addOperation:operation];
    [operation release];
}

- (void)composeDATContents:(NSString *)datContents threadSignature:(CMRThreadSignature *)aSignature nextIndex:(NSUInteger)aNextIndex
{
    CMR2chDATReader *reader;
    NSUInteger         nMessages;
	CMRThreadLayout	*layout_ = [self threadLayout];
    
    // can't process by downloader while viewer execute.
    [[CMRNetGrobalLock sharedInstance] add:aSignature];
    
    nMessages = [layout_ numberOfReadedMessages];
    // check unexpected contetns
    if (![[self threadIdentifier] isEqual:aSignature]) {
        NSLog(@"Unexpected contents:\n"
            @"  thread:  %@\n"
            @"  arrived: %@", [self threadIdentifier], aSignature);
        return;
    }
	// 2005-11-26 様子見中
    if ((aNextIndex != nMessages) && (aNextIndex != NSNotFound)) {
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 修正済
        NSLog(@"Unexpected sequence:\n"
            @"  expected: %lu\n"
            @"  arrived:  %lu", (unsigned long)nMessages, (unsigned long)aNextIndex);
        if ((aNextIndex == 0) && ([datContents length] > 0)) {
            // 高速更新連打対策。aNextIndex != nMessages でも aNextIndex == 0 の場合は許容する
            // （なぜか aNextIndex == 0 になってしまうことがある）
            aNextIndex = nMessages;
        } else {
            return;
        }
    }
    
    reader = [CMR2chDATReader readerWithContents:datContents];
    if (!reader) return;
    [reader setNextMessageIndex:aNextIndex];

    // updates title, created date, etc...
    if ([[self threadAttributes] needsToBeUpdatedFromLoadedContents]) {
        [[self threadAttributes] addEntriesFromDictionary:[reader threadAttributes]];
        [self addThreadTitleToHistory];
    }
    // inserts tag for new arrival messages.
    if (nMessages > 0) {
        [layout_ performSelectorOnMainThread:@selector(insertLastUpdatedHeader) withObject:nil waitUntilDone:YES];
    }
    
    [self pushComposingTaskWithThreadReader:reader];
//    [layout_ setMessagesEdited:YES];
}

- (void)threadAttributesDidLoadFromFile:(BSThreadFileLoadingOperation *)operation
{
    if ([operation isCancelled]) {
        return;
    }
    [self setInvalidate:YES];
    if ([NSThread isMainThread]) {
        NSDictionary	*attributes_;
        attributes_ = [operation attrDict];

        if (attributes_) {
            // 
            // ファイルの読み込みが終了したので、
            // 記録されていたスレッドの情報で
            // データを更新する。
            // 更に -addEntriesFromDictionary: で KVO の通知が飛んでくる。
            // また、この時点でウィンドウの領域なども設定する。
            //
            [[self threadAttributes] addEntriesFromDictionary:attributes_];
            [self synchronizeLayoutAttributes];
        }
        if (![[self window] isVisible]) {
            [self showWindow:self];
        }
        [self didChangeThread];
    } else {
        [self performSelectorOnMainThread:_cmd withObject:operation waitUntilDone:YES];
    }
    [self setInvalidate:NO];
}

- (void)threadComposingDidFinish:(id)sender
{
	NSUInteger	nReaded = NSNotFound;
	NSUInteger	nLoaded = NSNotFound;

	UTILAssertNotNil(sender);

    // remove from lock
    [[CMRNetGrobalLock sharedInstance] remove:[self threadIdentifier]];
    
    // 変な状態の時は何もしない
    if ([self isInvalidate]) { // -mergeComposedResult: で NO になっていない状態！
        return;
    }

	// レイアウトの終了
	// 読み込んだレス数を更新
	nReaded = [[self threadLayout] numberOfReadedMessages];
	nLoaded = [[self threadAttributes] numberOfLoadedMessages];
	
    if (nReaded > nLoaded)
		[[self threadAttributes] setNumberOfLoadedMessages:nReaded];
	
	// update any conditions
//	[self setInvalidate:NO];
	
    if ([sender boolValue]) {
		// 
		// ファイルからの読み込み、変換が終了
		// すでにレイアウトのタスクを開始したので、
		// オンラインモードなら更新する
		//
		[self addThreadTitleToHistory];

		[self scrollToLastReadedIndex:self]; // その前に最後に読んだ位置までスクロールさせておく

		if (![(CMRThreadDocument *)[self document] isDatOchiThread] || [self isRetrieving]) {
			if (![self changeThemeTaskIsInProgress]) {
				[self reloadIfOnlineMode:self];
			} else {
				[self performSelector:@selector(updateLayoutSettings) withObject:nil afterDelay:0.5];
				[self setChangeThemeTaskIsInProgress:NO];
			}
		}
        if ([(CMRThreadDocument *)[self document] isDatOchiThread]) {
            if ([self changeThemeTaskIsInProgress]) {
				[self performSelector:@selector(updateLayoutSettings) withObject:nil afterDelay:0.5];
				[self setChangeThemeTaskIsInProgress:NO];
			}
        }
	} else {
        if ([self isRetrieving]) {
            [self setRetrieving:NO];
        }
		if ([CMRPref scrollToLastUpdated]) {
            if ([self canScrollToLastUpdatedMessage]) {
                [self scrollToLastUpdatedIndex:self];
            }
        }
	}
    // remove from lock
//    [[CMRNetGrobalLock sharedInstance] remove:[self threadIdentifier]];


    // 明示的に全テキストのレイアウトを実行
    // これにより page up スクロール時のスクロールバーがビクンビクン！する現象が軽減。
    // ただしここでそれなりの時間はかかる。Core i7 2.66GHz で 0.3~0.7sec 程度のロス（レス数による）…
    [[self threadLayout] ensureLayoutForThreadView];

    if ((m_scaleCount != 0) && m_shouldResetScaling) {
        [self actualSizeText:self];
        self.shouldResetScaling = NO;
    }

    [[self textView] updateTrackingAreas];
	[self synchronizeWindowTitleWithDocumentName];

	// まだ名無しさんが決定していなければ決定
	// この時点では WorkerThread が動いており、
	// プログレス・バーもそのままなので少し遅らせる
	[self performSelector:@selector(setupDefaultNoNameIfNeeded) withObject:nil afterDelay:1.0];
    [self validateIndexingNavigator];
    [[self numberOfMessagesField] setStringValue:[NSString stringWithFormat:[self localizedString:@"%lu msgs"], (unsigned long)nReaded]];
    
    [[self scrollView] flashScrollers];
    
    // ID 色付け
    if ([CMRPref shouldColorIDString]) {
        [self colorizeID:[self textView]];
    }
}

- (CMRThreadLayout *)threadLayout
{
	if (!_layout) {
		_layout = [[CMRThreadLayout alloc] initWithTextView:[self textView]];
	}
	return _layout;
}

#pragma mark Detecting Nanashi-san
- (NSString *)detectDefaultNoName
{
	NSCountedSet	*nameSet;
	NSString		*name = nil;

	nameSet = [[NSCountedSet alloc] init];
    
    for (CMRThreadMessage *message in [[self threadLayout] allMessages]) {
        if ([message isAboned] || ![message name]) {
            continue;
        }
        [nameSet addObject:[message name]];
    }
	
    
    for (id item in nameSet) {
        if (!name || [nameSet countForObject:item] > [nameSet countForObject:name]) {
            name = item;
        }
    }
	
	name = [name copy];
	[nameSet release];
	
	return name ? [name autorelease] : @"";
}

- (void)setupDefaultNoNameIfNeeded
{
	BoardManager *mgr = [BoardManager defaultManager];
	NSString *board;
    BOOL manually = NO;

	board = [self boardName];
	if (!board) {
        return;
    }
	if ([mgr needToDetectNoNameForBoard:board shouldInputManually:&manually]) {
		if (![mgr startDownloadSettingTxtForBoard:board askIfOffline:YES allowToInputManually:manually] && manually) {
			[mgr askUserAboutDefaultNoNameForBoard:board presetValue:[self detectDefaultNoName]];
		}
	}
}

#pragma mark Accessors
- (BOOL)isInvalidate
{
	return _flags.invalidate != 0;
}

- (void)setInvalidate:(BOOL)flag
{
	_flags.invalidate = flag ? 1 : 0;
}

- (BOOL)changeThemeTaskIsInProgress
{
	return _flags.themechangeing != 0;
}

- (void)setChangeThemeTaskIsInProgress:(BOOL)flag
{
	_flags.themechangeing = flag ? 1 : 0;
}

- (BOOL)isRetrieving
{
    return _flags.retrieving != 0;
}

- (void)setRetrieving:(BOOL)flag
{
    _flags.retrieving = flag ? 1 : 0;
}

- (BOOL)isNotShownThreadRetrieving
{
    return _flags.browser_retrieving != 0;
}

- (void)setNotShownThreadRetrieving:(BOOL)flag
{
    _flags.browser_retrieving = flag ? 1 : 0;
}

- (CMRThreadAttributes *)threadAttributes
{
	return [(CMRThreadDocument*)[self document] threadAttributes];
}

- (id)threadIdentifier
{
	return [[self threadAttributes] threadSignature];
}

- (NSString *)path
{
	return [[self threadAttributes] path];
}
- (NSString *)title
{
	return [[self threadAttributes] threadTitle];
}
- (NSString *)boardName
{
	return [[self threadAttributes] boardName];
}

- (NSURL *)boardURL
{
	return [[self threadAttributes] boardURL];
}

- (NSURL *)threadURL
{
	return [[self threadAttributes] threadURL];
}

- (NSString *)datIdentifier
{
	return [[self threadAttributes] datIdentifier];
}

- (NSString *)bbsIdentifier
{
	return [[self threadAttributes] bbsIdentifier];
}

#pragma mark Working with CMRAbstructThreadDocument
- (void)changeAllMessageAttributesWithAAFlag:(id)flagObject
{
	UTILAssertKindOfClass(flagObject, NSNumber);
	BOOL	flag = [flagObject boolValue];
	[[self threadLayout] changeAllMessageAttributes:flag flags:CMRAsciiArtMask];
}

#pragma mark CMRThreadViewDelegate Protocol
- (void)tryToAddNGWord:(NSString *)string
{
	if (!string || [string isEmpty]) {
        return;
    }
    
	if ([string rangeOfString:@"\n" options:NSLiteralSearch].length != 0) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert setAlertStyle:NSWarningAlertStyle];
        // #warning 64BIT: Check formatting arguments
        // 2010-03-28 tsawada2 検証済
		[alert setMessageText:[NSString stringWithFormat:[self localizedString:@"Corpus Multiple Line Alert Title"],string]];
		[alert setInformativeText:[self localizedString:@"Corpus Multiple Line Alert Msg"]];
		NSBeep();
		[alert runModal];
		return;
    }
    
	[self checkIfUsesCorpusOptionOn];
    
    [[self addNGExWindowController] showAddNGExpressionSheetForWindow:[self window]
                                                      threadSignature:[self threadIdentifier]
                                                           expression:string];
}

- (void)extractUsingString:(NSString *)string
{
	if (!string || [string isEmpty]) {
        return;
    }
    
	if ([string rangeOfString:@"\n" options:NSLiteralSearch].length != 0) {
        return;
    }
	
	[self findTextByFilter:string
				searchMask:CMRSearchOptionCaseInsensitive
				targetKeys:[NSArray arrayWithObjects:@"name", @"mail", @"cachedMessage", nil]
			  locationHint:[self locationForInformationPopUp]];
}

- (void)insertReferencedMarkersForPopupContents:(NSTextView *)textView
{
    NSTextStorage *attrs = [textView textStorage];
    [attrs beginEditing];
    [[self threadLayout] insertReferencedCountStrings:attrs range:NSMakeRange(0, [attrs length]) adjustRange:NO];
    [attrs endEditing];
}

- (void)colorizeID:(NSTextView *)textView
{
    NSAttributedString *attrs = [textView textStorage];
    [[self threadLayout] colorizeIDImpl:attrs range:NSMakeRange(0, [attrs length]) layoutManager:[textView layoutManager]];
}

#pragma mark BSMessageSampleRegistrant Delegate
- (BOOL)registrant:(BSMessageSampleRegistrant *)aRegistrant shouldRegardNameAsDefaultNanashi:(NSString *)name
{
    return [[self detectDefaultNoName] isEqualToString:name];
}

- (NSUInteger)registrant:(BSMessageSampleRegistrant *)aRegistrant numberOfMessagesWithIDString:(NSString *)idString
{
    return [[[self threadLayout] countedSet] countForObject:idString];
}
@end


@implementation CMRThreadViewer(SelectingThreads)
- (NSUInteger)numberOfSelectedThreads
{
	return (![self threadAttributes]) ? 0 : 1;
}

- (NSDictionary *)selectedThread
{
	NSMutableDictionary		*dict_;
	CMRThreadAttributes		*attributes_;
	
	attributes_ = [self threadAttributes];
	if (!attributes_) return nil;
	
	dict_ = [NSMutableDictionary dictionary];
	[dict_ setNoneNil:[attributes_ threadTitle] forKey:CMRThreadTitleKey];
	[dict_ setNoneNil:[attributes_ path] forKey:CMRThreadLogFilepathKey];
	[dict_ setNoneNil:[attributes_ datIdentifier] forKey:ThreadPlistIdentifierKey];
	[dict_ setNoneNil:[attributes_ boardName] forKey:ThreadPlistBoardNameKey];
	
	return dict_;
}

- (NSArray *)selectedThreads
{
	NSDictionary	*selected_;
	
	selected_ = [self selectedThread];
	if (!selected_) return [NSArray empty];
	
	return [NSArray arrayWithObject:selected_];
}
@end


@implementation CMRThreadViewer(SaveAttributes)
- (void)threadWillClose
{
	if ([self shouldSaveThreadDataAttributes]) [self synchronize];
}

- (BOOL)synchronize
{
	NSString				*filepath_ = [self path];
	NSMutableDictionary		*mdict_;
	BOOL					attrEdited_, mesEdited_;

	[self saveWindowFrame];
	[self saveLastIndex];
	
	attrEdited_ = [[self threadAttributes] needsToUpdateLogFile];
	mesEdited_ = [[self threadLayout] isMessagesEdited];
	if (!attrEdited_ && !mesEdited_) {
		UTIL_DEBUG_WRITE(@"Not need to synchronize");
		return YES;
	}
	
	mdict_ = [NSMutableDictionary dictionaryWithContentsOfFile:filepath_];
	if (!mdict_) return NO;
	
	if (attrEdited_) {
		[[self threadAttributes] writeAttributes:mdict_];
		[[self threadAttributes] setNeedsToUpdateLogFile:NO];
	}

	if (mesEdited_) {
		NSMutableArray			*newArray_;
		CMRThreadPlistComposer	*composer_;
		CMRThreadMessageBuffer	*mBuffer_;
        //		NSEnumerator			*iter;
		//CMRThreadMessage		*m;
		
		newArray_ = [[NSMutableArray alloc] init];
		composer_ = [[CMRThreadPlistComposer alloc] initWithThreadsArray:newArray_];
		mBuffer_ = [[self threadLayout] messageBuffer];
		UTIL_DEBUG_WRITE1(@"compose messages count=%lu", (unsigned long)[mBuffer_ count]);
		
        //		iter = [[mBuffer_ messages] objectEnumerator];
		for (CMRThreadMessage *m in [mBuffer_ messages]) {
			[composer_ composeThreadMessage:m];
		}
		
		[mdict_ setObject:newArray_ forKey:ThreadPlistContentsKey];
		
		[composer_ release];
		[newArray_ release];

		[[self threadLayout] setMessagesEdited:NO];
	}
	if ([CMRPref saveThreadDocAsBinaryPlist]) {
		NSData *data_;
        data_ = [NSPropertyListSerialization dataWithPropertyList:mdict_ format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];

		if (!data_) {
            return NO;
        }
        return [data_ writeToFile:filepath_ options:NSDataWritingAtomic error:NULL];
	} else {
		return [mdict_ writeToFile:filepath_ atomically:YES];
	}
}

- (void)saveWindowFrame
{
	if (![self threadAttributes]) return;
	if (![self shouldLoadWindowFrameUsingCache]) return;
	
	[[self threadAttributes] setWindowFrame:[[self window] frame]];
}

- (void)saveLastIndex
{
	NSUInteger	idx;

	if ([CMRPref oldMessageScrollingBehavior]) {
		idx = [[self threadLayout] firstMessageIndexForDocumentVisibleRect];
	} else {
		idx = [[self threadLayout] lastMessageIndexForDocumentVisibleRect];
	}
	if ([[self threadLayout] isInProgress]) {
// #warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 修正済
		NSLog(@"*** REPORT ***\n  "
		@" Since the layout is in progress,"
		@" didn't save last readed index(%lu).", (unsigned long)idx);
		return;
	}
	[[self threadAttributes] setLastIndex:idx];
}
@end


@implementation CMRThreadViewer(NotificationPrivate)
- (NSUndoManager *)myUndoManager
{
	if (!m_undo) {
		m_undo = [[NSUndoManager alloc] init];
	}
	return m_undo;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)sender
{
	return [self myUndoManager];
}

- (void)appDefaultsLayoutSettingsUpdated:(NSNotification *)notification
{
	UTILAssertNotificationName(notification, AppDefaultsLayoutSettingsUpdatedNotification);
	UTILAssertNotificationObject(notification, CMRPref);

	if (![self textView]) return;
	[self updateLayoutSettings];

    BSTitleRulerView *view_ = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];
    NSString *path = [[self class] titleRulerAppearanceFilePath];
    UTILAssertNotNil(path);
    BSFlatTitleRulerAppearance *foo = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    [view_ setAppearance:foo];

	[[self scrollView] setNeedsDisplay:YES];
}

- (void)cleanUpItemsToBeRemoved:(NSArray *)files
{
    [[self threadLayout] clear:self];
}

- (void)threadClearTaskDidFinish:(id<CMRThreadLayoutTask>)task
{
	[self setThreadAttributes:nil];
	[[self window] invalidateCursorRectsForView:[self textView]];
	[[self textView] setNeedsDisplay:YES];
	[self validateIndexingNavigator];
    [[self numberOfMessagesField] setStringValue:@""];
}

- (void)trashDidPerformNotification:(NSNotification *)notification
{
	NSArray		*files_;
    //	NSNumber	*err_;
	
	UTILAssertNotificationName(notification, CMRTrashboxDidPerformNotification);
	UTILAssertNotificationObject(notification, [CMRTrashbox trash]);
	
/*	err_ = [[notification userInfo] objectForKey:kAppTrashUserInfoStatusKey];
	if (!err_) return;
	UTILAssertKindOfClass(err_, NSNumber);
	if ([err_ integerValue] != noErr) return;*/

	files_ = [[notification userInfo] objectForKey:kAppTrashUserInfoFilesKey];
	UTILAssertKindOfClass(files_, NSArray);
	if (![files_ containsObject:[self path]]) return;

	[self cleanUpItemsToBeRemoved:files_];
}

- (void)sleepDidEnd:(NSNotification *)aNotification
{
	if (![CMRPref isOnlineMode]) return;
    //	NSTimeInterval delay = [CMRPref delayForAutoReloadAtWaking];

	if ([CMRPref autoReloadViewerWhenWake] && [self threadAttributes]) {
        //		[self performSelector:@selector(reloadThread:) withObject:nil afterDelay:delay];
        [self reloadThread:nil];
	}
}

- (void)registerToNotificationCenter
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(appDefaultsLayoutSettingsUpdated:)
			   name:AppDefaultsLayoutSettingsUpdatedNotification
			 object:CMRPref];
	[nc addObserver:self
	       selector:@selector(trashDidPerformNotification:)
			   name:CMRTrashboxDidPerformNotification
			 object:[CMRTrashbox trash]];
	[nc addObserver:self
		   selector:@selector(threadViewerRunSpamFilter:)
			   name:CMRThreadViewerRunSpamFilterNotification
	         object:nil];
	[nc addObserver:self
		   selector:@selector(threadViewThemeDidChange:)
			   name:AppDefaultsThreadViewThemeDidChangeNotification
			 object:CMRPref];

/*	[[[NSWorkspace sharedWorkspace] notificationCenter]
	     addObserver:self
	        selector:@selector(sleepDidEnd:)
	            name:NSWorkspaceDidWakeNotification
	          object:nil];*/
    [nc addObserver:self selector:@selector(sleepDidEnd:) name:CMRAppDelegateWakeFromSleepNotification object:[NSApp delegate]];

	[super registerToNotificationCenter];
}

- (void)removeFromNotificationCenter
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

/*	[[[NSWorkspace sharedWorkspace] notificationCenter]
	  removeObserver:self
	            name:NSWorkspaceDidWakeNotification
	          object:nil];*/
    [nc removeObserver:self name:CMRAppDelegateWakeFromSleepNotification object:[NSApp delegate]];

	[nc removeObserver:self
				  name:AppDefaultsLayoutSettingsUpdatedNotification
				object:CMRPref];
	[nc removeObserver:self
				  name:CMRTrashboxDidPerformNotification
				object:[CMRTrashbox trash]];
	[nc removeObserver:self
				  name:CMRThreadViewerRunSpamFilterNotification
				object:nil];
	[nc removeObserver:self
				  name:AppDefaultsThreadViewThemeDidChangeNotification
				object:CMRPref];
	[super removeFromNotificationCenter];
}

+ (NSString *)localizableStringsTableName
{
	return APP_TVIEW_LOCALIZABLE_FILE;
}
@end
