//
//  CMRReplyControllerTbDelegate.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/09.
//  Copyright 2007-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRToolbarDelegateImp.h"

@interface CMRReplyControllerTbDelegate : CMRToolbarDelegateImp {
    IBOutlet NSView *replyTopLevelCustomView;
    IBOutlet NSButton *m_sendButton;
    IBOutlet NSButton *m_fontButton;
    IBOutlet NSButton *m_localRulesButton;
    IBOutlet NSSegmentedControl *m_accountsButton;
    
    IBOutlet NSButton *m_toggleBeButton;
    IBOutlet NSButton *m_toggleRoninButton;
    IBOutlet NSButton *m_toggleP2Button;
}

- (NSButton *)sendButton;
- (NSButton *)fontButton;
- (NSButton *)localRulesButton;
- (NSSegmentedControl *)accountsButton __attribute__((deprecated));

- (NSButton *)toggleBeButton;
- (NSButton *)toggleRoninButton;
- (NSButton *)toggleP2Button;

@end


@interface BSNewThreadControllerTbDelegate : CMRReplyControllerTbDelegate

@end
