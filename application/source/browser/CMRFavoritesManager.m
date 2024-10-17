//
//  CMRFavoritesManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/09.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRFavoritesManager.h"
#import "CocoMonar_Prefix.h"

#import "CMRThreadAttributes.h"
#import "CMRThreadSignature.h"
#import "CMRDocumentFileManager.h"
#import "BSDBThreadList.h"
#import "DatabaseManager.h"
#import "BSThreadListItem.h"

NSString *const CMRFavoritesManagerDidLinkFavoritesNotification = @"CMRFavoritesManagerDidLinkFavoritesNotification";
NSString *const CMRFavoritesManagerDidRemoveFavoritesNotification = @"CMRFavoritesManagerDidRemoveFavoritesNotification";
NSString *const CMRFavoritesManagerDidLinkOrRemoveFavoritesNotification = @"CMRFavoritesManagerDidLinkOrRemoveFavoritesNotification";

@implementation CMRFavoritesManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (id)init
{
    if (self = [super init]) {
        ;
    }
    return self;
}

+ (NSInteger)version
{
	return 2;
}

- (CMRFavoritesOperation)availableOperationWithPath:(NSString *)filepath
{
	NSDictionary	*attr_;
	
	if (!filepath) {
        return CMRFavoritesOperationNone;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
        // ファイルが存在しない場合でも、何らかの理由で「お気に入り」に登録された状態である可能性がある
        // その場合は、「お気に入りから削除」は実行可能である必要がある
        // そのへんの処理が組み込まれた -availableOperationWithSignature: に丸投げする
        return [self availableOperationWithSignature:[CMRThreadSignature threadSignatureFromFilepath:filepath]];
	}

	attr_ = [BSDBThreadList attributesForThreadsListWithContentsOfFile:filepath];
	// [Bug 10077] 回避のための強引な処理
	if (!attr_) {
		BOOL result_;
		result_ = [[DatabaseManager defaultManager] registerThreadFromFilePath:filepath];
		if (!result_) {
			return CMRFavoritesOperationNone;
		} else {
			return CMRFavoritesOperationLink;
		}
	}

    NSString *path = [attr_ objectForKey:CMRThreadLogFilepathKey];
	return [self availableOperationWithSignature:[CMRThreadSignature threadSignatureFromFilepath:path]];
}

- (CMRFavoritesOperation)availableOperationWithSignature:(CMRThreadSignature *)signature registered:(BOOL *)boolPtr
{
	id identifier;
	id boardName;
	id boardIDs;
    
    if (!signature) {
        return CMRFavoritesOperationNone;
    }

    identifier = [signature identifier];
    boardName = [signature boardName];

	boardIDs = [[DatabaseManager defaultManager] boardIDsForName:boardName];

	if (!identifier || !boardIDs) {
        return CMRFavoritesOperationNone;
    }
	/* TODO 複数存在する場合の処理 */
	NSUInteger boardID;
	boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];
	
	BOOL isFavorite;
	isFavorite = [[DatabaseManager defaultManager] isFavoriteThreadIdentifier:identifier onBoardID:boardID];

	if (boolPtr != NULL) *boolPtr = [[DatabaseManager defaultManager] isThreadIdentifierRegistered:identifier onBoardID:boardID numberOfAll:NULL];
	
	if (isFavorite) {
        return CMRFavoritesOperationRemove;
    } else {
        return [[NSFileManager defaultManager] fileExistsAtPath:[signature threadDocumentPath]] ? CMRFavoritesOperationLink : CMRFavoritesOperationNone;
    }
}

- (CMRFavoritesOperation)availableOperationWithSignature:(CMRThreadSignature *)signature
{
	return [self availableOperationWithSignature:signature registered:NULL];
}

- (BOOL)canCreateFavoriteLinkFromPath:(NSString *)filepath
{
	return (CMRFavoritesOperationLink == [self availableOperationWithPath:filepath]);
}

