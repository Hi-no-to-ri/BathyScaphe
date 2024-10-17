//
//  BSIPIPreferencesController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/08/31.
//  Copyright 2008 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIPreferencesController.h"
#import "BSIPIDefaults.h"
#import <CocoMonar/CMRSingletonObject.h>


@implementation BSIPIPreferencesController
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedPreferencesController);

- (id)init
{
	if (self = [super initWithWindowNibName:@"BSIPIPreferences"]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDirectoryDidChange:) name:BSIPIDefaultsSaveDirectoryDidChangeNotification object:[BSIPIDefaults sharedIPIDefaults]];
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BSIPIDefaultsSaveDirectoryDidChangeNotification object:[BSIPIDefaults sharedIPIDefaults]];
    [super dealloc];
}

- (NSPopUpButton *)directoryChooser
{
	return m_directoryChooser;
}

- (NSSegmentedControl *)preferredViewSelector
{
	return m_preferredViewSelector;
}

- (NSMatrix *)fullScreenSettingMatrix
{
	return m_fullScreenSettingMatrix;
}

- (IBAction)openOpenPanel:(id)sender
{
	NSOpenPanel	*panel_ = [NSOpenPanel openPanel];
	[panel_ setCanChooseFiles:NO];
	[panel_ setCanChooseDirectories:YES];
	[panel_ setResolvesAliases:YES];
	[panel_ setAllowsMultipleSelection:NO];
    [panel_ beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            [[BSIPIDefaults sharedIPIDefaults] setSaveDirectory:[[[panel_ URLs] lastObject] path]];
        }
//        [self updateDirectoryChooser];
    }];
}

- (void)saveDirectoryDidChange:(NSNotification *)notification
{
    [self updateDirectoryChooser];
}

static NSImage *bsIPI_iconForPath(NSString *sourcePath)
{
	NSImage	*icon_ = [[NSWorkspace sharedWorkspace] iconForFile:sourcePath];
	[icon_ setSize:NSMakeSize(16, 16)];
	return icon_;
}

- (void)updateDirectoryChooser
{
	NSString	*fullPathTip = [[BSIPIDefaults sharedIPIDefaults] saveDirectory];
	NSString	*title = [[NSFileManager defaultManager] displayNameAtPath:fullPathTip];
	NSMenuItem	*theItem = [[self directoryChooser] itemAtIndex:0];
	
	[theItem setTitle:title];
	[theItem setToolTip:fullPathTip];
	[theItem setImage:bsIPI_iconForPath(fullPathTip)];

	[[self directoryChooser] selectItem:nil];
	[[self directoryChooser] synchronizeTitleAndSelectedItem];
}

- (void)setupSettingsPanel
{
	[[self preferredViewSelector] setLabel:nil forSegment:0];
	[[self preferredViewSelector] setLabel:nil forSegment:1];
}

- (void)awakeFromNib
{
	[m_defaultsController setContent:[BSIPIDefaults sharedIPIDefaults]];
	[self updateDirectoryChooser];
	[self setupSettingsPanel];
}
@end
