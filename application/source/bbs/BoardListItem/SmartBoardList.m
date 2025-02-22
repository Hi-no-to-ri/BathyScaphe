//
//  SmartBoardList.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/18.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "SmartBoardList.h"
//#import <SGAppkit/BSBoardListView.h>
#import <CocoMonar/CMRPropertyKeys.h>
#import "CMRFavoritesManager.h"
#import "CMRThreadSignature.h"
#import "BoardManager.h"
#import "AppDefaults.h"
#import "UTILKit.h"
#import "DatabaseManager.h"


@interface SmartBoardList(Private)
//- (void) registerFileManager : (NSString *) filepath;
- (BOOL) synchronizeWithFile:(NSString *)filepath;
- (void)registerNotification;
- (void)unregisterNotification;
@end

@implementation SmartBoardList(Private)
/*- (void) registerFileManager : (NSString *) filepath
{
    SGFileLocation *f;
	
	if(!listFilePath || ![listFilePath isEqualTo:filepath]) {
		
		f = [SGFileLocation fileLocationAtPath : filepath];
		if (nil == f) return;
		
		[[CMRFileManager defaultManager]
        addFileChangedObserver : self
					  selector : @selector(didUpdateBoardFile:)
					  location : f];
		
		id t = listFilePath;
		listFilePath = [filepath copy];
		[t release];
	}
}*/
- (BOOL)synchronizeWithFile:(NSString *)filepath
{
	id items;
	
	if (!filepath) return NO;
	
	items = [[BoardListItem alloc] initWithContentsOfFile:filepath];
	if (!items) {
		return NO;
	}

	if (![filepath isEqualToString:[[BoardManager defaultManager] defaultBoardListPath]]) {
		id favorites;
		
		favorites = [BoardListItem favoritesItem];
		if (favorites && [items isMutable]) {
			[items insertItem:favorites atIndex:0];
		}
	}

	id temp = topLevelItem;
	topLevelItem = items;
	[temp release];
	
	[self setIsEdited:NO];
	
	return YES;
}

- (void)registerNotification
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(updateItem:)
												 name:BoardListItemUpdateThreadsNotification
											   object:nil];
}

- (void)unregisterNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end


@implementation SmartBoardList
- (id)init
{
	if (self = [super init]) {
		topLevelItem = [[BoardListItem alloc] initWithFolderName:@"Top"];
	}
	
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
	if (self = [super init]) {
		[self synchronizeWithFile:path];
//		[self registerFileManager:path];
		isEdited = NO;
		[self registerNotification];
	}

	return self;
}

- (void)dealloc
{
	[self unregisterNotification];
	[topLevelItem release];
	[listFilePath release];
	
	[super dealloc];
}
/*
- (NSString *) defaultBoardListPath
{
	return [[BoardManager defaultManager] defaultBoardListPath];
}
*/
- (BOOL)writeToFile:(NSString *)filepath atomically:(BOOL)flag
{
	id list = [topLevelItem plist];
	if (!list) return NO;

	return [list writeToFile:filepath atomically:flag];
}

- (BOOL)isEdited
{
	return isEdited;
}

- (void)setIsEdited:(BOOL)flag
{
	isEdited = flag;
}

// 絶対変更不可
- (NSArray *)boardItems
{
	return [topLevelItem items];
}

- (void)postBoardListDidChangeNotificationBoardEdited:(BOOL)flag
{
	[self setIsEdited:flag];
	UTILNotifyName(CMRBBSListDidChangeNotification);
}

- (void)postBoardListDidChangeNotification
{
	[self postBoardListDidChangeNotificationBoardEdited:YES];
}

- (BOOL)containsItemWithName:(NSString *)name ofType:(BoardListItemType)aType
{
	if ([name isEqualToString:CMXFavoritesDirectoryName]) return YES;

	id item = [topLevelItem itemForRepresentName:name ofType:aType deepSearch:YES];

	return (item != nil);
}

- (id)itemForName:(id)name
{
	return [topLevelItem itemForRepresentName:name deepSearch:YES];
}

- (id)itemWithNameHavingPrefix:(id)prefix
{
	return [topLevelItem itemWithRepresentNameHavingPrefix:prefix deepSearch:YES];
}

- (id)itemForName:(id)name ofType:(BoardListItemType)aType
{
	return [topLevelItem itemForRepresentName:name ofType:aType deepSearch:YES];
}

- (void)item:(id)item setName:(NSString *)name setURL:(NSString *)url
{
	[self setName:name toItem:item];
	[self setURL:url toItem:item];
}

- (void)setName:(NSString *)name toItem:(id)item
{
	[item setRepresentName:name];
	[self postBoardListDidChangeNotification];
}

- (void)rename:(NSString *)name toItem:(id)item
{
    [(BoardListItem *)item setName:name];
    [item setRepresentName:name];
    [self postBoardListDidChangeNotification];
}

