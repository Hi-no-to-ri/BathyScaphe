//
//  BSLastUpdatedHeaderCell.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/11/19.
//  Copyright 2011-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLastUpdatedHeaderCell.h"
#import <SGAppKit/SGAppKit.h>

@implementation BSLastUpdatedHeaderCell
- (id)initWithImageNameBase:(NSString *)imageNameBase searchCustomized:(BOOL)isCustomized
{
    if (self = [super initImageCell:nil]) {
        NSString *imageNameLeft = [imageNameBase stringByAppendingString:@"Left"];
        NSString *imageNameMiddle = [imageNameBase stringByAppendingString:@"Middle"];
        NSString *imageNameRight = [imageNameBase stringByAppendingString:@"Right"];
        
        if (isCustomized) {
            // App Support 内のイメージで構成できるか確認する
            NSImage *appLeftImage = [NSImage imageAppNamed:imageNameLeft searchNamed:NO];
            NSImage *appMiddleImage = [NSImage imageAppNamed:imageNameMiddle searchNamed:NO];
            NSImage *appRightImage = [NSImage imageAppNamed:imageNameRight searchNamed:NO];
            
            // 少なくとも左と真ん中のパーツがあればいい。右パーツは省略されていてもいい
            if (appLeftImage && appMiddleImage) {
                [self setImage:appLeftImage];
                m_middleImage = [appMiddleImage retain];
                m_rightImage = appRightImage ? [appRightImage retain] : nil;
            } else {
                // 必要なリソースが無い
                [self autorelease];
                return nil;
            }
        } else {
            // 内蔵リソース内のイメージで構成できるか確認する
            NSImage *internalLeftImage = [NSImage imageNamed:imageNameLeft];
            NSImage *internalMiddleImage = [NSImage imageNamed:imageNameMiddle];
            NSImage *internalRightImage = [NSImage imageNamed:imageNameRight];

            // 少なくとも左と真ん中のパーツがあればいい。右パーツは省略されていてもいい
            if (internalLeftImage && internalMiddleImage) {
                [self setImage:internalLeftImage];
                m_middleImage = [internalMiddleImage retain];
                m_rightImage = internalRightImage ? [internalRightImage retain] : nil;
            } else {
                // 必要なリソースが無い
                [self autorelease];
                return nil;
            }
        }
    }
    return self;
}

- (void)dealloc
{
    [m_middleImage release];
    [m_rightImage release];
    [super dealloc];
}

- (NSRect)cellFrameForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(NSUInteger)charIndex
{
    NSRect originalRect = [super cellFrameForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];

    NSTextView *textView = [textContainer textView];
    CGFloat textViewWidth = NSWidth([textView frame]);
    CGFloat imageWidth = textViewWidth - 10;
    CGFloat imageHeight = originalRect.size.height;
    
    return NSMakeRect(originalRect.origin.x, originalRect.origin.y, imageWidth, imageHeight);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView
{
    NSDrawThreePartImage(cellFrame, [self image], m_middleImage, m_rightImage, NO, NSCompositeSourceOver, 1.0, [aView isFlipped]);
}

- (BOOL)wantsToTrackMouse
{
    return NO;
}
@end
