//
//  BSHorizontalRuleCell.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/10/16.
//
//

#import "BSHorizontalRuleCell.h"
#import "AppDefaults.h"

@implementation BSHorizontalRuleCell
- (NSRect)cellFrameForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(NSUInteger)charIndex
{
    NSRect originalRect = [super cellFrameForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    
    CGFloat textContainerWidth = [textContainer containerSize].width;
    CGFloat hrWidth = textContainerWidth - (10 + [CMRPref messageHeadIndent]);
    CGFloat hrFrameHeight = lineFrag.size.height;
    
    if (hrWidth < 0) {
        hrWidth = 0;
    }
    
    return NSMakeRect(originalRect.origin.x, originalRect.origin.y, hrWidth, hrFrameHeight);
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView
{
    NSRect newFrame;
    CGFloat center = cellFrame.size.height / 2;
    newFrame.origin.x = floor(cellFrame.origin.x);
    newFrame.origin.y = floor(cellFrame.origin.y + center);
    newFrame.size.width = cellFrame.size.width;
    newFrame.size.height = 1;
    
    [[NSColor controlShadowColor] set];
    NSRectFill(newFrame);
    
    newFrame.origin.y += 1;
    [[NSColor controlLightHighlightColor] set];
    NSRectFill(newFrame);
}

- (BOOL)wantsToTrackMouse
{
    return NO;
}
@end