- (BOOL)favoriteItemExistsOfThreadPath:(NSString *)filepath
{
	UTILAssertNotNil(filepath);
	return (CMRFavoritesOperationRemove == [self availableOperationWithPath:filepath]);
}

- (BOOL)favoriteItemExistsOfThreadSignature:(CMRThreadSignature *)signature registeredToDatabase:(BOOL *)boolPtr
{
	UTILAssertNotNil(signature);
	return (CMRFavoritesOperationRemove == [self availableOperationWithSignature:signature registered:boolPtr]);
}

- (BOOL)favoriteItemExistsOfThreadSignature:(CMRThreadSignature *)signature
{
	UTILAssertNotNil(signature);
	return (CMRFavoritesOperationRemove == [self availableOperationWithSignature:signature]);
}

#pragma mark Add
- (BOOL)addFavoriteWithThread:(id)threadIdentifier ofBoard:(NSString *)boardName notify:(BOOL)flag
{
	id boardIDs; // TODO 複数存在する場合の処理
	BOOL isSuccess = NO;
    NSUInteger boardID;
	
	boardIDs = [[DatabaseManager defaultManager] boardIDsForName:boardName];
	if (!boardIDs) {
        return NO;
	}

    boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];
	isSuccess = [[DatabaseManager defaultManager] appendFavoriteThreadIdentifier:threadIdentifier onBoardID:boardID];
	
	if (isSuccess && flag) {
		UTILNotifyName(CMRFavoritesManagerDidLinkFavoritesNotification);
	}
	return isSuccess;
}

- (BOOL)addFavoriteWithSignature:(CMRThreadSignature *)signature
{
	if (!signature) {
        return NO;
    }
	return [self addFavoriteWithThread:[signature identifier] ofBoard:[signature boardName] notify:YES];
}

- (void)addFavoritesWithSignatureWithoutNotify:(CMRThreadSignature *)signature
{
    if (!signature) {
        return;
    }
    [self addFavoriteWithThread:[signature identifier] ofBoard:[signature boardName] notify:NO];
}

- (BOOL)addFavoriteWithFilePath:(NSString *)filepath
{
	if (!filepath) {
        return NO;
    }
    return [self addFavoriteWithSignature:[CMRThreadSignature threadSignatureFromFilepath:filepath]];
}

#pragma mark Remove
- (BOOL)removeFavoriteWithThread:(id)threadIdentifier ofBoard:(NSString *)boardName notify:(BOOL)flag
{
	id boardIDs; // TODO 複数存在する場合の処理
    NSUInteger boardID;
	BOOL isSuccess = NO;

	boardIDs = [[DatabaseManager defaultManager] boardIDsForName:boardName];
	if (!boardIDs) {
        return NO;
	}

    boardID = [[boardIDs objectAtIndex:0] unsignedIntegerValue];
	isSuccess = [[DatabaseManager defaultManager] removeFavoriteThreadIdentifier:threadIdentifier onBoardID:boardID];
	
	if (isSuccess && flag) {
		UTILNotifyName(CMRFavoritesManagerDidRemoveFavoritesNotification);
	}
	return isSuccess;
}

- (BOOL)removeFromFavoritesWithSignature:(CMRThreadSignature *)signature
{	
	if (!signature) {
        return NO;
    }
	return [self removeFavoriteWithThread:[signature identifier] ofBoard:[signature boardName] notify:YES];
}

- (void)removeFromFavoritesWithSignatureWithoutNotify:(CMRThreadSignature *)signature
{
    if (!signature) {
        return;
    }
    [self removeFavoriteWithThread:[signature identifier] ofBoard:[signature boardName] notify:NO];
}

- (BOOL)removeFromFavoritesWithFilePath:(NSString *)filepath
{
	if (!filepath) {
        return NO;
    }
	return [self removeFromFavoritesWithSignature:[CMRThreadSignature threadSignatureFromFilepath:filepath]];
}

- (void)notifyFavoritesDidChange
{
    UTILNotifyName(CMRFavoritesManagerDidLinkOrRemoveFavoritesNotification);
}
@end
