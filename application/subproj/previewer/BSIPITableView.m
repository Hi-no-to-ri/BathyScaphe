//
//  BSIPITableView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/07/10.
//  Copyright 2006-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPITableView.h"

@implementation BSIPITableView
- (BOOL)needsPanelToBecomeKey
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(tableView:shouldPerformKeyEquivalent:)]) {
		return [delegate tableView:self shouldPerformKeyEquivalent:theEvent];
	}

	return [super performKeyEquivalent:theEvent];
}

- (NSUInteger)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationCopy;
}
@end
