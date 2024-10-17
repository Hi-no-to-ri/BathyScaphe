//
//  BSLPSTableView.m
//  PreviewerSelector
//
//  Created by masakih 07/11/24.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSTableView.h"


@implementation BSLPSTableView

- (void)rightMouseDown:(NSEvent *)event
{
	NSPoint mouse = [self convertPoint:[event locationInWindow] fromView:nil];
	
	int row = [self rowAtPoint:mouse];
	
	[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
	  byExtendingSelection:NO];
	
	[super rightMouseDown:event];
}
@end
