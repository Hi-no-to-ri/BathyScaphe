//
//  ConcreteBoardListItem.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/12/06.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//

#import "ConcreteBoardListItem.h"

#import "FavoritesBoardListItem.h"
#import "SmartBoardListItem.h"
#import "FolderBoardListItem.h"
#import "BoardBoardListItem.h"

#import "DatabaseManager.h"
#import "BoardManager.h"
#import "AppDefaults.h"
#import "BSBoardNameSuffixAppender.h"

static ConcreteBoardListItem *_sharedInstance;

@implementation ConcreteBoardListItem

+ (id) sharedInstance
{
//	@synchronized(self) {
	if (!_sharedInstance) {
		_sharedInstance = [[self alloc] init];
	}
//	}
	
	return _sharedInstance;
}

- (id) retain { return self; }
- (oneway void) release {}
- (NSUInteger) retainCount { return NSUIntegerMax; }

+ (id) favoritesItem
{
	return [FavoritesBoardListItem sharedInstance];
}
+ (id) boardListItemWithFolderName : (NSString *) name
{
	return [[[FolderBoardListItem alloc] initWithFolderName : name] autorelease];
}
+ (id) boardListItemWithBoardID : (NSUInteger) boardID
{
	return [[[BoardBoardListItem alloc] initWithBoardID : boardID] autorelease];
}
+ (id) boardListItemWithURLString : (NSString *) urlString
{
	return [[[BoardBoardListItem alloc] initWithURLString : urlString] autorelease];
}
+ (id) baordListItemWithName : (NSString *) name condition : (id) condition
{
	return [[[SmartBoardListItem alloc] initWithName : name condition : condition] autorelease];
}
- (id) initForFavorites
{
	return (id)[[FavoritesBoardListItem sharedInstance] retain];
}
- (id) initWithFolderName : (NSString *) name
{
	return (id)[[FolderBoardListItem alloc] initWithFolderName : name];
}
- (id) initWithBoardID : (NSUInteger) boardID
{
	return (id)[[BoardBoardListItem alloc] initWithBoardID : boardID];
}
- (id) initWithURLString : (NSString *) urlString
{
	return (id)[[BoardBoardListItem alloc] initWithURLString : urlString];
}
- (id) initWithName : (NSString *) name condition : (id) condition
{
	return (id)[[SmartBoardListItem alloc] initWithName : name condition : condition];
}

+ (BoardListItem *)boardBoardListItemFromPlist:(id)plist
{
	NSString *url;
	NSString *boardName;
	NSUInteger boardID;
	DatabaseManager *dbm = [DatabaseManager defaultManager];    
	
	UTILCAssertKindOfClass(plist, [NSDictionary class]);
	
	boardName = [plist objectForKey:@"Name"];
	if (!boardName) {
        goto failCreation;
    }
	url = [plist objectForKey:@"URL"];
	if (!url) {
        goto failCreation;
    }
    // 暫定処置（2011-03-31）
    // まだ invalidBoardDataRemoved == NO である場合は、
    // -[BoardManager repairInvalidBoardData] 内で掲示板リストに登録されている
    // 不適当な URL の項目を削除し、かつ削除済みの内容で board.plist, board_default.plist を
    // 上書きする必要がある。そのためには、ここで初期化をブロックしたくない。
    // 一方、すでに invalidBoardDataRemoved == YES である場合は、
    // 対策済みで本来、不適当な URL の掲示板リスト項目は BoardWarrior でも掲示板の編集でも追加でも作成されない
    // はずであるから、ここで初期化をブロックする最終対策をとる。
    if ([CMRPref invalidBoardDataRemoved]) {
        if ([[[BoardManager defaultManager] invalidBoardURLsToBeRemoved] containsObject:url]) {
             NSLog(@"Blocking board (%@ -- %@).", boardName, url);
             return nil;
        }
    }
    
	boardID = [dbm boardIDForURLStringExceptingHistory:url];

	if (NSNotFound == boardID) { // まだデータベースに存在しない板か、あるいはアドレスが変更になっている
		NSArray *boardIDs = [dbm boardIDsForName:boardName]; // 板名から探す
		if (!boardIDs || [boardIDs count] == 0) { // 板名でも見つからない→間違いなくまだ存在しない板
			BOOL isOK = [dbm registerBoardName:boardName URLString:url];

			boardID = [dbm boardIDForURLString:url];
			if (!isOK || NSNotFound == boardID) {
				goto failCreation;
			}
		} else if ([boardIDs count] == 1) {
            // 一部の掲示板（「中国」、その他、地域系）は特別扱いが必要
            // 先に登録済みの掲示板は、そのままの名前
            // これから登録しようとしている同名の掲示板には、URL を基に適切な Suffix を付けて登録する。
            BSBoardNameSuffixAppender *appender = [BSBoardNameSuffixAppender sharedInstance];
            
            // 特別扱いが必要な掲示板かどうか判断
            if ([[appender targetBoardNames] containsObject:boardName]) {
                NSString *newBoardName = [appender boardNameByAppendingAppropriateSuffix:boardName forURL:url];
                BOOL isOK = [dbm registerBoardName:newBoardName URLString:url];
                boardID = [dbm boardIDForURLString:url];
                if (!isOK || NSNotFound == boardID) {
                    goto failCreation;
                }
            } else {
                boardID = [[boardIDs objectAtIndex:0] integerValue];
                [dbm moveBoardID:boardID toURLString:url];
            }
		} else {
			// TODO 明らかにおかしい。
			boardID = [[boardIDs objectAtIndex:0] integerValue];
			[dbm moveBoardID:boardID toURLString:url];
		}
	}

	id tmp = [BoardListItem boardListItemWithBoardID:boardID];
    return tmp;
failCreation:
	NSLog(@"Fail Import Board. %@", plist ) ;
	return nil;
}

