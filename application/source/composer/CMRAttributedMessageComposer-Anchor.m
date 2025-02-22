//
//  CMRAttributedMessageComposer-Anchor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 14/05/11.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRAttributedMessageComposer_p.h"
#import "NSCharacterSet+CMXAdditions.h"
#import "BSBeSAAPAnchorComposer.h"
#import "BSInnerLinkValueRep.h"

// URL文字列をスキャン
static BOOL scanURLCharactersFallDown(NSScanner *scanner, NSMutableString *stringBuffer);

@implementation CMRAttributedMessageComposer(Anchor)
- (void)convertLinkAnchor:(NSMutableAttributedString *)mAttrString inMessage:(CMRThreadMessage *)message
{
	NSIndexSet *indexSet;
    
    indexSet = [self makeInnerLinkAnchor:mAttrString];
	[self makeOuterLinkAnchor:mAttrString inMessage:message];
    if ([indexSet count] > 0) {
        [message setReferencingIndexes:indexSet];
    }
}

/////////////////////////////////////////////////////////////////////
/////////////////////// 内部リンクの作成 ////////////////////////////
/////////////////////////////////////////////////////////////////////
- (NSIndexSet *)makeInnerLinkAnchor:(NSMutableAttributedString *)message
{
	NSScanner *scanner;
    NSMutableIndexSet *baggage;
	
	scanner = [[NSScanner alloc] initWithString:[message string]];
    baggage = [NSMutableIndexSet indexSet];

	// この時点でエンティティは解決されていなくてはならない。
	// 視点文字（>,＞など）から始まる文字列をスキャン
	[self makeResLinkAnchor:message startCharacterSet:[NSCharacterSet innerLinkPrefixCharacterSet] withScanner:scanner indexesBaggage:baggage];
	[scanner release];
    
    return baggage;
}

- (void) makeInnerLinkAnchorInNameField : (NSMutableAttributedString *) nameField
{
	NSScanner		*scanner_;
	NSString		*content_;
	NSCharacterSet	*readerSet_;
	NSRange			searchRange_;
	
	content_ = [nameField string];
	scanner_ = [[NSScanner alloc] initWithString:content_];
	readerSet_ = [NSCharacterSet innerLinkPrefixCharacterSet];
	[scanner_ scanCharactersFromSet:readerSet_ intoString:NULL];
	
	searchRange_ = NSMakeRange(
						[scanner_ scanLocation], 
						[content_ length] - [scanner_ scanLocation]);
	[self makeResLinkAnchor : nameField
			  startingRange : searchRange_
			    withScanner : scanner_
		  startCharacterSet : readerSet_ indexesBaggage:nil];
	[scanner_ release];
}

- (void) makeResLinkAnchor : (NSMutableAttributedString *) mAttrStr
		 startCharacterSet : (NSCharacterSet            *) cset
               withScanner : (NSScanner                 *) scanner indexesBaggage:(NSMutableIndexSet *)mIndexSet
{
	NSString       *content_;
	NSRange         searchRng_;
	NSRange         result_;
	NSUInteger    length_;
	
	UTILAssertNotNil(cset);
	if (nil == mAttrStr || 0 == (length_ = [mAttrStr length])) return;
	
	content_ = [scanner string];
	searchRng_  = NSMakeRange(0, length_);

	[scanner setScanLocation:0];
	// 複数行にまたがったインデックスは読まない。
	// また、空白はその都度、飛ばす。
	[scanner setCharactersToBeSkipped:nil];
	
	while ((result_ = [content_ rangeOfCharacterFromSet : cset
							                   options : NSLiteralSearch
							                     range : searchRng_]).length != 0)
	{
		[self makeResLinkAnchor : mAttrStr
				  startingRange : result_
				    withScanner : scanner
			  startCharacterSet : cset indexesBaggage:mIndexSet];
		//検索範囲を指定(1)
		searchRng_.location = [scanner scanLocation];
		searchRng_.length   = length_ - searchRng_.location;
		
	}
}

