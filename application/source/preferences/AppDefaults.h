//
// AppDefaults.h
// BathyScaphe
//
// Updated by Tsutomu Sawada on 14/07/14.
// Copyright 2005-2015 BathyScaphe Project. All rights reserved.
// encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CocoMonar_Prefix.h"
#import <AppKit/NSNibDeclarations.h>

#import "BSPreferencesPaneInterface.h"
#import "BSPreviewPluginInterface.h"

@protocol w2chConnect, w2chAuthenticationStatus, be2chAuthenticationStatus, p22chAuthenticationStatus, p22chPosting;
@class BSThreadViewTheme, BoardWarrior, BSReplyTextTemplateManager;
/*!
 * @define      CMRPref
 * @discussion  グローバルな初期設定オブジェクト
 */
#define CMRPref		[AppDefaults sharedInstance]

enum {
	BSAutoSyncByWeek	= 1,
	BSAutoSyncBy2weeks	= 2,
	BSAutoSyncByMonth	= 3,
	BSAutoSyncByEveryStartUp = 11,
	BSAutoSyncEveryDay	= 12, // available in ReinforceII and later.
};
typedef NSUInteger BSAutoSyncIntervalType;

@interface AppDefaults : NSObject
{
	@private
	NSMutableDictionary		*m_backgroundColorDictionary;
	NSMutableDictionary		*m_threadsListDictionary;
	NSMutableDictionary		*m_threadViewerDictionary;
	NSMutableDictionary		*m_imagePreviewerDictionary;
	NSMutableDictionary		*_dictAppearance;
	NSMutableDictionary		*_dictFilter;
	NSMutableDictionary		*m_soundsDictionary;
	NSMutableDictionary		*m_boardWarriorDictionary;
	BSThreadViewTheme		*m_threadViewTheme;

	NSBundle *m_installedPreviewer; // Not retained.
    NSSet *m_spamHostSymbolsSet;
    
    BOOL m_isThemesInfoArrayValid;
    NSArray *m_themesInfoArray;
	
	// 頻繁にアクセスされる可能性のある変数
	struct {
		unsigned int mailAttachmentShown:1;
		unsigned int mailAddressShown:1;
		unsigned int enableAntialias:1;
		unsigned int usesLevelIndicator:1;
		unsigned int reserved:28;
	} PFlags;
}

+ (id) sharedInstance;
- (NSUserDefaults *) defaults;
- (void) postLayoutSettingsUpdateNotification;

- (BOOL) loadDefaults;
- (BOOL) saveDefaults;

// バイナリ形式でログを保存
- (BOOL)saveThreadDocAsBinaryPlist;
- (void)setSaveThreadDocAsBinaryPlist:(BOOL)flag; // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later.

//- (BOOL)disablesHistorySegCtrlMenu; // 暫定

- (BOOL) isOnlineMode;
- (void) setIsOnlineMode : (BOOL) flag;
//- (IBAction) toggleOnlineMode : (id) sender;

- (BOOL) isSplitViewVertical;
- (void) setIsSplitViewVertical : (BOOL) flag;

// スレッドを削除するときに警告しない
- (BOOL) quietDeletion;
- (void) setQuietDeletion : (BOOL) flag;
// 外部リンクをバックグラウンドで開く
- (BOOL) openInBg;
- (void) setOpenInBg : (BOOL) flag;

/* Reply Name & Mail */
- (NSString *) defaultReplyName;
- (void) setDefaultReplyName : (NSString *) name;
- (NSString *) defaultReplyMailAddress;
- (void) setDefaultReplyMailAddress : (NSString *) mail;
- (NSArray *) defaultKoteHanList;
- (void) setDefaultKoteHanList : (NSArray *) anArray;

- (NSTimeInterval)timeIntervalForNinjaFirstWait; // Available in BathyScaphe 2.0.2 and later.

// Available in BathyScaphe 2.0.2 and later.
- (BOOL)autoRetryAfterNinjaFirstWait;
- (void)setAutoRetryAfterNinjaFirstWait:(BOOL)flag;

/* Last Shown Board */
- (NSString *) browserLastBoard;
- (void) setBrowserLastBoard : (NSString *) boardName;

- (BSReplyTextTemplateManager *)RTTManager;

/* CometBlaster Additions */
- (BOOL) informWhenDetectDatOchi;
- (void) setInformWhenDetectDatOchi: (BOOL) shouldInform;

