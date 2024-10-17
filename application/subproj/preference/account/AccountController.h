//
//  AccountController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/11/21.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"

@class BSAccountViewController;

@interface AccountController : PreferencesController<NSOutlineViewDataSource, NSOutlineViewDelegate>
{    
    NSArray *_topLevelItems;
    NSDictionary *_childrenDict;
    
    IBOutlet NSOutlineView *_sidebar;
    IBOutlet NSView *_boxView;
    BSAccountViewController *_currentViewController;
}
@end
