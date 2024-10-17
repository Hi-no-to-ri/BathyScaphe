//
//  BSSimpleBackgroundView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/11/04.
//
//

#import "BSSimpleBackgroundView.h"

@implementation BSSimpleBackgroundView

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
	[super drawRect:dirtyRect];
	
    // Drawing code here.
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
    
    [[NSColor gridColor] set];
    NSRectFill(NSMakeRect([self frame].origin.x, [self frame].origin.y + [self frame].size.height - 1, [self frame].size.width, 1));
}

- (BOOL)isOpaque
{
    return YES;
}
@end
