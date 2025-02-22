//
//  SmartBoardList.h
//  BathyScaphe
//
//  Created by Hori,Masaki on 05/07/18.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "BoardListItem.h"

@interface SmartBoardList : NSObject<NSOutlineViewDataSource>
{
	id topLevelItem;
	
	NSString *listFilePath;
	BOOL isEdited;
}

//- (NSString *) defaultBoardListPath;

- (BOOL) writeToFile : (NSString *) filepath atomically : (BOOL) flag;

- (BOOL) isEdited;
- (void) setIsEdited : (BOOL) flag;

- (NSArray *) boardItems;

- (BOOL) containsItemWithName: (NSString     *) name
					   ofType: (BoardListItemType) aType;
- (id) itemForName : (id) name;
- (id) itemWithNameHavingPrefix : (id) prefix; // tsawada2 2007-02-10 added, For Type-To-Select search.
- (id) itemForName : (id) name ofType: (BoardListItemType) aType;

- (void) item : (id) item
      setName : (NSString     *) name // -representName が変わる（内部で -setName:toItem: が呼ばれるため）
       setURL : (NSString     *) url;
- (void) setName : (NSString *) name toItem : (id) item; // -representName が変わる
- (void)rename:(NSString *)name toItem:(id)item; // -name が変わる
- (void) setURL : (NSString *) urlString toItem : (id) item;

- (NSURL *) URLForBoardName : (id) name;

- (BOOL) addItem : (id) item afterObject : (id) target;
- (void) removeItem : (id) item;

+ (BoardListItemType) typeForItem : (id) item;
+ (BOOL) isBoard : (id) item;
+ (BOOL) isCategory : (id) item;
+ (BOOL) isFavorites : (id) item;

- (void)reloadBoardFile:(NSString *)filepath;
@end
