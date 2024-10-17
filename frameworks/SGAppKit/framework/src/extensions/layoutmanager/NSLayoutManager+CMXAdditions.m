//
//  NSLayoutManager+CMXAdditions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSLayoutManager+CMXAdditions.h"
#import <AppKit/AppKit.h>

@implementation NSLayoutManager(CMXAdditions)
- (NSRect)boundingRectForTextContainer:(NSTextContainer *)aContainer
{
	return [self boundingRectForGlyphRange:[self glyphRangeForTextContainer:aContainer] inTextContainer:aContainer];
}
@end
