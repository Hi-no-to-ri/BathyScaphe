//
//  BSFindBarViewController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/11/04.
//
//

#import <Cocoa/Cocoa.h>

@interface BSFindBarViewController : NSViewController {
    IBOutlet NSPopUpButton *searchOptionButton;
    IBOutlet NSPopUpButton *searchTargetButton;
    
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSTextField *statusField;
}

- (IBAction)chooseSearchOption:(id)sender;
- (IBAction)chooseSearchTarget:(id)sender;

- (void)setStatusText:(NSString *)msg status:(BOOL)isSearching;
@end
