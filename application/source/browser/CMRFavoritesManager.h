//
//  CMRFavoritesManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/09.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class CMRThreadSignature;

typedef NS_ENUM(NSUInteger, CMRFavoritesOperation) {
	CMRFavoritesOperationNone,
	CMRFavoritesOperationLink,
	CMRFavoritesOperationRemove
};

@interface CMRFavoritesManager : NSObject
+ (id)defaultManager;

- (CMRFavoritesOperation)availableOperationWithPath:(NSString *)filepath;
- (CMRFavoritesOperation)availableOperationWithSignature:(CMRThreadSignature *)signature;

- (BOOL)canCreateFavoriteLinkFromPath:(NSString *)filepath;
- (BOOL)favoriteItemExistsOfThreadPath:(NSString *)filepath;
- (BOOL)favoriteItemExistsOfThreadSignature:(CMRThreadSignature *)signature;

- (BOOL)addFavoriteWithSignature:(CMRThreadSignature *)signature;
- (BOOL)removeFromFavoritesWithSignature:(CMRThreadSignature *)signature;

- (void)addFavoritesWithSignatureWithoutNotify:(CMRThreadSignature *)signature;
- (void)removeFromFavoritesWithSignatureWithoutNotify:(CMRThreadSignature *)signature;
- (void)notifyFavoritesDidChange;
@end


extern NSString *const CMRFavoritesManagerDidLinkFavoritesNotification;
extern NSString *const CMRFavoritesManagerDidRemoveFavoritesNotification;

extern NSString *const CMRFavoritesManagerDidLinkOrRemoveFavoritesNotification;
