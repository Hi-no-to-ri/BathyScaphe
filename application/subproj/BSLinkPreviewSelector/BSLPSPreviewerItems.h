//
//  BSLPSPreviewerItems.h
//  PreviewerSelector
//
//  Created by masakih on 10/09/12.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

#import "BSLPSPreviewerItem.h"


@interface BSLPSPreviewerItems : NSObject
{
	NSMutableArray *_previewerItems;
	
	NSMutableArray *_deletedPreviewerItemIDs;
}

- (void)setPreference:(id)pref;

@property (readonly) NSArray *previewerItems;

- (void)addItem:(BSLPSPreviewerItem *)item;
- (void)addItemFromBundle:(NSBundle *)plugin;
- (void)addItemFromURL:(NSURL *)url;
- (void)removeItem:(BSLPSPreviewerItem *)item;
- (void)moveItem:(BSLPSPreviewerItem *)item toIndex:(NSUInteger)index;
- (NSUInteger)itemCount;
- (BSLPSPreviewerItem *)itemAtIndex:(NSUInteger)index;

@end
