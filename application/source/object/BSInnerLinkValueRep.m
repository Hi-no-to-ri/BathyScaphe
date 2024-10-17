//
//  BSInnerLinkValueRep.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/03/23.
//  encoding="UTF-8"
//

#import "BSInnerLinkValueRep.h"
#import "NSCharacterSet+CMXAdditions.h"
#import "CMRMessageAttributesStyling.h"
#import "UTILKit.h"

static void bs_scanResLinkElement_(NSString *str, NSMutableIndexSet *buffer);

@interface BSInnerLinkValueRep(private)
- (void)setIndexes:(NSIndexSet *)indexes;
- (NSIndexSet *)analyzeIndexesFromOriginalString;
@end


@implementation BSInnerLinkValueRep
- (id)initWithOriginalString:(NSString *)string
{
    self = [super init];
    if (self) {
        m_originalString = [string copy];
        m_localAbonePreview = NO;
    }
    return self;
}

- (id)initWithIndex:(NSUInteger)index
{
    self = [super init];
    if (self) {
        m_indexes = [[NSIndexSet indexSetWithIndex:index] retain];
        m_originalString = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)index + 1];
        m_localAbonePreview = NO;
    }
    return self;
}

- (void)dealloc
{
    [m_indexes release];
    [m_originalString release];
    [super dealloc];
}

- (NSIndexSet *)indexes
{
    if (!m_indexes) {
        m_indexes = [[self analyzeIndexesFromOriginalString] retain];
    }
    return m_indexes;
}

- (BOOL)isLocalAbonedPreviewLink
{
    return m_localAbonePreview;
}

- (void)setLocalAbonedPreviewLink:(BOOL)flag
{
    m_localAbonePreview = flag;
}

- (NSString *)originalString
{
    return m_originalString;
}

- (NSString *)stringValue
{
    return [NSString stringWithFormat:@"%@:%@", CMRAttributeInnerLinkScheme, [self originalString]];
}

- (BOOL)isEqual:(id)anObject
{
	if (self == anObject) {
        return YES;
    }
    
	if (![anObject isMemberOfClass:[self class]]) {
        return NO;
    }
    
    if ([self isLocalAbonedPreviewLink] != [(BSInnerLinkValueRep *)anObject isLocalAbonedPreviewLink]) {
        return NO;
    }

    return [[self originalString] isEqualToString:[anObject originalString]];
}

- (NSUInteger)hash
{
    // 1231, 1237 は適当
    return [[self originalString] hash] ^ ([self isLocalAbonedPreviewLink] ? 1231 : 1237);
}

- (id)copyWithZone:(NSZone *)zone
{
    BSInnerLinkValueRep *copied = [[[self class] allocWithZone:zone] initWithOriginalString:[self originalString]];
    [copied setIndexes:[self indexes]];
    [copied setLocalAbonedPreviewLink:[self isLocalAbonedPreviewLink]];
    return copied;
}
@end


@implementation BSInnerLinkValueRep(private)
- (void)setIndexes:(NSIndexSet *)indexes
{
    [indexes retain];
    [m_indexes release];
    m_indexes = indexes;
}

- (NSIndexSet *)analyzeIndexesFromOriginalString
{
	NSArray *comps_;

	NSMutableIndexSet *buffer_ = [NSMutableIndexSet indexSet];

	comps_ = [[self originalString] componentsSeparatedByCharacterSequenceFromSet:[NSCharacterSet innerLinkSeparaterCharacterSet]];

	UTILRequireCondition(comps_ && [comps_ count], RetMessageLink);

    for (NSString *element in comps_) {
        bs_scanResLinkElement_(element, buffer_);
    }

    return [[[NSIndexSet alloc] initWithIndexSet:buffer_] autorelease];

RetMessageLink:
	return nil;
}
@end

/*
A - B ==> {A, B-A}
A - B - C ==> {A, 1}, {B, 1}, {C, 1}, 
*/
static void bs_scanResLinkElement_(NSString *str, NSMutableIndexSet *buffer)
{
	if (!str || [str length] == 0) {
		return;
	}

	NSInteger idx = 0;
	NSMutableString *tmp;
	NSMutableIndexSet *tmpIndexes = [NSMutableIndexSet indexSet];

	tmp = [[NSMutableString alloc] initWithString:str];
	CFStringTransform((CFMutableStringRef)tmp, NULL, kCFStringTransformFullwidthHalfwidth, false);

	NSScanner *scan = [NSScanner scannerWithString:tmp];
	[tmp release];

    [scan setCharactersToBeSkipped:[NSCharacterSet whitespaceAndInnerLinkRangeCharacterSet]];
	while (1) {

		if (![scan scanInteger:&idx]) {
			break;
        }
		if (idx < 1) {
            continue;
        }
		// 他のメソッドはレス番号を0ベースとして扱うので
		[tmpIndexes addIndex:(idx - 1)];
	}

	NSUInteger numOfIdxes = [tmpIndexes count];

	if (numOfIdxes == 0) {
		return;
	} else if (numOfIdxes == 2) {
		NSUInteger first = [tmpIndexes firstIndex];
		NSUInteger last = [tmpIndexes lastIndex];
        NSUInteger length = last - first + 1;
        if (length > 50) { // 50個以上連続するレスアンカー（>>1-1001など）は、50個までしか処理しないようにする
            length = 50;
        }
		NSRange	foo = NSMakeRange(first, length);
		[buffer addIndexesInRange:foo];
	} else {
		[buffer addIndexes:tmpIndexes];
	}
}
