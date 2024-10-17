//
//  BSNoThreadsView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2012/11/01.
//
//

#import "BSNoThreadsView.h"

@implementation BSNoThreadsView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor whiteColor] set]; // 念のため
    NSRectFill(dirtyRect);
    // ざらざらパターンを被せる
    NSColor *noize = [NSColor colorWithPatternImage:[NSImage imageNamed:@"BSNoThreadsViewBgPattern"]];
    [noize set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}

- (BOOL)isOpaque
{
    return YES;
}
@end
