//
//  CMRAppDelegate.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/19.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAppDelegate_p.h"
#import "BoardWarrior.h"
#import "CMRBrowser.h"
#import "BoardListItem.h"
#import "CMRDocumentController.h"
#import "TS2SoftwareUpdate.h"
#import "CMRDocumentController.h"
#import "BSDateFormatter.h"
#import "DatabaseManager.h"
#import "CookieManager.h"
#import "BSTGrepClientWindowController.h"
#import "BSAppResetPanelController.h"
#import "BSSSSPIconManager.h"
#import "BSIntroWindowController.h"

static NSString *const kOnlineItemKey = @"On Line";
static NSString *const kOfflineItemKey = @"Off Line";

static NSString *const kWhatsNewHelpAnchorKey = @"WhatsNewHelpAnchor";

static NSString *const kSWCheckURLKey = @"System - Software Update Check URL";
static NSString *const kSWDownloadURLKey = @"System - Software Update Download Page URL";

NSString *const CMRAppDelegateWakeFromSleepNotification = @"jp.tsawada2.BathyScaphe.CMRAppDelegateWakeFromSleepNotification";

@interface CMRAppDelegate()
@property(nonatomic, strong) BSIntroWindowController *introWindowController;
@end

@implementation CMRAppDelegate
@synthesize introWindowController = m_introWinController;

- (void)awakeFromNib
{
    [self setupMenu];
}

- (NSString *)threadPath
{
	return m_threadPath;
}

- (void)setThreadPath:(NSString *)aString
{
	[aString retain];
	[m_threadPath release];
	m_threadPath = aString;
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [m_introWinController release];
	[m_threadPath release];
	[super dealloc];
}

#pragma mark Hoge
- (BOOL)diagInternetConnection
{
    // オフラインモードの場合は何もしない
    if (![CMRPref isOnlineMode]) {
        return NO;
    }
    // インターネット接続できていれば YES、そうでなければ NO
    NSURL *url = [NSURL URLWithString:@"http://www.2ch.net/"];
    CFNetDiagnosticRef diagRef = CFNetDiagnosticCreateWithURL(kCFAllocatorDefault, (CFURLRef)url);
    CFNetDiagnosticStatus status = CFNetDiagnosticCopyNetworkStatusPassively(diagRef, NULL);
    CFRelease(diagRef);
    
    return (status == kCFNetDiagnosticConnectionUp);
}

- (void)timerFire:(NSTimer *)aTimer
{
    // タイマーカウントを増やす
    retryCount++;
    
    if ([self diagInternetConnection] || retryCount > 6) {
        // タイマー無効化
        [aTimer invalidate];
        // タイマーカウントを 0 にする
        retryCount = 0;
        
        // リロード用 Notification を発行する
        [[NSNotificationCenter defaultCenter] postNotificationName:CMRAppDelegateWakeFromSleepNotification object:self];
    }
}

- (void)didWakeFromSleep:(NSNotification *)aNotification
{
    // タイマーカウントが 0 でなかったなら
    if (retryCount != 0) {
    // タイマーカウントを 0 にする
        retryCount = 0;
    }
    // そうでなければ
    else
    // 1秒後にタイマー起動、繰り返し
    {
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    }
}

#pragma mark IBAction
- (IBAction)checkForUpdate:(id)sender
{
	[[TS2SoftwareUpdate sharedInstance] startUpdateCheck:sender];
}

- (IBAction)showPreferencesPane:(id)sender
{
	[NSApp sendAction:@selector(showWindow:) to:[CMRPref sharedPreferencesPane] from:sender];
    isPrefOpen = YES;
}

- (IBAction)toggleOnlineMode:(id)sender
{   
	[CMRPref setIsOnlineMode:(![CMRPref isOnlineMode])];
}

