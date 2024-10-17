//
//  HMPlugInPaneViewController.h
//  BathyScaphe
//
//  Created by masakih on 12/08/04.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSLPSPreviewerItem;

@interface BSPSPlugInPaneViewController : NSViewController
{
	NSArrayController *_itemsController;
	NSArray *_items;
	
	NSView *_itemPreferencePlaceholder;
	NSView *_defaultPreferenceView;
	NSView *_currentItemPreferenceView;
	
	NSTableView *_itemsListView;
	NSScrollView *_scrollView;
}
@property (assign) IBOutlet NSArrayController *itemsController;
@property (assign) IBOutlet NSView *defaultPreferenceView;
@property (assign) IBOutlet NSView *itemPreferencePlaceholder;
@property (assign) IBOutlet NSTableView *itemsListView;
@property (assign) IBOutlet NSScrollView *scrollView;

@property (readonly) BSLPSPreviewerItem *selection;

- (IBAction)openPreferences:(id)sender;
- (IBAction)toggleAPlugin:(id)sender;

- (IBAction)addPlugIn:(id)sender;
- (IBAction)removePlugIn:(id)sender;
@end