- (void)setURL:(NSString *)urlString toItem:(id)item
{
	if ([item hasURL]) {
		[item setURLString:urlString];
		[self postBoardListDidChangeNotification];
	}
}

- (NSURL *)URLForBoardName:(id)name
{
	id item = [topLevelItem itemForName:name deepSearch:YES];

	if (item && [item hasURL]) {		
		return [item url];
	}
	
	return nil;
}

+ (BoardListItemType)typeForItem:(id)item
{
	return [BoardListItem typeForItem:item];
}

+ (BOOL)isBoard:(id)item
{
	return [BoardListItem isBoardItem : item];
}

+ (BOOL)isCategory:(id)item
{
	return [BoardListItem isFolderItem:item];
}

+ (BOOL)isFavorites:(id)item
{
	return [BoardListItem isFavoriteItem:item];
}

- (BOOL)addItem:(id)item afterObject:(id)target
{
	UTILAssertKindOfClass(item, BoardListItem);
	if (target) {
		UTILAssertKindOfClass(target, BoardListItem);
	}

	NSInteger type;

	if (BoardListCategoryItem == [(BoardListItem *)item type]) {
		type = BoardListCategoryItem;
	} else {
		type = BoardListBoardItem | BoardListSmartBoardItem;
	}

	if ([topLevelItem itemForRepresentName:[item name] ofType:type deepSearch:YES]) return NO;

	if (!target) {
		[topLevelItem addItem:item];
		[self postBoardListDidChangeNotification];
		return YES;
	}

	@try {
		[topLevelItem insertItem:item afterItem:target deepSearch:YES];
	}
	@catch (id localException) {
		if (![NSRangeException isEqualTo:[localException name]]) {
			[localException raise];
		}
		return NO;
	}
	
	[self postBoardListDidChangeNotification];
	
	return YES;
}

- (void)removeItem:(id)item
{
	[topLevelItem removeItem:item deepSearch:YES];
	[self postBoardListDidChangeNotification];
}

- (void)updateItem:(id)notification
{
	[self postBoardListDidChangeNotification];
}

- (void)reloadBoardFile:(NSString *)filepath
{
	[self synchronizeWithFile:filepath];
	[self postBoardListDidChangeNotificationBoardEdited:NO];
}

/*- (void) didUpdateBoardFile:(NSNotification *) aNotification
{
    SGFileRef *f;
    NSString  *name;
	
    UTILAssertNotificationName(
							   aNotification,
							   CMRFileManagerDidUpdateFileNotification);
	UTILAssertNotificationObject(
								 aNotification,
								 [CMRFileManager defaultManager]);
    
    f = [[aNotification userInfo] objectForKey: kCMRChangedFileRef];
	name = [f filepath];
    name = [name lastPathComponent];
    if (NO == [name isEqualToString : [listFilePath lastPathComponent]]) {
        return;
    }
    
    [self synchronizeWithFile: [f filepath]];
	[self postBoardListDidChangeNotificationBoardEdited: NO];
}*/
@end


@implementation SmartBoardList (OutlineViewDataSorce)
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	id result = nil;
	
	if (!item) {
		result = [topLevelItem itemAtIndex:index];
	} else if ([item hasChildren]) {
		result = [item itemAtIndex:index];
	}

	return result;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	BOOL result = NO;
	
	if (!item) {
		result = YES;
	} else if ([item hasChildren]) {
		result = YES;
	}
	
	return result;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	NSInteger result = 0;
	
	if (!item) {
		result = [topLevelItem numberOfItem];
	} else if ([item hasChildren]) {
		result = [item numberOfItem];
	}
	
	return result;
}