- (IBAction)resetApplication:(id)sender
{
    BSAppResetPanelController *resetController = [[BSAppResetPanelController alloc] init];
    NSWindow *window = [resetController window];
    NSInteger returnCode = [NSApp runModalForWindow:window];
    NSUInteger mask = [CMRPref appResetTargetMask];
    [window orderOut:self];

    if (returnCode == NSOKButton) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInteger:mask] forKey:@"targetMask"];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc postNotificationName:CMRApplicationWillResetNotification object:self userInfo:userInfo];
        
        if (mask & BSAppResetCookie) {
            [[CookieManager defaultManager] removeAllCookies];
        }
        if (mask & BSAppResetCache) {
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
            [[BSSSSPIconManager defaultManager] removeAllCachedIcons];
        }
        if (mask & BSAppResetHistory) {
            [[CMRHistoryManager defaultManager] removeAllItems];
        }
        if (mask & BSAppResetWindow) {
            [self closeAll:self];
        }
        if (mask & BSAppResetPreviewer) {
            [NSApp sendAction:@selector(resetPreviewer:) to:[CMRPref sharedLinkPreviewer] from:sender];
        }

		[nc postNotificationName:CMRApplicationDidResetNotification object:self userInfo:userInfo];
    }
    [resetController release];
}

- (IBAction)customizeTextTemplates:(id)sender
{
	[[CMRPref sharedPreferencesPane] showSubpaneWithIdentifier:PPReplyTemplatesSubpaneIdentifier atPaneIdentifier:PPReplyDefaultIdentifier];
}

- (IBAction)togglePreviewPanel:(id)sender
{
    id previewer = [CMRPref sharedLinkPreviewer];
    if (!previewer) {
        return;
    }
	[NSApp sendAction:@selector(togglePreviewPanel:) to:previewer from:sender];
}

- (IBAction)showPluginSettings:(id)sender
{
    id previewer = [CMRPref sharedLinkPreviewer];
    if (!previewer) {
        return;
    }
	[NSApp sendAction:@selector(showPreviewerPreferences:) to:previewer from:sender];
}

- (IBAction)showTaskInfoPanel:(id)sender
{
    [[CMRTaskManager defaultManager] showWindow:sender];
}

- (IBAction)showTGrepClientWindow:(id)sender
{
    [[BSTGrepClientWindowController sharedInstance] showWindow:sender];
}

// For Help Menu
- (IBAction)openURL:(id)sender
{
    NSURL *url;
    
    UTILAssertRespondsTo(sender, @selector(representedObject));
    if ((url = [sender representedObject])) {
        UTILAssertKindOfClass(url, NSURL);
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (IBAction)showIntroWindow:(id)sender
{
    if (!self.introWindowController) {
        BSIntroWindowController *controller = [[BSIntroWindowController alloc] initWithWindowNibName:@"BSIntroPanel"];
        self.introWindowController = controller;
        [controller release];
    }

    [[self.introWindowController window] center];
    [self.introWindowController showWindow:sender];
}

- (IBAction)showQuickStart:(id)sender
{
    NSBundle	*mainBundle;
    NSString	*fileName;
    NSString	*appName;
    NSWorkspace	*ws = [NSWorkspace sharedWorkspace];
    
    mainBundle = [NSBundle mainBundle];
    fileName = [mainBundle pathForResource:@"quickstartguide" ofType:@"pdf"];
    appName = [ws absolutePathForAppBundleWithIdentifier:@"com.apple.Preview"];
    
    [ws openFile:fileName withApplication:appName];
}

- (IBAction)showWhatsnew:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:[self localizedString:kWhatsNewHelpAnchorKey] inBook:[NSBundle applicationHelpBookName]];
}

- (IBAction)showAcknowledgment:(id)sender
{
	NSBundle	*mainBundle;
    NSString	*fileName;
	NSString	*appName;
	NSWorkspace	*ws = [NSWorkspace sharedWorkspace];

    mainBundle = [NSBundle mainBundle];
    fileName = [mainBundle pathForResource:@"Acknowledgments" ofType:@"rtf"];
	appName = [ws absolutePathForAppBundleWithIdentifier:@"com.apple.TextEdit"];
	
    [ws openFile:fileName withApplication:appName];
}

- (IBAction)openURLPanel:(id)sender
{
	if (![NSApp isActive]) [NSApp activateIgnoringOtherApps:YES];
	[[CMROpenURLManager defaultManager] askUserURL];
}

