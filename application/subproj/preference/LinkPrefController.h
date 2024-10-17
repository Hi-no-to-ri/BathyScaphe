//
//  LinkPrefController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/11/14.
//  Copyright 2007 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "PreferencesController.h"


@interface LinkPrefController : PreferencesController {
	IBOutlet NSPopUpButton	*m_downloadDestinationChooser;
	IBOutlet NSTableColumn	*m_pathExtensionColumn;
	
	IBOutlet NSView			*m_previewerPrefPlaceholder;
}

- (IBAction)chooseDestination:(id)sender;

- (NSPopUpButton *)downloadDestinationChooser;

// Binding
- (NSInteger)previewOption;
- (void)setPreviewOption:(NSInteger)selectedTag;

- (void)updateFolderButtonUI;
@end