/* MeteorSweeper Additions */
//- (BOOL) moveFocusToViewerWhenShowThreadAtRow;
//- (void) setMoveFocusToViewerWhenShowThreadAtRow: (BOOL) shouldMove;

/* ReinforceII Hidden Option */
- (BOOL) oldMessageScrollingBehavior __attribute__ ((deprecated));
- (void) setOldMessageScrollingBehavior: (BOOL) flag __attribute__ ((deprecated));

/* Available in BathyScaphe 2.0.5 "Homuhomu" and later. */
- (BOOL)invalidBoardDataRemoved;
- (void)setInvalidBoardDataRemoved:(BOOL)flag;

- (NSUInteger)appResetTargetMask;
- (void)setAppResetTargetMask:(NSUInteger)mask;

/* Available in BathyScaphe 2.1 ".Invader" and later. */
- (BOOL)noNameEntityReferenceConverted;
- (void)setNoNameEntityReferenceConverted:(BOOL)flag;

- (BOOL)abondonAllReplyTextViewFeatures;
- (void)setAbondonAllReplyTextViewFeatures:(BOOL)flag;

#pragma mark ThreadsList Sorting
/* Sort */
- (BOOL)collectByNew;
- (void)setCollectByNew:(BOOL)flag;
// Available in BathyScaphe 1.6.2 and later.
- (NSArray *)threadsListSortDescriptors;
- (void)setThreadsListSortDescriptors:(NSArray *)desc;

#pragma mark Contents Search
/* Search option */
- (CMRSearchMask) contentsSearchOption;
- (void) setContentsSearchOption : (CMRSearchMask) option;

/* Starlight Breaker Additions */
- (BOOL) findPanelExpanded;
- (void) setFindPanelExpanded: (BOOL) isExpanded;
- (NSArray *) contentsSearchTargetArray;
- (void) setContentsSearchTargetArray: (NSArray *) array;

/* Final Moratorium Addition */
- (BSTGrepSearchOptionType)tGrepSearchOption;
- (void)setTGrepSearchOption:(BSTGrepSearchOptionType)tagValue;

/* Twincam Angel Additions */
//- (NSTimeInterval)delayForAutoReloadAtWaking;
//- (void)setDelayForAutoReloadAtWaking:(NSTimeInterval)doubleValue;

#pragma mark History

- (NSInteger)maxCountForThreadsHistory;
- (void)setMaxCountForThreadsHistory:(NSInteger)counts;
- (NSInteger)maxCountForBoardsHistory;
- (void)setMaxCountForBoardsHistory:(NSInteger)counts;
- (NSInteger)maxCountForSearchHistory;
- (void)setMaxCountForSearchHistory:(NSInteger)counts;

#pragma mark SQLite Semiauto vacuum
- (NSInteger)previousSQLitePageCount;
- (void)setPreviousSQLitePageCount:(NSInteger)pageCount;

- (BOOL)isIntroShown;
- (void)setIntroShown:(BOOL)flag;
@end



@interface AppDefaults(BackgroundColors)
- (BOOL)threadsListTableUsesAlternatingRowBgColors;
- (void)setThreadsListTableUsesAlternatingRowBgColors:(BOOL)flag;

- (NSColor *)threadsListBackgroundColor;
- (void)setThreadsListBackgroundColor:(NSColor *)color;

//- (NSColor *)replyBackgroundColor;

- (BSThreadTitleBarColorStyleType)threadTitleBarColorStyle;
- (void)setThreadTitleBarColorStyle:(BSThreadTitleBarColorStyleType)aType;

- (void)_loadBackgroundColors;
- (BOOL)_saveBackgroundColors;
@end



@interface AppDefaults(Filter)
- (BOOL)spamFilterEnabled;
- (void)setSpamFilterEnabled:(BOOL)flag;

- (NSMutableArray *)spamMessageCorpus;
- (void)setSpamMessageCorpus:(NSMutableArray *)mutableArray;

// 迷惑レスを見つけたときの動作：
- (BSSpamFilterBehavior)spamFilterBehavior;
- (void)setSpamFilterBehavior:(BSSpamFilterBehavior)mask;

// AAD(Ascii Art Detector). Available in MeteorSweeper and later.
- (BOOL)asciiArtDetectorEnabled;
- (void)setAsciiArtDetectorEnabled: (BOOL) flag;

