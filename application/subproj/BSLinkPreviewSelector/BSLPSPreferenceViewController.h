//
//  PreviewerSelectorPreferenceViewController.h
//  PreviewerSelector
//
//  Created by masakih on 12/07/15.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSLPSPreferenceViewController : NSViewController
{
	IBOutlet NSArrayController *itemsController;
	NSTableView *_tableView;
	NSArray *plugInList;
}
@property (assign, nonatomic) IBOutlet NSTableView *tableView;

- (id)init;

- (void)setPlugInList:(id)list;

- (IBAction)openPreferences:(id)sender;
- (IBAction)toggleAPlugin:(id)sender;
@end
