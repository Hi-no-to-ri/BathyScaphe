//
//  BSBoardListCellView.m
//  SGAppKit
//
//  Created by Tsutomu Sawada on 2014/07/28.
//
//

#import "BSBoardListCellView.h"
#if 0
#import "NSImage-SGExtensions.h"
#endif

@implementation BSBoardListCellView
#if 0
@synthesize imageNameBase = m_imageNameBase;
// 実際のところ -dealloc はほとんど呼ばれない（呼ばれたときも、binding 確立していないときだった）
// まずは -unbind: しないで様子を見る
- (void)dealloc
{
    [self.imageView unbind:@"hidden"];

    [m_imageNameBase release];
    [super dealloc];
}
- (NSImage *)iconForCellView
{
    if (!m_imageNameBase) {
        return nil;
    }
    
    NSString *iconName;
    NSInteger style = self.rowSizeStyle;
    
    if (style == NSTableViewRowSizeStyleMedium) {
        iconName = [[m_imageNameBase stringByAppendingString:@"Medium"] stringByAppendingString:@"Template"];
    } else if (style == NSTableViewRowSizeStyleLarge) {
        iconName = [[m_imageNameBase stringByAppendingString:@"Large"] stringByAppendingString:@"Template"];
    } else {
        iconName = [m_imageNameBase stringByAppendingString:@"Template"];
    }
    
    return [NSImage imageAppNamed:iconName];
}
#endif
- (void)viewWillDraw
{
    [super viewWillDraw];
    // アイコンを表示しないときはテキストフィールドの位置をアイコンの位置までずらし、横幅を拡大する
    if ([self.imageView isHidden]) {
        NSRect textFrame = self.textField.frame;
        NSRect imageFrame = self.imageView.frame;
        textFrame.size.width += NSMinX(textFrame) - NSMinX(imageFrame);
        textFrame.origin.x = imageFrame.origin.x;
        self.textField.frame = textFrame;
#if 0
    } else {
        self.imageView.image = [self iconForCellView];
#endif
    }
}
@end
