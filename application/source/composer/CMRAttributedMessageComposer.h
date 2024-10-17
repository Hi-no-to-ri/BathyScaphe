//
//  CMRAttributedMessageComposer.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 13/04/04.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CMRMessageComposer.h"



@interface CMRAttributedMessageComposer : CMRMessageComposer
{
	@private
	NSMutableAttributedString	*_contentsStorage;
	NSMutableAttributedString	*_nameCache;
	
	UInt32			_mask;
	struct {
		unsigned int mask:31;
		unsigned int compose:1;
		unsigned int :0;
	} _CCFlags;
}
+ (id)composerWithContentsStorage:(NSMutableAttributedString *)storage;
- (id)initWithContentsStorage:(NSMutableAttributedString *)storage;

/* mask で指定された属性を無視する */
- (UInt32)attributesMask;
- (void)setAttributesMask:(UInt32)mask;

/* flag: mask に一致する属性をもつレスを生成するかどうか */
- (void)setComposingMask:(UInt32)mask compose:(BOOL)flag;

- (NSMutableAttributedString *)contentsStorage;
- (void)setContentsStorage:(NSMutableAttributedString *)aContentsStorage;
@end