- (IBAction)closeAll:(id)sender
{
	NSArray *allWindows = [NSApp windows];
	if (!allWindows) return;
	NSEnumerator	*iter = [allWindows objectEnumerator];
	NSWindow		*window;
	while (window = [iter nextObject]) {
		if ([window isVisible] && ![window isSheet]) {
			[window performClose:sender];
		}
	}
}

- (IBAction)clearHistory:(id)sender
{
	[[CMRHistoryManager defaultManager] removeAllItems];
}

- (IBAction)showThreadFromHistoryMenu:(id)sender
{
	UTILAssertRespondsTo(sender, @selector(representedObject));
    [[CMRDocumentController sharedDocumentController] showDocumentWithHistoryItem:[sender representedObject]];
}

- (IBAction)showBoardFromHistoryMenu:(id)sender
{
    UTILAssertRespondsTo(sender, @selector(representedObject));

	BoardListItem *boardListItem = [sender representedObject];
	if (boardListItem && [boardListItem respondsToSelector: @selector(representName)]) {
		[self showThreadsListForBoard:[boardListItem representName] selectThread:nil addToListIfNeeded:YES];
	}
}

- (IBAction)startHEADCheckDirectly:(id)sender
{
	BOOL	hasBeenOnline = [CMRPref isOnlineMode];

	// 簡単のため、いったんオンラインモードを切る
	if (hasBeenOnline) [self toggleOnlineMode:sender];
	
	[self showThreadsListForBoard:CMXFavoritesDirectoryName selectThread:nil addToListIfNeeded:NO];
	[CMRMainBrowser reloadThreadsList:sender];

	// 必要ならオンラインに復帰
	if (hasBeenOnline) [self toggleOnlineMode:sender];
}

- (IBAction)runBoardWarrior:(id)sender
{
	[[BoardWarrior warrior] syncBoardLists];
}

- (IBAction)openAEDictionary:(id)sender
{
	NSString *selfPath = [[NSBundle mainBundle] bundlePath];
	NSString *toysPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.apple.ScriptEditor2"];
	if (selfPath && toysPath) {
		[[NSWorkspace sharedWorkspace] openFile:selfPath withApplication:toysPath];
	}
}

- (void)mainBrowserDidFinishShowThList:(NSNotification *)aNotification
{
	UTILAssertNotificationName(
		aNotification,
		CMRBrowserThListUpdateDelegateTaskDidFinishNotification);

	[CMRMainBrowser selectRowWithThreadPath:[self threadPath]
					   byExtendingSelection:NO
							scrollToVisible:YES];

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:CMRBrowserThListUpdateDelegateTaskDidFinishNotification
												  object:CMRMainBrowser];
}

- (void)showThreadsListForBoard:(NSString *)boardName selectThread:(NSString *)path addToListIfNeeded:(BOOL)addToList
{
	if (CMRMainBrowser) {
		[CMRMainBrowser showWindow:self];
	} else {
		[[CMRDocumentController sharedDocumentController] newDocument:self];
	}

	if (path) {
		[self setThreadPath:path];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(mainBrowserDidFinishShowThList:)
													 name:CMRBrowserThListUpdateDelegateTaskDidFinishNotification
												   object:CMRMainBrowser];
	}
	// addBrdToUsrListIfNeeded オプションは当面の間無視（常に YES 扱いで）
	[CMRMainBrowser selectRowOfName:boardName forceReload:NO]; // この結果として outlineView の selectionDidChange: が「確実に」
													 // 呼び出される限り、そこから showThreadsListForBoardName: が呼び出される
}

- (IBAction)openWebSiteForUpdate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:SGTemplateResource(kSWDownloadURLKey)]];
}

