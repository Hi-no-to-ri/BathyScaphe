//
//  DTRangeDictionary.m
//  DTMarkdownParser
//
//  Created by Oliver Drobnik on 01/11/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

//  Edited by Tsutomu Sawada (BathyScaphe Project) on 15/06/14.

#import "DTRangesArray.h"

@implementation DTRangesArray
// BathyScaphe Comment-outed: this is only supported on modern runtime (64bit).
//{
//	NSRange *_ranges;
//	NSUInteger _count;
//	NSUInteger _capacity;
//}

- (void)dealloc
{
	free(_ranges);
    // BathyScaphe Added: BathyScaphe is currently on no-ARC environment.
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

#pragma mark - Enumerating Ranges

- (void)enumerateLineRangesUsingBlock:(void(^)(NSRange range, NSUInteger idx, BOOL *stop))block
{
	NSParameterAssert(block);
	
	for (NSUInteger idx = 0; idx<_count; idx++)
	{
		NSRange range = _ranges[idx];
		BOOL stop = NO;
		
		block(range, idx, &stop);
		
		if (stop)
		{
			break;
		}
	}
}

- (void)bs_slideLineRangesForLength:(NSInteger)changeInLength fromLocation:(NSUInteger)fromLocation
{
    for (NSUInteger idx = 0; idx<_count; idx++)
    {
        if (_ranges[idx].location >= fromLocation)
        {
            _ranges[idx].location += changeInLength;
        }
    }
}

- (void)bs_slideLineRangesForLength:(NSInteger)changeInLength firstTargetIndex:(NSUInteger)baseIndex
{
    NSAssert(baseIndex<_count, @"baseIndex over count");
    
    for (NSUInteger idx = baseIndex; idx<_count; idx++)
    {
        _ranges[idx].location += changeInLength;
    }
}

- (void)bs_extendRangeAtIndex:(NSUInteger)baseIndex forLength:(NSInteger)extensionLength
{
    NSAssert(baseIndex<_count, @"baseIndex over count");
    
    _ranges[baseIndex].length += extensionLength;
    
    if (baseIndex+1<_count) {
        [self bs_slideLineRangesForLength:extensionLength firstTargetIndex:baseIndex+1];
    }
}

#pragma mark - Getting Information

- (NSUInteger)count
{
	return _count;
}

- (NSRangePointer)bs_ranges
{
    NSAssert(_count>0, @"Count is zero!");
    return _ranges;
}

#pragma mark - Modifying the Array

- (void)_extendCapacity
{
	if (_capacity)
	{
		_capacity = _capacity*2;
		_ranges = realloc(_ranges, _capacity * sizeof(NSRange));
	}
	else
	{
		_capacity = 100;
		_ranges = malloc(_capacity * sizeof(NSRange));
	}
}

- (void)addRange:(NSRange)range
{
	if (_count+1>_capacity)
	{
		[self _extendCapacity];
	}
	
	_ranges[_count] = range;
	_count++;
}

- (void)bs_addRangesFromArray:(DTRangesArray *)array withSlidingLocation:(NSInteger)delta
{
    NSRange *ranges = [array bs_ranges];
    NSUInteger count = [array count];
    
    for (NSUInteger i = 0; i < count; i++) {
        NSRange range = ranges[i];
        range.location += delta;
        [self addRange:range];
    }
}

- (void)bs_addRangesFromArray:(DTRangesArray *)array
{
    [self bs_addRangesFromArray:array withSlidingLocation:0];
}

#pragma mark - Finding Ranges

- (NSRange)rangeAtIndex:(NSUInteger)index
{
	NSAssert(index<_count, @"Cannot retrieve index %lu which is outside of number of ranges %lu", (unsigned long)index, (unsigned long)_count);
	
	return _ranges[index];
}

- (NSRange *)_rangeInRangesContainingLocation:(NSUInteger)location
{
	int (^comparator)(const void *, const void *) = ^(const void *locationPtr, const void *rangePtr) {
		
		NSUInteger location = *(NSUInteger *)locationPtr;
		NSRange range = *(NSRange *)rangePtr;
		
		if (location < range.location)
		{
			return -1;
		}
		
		if (location >= NSMaxRange(range))
		{
			return 1;
		}
		
		return 0;
	};
	
	return bsearch_b(&location, _ranges, _count, sizeof(NSRange), comparator);
}


- (NSUInteger)indexOfRangeContainingLocation:(NSUInteger)location
{
	NSRange *found = [self _rangeInRangesContainingLocation:location];
	
	if (found)
	{
		return found - _ranges; // calc index
	}
	
	return NSNotFound;
}

- (NSRange)rangeContainingLocation:(NSUInteger)location
{
	NSRange *found = [self _rangeInRangesContainingLocation:location];
	
	if (found)
	{
		return *found;
	}
	
	return NSMakeRange(NSNotFound, 0);
}

@end
