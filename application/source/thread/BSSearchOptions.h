//
//  BSSearchOptions.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/03/17.
//  Copyright 2007-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <CocoMonar/CocoMonar.h>

enum {
	BSSearchNoTargetMask = 0,
	BSSearchForNameMask = 1 << 0,
	BSSearchForMailMask = 1 << 1,
	BSSearchForIDMask = 1 << 2,
	BSSearchForHostMask = 1 << 3,
	BSSearchForMessageMask = 1 << 4,
};
	
@interface BSSearchOptions : NSObject<NSCopying> {//, CMRPropertyListCoding> {
	@private
	NSString		*m_searchString;
	NSArray			*m_targetKeysArray;
	CMRSearchMask	m_searchMask;

    NSUInteger      m_targetsMask;
}

@property(readwrite, retain) NSString *searchString;
@property(readwrite, assign) NSUInteger targetsMask;

+ (id)operationWithFindObject:(NSString *)searchString
					   options:(CMRSearchMask)options
						target:(NSArray *)keysArray;
- (id) initWithFindObject:(NSString *)searchString
				  options:(CMRSearchMask)options
				   target:(NSArray *)keysArray;

- (NSString *)findObject __attribute__((deprecated("Use -searchString instead.")));
- (NSArray *)targetKeysArray __attribute__((deprecated("Use -targetsMask instead.")));
- (CMRSearchMask)optionMasks;

- (BOOL)optionStateForOption:(CMRSearchMask)opt;
- (void)setOptionState:(BOOL)flag forOption:(CMRSearchMask)opt;

- (void)setTarget:(BOOL)flag forMask:(NSUInteger)mask;

// {0,1,1,0,1} -> {@"mail", @"IDString", @"cachedMessage"} みたいな変換
+ (NSArray *)keysArrayFromStatesArray:(NSArray *)statesArray;

+ (NSArray *)keysArrayFromTargetsMask:(NSUInteger)mask;

- (BOOL)isCaseInsensitive;
- (void)setIsCaseInsensitive:(BOOL)checkBoxState;
- (BOOL)isLinkOnly;
- (void)setIsLinkOnly:(BOOL)checkBoxState;
- (BOOL)usesRegularExpression;
- (void)setUsesRegularExpression:(BOOL)flag;
@end
