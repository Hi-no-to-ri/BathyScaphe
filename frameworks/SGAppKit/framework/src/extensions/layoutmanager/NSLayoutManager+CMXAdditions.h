//
//  NSLayoutManager+CMXAdditions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/07.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSLayoutManager.h>

@class NSTextContainer;

@interface NSLayoutManager(CMXAdditions)
- (NSRect)boundingRectForTextContainer:(NSTextContainer *)aContainer;
@end
