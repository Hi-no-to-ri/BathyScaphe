//
//  CMRAppTypes.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/07/19.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


typedef NS_OPTIONS(NSUInteger, ThreadStatus) {
    ThreadStandardStatus        = 0,
    ThreadNoCacheStatus         = 1,
    ThreadLogCachedStatus       = 1 << 1,
    ThreadUpdatedStatus         = (1 << 2) | ThreadLogCachedStatus,
    ThreadNewCreatedStatus      = (1 << 3) | ThreadNoCacheStatus,
    ThreadHeadModifiedStatus    = (1 << 4) | ThreadLogCachedStatus // Available in BathyScaphe 1.2 and later.
};

typedef NS_ENUM(NSUInteger, ThreadViewerLinkType) {
    ThreadViewerMoveToIndexLinkType,
    ThreadViewerOpenBrowserLinkType,
    ThreadViewerResPopUpLinkType,
};

typedef NS_OPTIONS(NSUInteger, CMRAutoscrollCondition) {
    CMRAutoscrollNone             = 0,
    CMRAutoscrollWhenTLUpdate     = 1,
    CMRAutoscrollWhenTLSort       = 1 << 1,
    CMRAutoscrollWhenThreadUpdate = 1 << 2,
    CMRAutoscrollWhenTLVMChange   = 1 << 3, // Available in Tenori Tiger.
    CMRAutoscrollWhenThreadDelete = 1 << 4, // Available in BathyScaphe 1.6.3 "Hinagiku" and later.
    CMRAutoscrollAny              = 0xffffffffU,
    CMRAutoscrollStandard         = CMRAutoscrollAny ^ CMRAutoscrollWhenThreadDelete, // Available in BathyScaphe 1.6.3 "Hinagiku" and later.
}; // Available in BathyScaphe 1.6.3 "Hinagiku" and later.

typedef NS_ENUM(NSUInteger, BSSpamFilterBehavior) {
    kSpamFilterChangeTextColorBehavior = 1,
    kSpamFilterLocalAbonedBehavior,
    kSpamFilterInvisibleAbonedBehavior
}; // Available in BathyScaphe 2.0 and later.

typedef NS_ENUM(NSInteger, BSAddNGExpressionScopeType) {
    BSAddNGExAllScopeType = 0,
    BSAddNGExBoardScopeType = 1,
    BSAddNGExThreadScopeType = 2, // reserved
}; // Available in BathyScaphe 2.0 "Final Moratorium" and later.

typedef NS_OPTIONS(NSUInteger, CMRSearchMask) {
    CMRSearchOptionNone                  = 0,
    CMRSearchOptionCaseInsensitive       = 1,
    CMRSearchOptionBackwards             = 1 << 1,
    CMRSearchOptionZenHankakuInsensitive = 1 << 2,
    CMRSearchOptionIgnoreSpecified       = 1 << 3,
    CMRSearchOptionLinkOnly              = 1 << 4,
    CMRSearchOptionUseRegularExpression  = 1 << 5 // Available in Starlight Breaker.
};

typedef NS_ENUM(NSUInteger, BSOpenInBrowserType) {
    BSOpenInBrowserLatestFifty  = 0,
    BSOpenInBrowserFirstHundred = 1,
    BSOpenInBrowserAll          = 2,
};

typedef NS_ENUM(NSUInteger, BSLoginPolicyType) {
    BSLoginPolicyMandatory      = 0, // アカウントログイン必須
    BSLoginPolicyUnavailable    = 1, // アカウントログインをサポートしない掲示板
    BSLoginPolicyDecidedByUser  = 2, // アカウントログインするかどうかはユーザの設定を参照する
    BSLoginPolicyNoAccount      = 3, // アカウントが環境設定で入力されていない
};

typedef NS_ENUM(NSUInteger, BSThreadsListViewModeType) {
    BSThreadsListShowsLiveThreads = 0, // 0x00
    BSThreadsListShowsStoredLogFiles = 1, // 0x01
    BSThreadsListShowsSmartList = 2, // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later. 0x10
    BSThreadsListShowsFavorites = 3, // Available in BathyScaphe 1.6.5 "Prima Aspalas" and later. 0x11
}; // Available in Twincam Angel and later.

typedef NS_ENUM(NSUInteger, BSTGrepSearchOptionType) {
    BSTGrepSearchByNew = 0, // tGrep only.
    BSTGrepSearchByFast = 1, // tGrep only.
    BSTGrepSearchByLast = 2, // find.2ch.net only. Available in BathyScaphe 2.0.4 and later.
    BSTGrepSearchByCount = 3, // find.2ch.net only. Available in BathyScaphe 2.0.4 and later.
}; // Available in BathyScaphe 2.0 "Final Moratorium" and later.

typedef NS_OPTIONS(NSUInteger, BSAppResetMask) {
    BSAppResetNone = 0,
    BSAppResetHistory = 1,
    BSAppResetCookie = 1 << 1,
    BSAppResetCache = 1 << 2,
    BSAppResetWindow = 1 << 3,
    BSAppResetPreviewer = 1 << 4,
    BSAppResetAll = 0xffffffffU,
}; // Available in BathyScaphe 2.0.5 and later.

typedef NS_ENUM(NSUInteger, BSKeychainAccountType) {
    BSKeychainAccountX2chAuth = 1,
    BSKeychainAccountBe2chAuth = 2,
    BSKeychainAccountP22chNetAuth = 3, // Available in Kazusa-Ushiku and later.
}; // Moved from BathyScaphe.app (Kazusa-Ushiku and later.)

typedef NS_ENUM(NSUInteger, BSPopupTriggerType) {
    BSPopupByMouseOver,
    BSPopupByMouseClick,
    BSPopupByContinuousMouseDown,
}; // Available in Matatabi-Step and later.

typedef NS_ENUM(NSUInteger, BSThreadTitleBarColorStyleType) {
    BSThreadTitleBarLight = 1,
    BSThreadTitleBarIndigo = 2,
}; // Available in Matatabi-Step and later.