+ (BoardListItem *) folderBaordListItemFromPlist : (id) plist
{
	BoardListItem *result;
	NSString *name;
	NSArray *contents;
	
	UTILCAssertKindOfClass(plist, [NSDictionary class]);
	
	name = [plist objectForKey : @"Name"];
	if (!name) return nil;
	contents = [plist objectForKey : @"Contents"];
	if (!contents) return nil;
	
	result = [[[BoardListItem alloc] initWithFolderName : name] autorelease];
	if(!result) goto failCreation;
	
	for(id item in contents) {
		BoardListItem *boardItem;
		
		if (!item) continue;

//		boardItem = [self boardBoardListItemFromPlist : item];
		boardItem = [self baordListItemFromPlist : item];
		if(boardItem) {
			[result addItem : boardItem];
			continue;
		}
	}
	
	return result;
	
failCreation:
	NSLog(@"Fail Import Folder. %@", plist ) ;
	return nil;
}

+ (BoardListItem *) baordListItemFromPlist : (id) plist
{
	BoardListItem *result = nil;
	NSString *name;
	id contents;
	id url;
	id cond;
	
	UTILCAssertKindOfClass(plist, [NSDictionary class]);
	
	name = [plist objectForKey : @"Name"];
	if (!name) return nil;
	
	contents = [plist objectForKey : @"Contents"];
	if (contents) {
		result = [self folderBaordListItemFromPlist : plist];
	}
	
	url = [plist objectForKey : @"URL"];
	if (url) {
		result = [self boardBoardListItemFromPlist : plist];
	}
	
	cond = [plist objectForKey:@"SmartConditionConditionKey"];
	if(cond) {
		result = [SmartBoardListItem objectWithPropertyListRepresentation:plist];
	}
	cond = [plist objectForKey:@"Predicate"];
	if(cond) {
		result = [SmartBoardListItem objectWithPropertyListRepresentation:plist];
	}
	
	return result;
}

- (id) initWithContentsOfFile : (NSString *) path;
{
	id result = nil;
	NSArray *array;
	
	SQLiteDB *db;
	
	result = [[BoardListItem alloc] initWithFolderName : @"Top"];
	
	array = [NSArray arrayWithContentsOfFile : path];
	if (!array) {
		NSLog(@"File Import BoardListFile. %@", path) ;
		goto final;
	}
	
	db = [[DatabaseManager defaultManager] databaseForCurrentThread];
	if (!db) {
		goto final;
	}
	
	if ([db beginTransaction]) {
		for (id object in array) {
			id item;
			
			item = [[self class] baordListItemFromPlist : object];
			if (item) {
				[result addItem : item];
			}
		}
		[db commitTransaction];
	}
	
final :
		
		return result;
}
@end

@implementation ConcreteBoardListItem (TypeCheck)

+ (BOOL) isBoardItem : (BoardListItem *) item
{
	return [item isKindOfClass : [BoardBoardListItem class]];
}
+ (BOOL) isFavoriteItem : (BoardListItem *) item
{
	return [item isKindOfClass : [FavoritesBoardListItem class]];
}
+ (BOOL) isFolderItem : (BoardListItem *) item
{
	return [item isKindOfClass : [FolderBoardListItem class]];
}
+ (BOOL) isSmartItem : (BoardListItem *) item
{
	return [item isKindOfClass : [SmartBoardListItem class]];
}
+ (BOOL) isCategory : (BoardListItem *) item
{
	return [self isFolderItem : item];
}

+ (BoardListItemType) typeForItem : (BoardListItem *) item
{
	if ([self isBoardItem : item]) {
		return BoardListBoardItem;
	} else if ([self isFolderItem : item]) {
		return BoardListCategoryItem;
	} else if ([self isFavoriteItem : item]) {
		return BoardListFavoritesItem;
	} else if ([self isSmartItem : item]) {
		return BoardListSmartBoardItem;
	}
	
	return BoardListUnknownItem;
}

@end

