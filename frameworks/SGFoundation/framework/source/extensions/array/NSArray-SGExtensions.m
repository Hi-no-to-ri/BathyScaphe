//
//  NSArray-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSArray-SGExtensions.h"


@implementation NSArray(SGExtensions)
+ (id)empty
{
	static id kSharedInstance;
	if (!kSharedInstance) {
		kSharedInstance = [[NSArray alloc] init];
	}
	return kSharedInstance;
}

- (BOOL)isEmpty
{
	return (0 == [self count]);
}
@end
