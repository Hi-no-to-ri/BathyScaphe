//
//  CMRFilterPrefController.h
//  BachyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/11.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "PreferencesController.h"


@interface CMRFilterPrefController : PreferencesController
{
    IBOutlet NSButton *m_firstSymbolButton;
    IBOutlet NSButton *m_overseaSymbolButton;
    IBOutlet NSObjectController *m_preferencesObjectController;
}

- (NSObjectController *)preferencesObjectController;

- (IBAction)resetSpamDB:(id)sender;
- (IBAction)openNGExpressionsEditorSheet:(id)sender;

- (IBAction)openThemeEditorForColorSetting:(id)sender;
@end
