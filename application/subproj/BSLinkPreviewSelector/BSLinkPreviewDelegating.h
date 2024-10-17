//
//  BSLinkPreviewDelegating.h
//  BathyScaphe
//
//  Created by masakih on 13/02/24.
//  Copyright 2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/NSObject.h>
#import "BSPreviewPluginInterface.h"

@class BSLPSPreviewerItem;
@class BSLinkPreviewSelector;

@protocol BSLinkPreviewDelegating <NSObject>

- (NSArray *)previewerDisplayNames;
- (NSArray *)previewerIdentifires;

// ##### C A U T I O N !! #####
// YOU DO NOT CALL THESE METHODS WITH YOUR NAME OR IDENTIFIER.
// IT MAY FALL INTO AN INFINITE LOOP.
- (BOOL)openURL:(NSURL *)url inPreviewerByName:(NSString *)previewerName;
- (BOOL)openURL:(NSURL *)url inPreviewerByIdentifier:(NSString *)identifier;

- (NSArray *)previewerItems;	// array of BSLPSPreviewerItem instances.

// for direct controll previewers.
- (NSArray *)previewers;
- (id <BSLinkPreviewing>)previewerByName:(NSString *)name;
- (id <BSLinkPreviewing>)previewerByIdentifier:(NSString *)identifier;
@end


@interface NSObject (BSLinkPreviewDelegating)
+ (id <BSLinkPreviewDelegating>)BSLinkPreviewSelector;
@end

@interface NSObject (PreviewerOptionalMethod)
// this method called, if previewer load by BSLinkPreviewSelector.
// all property is ready.
- (void)awakeByLinkPreviewSelector:(id <BSLinkPreviewDelegating>)previewerSelector;
@end


// 使用可能なプレビューアーの構成が変更されたときに通知される
extern NSString *BSLinkPreviewSelectorDidChangeItemsNotification;
extern NSString *BSLinkPreviewSelectorItemChangeTypeNotificationKey;	// NSNumber
extern NSString *BSLinkPreviewSelectorChangedItemNameNotificationKey;	// NSString
extern NSString *BSLinkPreviewSelectorChangedItemNotificationKey;	// id<BSLinkPreviewing>
extern NSString *BSLinkPreviewSelectorChangedItemIdentifierNotificationKey;	// NSString

enum {
	BSLinkPreviewSelectorRemoveItemType,
	BSLinkPreviewSelectorAddItemType,
};