// Available in SilverGull and later.
- (BOOL)treatsAsciiArtAsSpam;
- (void)setTreatsAsciiArtAsSpam:(BOOL)flag;

// Available in BathyScaphe 2.0 and later.
- (NSSet *)spamHostSymbols;
- (void)setSpamHostSymbols:(NSSet *)set;

- (BOOL)treatsNoSageAsSpam;
- (void)setTreatsNoSageAsSpam:(BOOL)flag;

- (BSAddNGExpressionScopeType)ngExpressionAddingScope;
- (void)setNgExpressionAddingScope:(BSAddNGExpressionScopeType)scope;

- (BOOL)runSpamFilterAfterAddingNGExpression;
- (void)setRunSpamFilterAfterAddingNGExpression:(BOOL)flag;

// Available in BathyScaphe 2.0.5 "Homuhomu" and later.
- (BOOL)registrantShouldConsiderName;
- (void)setRegistrantShouldConsiderName:(BOOL)flag;

- (void)resetSpamFilter;

- (void)setSpamFilterNeedsSaveToFiles:(BOOL)flag;

- (void)_loadFilter;
- (BOOL)_saveFilter;
@end


@interface AppDefaults(FontAndColor)
- (BOOL)popUpWindowVerticalScrollerIsSmall;
- (void)setPopUpWindowVerticalScrollerIsSmall:(BOOL)flag;

- (NSColor *)threadsListColor;
- (void)setThreadsListColor:(NSColor *)color;
- (NSFont *)threadsListFont;
- (void)setThreadsListFont:(NSFont *)aFont;
- (NSColor *)threadsListNewThreadColor;
- (void)setThreadsListNewThreadColor:(NSColor *)color;
- (NSFont *)threadsListNewThreadFont;
- (void)setThreadsListNewThreadFont:(NSFont *)aFont;
/* Available in Twincam Angel. */
- (NSFont *)threadsListDatOchiThreadFont;
- (void)setThreadsListDatOchiThreadFont:(NSFont *)aFont;
- (NSColor *)threadsListDatOchiThreadColor;
- (void)setThreadsListDatOchiThreadColor:(NSColor *)color;

//- (NSColor *)messageFilteredColor;
//- (void)setMessageFilteredColor:(NSColor *)color;
//- (NSColor *)textEnhancedColor;
//- (void)setTextEnhancedColor:(NSColor *)color;

/* more options */
- (BOOL)hasMessageAnchorUnderline;
- (void)setHasMessageAnchorUnderline:(BOOL)flag;

- (BOOL)shouldThreadAntialias;
- (void)setShouldThreadAntialias:(BOOL)flag;

- (BOOL)threadsListDrawsGrid;
- (void)setThreadsListDrawsGrid:(BOOL)flag;

/* Row height, cell spacing */
- (CGFloat)messageHeadIndent;
- (void)setMessageHeadIndent:(CGFloat)anIndent;

/* SledgeHammer Addition */
- (CGFloat)msgIdxSpacingBefore;
- (void)setMsgIdxSpacingBefore:(CGFloat)aValue;
- (CGFloat)msgIdxSpacingAfter;
- (void)setMsgIdxSpacingAfter:(CGFloat)aValue;

- (CGFloat)threadsListRowHeight;
- (void)setThreadsListRowHeight:(CGFloat)rowHeight;
- (void)fixRowHeightToFontSize;

// 掲示板リストのアイコン（、テキスト、行の高さ）サイズを小／中／大　で設定。
- (NSInteger)boardListRowSizeStyle;
- (void)setBoardListRowSizeStyle:(NSInteger)style;

// 掲示板リストにアイコンを表示するか？
- (BOOL)boardListShowsIcon;
- (void)setBoardListShowsIcon:(BOOL)shows;

/* Reserved */
//- (BOOL)useFixedLeading;
//- (void)setUseFixedLeading:(BOOL)flag;
//- (CGFloat)customLineSpacing;
//- (void)setCustomLineSpacing:(CGFloat)points;

- (NSFont *)firstAvailableAAFont; // Available in BathyScaphe 2.1 ".Invader" and later.
- (NSFont *)firstAvailableAAFont:(BSThreadViewTheme *)theme; // Available in BathyScaphe 2.1 ".Invader" and later.

- (void)_loadFontAndColor;
- (BOOL)_saveFontAndColor;
@end


