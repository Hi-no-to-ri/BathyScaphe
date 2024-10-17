//
//  PSPreviewerInterface.h
//  PreviewerSelector
//
//  Created by masakih on 09/03/10.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//


// The PSPreviewerInterface protocol is deprecated.  Use the BSLinkPreviewDelegating protocol in your code.
//#warning PSPreviewerInterface is deprecated.

#import <Foundation/NSObject.h>
#import "BSPreviewPluginInterface.h"

@class BSLPSPreviewerItem;
@class BSLinkPreviewSelector;

__attribute__((deprecated))
@protocol PSPreviewerInterface <NSObject>

- (NSArray *)previewerDisplayNames;
- (NSArray *)previewerIdentifires;

// ##### C A U T I O N !! #####
// YOU DO NOT CALL THESE METHODS WITH YOUR NAME OR IDENTIFIER.
// IT MAY FALL INTO AN INFINITE LOOP.
- (BOOL)openURL:(NSURL *)url inPreviewerByName:(NSString *)previewerName;
- (BOOL)openURL:(NSURL *)url inPreviewerByIdentifier:(NSString *)identifier;

- (NSArray *)previewerItems;	// array of PSPreviewerItem instances.

// for direct controll previewers.
- (NSArray *)previewers;
- (id <BSLinkPreviewing>)previewerByName:(NSString *)name;
- (id <BSLinkPreviewing>)previewerByIdentifier:(NSString *)identifier;
@end


@interface NSObject (PSPreviewerInterface)
+ (id <PSPreviewerInterface>)PSPreviewerSelector;
@end

@interface NSObject (PreviewerOptionalMethod_DEPRECATED)
// this method called, if previewer load by PreviewerSelector.
// all property is ready.
- (void)awakeByPreviewerSelector:(id <PSPreviewerInterface>)previewerSelector;
@end
