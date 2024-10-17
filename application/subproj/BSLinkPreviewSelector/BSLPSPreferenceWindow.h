//
//  HMPreferenceWindow.h
//  BathyScaphe
//
//  Created by msakih on 12/08/04.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSPSPlugInPaneViewController;

@interface BSLPSPreferenceWindow : NSWindowController
{
	BSPSPlugInPaneViewController *_viewController;
}

- (void)setItems:(id)items;
@end
