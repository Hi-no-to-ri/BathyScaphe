//
//  BSSegmentedToolbarItem.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/08/30.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSSegmentedToolbarItem : NSToolbarItem {
}

- (BOOL)isSelectedForSegment:(NSInteger)segment;
- (void)setSelected:(BOOL)flag forSegment:(NSInteger)segment;
@end


@interface NSObject(BSSegmentedToolbarItemValidation)
- (BOOL)segmentedToolbarItem:(BSSegmentedToolbarItem *)item validateSegment:(NSInteger)segment;
@end
