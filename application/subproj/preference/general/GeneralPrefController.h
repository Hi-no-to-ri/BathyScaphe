//
//  GeneralPrefController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/07/19.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"


@interface GeneralPrefController : PreferencesController {
    IBOutlet NSMatrix *m_autoscrollRadioButtons;
}

- (NSMatrix *)autoscrollRadioButtons;

- (IBAction)changeAutoscrollSettings:(id)sender;
@end