@interface AppDefaults(ThreadsListSettings)
- (CMRAutoscrollCondition)threadsListAutoscrollMask;
- (void)setThreadsListAutoscrollMask:(CMRAutoscrollCondition)mask;

- (BOOL)useIncrementalSearch;
- (void)setUseIncrementalSearch:(BOOL)TorF;

/* ShortCircuit Additions */
- (id)threadsListTableColumnState;
- (void)setThreadsListTableColumnState:(id)aColumnState;

/* InnocentStarter Additions */
- (BOOL)autoReloadListWhenWake;
- (void)setAutoReloadListWhenWake:(BOOL)doReload;

/* Twincam Angel Additions */
- (BSThreadsListViewModeType)threadsListViewMode;
- (void)setThreadsListViewMode:(BSThreadsListViewModeType)type;

/* Available in BathyScaphe 1.6.2 and later. */
- (BOOL)energyUsesLevelIndicator;
- (void)setEnergyUsesLevelIndicator:(BOOL)flag;

/* Available in BathyScaphe 1.6.3 "Hinagiku" and later. */
- (BOOL)invalidSortDescriptorFixed;
- (void)setInvalidSortDescriptorFixed:(BOOL)flag;

/* Available in BathyScaphe 1.6.5 "Prima Aspalas" and later. */
- (BOOL)sortsImmediately;
- (void)setSortsImmediately:(BOOL)flag;

/* Available in BathyScaphe 2.0 "Final Moratorium" and later. */
- (BOOL)drawsLabelColorOnRowBackground;
- (void)setDrawsLabelColorOnRowBackground:(BOOL)flag;

/* Available in BathyScaphe 2.1 ".Invader" and later. */
- (BOOL)nextUpdatedThreadContainsNewThread;
- (void)setNextUpdatedThreadContainsNewThread:(BOOL)flag;

/* Available in BathyScaphe 2.3 "Bright Stream" and later. */
- (BOOL)usesRelativeDateFormat;
- (void)setUsesRelativeDateFormat:(BOOL)flag;

- (void)_loadThreadsListSettings;
- (BOOL)_saveThreadsListSettings;
@end


@interface AppDefaults(ThreadViewTheme)
- (BSThreadViewTheme *)threadViewTheme;
- (void)setThreadViewTheme:(BSThreadViewTheme *)aTheme;

- (BOOL)usesCustomTheme;
- (void)setUsesCustomTheme:(BOOL)flag;

- (NSString *)defaultThemeFilePath;
- (NSString *)createFullPathFromThemeFileName:(NSString *)fileName;

- (NSString *)themeFileName;
//- (void)setThemeFileName:(NSString *)fileName;

// Convenience method for setting themeFileName and usesCustomTheme at once
- (void)setThemeFileNameWithFullPath:(NSString *)fullPath isCustomTheme:(BOOL)isCustom;

- (NSArray *)installedThemes;
- (void)invalidateInstalledThemes;
@end


@interface AppDefaults(ThreadViewerSettings)
/* スレッドをダウンロードしたときはすべて表示する */
//- (BOOL) showsAllMessagesWhenDownloaded;
//- (void) setShowsAllMessagesWhenDownloaded : (BOOL) flag;

/* 「ウインドウの位置と領域を記憶」 */
- (NSString *) windowDefaultFrameString;
- (void) setWindowDefaultFrameString : (NSString *) aString;
- (NSString *) replyWindowDefaultFrameString;
- (void) setReplyWindowDefaultFrameString : (NSString *) aString;

/* Kazusa-Ushiku Additions */
- (BOOL)navigationBarShownForClass:(Class)windowClass;
- (void)setNavigationBarShown:(BOOL)flag forClass:(Class)windowClass;

- (ThreadViewerLinkType)threadViewerLinkType __attribute__ ((deprecated));
- (void)setThreadViewerLinkType:(ThreadViewerLinkType)aType __attribute__ ((deprecated));

- (BOOL) mailAttachmentShown;
- (void) setMailAttachmentShown : (BOOL) flag;
- (BOOL) mailAddressShown;
- (void) setMailAddressShown : (BOOL) flag;

- (BSOpenInBrowserType)openInBrowserType;
- (void)setOpenInBrowserType:(BSOpenInBrowserType)aType;

/* SledgeHammer Additions */
- (BOOL) showsPoofAnimationOnInvisibleAbone;
- (void) setShowsPoofAnimationOnInvisibleAbone : (BOOL) showsPoof;