- (BOOL)makeResLinkAnchor:(NSMutableAttributedString *)mAttrStr startingRange:(NSRange)linkRange withScanner:(NSScanner *)scanner startCharacterSet:(NSCharacterSet *)startCharacters indexesBaggage:(NSMutableIndexSet *)mIndexSet
{
	NSString			*src_;
//	NSString			*link_;
    BSInnerLinkValueRep *link_;
//	NSCharacterSet		*cset_;
    NSCharacterSet *cset_ = [NSCharacterSet numberCharacterSet_JP];
	NSRange				specRange;			// 範囲指定部分
	NSUInteger			scanLocation_;
	static NSCharacterSet *whiteSpaceSet = nil;
	if (!whiteSpaceSet) {
		whiteSpaceSet = [[NSCharacterSet whitespaceCharacterSet] retain];
	}
	src_ = [scanner string];
	
	// スキャン開始。
	// 始点文字と空白は飛ばす
	[scanner setScanLocation:linkRange.location];
	[scanner scanCharactersFromSet:startCharacters intoString:NULL];
	[scanner scanCharactersFromSet:whiteSpaceSet intoString:NULL];
	
	specRange.location = [scanner scanLocation];
	specRange.length   = 0;
	
	// リンクではない印として
	scanLocation_ = NSNotFound;
	while (1) {
		unichar c;
		
//		cset_ = [NSCharacterSet numberCharacterSet_JP];
		if (![scanner scanCharactersFromSet:cset_ intoString:NULL]) {
			break;
		}
		// ひとつでも数値を読んだら、リンクを貼ることができる
		scanLocation_ = [scanner scanLocation];
		
		[scanner scanCharactersFromSet:whiteSpaceSet intoString:NULL];
		if ([scanner isAtEnd]) {
            break;
		}
		// 区切り文字または範囲指定文字
		c = [src_ characterAtIndex:[scanner scanLocation]];
/*		cset_ = [NSCharacterSet innerLinkRangeCharacterSet];
		if (NO == [cset_ characterIsMember : c]) {
			cset_ = [NSCharacterSet innerLinkSeparaterCharacterSet];
			if (NO == [cset_ characterIsMember : c])
				break;
		}*/
        if (![[NSCharacterSet innerLinkRangeAndSeparaterCharacterSet] characterIsMember:c]) {
            break;
        }
		[scanner setScanLocation:[scanner scanLocation] +1];
		
		[scanner scanCharactersFromSet:whiteSpaceSet intoString:NULL];
	}
	if (NSNotFound == scanLocation_) {
		return NO;
	}
	// 数値を読み込んだ直後の位置に戻す
    if (NSLocationInRange(scanLocation_, linkRange)) {
        [scanner setScanLocation:scanLocation_];
	}
	linkRange.length = ([scanner scanLocation] - linkRange.location);
	specRange.length = ([scanner scanLocation] - specRange.location);
	
//	link_ = [NSString stringWithFormat: @"%@:%@", CMRAttributeInnerLinkScheme, [[scanner string] substringWithRange : specRange]];
	link_ = [[BSInnerLinkValueRep alloc] initWithOriginalString:[[scanner string] substringWithRange:specRange]];
	[mAttrStr addAttribute:NSLinkAttributeName value:link_ range:linkRange];

    if (mIndexSet && [link_ indexes]) {
        [mIndexSet addIndexes:[link_ indexes]];
    }
    [link_ release];
	return YES;
}

/////////////////////////////////////////////////////////////////////
/////////////////////// 外部リンクの作成 ////////////////////////////
/////////////////////////////////////////////////////////////////////
static NSString *const kColonSlash2LinkURLString = @"://";
static NSString *const kSlash2LinkURLString      = @"//";
static NSString *const kW3LinkURLString          = @"www.";
static NSString *const kURLDefaultProtocol       = @"http";
static NSString *const kURLHTTPSProtocol         = @"https";
	