// 掲示板リストだけでなく、「掲示板の追加」シートでも呼び出される
// View-based でも呼ばれる
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([BoardPlistNameKey isEqualToString:[tableColumn identifier]]) {
        id obj = [item representName];
		if (!obj) {
			UTILDebugWrite(@"can not get represent name.");
			return nil;
		}
        return obj;
	} else if ([BoardPlistURLKey isEqualToString:[tableColumn identifier]] && [item hasURL]) { // URL カラムは「掲示板の追加」シートのみ
		return [[item url] absoluteString];
	} else {
		return nil;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object
{
	return [topLevelItem itemForRepresentName:object deepSearch:YES];
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
{
	return [item representName];
}

- (id<NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item
{
    if (item == [BoardListItem favoritesItem]) {
        return nil;
    }
    return (id<NSPasteboardWriting>)item;
}

/*- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard
{
	if ([items containsObject:[BoardListItem favoritesItem]]) {
        return NO;
    }
	
    [pboard clearContents];
    [pboard writeObjects:items];
	return YES;
}*/

- (BOOL)outlineView:(NSOutlineView *)outlineView handleDroppedThreads:(NSArray *)threadSignatures item:(id)item childIndex:(NSInteger)index
{
	if (item != [BoardListItem favoritesItem]) {
		return NO;
	}

	CMRFavoritesManager *fm_ = [CMRFavoritesManager defaultManager];
	BOOL result_ = NO;

	for (CMRThreadSignature *threadSignature in threadSignatures) {
        if ([fm_ availableOperationWithSignature:threadSignature] != CMRFavoritesOperationLink) {
            continue;
        }
		if ([fm_ addFavoriteWithSignature:threadSignature]) {
            if (!result_) {
                result_ = YES;
            }
		} else {
            result_ = NO;
        }
	}
	return result_;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView handleDroppedBoards:(NSArray *)boardListItems item:(id)item childIndex:(NSInteger)index
{
	BoardListItem	*target_;
		
	target_ = (nil == item) ? topLevelItem : item;
	if (!target_) {
		return NO;
    }
	if(![target_ isMutable]) {
        return NO;
    }

	for (BoardListItem *dropped_ in [boardListItems reverseObjectEnumerator]) {
		NSUInteger found_;
		NSString *name_;
		BoardListItem *original_;
		BoardListItem *parent_;
		
		if ([BoardListItem isFavoriteItem:dropped_]) {
            continue;
        }

		if ((found_ = [target_ indexOfItem:dropped_]) != NSNotFound) {
			if (found_ < index) {
				index -= 1;
			}
		}

		name_ = [dropped_ name];
		original_ = [topLevelItem itemForName:name_ ofType:[dropped_ type] deepSearch:YES];
		parent_ = [topLevelItem parentForItem:original_];
		/* TODO SmartBoardListItem の時の処理 */
		if (parent_ && [parent_ isMutable]) {
			[parent_ removeItem:original_];
		} else if (parent_) { /* 親があって且つimmutable */
			continue;
		}
		if (index < 0 || index >= [target_ numberOfItem]) {
			[target_ addItem:dropped_];
		} else {
			[target_ insertItem:dropped_ atIndex:index];
		}
	}
	[self postBoardListDidChangeNotification];

	[outlineView reloadData];
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index
{
	NSPasteboard	*pboard_ = [info draggingPasteboard];
    NSArray *blItems = [pboard_ readObjectsForClasses:[NSArray arrayWithObject:[BoardListItem class]] options:[NSDictionary dictionary]];
    NSArray *threadSignatures_ = [pboard_ readObjectsForClasses:[NSArray arrayWithObject:[CMRThreadSignature class]] options:[NSDictionary dictionary]];

	if (blItems && ([blItems count] > 0)) {
		return [self outlineView:outlineView
			 handleDroppedBoards:blItems
							item:item
					  childIndex:index];
	} else if (threadSignatures_ && ([threadSignatures_ count] > 0)) {
		return [self outlineView:outlineView
			handleDroppedThreads:threadSignatures_
							item:item
					  childIndex:index];
	} else {
		return NO;
	}
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index
{
	NSPasteboard *pboard_ = [info draggingPasteboard];

	if ([pboard_ canReadItemWithDataConformingToTypes:[NSArray arrayWithObject:BSPasteboardTypeThreadSignature]]) {
        NSArray *threadSignatures_ = [pboard_ readObjectsForClasses:[NSArray arrayWithObject:[CMRThreadSignature class]] options:[NSDictionary dictionary]];
        if (threadSignatures_) {
            for (CMRThreadSignature *signature_ in threadSignatures_) {
                if (![[CMRFavoritesManager defaultManager] favoriteItemExistsOfThreadSignature:signature_]) {
                    [outlineView setDropItem:[BoardListItem favoritesItem] dropChildIndex:NSOutlineViewDropOnItemIndex];
                    return NSDragOperationCopy;
                }
            }
        }
		return NSDragOperationNone;
	} else if ([pboard_ canReadItemWithDataConformingToTypes:[NSArray arrayWithObject:BSPasteboardTypeBoardListItem]]) {
        if (!item) {
            return NSDragOperationMove;//(index > 0) ? NSDragOperationMove : NSDragOperationNone; //「お気に入り」の上に他のリスト項目はドロップできない
        }
		if (![BoardListItem isFolderItem:item]) { // フォルダでない項目が親というのはおかしい
			return NSDragOperationNone;
		}
        NSArray *blItems = [pboard_ readObjectsForClasses:[NSArray arrayWithObject:[BoardListItem class]] options:[NSDictionary dictionary]];
        for (BoardListItem *boardListItem in blItems) {
            if ([item isEqualTo:boardListItem]) { // 自分自身の内部にドロップしようとしている
                return NSDragOperationNone;
            } else if ([boardListItem parentForItem:item]) { // 自分自身の内部にあるカテゴリの中にドロップしようとしている
                return NSDragOperationNone;
            }
        }
        return NSDragOperationMove;
    }
	return NSDragOperationNone;	
}

- (BOOL)outlineView:(NSOutlineView *)outlineView addItem:(id)item afterItem:(id)pointingItem
{
	if ([self addItem:item afterObject:pointingItem]) {
		[outlineView reloadData];
		return YES;
	}
	return NO;
}
@end
