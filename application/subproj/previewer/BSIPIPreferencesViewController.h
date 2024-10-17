//
//  BSIPIPreferencesViewController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2015/02/07.
//
//

#import <Cocoa/Cocoa.h>

@interface BSIPIPreferencesViewController : NSViewController {
    IBOutlet NSPopUpButton			*m_directoryChooser;
    IBOutlet NSSegmentedControl		*m_preferredViewSelector;
    IBOutlet NSMatrix				*m_fullScreenSettingMatrix;
    IBOutlet NSObjectController		*m_defaultsController;
}

+ (id)sharedPreferencesController;

- (IBAction)openOpenPanel:(id)sender;

- (NSPopUpButton *)directoryChooser;
- (NSSegmentedControl *)preferredViewSelector;
- (NSMatrix *)fullScreenSettingMatrix;

- (void)updateDirectoryChooser;
@end
