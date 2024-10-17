//
//  BSBeSAAPAnchorComposer.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/10/12.
//  Copyright 2008-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSBeSAAPAnchorComposer.h"
#import "CMRMessageAttributesStyling.h"
#import "BSSSSPIconManager.h"


@implementation BSBeSAAPAnchorComposer
static BOOL g_showsSAAPIcon = YES;

static NSUInteger g_length = 0;

static inline NSString *convertedLinkString(NSString *saapString)
{
    if (g_length == 0) {
        g_length = [BSInnerSsspLinkScheme length];
    }
	NSMutableString *string = [NSMutableString stringWithString:saapString];
	[string replaceCharactersInRange:NSMakeRange(0, g_length) withString:@"http"];
	return string;
}

+ (BOOL)showsSAAPIcon
{
	return g_showsSAAPIcon;
}

+ (void)setShowsSAAPIcon:(BOOL)flag
{
	g_showsSAAPIcon = flag;
}

- (id)init
{
    if (self = [super init]) {
        m_replacingRanges = [[NSMutableIndexSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [m_replacingRanges release];
	[super dealloc];
}

- (void)addSaapLinkRange:(NSRange)range
{
    [m_replacingRanges addIndexesInRange:range];
}

- (BOOL)replaceHttpString:(NSString *)httpString atRange:(NSRange)range inMessage:(NSMutableAttributedString *)message
{
    NSURL *url = [NSURL URLWithString:httpString];
    NSTextAttachment *foo = [[BSSSSPIconManager defaultManager] SSSPIconAttachmentForURL:url];
    NSAttributedString *attrStr = [NSAttributedString attributedStringWithAttachment:foo];
    if (attrStr) {
        [message insertAttributedString:attrStr atIndex:NSMaxRange(range)];
        // 単純に置き換えてしまうと行のインデントが無くなってしまうため、アイコンの前にゼロ幅スペースを挿入する。
        [[message mutableString] replaceCharactersInRange:range withString:[NSString stringWithCharacter:0x200B]];
        return YES;
    }
    return NO;
}

- (void)composeAllSAAPAnchorsIfNeeded:(NSMutableAttributedString *)message
{
    BOOL notShows = ![[self class] showsSAAPIcon];
    [m_replacingRanges enumerateRangesWithOptions:NSEnumerationReverse usingBlock:^(NSRange range, BOOL *stop) {
        NSString *saapSubstring = [[message string] substringWithRange:range];
        NSString *httpString = convertedLinkString(saapSubstring);
		if (notShows || ![self replaceHttpString:httpString atRange:range inMessage:message]) {
            // アイコンを表示しない設定、または、アイコンへの置換に失敗した場合は、単にリンク文字列を削除する
            [message deleteCharactersInRange:range];
        }
    }];
}
@end
