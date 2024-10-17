//
//  CMRMainMenuManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/18.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSLabelMenuItemView;


@interface CMRMainMenuManager : NSObject {
    BSLabelMenuItemView *m_labelMenuItemView;
}

+ (id)defaultManager;

- (NSMenuItem *)applicationMenuItem;
- (NSMenuItem *)fileMenuItem;
- (NSMenuItem *)editMenuItem;
- (NSMenuItem *)browserMenuItem;
- (NSMenuItem *)historyMenuItem;
- (NSMenuItem *)BBSMenuItem;
- (NSMenuItem *)threadMenuItem;
- (NSMenuItem *)windowMenuItem;
- (NSMenuItem *)helpMenuItem;
- (NSMenuItem *)scriptsMenuItem;

- (NSInteger)historyItemInsertionIndex;
- (NSMenu *)historyMenu;
- (NSMenu *)boardHistoryMenu; // Available in Starlight Breaker and later.
- (NSMenu *)fileMenu;
- (NSMenu *)templatesMenu; // Available in SilverGull and later.

- (NSMenu *)threadContexualMenuTemplate; // Available in Twincam Angel and later.

- (void)updateScriptsMenuIcon;
@end


@interface CMRMainMenuManager(CMRApp)
- (NSMenuItem *)browserListColumnsMenuItem;
- (NSMenuItem *)threadLabelsMenuItem;

- (void)removeDebugMenuItemIfNeeded;
- (void)setupLabelMenuItems:(NSNotification *)aNotification;
@end
