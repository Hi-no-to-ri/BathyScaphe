//
//  CMRThreadsList.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/01/05.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CocoMonar_Prefix.h"
#import "BSThreadsListDataSource.h"

enum {
    kValueTemplateDefaultType,
    kValueTemplateNewArrivalType,
    kValueTemplateNewUnknownType,
    kValueTemplateDatOchiType // Available in Starlight Breaker.
};

@interface CMRThreadsList : NSObject<NSTableViewDelegate>
{
    NSArray *_threads;
    NSArray *_filteredThreads;

    NSOperationQueue *_operationQueue; // retain しない
}

@property(readwrite, assign) NSOperationQueue *operationQueue;

- (void)startLoadingThreadsList;
- (void)doLoadThreadsList;

- (BOOL)isFavorites;
- (BOOL)isSmartItem;
- (BOOL)isBoard; // Available in Tenori Tiger.

- (void)rebuildThreadsList; // Available in Tenori Tiger.
@end


@interface CMRThreadsList(CleanUp)
- (void)cleanUpItemsToBeRemoved:(NSArray *)files;

- (BOOL)tableView:(NSTableView *)tableView removeFiles:(NSArray *)files;
- (BOOL)removeDatochiFiles;
@end


@interface CMRThreadsList(AccessingList)
- (NSArray *)threads;
- (void)setThreads:(NSArray *)aThreads;
- (NSArray *)filteredThreads;
- (void)setFilteredThreads:(NSArray *)aFilteredThreads;
@end

 
@interface CMRThreadsList(Attributes)
- (NSString *)boardName;
- (NSURL *)boardURL;

- (NSUInteger)numberOfThreads;
- (NSUInteger)numberOfFilteredThreads;
@end


@interface CMRThreadsList(Filter)
// Available in MeteorSweeper.
- (BOOL)filterByString:(NSString *)searchString;
@end


@interface CMRThreadsList(DataSource)<CMRThreadsListDataSource>
+ (void)resetDataSourceTemplates;
+ (void)resetDataSourceTemplateForColumnIdentifier:(NSString *)identifier width:(CGFloat)loc;
+ (void)resetDataSourceTemplateForDateColumn;

+ (NSDictionary *)threadCreatedDateAttrTemplate;
+ (NSDictionary *)threadModifiedDateAttrTemplate;
+ (NSDictionary *)threadLastWrittenDateAttrTemplate;

+ (id)objectValueTemplate:(id)aValue forType:(NSInteger)aType;
@end


@interface CMRThreadsList(DraggingImage)
- (NSImage *)dragImageForRowIndexes:(NSIndexSet *)rowIndexes inTableView:(NSTableView *)tableView offset:(NSPointPointer)dragImageOffset;
@end


@interface CMRThreadsList(Download)
- (void)downloadThreadsList;
@end


@interface CMRThreadsList(ListImport)
+ (NSMutableDictionary *)attributesForThreadsListWithContentsOfFile:(NSString *)path;
@end

// Notification
extern NSString *const CMRThreadsListDidChangeNotification;