#pragma mark Validation
- (BOOL)validateNSControlToolbarItem:(NSToolbarItem *)item
{
	SEL action = [(NSControl *)[item view] action];
	if (action == @selector(toggleOnlineMode:)) {
		BOOL			isOnline = [CMRPref isOnlineMode];
		NSString		*title_;
		
		title_ = isOnline ? [self localizedString:kOnlineItemKey] : [self localizedString:kOfflineItemKey];
		
		[(NSButton *)[item view] setState:(isOnline ? NSOnState : NSOffState)];
		[item setLabel:title_];
		return YES;
	}
	return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)theItem
{
	SEL action_ = [theItem action];

	if (action_ == @selector(closeAll:)) {
		return ([NSApp makeWindowsPerform:@selector(isVisible) inOrder:YES] != nil);
	} else if (action_ == @selector(togglePreviewPanel:)) {
        id newPreviewer = [CMRPref sharedLinkPreviewer];
        return [newPreviewer respondsToSelector:@selector(togglePreviewPanel:)];
	} else if (action_ == @selector(startHEADCheckDirectly:)) {
		return YES;
	} else if (action_ == @selector(toggleOnlineMode:)) {
		[theItem setState:[CMRPref isOnlineMode] ? NSOnState : NSOffState];
		return YES;
	}
	return YES;
}

#pragma mark NSAlert delegate
- (BOOL)alertShowHelp:(NSAlert *)alert
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[alert helpAnchor] inBook:[NSBundle applicationHelpBookName]];
	return YES;
}

#pragma mark NSApplication Delegates
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	BSStringFromDateTransformer *transformer;
	NSAppleEventManager	*aeMgr = [NSAppleEventManager sharedAppleEventManager];

	[aeMgr setEventHandler:[CMROpenURLManager defaultManager]
			   andSelector:@selector(handleGetURLEvent:withReplyEvent:)
			 forEventClass:'GURL'
				andEventID:'GURL'];

	TS2SoftwareUpdate *checker = [TS2SoftwareUpdate sharedInstance];
	[checker setUpdateInfoURL:[NSURL URLWithString:SGTemplateResource(kSWCheckURLKey)]];
	[checker setUpdateNowSelector:@selector(openWebSiteForUpdate:)];
    
	transformer = [[[BSStringFromDateTransformer alloc] init] autorelease];
	[NSValueTransformer setValueTransformer:transformer forName:@"BSStringFromDateTransformer"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	AppDefaults *defaults_ = CMRPref;

    [[BSDateFormatter sharedDateFormatter] setUsesRelativeDateFormat:[CMRPref usesRelativeDateFormat]];

    /* Service menu */
    [NSApp setServicesProvider:[CMROpenURLManager defaultManager]];

	/* Remove Debug menu if needed */
    [[CMRMainMenuManager defaultManager] removeDebugMenuItemIfNeeded];

    if (![defaults_ invalidSortDescriptorFixed]) {
        [self fixInvalidSortDescriptors];
    }

    if (![defaults_ invalidBoardDataRemoved]) {
        [self removeInfoServerData];
    }
    
    if (![defaults_ noNameEntityReferenceConverted]) {
        [self fixUnconvertedNoNameEntityReference];
    }
	
	// load principal link previewer. BathyScaphe 2.4
	[defaults_ installedPreviewerBundle];

    /* Software Update */
    [TS2SoftwareUpdate setShowsDebugLog:[[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]];
	if ([defaults_ isOnlineMode]) {
        [[TS2SoftwareUpdate sharedInstance] startUpdateCheck:nil];
    }
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(didWakeFromSleep:) name:NSWorkspaceDidWakeNotification object:[NSWorkspace sharedWorkspace]];
    
    /* ようこそ */
    if (![defaults_ isIntroShown]) {
        [self performSelector:@selector(showIntroWindow:) withObject:self afterDelay:1.0]; // 少し遅らせる
        [defaults_ setIntroShown:YES];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    if (!isPrefOpen) {
        return NSTerminateNow;
    } else {
        [[CMRPref sharedPreferencesPane] forceSaveChanges];
        isPrefOpen = NO;
        [sender replyToApplicationShouldTerminate:YES];
        return NSTerminateLater;
    }
}
@end


@implementation CMRAppDelegate(CMRLocalizableStringsOwner)
+ (NSString *)localizableStringsTableName
{
    return APP_MAINMENU_LOCALIZABLE_FILE_NAME;
}
@end