- (void)makeOuterLinkAnchor:(NSMutableAttributedString *)theMessage inMessage:(CMRThreadMessage *)message
{
    NSScanner *scanner_ = nil;
    NSString *content_ = [theMessage string];
    NSUInteger length_ = [theMessage length];
    NSRange linkRange_   = kNFRange;

    NSRange searchRange_;
    NSMutableString *anchor_;
    NSUInteger scanIndex_;

	BSBeSAAPAnchorComposer *helper = nil;
    
    if (!theMessage || length_ == 0) {
		return;
    }

    scanner_ = [[NSScanner alloc] initWithString:content_];
    [scanner_ setCharactersToBeSkipped:nil];
    
    // www.foo.com/...
    searchRange_ = NSMakeRange(0, length_);
    [scanner_ setScanLocation:0];
    while ((linkRange_ = [content_ rangeOfString:kW3LinkURLString options:NSLiteralSearch range:searchRange_]).length != 0) {
        scanIndex_ = NSMaxRange(linkRange_);
        searchRange_.location = scanIndex_;
        searchRange_.length = (length_ - searchRange_.location);
        if (scanIndex_ != 0 && '/' == [content_ characterAtIndex:linkRange_.location -1]) {
            continue;
        }
        [scanner_ setScanLocation:scanIndex_];
        if ([scanner_ isAtEnd]) {
			break;
        }
        // URL文字列
		anchor_ = [NSMutableString stringWithString:@"http://www."];
        if (!scanURLCharactersFallDown(scanner_, anchor_)) {
            continue;
        }
        // 次の検索範囲の指定（2）
        scanIndex_ = [scanner_ scanLocation];
        searchRange_.location = scanIndex_;
        searchRange_.length = (length_ - searchRange_.location);
        // リンクを設定する範囲の指定
        linkRange_.length = (scanIndex_ - linkRange_.location);

        [theMessage addAttribute:NSLinkAttributeName value:anchor_ range:linkRange_];
    }

    // http://..., ttp://..., etc
    searchRange_ = NSMakeRange(0, length_);
    [scanner_ setScanLocation : 0];
    while ((linkRange_ = [content_ rangeOfString:kSlash2LinkURLString options:NSLiteralSearch range:searchRange_]).length != 0) {
        BOOL isBeIconProtocol = NO;
        BOOL isInvalidSSSPProtocol = NO;
        
        scanIndex_ = NSMaxRange(linkRange_);
        [scanner_ setScanLocation : scanIndex_];
        if ([scanner_ isAtEnd]) break;
        
        scanIndex_ = linkRange_.location;
        if (scanIndex_ > 0) scanIndex_--;
        
        anchor_ = [kColonSlash2LinkURLString mutableCopy];
        [anchor_ autorelease];
        
        if (NSLocationInRange(scanIndex_, searchRange_) && ':' == [content_ characterAtIndex:scanIndex_]) {
            NSRange        prtRng_;
            NSString    *protocol_;
            unichar        c;
            
            protocol_ = kURLDefaultProtocol;
            UTILRequireCondition(scanIndex_ > 0, EndInsertString);
            
            prtRng_.location = scanIndex_;
            prtRng_.length = 0;
            c = [content_ characterAtIndex:(prtRng_.location -1)];
            while ('a' <= c && c <= 'z') {
                prtRng_.location--;
                prtRng_.length++;
                if (NO == NSLocationInRange(prtRng_.location, searchRange_))
                    break;
                if (0 == prtRng_.location)
                    break;
                c = [content_ characterAtIndex:(prtRng_.location -1)];
            }
            
            protocol_ = [content_ substringWithRange : prtRng_];
            if ([kURLDefaultProtocol hasSuffix : protocol_] || 0 == [protocol_ length]) {
                
                protocol_ = kURLDefaultProtocol;
            } else if ( [kURLHTTPSProtocol hasSuffix : protocol_] ) {
                protocol_ = kURLHTTPSProtocol;
            } else if ([BSInnerSsspLinkScheme isEqualToString:protocol_]) {
                isBeIconProtocol = YES;
            } else if ([BSSsspLinkScheme isEqualToString:protocol_]) {
                isInvalidSSSPProtocol = YES;
            }
            
            scanIndex_ = prtRng_.location;
            
EndInsertString:
            [anchor_ insertString:protocol_ atIndex:0];
            
            linkRange_.length += (linkRange_.location - scanIndex_);
            linkRange_.location = scanIndex_;
        } else {
            if (![scanner_ scanString:kW3LinkURLString intoString:NULL]) {
                // 次の検索範囲の指定（1）
                scanIndex_ = [scanner_ scanLocation];
                searchRange_.location = scanIndex_;
                searchRange_.length = (length_ - searchRange_.location);
                continue;
            }

            linkRange_.length += [kW3LinkURLString length];
            [anchor_ appendString:kW3LinkURLString];
            [anchor_ insertString:kURLDefaultProtocol atIndex:0];
        }
        
        // この時点で
        // (xxxx)://www., または http:// 
        
        scanIndex_ = NSMaxRange(linkRange_);
        [scanner_ setScanLocation:scanIndex_];
        if ([scanner_ isAtEnd]) break;
        
        // 次の検索範囲の指定（1）
        scanIndex_ = [scanner_ scanLocation];
        searchRange_.location = scanIndex_;
        searchRange_.length = (length_ - searchRange_.location);
        
        if (!scanURLCharactersFallDown(scanner_, anchor_))
            continue;
        
        // 次の検索範囲の指定（2）
        scanIndex_ = [scanner_ scanLocation];
        searchRange_.location = scanIndex_;
        searchRange_.length = (length_ - searchRange_.location);
        // リンクを設定する範囲の指定
        linkRange_.length = (scanIndex_ - linkRange_.location);
        
		if (isBeIconProtocol) {
            if (!helper) {
                helper = [[BSBeSAAPAnchorComposer alloc] init];
            }
            [helper addSaapLinkRange:linkRange_];
        } else if (isInvalidSSSPProtocol) {
            ; // リンク化しない（read.cgi の挙動に合わせる）
		} else {
			[theMessage addAttribute:NSLinkAttributeName value:anchor_ range:linkRange_];
		}
    }

	if (helper) {
        [helper composeAllSAAPAnchorsIfNeeded:theMessage];
		[helper release];
		helper = nil;
	}

    [scanner_ release];
}
@end



