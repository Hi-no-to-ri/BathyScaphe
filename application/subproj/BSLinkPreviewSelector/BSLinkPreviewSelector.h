//
//  BSLinkPreviewSelector.h
//  PreviewerSelector
//
//  Created by masakih on 06/05/07.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

#import "BSImagePreviewerInterface.h"
#import "BSPreviewPluginInterface.h"

@class BSLPSPreviewerItems, BSLPSPreviewerItem;
@class BSLPSSImplePreferenceViewController;

@class BSLPSPreferenceWindow;

@interface BSLinkPreviewSelector : NSObject <BSLinkPreviewing>
{
	AppDefaults *_preferences;
	BSLPSPreviewerItems *_items;
	
	BSLPSSImplePreferenceViewController *prefViewController;
	BSLPSPreferenceWindow *_preferenceWindow;
}

+ (id)sharedInstance;

- (NSString *)plugInsDirectory;

- (NSArray *)loadedPlugInsInfo;

- (void)savePlugInsInfo;
//- (void)restorePlugInsInfo;

- (id)preferenceForKey:(id)key;
- (void)setPreference:(id)pref forKey:(id)key;

- (NSView *)preferenceView;

// 
- (void)addItem:(BSLPSPreviewerItem *)item;
- (void)addItemFromBundle:(NSBundle *)plugin;
- (void)addItemFromURL:(NSURL *)url;
- (void)removeItem:(BSLPSPreviewerItem *)item;
- (void)moveItem:(BSLPSPreviewerItem *)item toIndex:(NSUInteger)index;
- (NSUInteger)itemCount;
- (BSLPSPreviewerItem *)itemAtIndex:(NSUInteger)index;

@end

@interface BSLinkPreviewSelector (PSPreviewerInterface_Support)
- (void)rebuildPreviewers;
@end

#define PSLocalizedString( str, comment ) \
NSLocalizedStringFromTableInBundle( (str), @"Localizable", [NSBundle bundleForClass:[BSLinkPreviewSelector class]], (comment) )

#define AppIdentifierString @"jp.tsawada2.bathyscaphe.BSLinkPreviewSelector"
extern NSString *keyPrefPlugInsInfo;

