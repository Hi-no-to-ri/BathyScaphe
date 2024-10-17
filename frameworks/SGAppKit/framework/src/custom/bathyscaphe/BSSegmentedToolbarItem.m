//
//  BSSegmentedToolbarItem.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/08/30.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSSegmentedToolbarItem.h"

@implementation BSSegmentedToolbarItem
- (BOOL)isSelectedForSegment:(NSInteger)segment
{
    return [(NSSegmentedControl *)[self view] isSelectedForSegment:segment];
}

- (void)setSelected:(BOOL)flag forSegment:(NSInteger)segment
{
    [(NSSegmentedControl *)[self view] setSelected:flag forSegment:segment];
}

- (void)validate
{
    id segmentedControl = [self view];
    if (!segmentedControl) {
        return;
    }
    
    if ([segmentedControl action] == NULL) {
        return;
    }
    
    id targetObject = [NSApp targetForAction:[segmentedControl action] to:[segmentedControl target] from:self];
    
    if (targetObject && [targetObject respondsToSelector:@selector(segmentedToolbarItem:validateSegment:)]) {
        [segmentedControl setEnabled:YES];
        [[self menuFormRepresentation] setEnabled:YES];

        NSInteger i;
        NSInteger numOfSegments;
        numOfSegments = [segmentedControl segmentCount];
        for(i = 0; i < numOfSegments; i++) {
        
        BOOL enabled = [targetObject segmentedToolbarItem:self validateSegment:i];
            [segmentedControl setEnabled:enabled forSegment:i];
        }
    } else {
        [segmentedControl setEnabled:NO];
        [[self menuFormRepresentation] setEnabled:NO];
    }
}
@end
