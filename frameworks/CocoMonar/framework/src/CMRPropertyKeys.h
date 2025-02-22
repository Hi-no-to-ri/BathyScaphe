//
//  CMRPropertyKeys.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


extern NSString *const ThreadPlistContentsKey;
extern NSString *const ThreadPlistLengthKey;
extern NSString *const ThreadPlistBoardNameKey;
extern NSString *const ThreadPlistIdentifierKey;
extern NSString *const CMRThreadWindowFrameKey;
extern NSString *const CMRThreadLastReadedIndexKey;
extern NSString *const CMRThreadVisibleRangeKey;
extern NSString *const CMRThreadUserStatusKey;


extern NSString *const ThreadPlistContentsIndexKey;
extern NSString *const ThreadPlistContentsNameKey;
extern NSString *const ThreadPlistContentsMailKey;
extern NSString *const ThreadPlistContentsDateKey;
extern NSString *const ThreadPlistContentsDatePrefixKey;	//Hummmmmm........
extern NSString *const ThreadPlistContentsIDKey;
extern NSString *const ThreadPlistContentsMessageKey;
extern NSString *const ThreadPlistContentsBeProfileKey;
extern NSString *const CMRThreadContentsStatusKey;		// NSNumber
extern NSString *const CMRThreadContentsHostKey;
extern NSString *const ThreadPlistContentsMilliSecKey; // Deprecated in BathyScaphe 1.6.2 and later.
extern NSString *const ThreadPlistContentsDateRepKey;


extern NSString *const BoardPlistURLKey;
extern NSString *const BoardPlistContentsKey;
extern NSString *const BoardPlistNameKey;

extern NSString *const CMRThreadTitleKey;
extern NSString *const CMRThreadLastLoadedNumberKey;
extern NSString *const CMRThreadLogFilepathKey;
extern NSString *const CMRThreadNumberOfMessagesKey;
extern NSString *const CMRThreadNumberOfUpdatedKey;
extern NSString *const CMRThreadSubjectIndexKey;
extern NSString *const CMRThreadStatusKey;

extern NSString *const CMRThreadCreatedDateKey;
extern NSString *const CMRThreadModifiedDateKey;

extern NSString *const BSThreadEnergyKey; // Available in BathyScaphe 1.6.2 and later.
extern NSString *const BSThreadLabelKey; // Available in BathyScaphe 2.0 and later.


extern NSString *const CMRBBSListItemsPboardType;
//extern NSString *const CMRFavoritesItemsPboardType; // Deprecated in ReinforceII and later.

extern NSString *const BSFavoritesIndexSetPboardType; // Available in ReinforceII and later.

extern NSString *const CMRBBSManagerUserListDidChangeNotification;
extern NSString *const CMRBBSManagerDefaultListDidChangeNotification;


extern NSString *const CMRBBSListDidChangeNotification;

extern NSString *const AppDefaultsLayoutSettingsUpdatedNotification;

extern NSString *const CMRApplicationWillResetNotification;
extern NSString *const CMRApplicationDidResetNotification;

extern NSString *const BSThreadItemsPboardType; // Available in ReinforceII and later.
