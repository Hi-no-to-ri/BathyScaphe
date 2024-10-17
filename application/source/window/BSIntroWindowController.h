//
//  BSIntroWindowController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2015/01/17.
//
//

#import <Cocoa/Cocoa.h>

@interface BSIntroWindowController : NSWindowController {
    IBOutlet NSView *m_baseView;
    IBOutlet NSButton *m_qsButton;
    IBOutlet NSButton *m_wnButton;
}

- (IBAction)showQuickstart:(id)sender;
- (IBAction)showWhatsnew:(id)sender;
- (IBAction)closeIntro:(id)sender;

@end