/*!
 * @constant    kLinkFullSizeTildeUnicharMap1
 * @constant    kLinkFullSizeTildeUnicharMap2
 * @discussion  全角チルダ
 */
static const unichar kLinkFullSizeTildeUnicharMap1 = 0x301c;
static const unichar kLinkFullSizeTildeUnicharMap2 = 0xff5e;


// NULL Terminated
static NSString **fdNonStandardURLCharacters(void)
{
	static NSString *kNonStandardURLCharacters[3] = {NULL,};
	
	if (NULL == kNonStandardURLCharacters[0]) {
		kNonStandardURLCharacters[0] = 
			[[NSString alloc] initWithCharacter : kLinkFullSizeTildeUnicharMap1];
		kNonStandardURLCharacters[1] = 
			[[NSString alloc] initWithCharacter : kLinkFullSizeTildeUnicharMap2];
		kNonStandardURLCharacters[2] = NULL;
	}
	return kNonStandardURLCharacters;
}
static NSString **fdStandardURLCharacters(void)
{
	static NSString *kFdStandardURLCharacters[3] = {
				@"~", @"~", NULL};
	
	return kFdStandardURLCharacters;
}


// URL文字列をスキャン
static BOOL scanURLCharactersFallDown(NSScanner *scanner, NSMutableString *stringBuffer)
{
	NSCharacterSet		*cset_;
	NSString			*scanned_;
	BOOL				scanResult_ = NO;
	
	cset_ = [NSCharacterSet URLCharacterSet];
	while (1) {
		NSString	**fdNSUURLs_ = fdNonStandardURLCharacters();
		NSString	**fdSURLs_   = fdStandardURLCharacters();
		
		for (; (*fdNSUURLs_ != NULL && *fdSURLs_ != NULL); fdNSUURLs_++) {
			// 全角チルダなどを変換
			if ([scanner scanString:*fdNSUURLs_ intoString:NULL])
				[stringBuffer appendString : *fdSURLs_];
			
			fdSURLs_++;
		}
		
		if (![scanner scanCharactersFromSet:cset_ intoString:&scanned_]) {
			break;
		}

		[stringBuffer appendString:scanned_];
		scanResult_ = YES;
	}
	
	return scanResult_;
}
