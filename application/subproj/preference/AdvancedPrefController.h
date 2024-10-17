//
//  AdvancedPrefController.h
//  BathyScaphe
//
//  Created by tsawada2 on 05/05/22.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "PreferencesController.h"

@interface AdvancedPrefController : PreferencesController {
    IBOutlet NSComboBox *m_bbsMenuURLChooser;
}

- (NSComboBox *)bbsMenuURLChooser;

- (IBAction)didChooseBbsMenuURL:(id)sender;
@end
