//
//  BSSearchOptions.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/17.
//  Copyright 2007-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSSearchOptions.h"


@implementation BSSearchOptions
@synthesize searchString = m_searchString;
@synthesize targetsMask = m_targetsMask;

#pragma mark Designated Initializers
+ (id) operationWithFindObject: (NSString *) searchString
					   options: (CMRSearchMask) options
						target: (NSArray *) keysArray
{
	return [[[self alloc] initWithFindObject: searchString
									 options: options
									  target: keysArray] autorelease];
}

- (id) initWithFindObject: (NSString *) searchString
				  options: (CMRSearchMask) options
				   target: (NSArray *) keysArray;
{
	if (self = [super init]) {
		m_searchString = [searchString retain];
		m_targetKeysArray = [keysArray retain];
        NSUInteger foo = 0;
        for (NSString *key in keysArray) {
            if ([key isEqualToString:@"name"]) {
                foo |= BSSearchForNameMask;
            } else if ([key isEqualToString:@"mail"]) {
                foo |= BSSearchForMailMask;
            } else if ([key isEqualToString:@"IDString"]) {
                foo |= BSSearchForIDMask;
            } else if ([key isEqualToString:@"host"]) {
                foo |= BSSearchForHostMask;
            } else if ([key isEqualToString:@"cachedMessage"]) {
                foo |= BSSearchForMessageMask;
            }
        }
        m_targetsMask = foo;
		m_searchMask = options;
	}
	return self;
}

#pragma mark Overrides
- (void) dealloc
{
	[m_searchString release];
	[m_targetKeysArray release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat : 
				@"<%@ %p> findObject=%@ targetKeysArray=[%@] option=%lu",
				[self className],
				self,
				[self searchString],
				[[self targetKeysArray] componentsJoinedByString: @", "],
				(unsigned long)[self optionMasks]];
}

- (BOOL) isEqual : (id) other
{
	BSSearchOptions	*other_ = other;
	id					obj1, obj2;
	BOOL				result = NO;
	
	if(nil == other) return NO;
	if(nil == self) return YES;
	
	obj1 = [self searchString];
	obj2 = [other_ searchString];
	result = (obj1 == obj2) ? YES : [obj1 isEqual : obj2];
	if(NO == result)
		return NO;
	
	obj1 = [self targetKeysArray];
	obj2 = [other_ targetKeysArray];
	result = (obj1 == obj2) ? YES : [obj1 isEqual : obj2];
	if(NO == result)
		return NO;
	
	return ([self optionMasks] == [other_ optionMasks]);
}

- (NSUInteger) hash
{
	return [[self searchString] hash];
}

#pragma mark NSCopying
- (id) copyWithZone : (NSZone *) zone
{
	return [self retain];
}

#pragma mark CMRPropertyListCoding
/*#define kRepresentationFindObjectKey		@"Find"
#define kRepresentationReplaceObjectKey		@"Replace"
#define kRepresentationUserInfoObjectKey	@"UserInfo"
#define kRepresentationOptionKey			@"Option"
+ (id) objectWithPropertyListRepresentation : (id) rep
{
	id			findObject_;
	id			replaceObject_;
	id			userInfo_;
	unsigned	findOption_;
	
	if(nil == rep || NO == [rep isKindOfClass : [NSDictionary class]])
		return nil;
	
	findObject_ = [rep objectForKey : kRepresentationFindObjectKey];
	replaceObject_ = [rep objectForKey : kRepresentationReplaceObjectKey];
	userInfo_ = [rep objectForKey : kRepresentationUserInfoObjectKey];
	findOption_ = [rep unsignedIntegerForKey : kRepresentationOptionKey];
	
	return [self operationWithFindObject : findObject_
								 replace : replaceObject_
								userInfo : userInfo_
								  option : findOption_];
}

- (id) propertyListRepresentation
{
	NSMutableDictionary		*dict;
	
	dict = [NSMutableDictionary dictionary];
	
	[dict setNoneNil:[self findObject] forKey:kRepresentationFindObjectKey];
	[dict setNoneNil:[self replaceObject] forKey:kRepresentationReplaceObjectKey];
	[dict setNoneNil:[self userInfo] forKey:kRepresentationUserInfoObjectKey];
	[dict setUnsignedInteger:[self findOption] forKey:kRepresentationOptionKey];

	return dict;
}
*/
#pragma mark Accessors
- (NSString *) findObject
{
	return m_searchString;
}

- (NSArray *) targetKeysArray
{
	return m_targetKeysArray;
}

- (CMRSearchMask) optionMasks
{
	return m_searchMask;
}

- (BOOL) optionStateForOption: (CMRSearchMask) opt
{
	return (m_searchMask & opt);
}

- (void) setOptionState: (BOOL) flag
			  forOption: (CMRSearchMask) opt;
{
	m_searchMask = flag ? (m_searchMask | opt) : (m_searchMask & (~opt));
}

- (void)setTarget:(BOOL)flag forMask:(NSUInteger)mask
{
    [self willChangeValueForKey:@"targetsMask"];
    m_targetsMask = flag ? (m_targetsMask | mask) : (m_targetsMask & (~mask));
    [self didChangeValueForKey:@"targetsMask"];
}

+ (NSArray *)keysArrayFromStatesArray:(NSArray *)statesArray
{
    static NSArray *allKeys = nil;
    if (!allKeys) {
        allKeys = [[NSArray alloc] initWithObjects:@"name", @"mail", @"IDString", @"host", @"cachedMessage", nil];
    }
    NSMutableArray  *tmpArray = [NSMutableArray array];
    NSInteger   i;
    
    for (i = 0; i < 5; i++) {
        if ([[statesArray objectAtIndex:i] integerValue] == NSOnState) {
            [tmpArray addObject:[allKeys objectAtIndex:i]];
        }
    }
    return tmpArray;
}

+ (NSArray *)keysArrayFromTargetsMask:(NSUInteger)mask
{
    static NSArray *allKeys = nil;
    static char foo[5] = {1,2,4,8,16};
    if (!allKeys) {
        allKeys = [[NSArray alloc] initWithObjects:@"name", @"mail", @"IDString", @"host", @"cachedMessage", nil];
    }
    NSMutableArray  *tmpArray = [NSMutableArray array];
    NSInteger   i;
    
    for (i = 0; i < 5; i++) {
        if (mask & foo[i]) {
            [tmpArray addObject:[allKeys objectAtIndex:i]];
        }
    }
//    NSLog(@"Check %@", tmpArray);
    return tmpArray;
}

- (BOOL)isCaseInsensitive
{
    return [self optionStateForOption:CMRSearchOptionCaseInsensitive];
}

- (void)setIsCaseInsensitive:(BOOL)checkBoxState
{
    [self setOptionState:checkBoxState forOption:CMRSearchOptionCaseInsensitive];
}

- (BOOL)isLinkOnly
{
    return [self optionStateForOption:CMRSearchOptionLinkOnly];
}

- (void)setIsLinkOnly:(BOOL)checkBoxState
{
    [self setOptionState:checkBoxState forOption:CMRSearchOptionLinkOnly];
}

- (BOOL)usesRegularExpression
{
    return [self optionStateForOption:CMRSearchOptionUseRegularExpression];
}

- (void)setUsesRegularExpression:(BOOL)flag
{
    [self setOptionState:flag forOption:CMRSearchOptionUseRegularExpression];
}
@end