/* ShortCircuit Additions */
//- (unsigned int) firstVisibleCount;
//- (void) setFirstVisibleCount : (unsigned int) aValue;
//- (unsigned int) lastVisibleCount;
//- (void) setLastVisibleCount : (unsigned int) aValue;

/* SecondFlight Additions */
- (BOOL) previewLinkWithNoModifierKey;
- (void) setPreviewLinkWithNoModifierKey : (BOOL) previewDirectly;

/* InnocentStarter Additions */
- (double)mouseDownTrackingTime;
//- (void)setMouseDownTrackingTime:(double)aValue;

/* Vita Additions */
- (BOOL) scrollToLastUpdated;
- (void) setScrollToLastUpdated : (BOOL) flag;

/* Twincam Angel Additions */
- (NSString *)linkDownloaderDestination;
- (void)setLinkDownloaderDestination:(NSString *)path;
- (NSMutableArray *)linkDownloaderDictArray;
- (void)setLinkDownloaderDictArray:(NSMutableArray *)array;
- (NSArray *)linkDownloaderExtensionTypes;
- (NSArray *)linkDownloaderAutoopenTypes;

// Removed in BathyScaphe 2.0.
//- (BOOL)linkDownloaderAttachURLToComment;
//- (void)setLinkDownloaderAttachURLToComment:(BOOL)flag;

/* SilverGull Additions */
- (BOOL)autoReloadViewerWhenWake;
- (void)setAutoReloadViewerWhenWake:(BOOL)flag;

/* Tenori Tiger Addition */
//- (CMRThreadVisibleRange *)defaultVisibleRange;
- (BOOL)showsSAAPIcon;
- (void)setShowsSAAPIcon:(BOOL)flag;

/* Prima Aspalas Addition */
- (BOOL)convertsHttpToItmsIfNeeded;
- (void)setConvertsHttpToItmsIfNeeded:(BOOL)flag;

/* Final Moratorium Addition */
- (BOOL)multitouchGestureEnabled;
- (void)setMultitouchGestureEnabled:(BOOL)flag;

/* Thunder Vernier Addition */
//- (BOOL)shouldForceLayoutForLoadedMessages;
//- (void)setShouldForceLayoutForLoadedMessages:(BOOL)flag;

/* Baby Universe Day Additions */
- (BOOL)shouldColorIDString;
- (void)setShouldColorIDString:(BOOL)flag;

/* Bright Stream Additions */
- (BOOL)showsReferencedMarker;
- (void)setShowsReferencedMarker:(BOOL)flag;

/* Matatabi-Step Additions */
- (BOOL)isPopupTriggerTypeSet;
- (BSPopupTriggerType)popupTriggerType;
- (void)setPopupTriggerType:(BSPopupTriggerType)type;

- (void) _loadThreadViewerSettings;
- (BOOL) _saveThreadViewerSettings;
@end



@interface AppDefaults(Account)
- (NSURL *)x2chAuthenticationRequestURL;
- (NSURL *)be2chAuthenticationRequestURL;
- (NSString *)be2chAuthenticationFormFormat;

- (BOOL)shouldLoginIfNeeded;
- (void)setShouldLoginIfNeeded:(BOOL)flag;
- (BOOL)shouldLoginBe2chAnyTime;
- (void)setShouldLoginBe2chAnyTime:(BOOL)flag;
- (BOOL)usesP22chForReply;
- (void)setUsesP22chForReply:(BOOL)flag;

- (BOOL)hasAccountInKeychain:(BSKeychainAccountType)type;
- (void)setHasAccountInKeychain:(BOOL)usesKeychain forType:(BSKeychainAccountType)type;

- (BOOL)availableBe2chAccount;

- (NSString *)x2chUserAccount;
- (void)setX2chUserAccount:(NSString *)account;
- (NSString *)be2chAccountMailAddress;
- (void)setBe2chAccountMailAddress:(NSString *)address;
- (NSString *)p22chUserAccount;
- (void)setP22chUserAccount:(NSString *)account;

- (NSString *)accountForType:(BSKeychainAccountType)type;
- (void)setAccount:(NSString *)account forType:(BSKeychainAccountType)type;

