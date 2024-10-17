//
//  SGHTMLView.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/28.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@protocol SGHTMLViewDelegate;

@interface SGHTMLView:NSTextView
{
	@private
    // 自身がポップアップウインドウ上にあるときの、mouseExited 判定用
    NSTrackingArea *bs_visibleArea;
}

- (BOOL)mouseClicked:(NSEvent *)theEvent atIndex:(NSUInteger)charIndex;

- (id<SGHTMLViewDelegate>)delegate;
- (void)setDelegate:(id<SGHTMLViewDelegate>)aDelegate;
@end


@protocol SGHTMLViewDelegate<NSTextViewDelegate, NSObject>
@optional
- (NSArray *)HTMLViewFilteringLinkSchemes:(SGHTMLView *)aView;

- (void)HTMLView:(SGHTMLView *)aView mouseEnteredInTrackingArea:(NSTrackingArea *)area withEvent:(NSEvent *)anEvent;
- (void)HTMLView:(SGHTMLView *)aView mouseExitedFromTrackingArea:(NSTrackingArea *)area withEvent:(NSEvent *)anEvent;

- (BOOL)HTMLView:(SGHTMLView *)aView mouseClicked:(NSEvent *)theEvent atIndex:(NSUInteger)charIndex;

// continuous mouseDown
- (BOOL)HTMLView:(SGHTMLView *)aView shouldHandleContinuousMouseDown:(NSEvent *)theEvent;
- (BOOL)HTMLView:(SGHTMLView *)aView continuousMouseDown:(NSEvent *)theEvent;

// リンク先のファイルをダウンロード：-linkMenuWithLink: 用
- (NSDictionary *)refererThreadInfoForLinkDownloader; // implemented in CMRThreadViewer-Link.m 暫定
@end

// Notification
extern NSString *const SGHTMLViewMouseEnteredNotification;
extern NSString *const SGHTMLViewMouseExitedNotification;

// userData dict keys. for -HTMLView:mouseEnteredInLink:inTrackingRect:withEvent: and -HTMLView:mouseExitedFromLink:inTrackingRect:withEvent.
extern NSString *const SGHTMLViewLinkUserDataAttributeNameKey;
extern NSString *const SGHTMLViewLinkUserDataLinkValueKey;
extern NSString *const SGHTMLViewLinkUserDataFieldHintKey; // YES (as NSNumber) if link text is on 'ID' field, NO otherwise.
