//
//  CMXPopUpWindowManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/12/25.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMXPopUpWindowManager.h"
#import "CocoMonar_Prefix.h"
#import "CMXPopUpWindowController.h"
#import "AppDefaults.h"
#import "CMRThreadSignature.h"
#import "BSInnerLinkValueRep.h"

static BOOL NSNearlyEqualPoints(NSPoint point1, NSPoint point2) {
    CGFloat dx = fabs(point1.x - point2.x);
    CGFloat dy = fabs(point1.y - point2.y);
    return ((dx < 1) && (dy < 1));
}

static BOOL NSNearlyEqualFrames(NSRect rect1, NSRect rect2) {
    return (NSEqualSizes(rect1.size, rect2.size) && NSNearlyEqualPoints(rect1.origin, rect2.origin));
}

@implementation CMXPopUpWindowManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (void)dealloc
{
	[bs_controllersArray release];
	[super dealloc];
}

- (NSMutableArray *)controllerArray
{
	if (!bs_controllersArray) {
        bs_controllersArray = [[NSMutableArray alloc] init];
	}
	return bs_controllersArray;
}

- (CMXPopUpWindowController *)availableController
{
	NSMutableArray *array_= [self controllerArray];

    for (CMXPopUpWindowController *controller in array_) {
        if ([controller canPopUpWindow]) {
            return controller;
        }
    }
    CMXPopUpWindowController *controller_;
	
    //
    // すべて使用中
    // 
    controller_ = [[CMXPopUpWindowController alloc] init];
    [controller_ window];

    [array_ addObject:controller_];
    [controller_ release];
	return controller_;
}

- (BOOL)isPopUpWindowVisible
{
    NSMutableArray *array = [self controllerArray];
    for (CMXPopUpWindowController *controller in array) {
        if (![controller canPopUpWindow]) {
            return YES;
        }
    }
	return NO;
}

- (CMXPopUpWindowController *)controllerForObject:(id)object
{
    NSMutableArray *array = [self controllerArray];
    for (CMXPopUpWindowController *controller in array) {
        if ([[controller object] isEqual:object]) {
            return controller;
        }
    }
	return nil;
}

- (BOOL)isSamePopUpWindowVisibleForObject:(id)object atLocation:(NSRect)frame
{
    for (CMXPopUpWindowController *controller in [self controllerArray]) {
        if (![controller canPopUpWindow] && [[controller object] isEqual:object]) {
            NSRect openedPopupFrame = [[controller window] frame];
//            NSLog(@"openedPopupFrame is %@ (frame is %@)", NSStringFromRect(openedPopupFrame), NSStringFromRect(frame));
            if (NSNearlyEqualFrames(frame, openedPopupFrame)) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSWindow *)windowForObject:(id)object
{
	return [[self controllerForObject:object] window];
}

- (BOOL)popUpWindowIsVisibleForObject:(id)object
{
	return [[self windowForObject:object] isVisible];
}

#pragma mark PopUp or Close PopUp
- (id)showPopUpWindowWithContext:(NSAttributedString *)context
                       forObject:(id)object
                           owner:(id)owner
                    locationHint:(NSPoint)point
{
	CMXPopUpWindowController	*controller_;
	
	UTILAssertNotNilArgument(context, @"context");
    CMXPopUpWindowController *openedPopup = [self controllerForObject:object];
    if (openedPopup) {
        // 既に同一内容のポップアップが表示されていて、かつ、ロックされていないポップアップの場合は、ここで処理を終了する（重複ポップアップの発生を抑制）
        if (![openedPopup canPopUpWindow] && [openedPopup isClosable]) {
            // レスアンカーのポップアップの場合、-object は CMRThreadSignature 「ではない」（重複ポップアップ抑制必要）
            // 検索結果、レスの属性抽出、逆参照ポップアップの場合、-object は CMRThreadSignature（重複ポップアップ抑制しない）
            if (![[openedPopup object] isKindOfClass:[CMRThreadSignature class]]) {
                // locationHint が同一点であれば抑制
                NSPoint point2 = [openedPopup givenLocationHint];
                if (NSNearlyEqualPoints(point2, point)) {
                    return nil; // 抑制
                }
            }
        }
    }
	controller_ = [self availableController];
	[controller_ setObject:object];

	// setup UI
	[controller_ setTheme:[CMRPref threadViewTheme]];

	NSRect rect = [controller_ preparePopUpWindowWithContext:context owner:owner locationHint:point];
    if ([self isSamePopUpWindowVisibleForObject:object atLocation:rect]) {
        return nil;
    } else {
        [controller_ showPreparedPopUpWindow];
        return controller_;
    }
}

- (void)closePopUpWindowForOwner:(id)owner
{
    NSMutableArray *array = [self controllerArray];
    for (CMXPopUpWindowController *controller in array) {
        if ([(id)[controller owner] isEqual:owner]) {
            [controller performClose];
        }
    }
}

- (BOOL)performClosePopUpWindowForObject:(id)object
{
	CGFloat insetWidth_;
	CMXPopUpWindowController *controller_;

	controller_ = [self controllerForObject:object];
	if (!controller_) {
		return NO;
	}
	insetWidth_ = [[controller_ class] popUpTrackingInsetWidth];
	if (![controller_ mouseInWindowFrameInset:-insetWidth_]) {
		[controller_ performClose];
		return YES;
	}
	return NO;
}
@end