- (NSString *)passwordForType:(BSKeychainAccountType)type __attribute__((deprecated));
- (NSString *)passwordForType:(BSKeychainAccountType)type error:(NSError **)errorPtr;
- (BOOL)setPassword:(NSString *)password forType:(BSKeychainAccountType)type error:(NSError **)errorPtr;

- (BOOL)changeAccount:(NSString *)newAccount password:(NSString *)newPassword forType:(BSKeychainAccountType)type error:(NSError **)errorPtr;

- (void)loadAccountSettings;
@end


@interface AppDefaults(BundleSupport)
- (NSBundle *) moduleWithName : (NSString *) bundleName
					   ofType : (NSString *) type
				  inDirectory : (NSString *) bundlePath;

- (id<BSLinkPreviewing>)sharedLinkPreviewer; // Available in BathyScaphe 2.0 and later.
- (id<BSPreferencesPaneProtocol>)sharedPreferencesPane;
- (id<w2chConnect>) w2chConnectWithURL : (NSURL        *) anURL
                            properties : (NSDictionary *) properties;

- (id<p22chPosting>)p22chConnectWithUserInfo:(NSDictionary *)userInfo;

// Available in Twincam Angel.
- (id<w2chAuthenticationStatus>)shared2chAuthenticator;
- (id<be2chAuthenticationStatus>)sharedBe2chAuthenticator; // Available in BathyScaphe 2.0.2 and later.
- (id<p22chAuthenticationStatus>)sharedP22chAuthenticator; // Available in Kazusa-Ushiku and later.
- (NSBundle *)installedPreviewerBundle;

- (void)letPreviewerShowPreferences:(id)sender;
- (BOOL)previewerSupportsShowingPreferences;
- (BOOL)previewerSupportsAppReset:(NSString **)resetLabelPtr; // Available in BathyScaphe 2.0.5 and later.

- (void) _loadImagePreviewerSettings;
- (BOOL) _saveImagePreviewerSettings;

// Available in BathyScaphe 2.4 and later.
- (BOOL)preloadPreviewers;
- (void)setPreloadPreviewers:(BOOL)flag;
@end

/* Vita Additions */
@interface AppDefaults(Sounds)
- (NSString *) HEADCheckNewArrivedSound;
- (void) setHEADCheckNewArrivedSound : (NSString *) soundName;
- (NSString *) HEADCheckNoUpdateSound;
- (void) setHEADCheckNoUpdateSound : (NSString *) soundName;
- (NSString *) replyDidFinishSound;
- (void) setReplyDidFinishSound : (NSString *) soundName;

- (void) _loadSoundsSettings;
- (BOOL) _saveSoundsSettings;
@end

/* MeteorSweeper Additions */
@interface AppDefaults(BoardWarriorSupport)
- (NSURL *)BBSMenuURL;
- (void)setBBSMenuURL:(NSURL *)anURL;

- (BOOL)autoSyncBoardList;
- (void)setAutoSyncBoardList:(BOOL)autoSync;

- (BSAutoSyncIntervalType)autoSyncIntervalTag;
//- (void)setAutoSyncIntervalTag:(BSAutoSyncIntervalType)aType;

- (NSTimeInterval)timeIntervalForAutoSyncPrefs;

- (NSDate *)lastSyncDate;
- (void)setLastSyncDate:(NSDate *)finishedDate;

- (BOOL)shouldAutoSyncBoardListImmediately; // Available in BathyScaphe 2.0.5 and later.

- (void)_loadBWSettings;
- (BOOL)_saveBWSettings;
@end


@interface AppDefaults(PreferencesPaneSupport) // Available in BathyScaphe 1.6.3 "Hinagiku" and later.
// タブビューが配置されている一部の環境設定ペインで、「最後に選択されていたタブ」を記録、参照するための API
- (NSString *)lastShownSubpaneIdentifierForPaneIdentifier:(NSString *)paneIdentifier;
- (void)setLastShownSubpaneIdentifier:(NSString *)subpaneId forPaneIdentifier:(NSString *)paneId;

// 掲示板オプション
// Available in BathyScaphe 2.0 "Final Moratorium" and later.
- (NSString *)lastShownBoardInfoInspectorPaneIdentifier;
- (void)setLastShownBoardInfoInspectorPaneIdentifier:(NSString *)paneId;
@end

#pragma mark Constants

extern NSString *const AppDefaultsWillSaveNotification;
extern NSString *const AppDefaultsThreadViewThemeDidChangeNotification;
