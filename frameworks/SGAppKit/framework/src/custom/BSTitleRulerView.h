//
//  BSTitleRulerView.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/09/22.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BSFlatTitleRulerAppearance;

typedef NS_ENUM(NSUInteger, BSTitleRulerModeType) {
	BSTitleRulerShowTitleOnlyMode		= 0, // スレッドタイトルバーのみ
	BSTitleRulerShowInfoOnlyMode		= 1, // 「dat 落ちと判定されました。」のみ
	BSTitleRulerShowTitleAndInfoMode	= 2, // スレッドタイトルバー、その下に「dat 落ちと判定されました。」
};

@interface BSTitleRulerView : NSRulerView {
	@private
	BSFlatTitleRulerAppearance *m_appearance;

	NSString	*m_titleStr;
	NSString	*m_infoStr;
	NSString	*m_pathStr;

	BSTitleRulerModeType	_currentMode;
    
    BOOL    isYosemite;

    NSTextField *m_titleField;
}

// Designated initializer. Available in BathyScaphe 2.4.3 "Matatabi-Step" and later.
- (id)initWithScrollView:(NSScrollView *)aScrollView appearance:(BSFlatTitleRulerAppearance *)appearance;

- (BSFlatTitleRulerAppearance *)appearance;
- (void)setAppearance:(BSFlatTitleRulerAppearance *)anAppearance;

- (NSString *)titleStr;
- (void)setTitleStr:(NSString *)aString;

- (NSString *)infoStr;
- (void)setInfoStr:(NSString *)aString;

- (NSString *)pathStr;
- (void)setPathStr:(NSString *)aString;

- (BSTitleRulerModeType)currentMode;
- (void)setCurrentMode:(BSTitleRulerModeType)newType;
@end
