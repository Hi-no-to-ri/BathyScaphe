//
//  CMRAppDelegate.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/16.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
@class BSIntroWindowController;

@interface CMRAppDelegate : NSObject
{
	@private
	NSString *m_threadPath;
    
    NSUInteger retryCount; // スリープ後のネットワーク接続確認回数
    BOOL isPrefOpen; // 環境設定が開いている（可能性がある）
    BSIntroWindowController *m_introWinController;
}

// Application Menu Action
- (IBAction)checkForUpdate:(id)sender;
- (IBAction)showPreferencesPane:(id)sender;
- (IBAction)toggleOnlineMode:(id)sender;
- (IBAction)resetApplication:(id)sender;

// Edit Menu Action
- (IBAction)customizeTextTemplates:(id)sender;

// Windows Menu Action
- (IBAction)togglePreviewPanel:(id)sender;
- (IBAction)showPluginSettings:(id)sender;
- (IBAction)showTaskInfoPanel:(id)sender;
- (IBAction)showTGrepClientWindow:(id)sender;

// Help Menu Action
- (IBAction)openURL:(id)sender;
- (IBAction)showIntroWindow:(id)sender;
- (IBAction)showQuickStart:(id)sender;
- (IBAction)showWhatsnew:(id)sender;
- (IBAction)showAcknowledgment:(id)sender;

// File Menu Action
- (IBAction)openURLPanel:(id)sender;
- (IBAction)closeAll:(id)sender;

// History Menu Action
- (IBAction)clearHistory:(id)sender;
- (IBAction)showThreadFromHistoryMenu:(id)sender;
- (IBAction)showBoardFromHistoryMenu:(id)sender;

// Dock menu Action
- (IBAction)startHEADCheckDirectly:(id)sender;

- (IBAction)runBoardWarrior:(id)sender;
- (IBAction)openAEDictionary:(id)sender; // Available in Twincam Angel and later.

- (void)showThreadsListForBoard:(NSString *)boardName selectThread:(NSString *)path addToListIfNeeded:(BOOL)addToList;
@end


@interface CMRAppDelegate(Util)
+ (NSArray *)defaultColumnsArray;
- (NSMenu *)browserListColumnsMenuTemplate;
@end

extern NSString *const CMRAppDelegateWakeFromSleepNotification;
