//
//  BSHostLivedoorHandler.m
//  BathyScaphe
//
//  Written by Tsutomu Sawada on 06/12/09.
//  Copyright 2006-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRHostHandler_p.h"
#import "CMRHostHTMLHandler.h"


@implementation BSHostLivedoorHandler
+ (BOOL)canHandleURL:(NSURL *)anURL
{
    const char *hostName_ = [[anURL host] UTF8String];

    if (NULL == hostName_) return NO;
    return is_jbbs_livedoor(hostName_);
}

- (NSDictionary *)properties
{
    return CMRHostPropertiesForKey(@"jbbs_livedoor");
}

- (NSURL *)boardURLWithURL:(NSURL *)anURL bbs:(NSString *)bbs
{
    NSString    *absolute_;
    
    if ([bbs containsString:@"/"]) {
        // bbs == @"anime/3939" のようにくっついていると判断
        absolute_ = [NSString stringWithFormat:@"http://%@/%@/", [anURL host], bbs];
    } else {
        // bbs == @"anime" しかない場合。足りないものはもとの anURL から補う
        NSArray     *paths_;
        
        paths_ = [[anURL path] pathComponents];
        if ([paths_ count] < 5) {
            return nil;
        }
        absolute_ = [NSString stringWithFormat:@"http://%@/%@/%@/", [anURL host], bbs, [paths_ objectAtIndex:4]];
    }
    return [NSURL URLWithString:absolute_];
}

- (NSString *)makeURLStringWithBoard:(NSURL *)boardURL datName:(NSString *)datName
{
    NSString        *absolute_;
    const char      *bbs_ = NULL;
    NSURL           *location_;
    NSDictionary    *properties_;

    UTILRequireCondition(boardURL && datName, ErrReadURL);

    location_ = [self readURLWithBoard:boardURL];
    UTILRequireCondition(location_, ErrReadURL);
    
    properties_ = [self readCGIProperties];
    UTILRequireCondition(properties_, ErrReadURL);
    
    CMRGetHostCStringFromBoardURL(boardURL, &bbs_);
    UTILRequireCondition(bbs_, ErrReadURL);

// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 検証済
    absolute_ = [NSString stringWithFormat:
                    READ_URL_FORMAT_SHITARABA,
                    [location_ absoluteString],
                    [[[boardURL path] pathComponents] objectAtIndex:1],
                    bbs_,
                    datName];

    return absolute_;
ErrReadURL:
    return nil;
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName
{
    NSString        *absolute_;
    NSURL           *location_;

    absolute_ = [self makeURLStringWithBoard:boardURL datName:datName];
    UTILRequireCondition(absolute_, ErrReadURL);
    
    location_ = [NSURL URLWithString:absolute_];

    return location_;
    
ErrReadURL:
    return nil;
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName latestCount:(NSInteger)count
{
    NSString    *base_;
    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    if (!base_) return nil;

// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
    return [NSURL URLWithString:[base_ stringByAppendingFormat:@"l%ld", (long)count]];
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL datName:(NSString *)datName headCount:(NSInteger)count
{
    NSString    *base_;
    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    if (!base_) return nil;

// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
    return [NSURL URLWithString:[base_ stringByAppendingFormat:@"-%ld", (long)count]];
}

- (NSURL *)readURLWithBoard:(NSURL *)boardURL
                    datName:(NSString *)datName
                      start:(NSUInteger)startIndex
                        end:(NSUInteger)endIndex
                    nofirst:(BOOL)nofirst
{
    id              tmp;
    NSURL           *location_;
    NSString        *base_;

    base_ = [self makeURLStringWithBoard:boardURL datName:datName];
    UTILRequireCondition(base_, ErrReadURL);
    tmp = SGTemporaryString();
    [tmp setString:base_];

    if (startIndex != NSNotFound) {
// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
        [tmp appendFormat:@"%lu", (unsigned long)startIndex];
    }
    if (nofirst) {
            [tmp appendString:@"n-"];
    } else {
        [tmp appendString:@"-"];
    }

    if (endIndex != NSNotFound) {
        if (endIndex != startIndex) {
            if (NSNotFound == startIndex) {
                [tmp appendString:@"1-"];
            }
// #warning 64BIT: Check formatting arguments
// 2010-03-25 tsawada2 修正済
            [tmp appendFormat:@"%lu", (unsigned long)endIndex];
        } else {
            NSUInteger length = [tmp length];
            NSRange range;
            if (nofirst) {
                range = NSMakeRange(length-2, 2);
            } else {
                range = NSMakeRange(length-1, 1);
            }
            [tmp deleteCharactersInRange:range];
        }
    }
    location_ = [NSURL URLWithString:tmp];
    
    return location_;
    
ErrReadURL:
    return nil;
}

- (BOOL)parseParametersWithReadURL:(NSURL *)link
                               bbs:(NSString **)bbs
                               key:(NSString **)key
                             start:(NSUInteger *)startIndex
                                to:(NSUInteger *)endIndex
                         showFirst:(BOOL *)showFirst
{
    NSArray *comps_;
    id tmp;
    
    id cgiName_;
    NSString *directory_;
    NSUInteger directoryIndex_;
    NSDictionary *properties_;
    
    if (bbs != NULL) *bbs = nil;
    if (key != NULL) *key = nil;
    if (startIndex != NULL) *startIndex = NSNotFound;
    if (endIndex != NULL) *endIndex = NSNotFound;
    if (showFirst != NULL) *showFirst = YES;
    
    UTILRequireCondition(link, ErrParse);
    UTILRequireCondition([[self class] canHandleURL:link], ErrParse);
    
    properties_ = [self readCGIProperties];
    tmp = [properties_ objectForKey:kReadCGIDirectoryIndexKey];
    UTILAssertKindOfClass(tmp, NSNumber);
    directoryIndex_ = [tmp unsignedIntegerValue];
    
    cgiName_ = [properties_ objectForKey:kReadCGINameKey];
    UTILRequireCondition(([cgiName_ isKindOfClass:[NSString class]] || [cgiName_ isKindOfClass:[NSArray class]]), ErrParse);
    
    directory_ = [properties_ objectForKey:kReadCGIDirectoryKey];
    UTILAssertKindOfClass(directory_, NSString);
    
    comps_ = [[link path] pathComponents];
    UTILRequireCondition(([comps_ count] > directoryIndex_ +1), ErrParse);
    
    // ディレクトリとCGIの名前
    tmp = [comps_ objectAtIndex:directoryIndex_];
    UTILRequireCondition([tmp isEqualToString:directory_], ErrParse);
    tmp = [comps_ objectAtIndex:directoryIndex_ +1];
    
    if ([cgiName_ isKindOfClass:[NSString class]]) {
        UTILRequireCondition([tmp hasPrefix:cgiName_], ErrParse);
    } else { // NSArray
        BOOL flag = NO;
        for (NSString *eachName in cgiName_) {
            if ([tmp hasPrefix:eachName]) {
                flag = YES;
                break;
            }
        }
        
        UTILRequireCondition(flag, ErrParse);
    }
    
    // クエリによるパラメータ指定なら断念（最近ほとんどないよね？）。
    // そうでなければ、最後のパス要素をスキャン。
    if ([link query]) {
        return NO;
        
    } else if ([comps_ count] > directoryIndex_ + 4) {
        if (bbs != NULL) {
            NSString *hoge = [NSString stringWithFormat:@"%@/%@", [comps_ objectAtIndex:directoryIndex_ + 2], [comps_ objectAtIndex:directoryIndex_ + 3]];
//            *bbs = [comps_ objectAtIndex:directoryIndex_ + 2];
            *bbs = hoge;
        }
        if (key != NULL) {
            *key = [comps_ objectAtIndex:directoryIndex_ + 4];
        }
        if ([comps_ count] > directoryIndex_ + 5) {
            NSString  *mesIndexStr_;
            NSScanner *scanner_;
            NSString  *skiped_;
            NSInteger index_;
            
            skiped_ = nil;
            
            // 最後のパス文字列がインデックス文字列
            // になっているので、そこからインデックス
            // をスキャン
            mesIndexStr_ = [comps_ lastObject];
            scanner_ = [NSScanner scannerWithString:mesIndexStr_];
            [scanner_ scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&skiped_];
            // #warning 64BIT: scanInt: argument is pointer to int, not NSInteger; you can use scanInteger:
            // 2010-03-27 tsawada2 修正済
            if ([scanner_ scanInteger:&index_]) {
                if (startIndex != NULL) {
                    *startIndex = index_;
                }
                if (endIndex != NULL) {
                    *endIndex = index_;
                }
                // 範囲が指定されているか
                if ([scanner_ scanString:@"-" intoString:NULL]) {
                    // #warning 64BIT: scanInt: argument is pointer to int, not NSInteger; you can use scanInteger:
                    // 2010-03-27 tsawada2 修正済
                    if ([scanner_ scanInteger:&index_]) {
                        if (endIndex != NULL) {
                            *endIndex = index_;
                        }
                    }
                }
            }
            if (showFirst != NULL) {
                *showFirst = NO;
            }
        }
        
        return YES;
        
    }   
    
ErrParse:
    return NO;
}

- (NSURL *)rawmodeURLWithBoard:(NSURL *)boardURL
                       datName:(NSString *)datName
                         start:(NSUInteger)startIndex
                           end:(NSUInteger)endIndex
                       nofirst:(BOOL)nofirst
{
    NSURL   *url_ = [self readURLWithBoard:boardURL datName:datName start:startIndex end:NSNotFound nofirst:nofirst];
    if (!url_) return nil;

    NSMutableString *tmp = [[url_ absoluteString] mutableCopy];
    [tmp replaceOccurrencesOfString:@"read.cgi" withString:@"rawmode.cgi" options:NSLiteralSearch range:NSMakeRange(0, [tmp length])];

    NSURL   *newURL_ = [NSURL URLWithString:tmp];
    [tmp release];

    return newURL_;
}

#pragma mark HTML Parser
- (NSString *)convertObjectsToExtraFields:(NSArray *)components
{
    NSMutableString *tmp = [NSMutableString string];
    NSString    *idOrHost;

    [tmp appendString:[components objectAtIndex:3]]; // Date

    idOrHost = [components objectAtIndex:6]; // ID or HOST

    if (![idOrHost isEqualToString:@""]) {
        NSUInteger length_ = [idOrHost length];

        [tmp appendString:(length_ < 11) ? @" ID:" : @" HOST:"];
        [tmp appendString:idOrHost];
    }
    
    return tmp;
}

- (void)addDatLine:(NSArray *)components with:(id)thread count:(NSUInteger *)pLoadedCount
{
    NSUInteger actualIndex = [[components objectAtIndex:0] integerValue];

    if (actualIndex == 0) return;

    if (*pLoadedCount != NSNotFound && *pLoadedCount +1 != actualIndex) {
        NSUInteger  i;

        // 適当に行を詰める
        NSLog(@"BSHostLivedoorHandler: Invisible Abone Detected(%lu)", (unsigned long)actualIndex);
        for (i = *pLoadedCount +1; i < actualIndex; i++) {
            [thread appendString:@"<><><><>\n"];
        }
    }

    *pLoadedCount = actualIndex;

    NSString *extraFields = [self convertObjectsToExtraFields:components];

    NSString *tmp_ = [NSString stringWithFormat:@"%@<>%@<>%@<>%@<>\n",
                                                [components objectAtIndex:1],
                                                [components objectAtIndex:2],
                                                extraFields,
                                                [components objectAtIndex:4]];

    [thread appendString:tmp_];
}

- (id)parseHTML:(NSString *)inputSource with:(id)thread count:(NSUInteger)loadedCount lastReadedCount:(NSUInteger *)lastCount
{
    NSArray *eachLineArray_ = [inputSource componentsSeparatedByString:@"\n"];
    NSEnumerator    *iter_ = [eachLineArray_ objectEnumerator];
    NSString        *eachLine_;
    BOOL            titleParsed_ = NO;
    NSUInteger        parsedCount = loadedCount;

  @try {
    while (eachLine_ = [iter_ nextObject]) {
        NSArray *components_ = [eachLine_ componentsSeparatedByString:@"<>"];
        /* sample
        レス番号<>名前<>メール欄<>日付<>本文<>スレタイ（最初のレスのみ）<>ID
        3<>名無しさん<><>2006/08/10(木) 23:36:41<>ぬるぽ<><>ZCWPDDtE
        */
        
        // OS X Mountain Lion で <> の後に特定の文字が続いた場合、ちゃんと分解されない場合があるので対策
        if ([components_ count] < 7) {
            NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:7];
            for (NSString *component in components_) {
                NSRange range = [component rangeOfString:@"<>" options:NSLiteralSearch range:NSMakeRange(0, [component length])];
                if (range.location != NSNotFound) {
                    // <> の前
                    NSString *foo = [component substringToIndex:range.location];
                    // <> の後だが、そのままだと表示時に不都合が生じるので、ダミーの文字を前にくっつけてやらなければいけない
                    NSString *bar = [@" " stringByAppendingString:[component substringFromIndex:NSMaxRange(range)]];
                    [mArray addObject:foo];
                    [mArray addObject:bar];
                } else {
                    [mArray addObject:component];
                }
            }
            components_ = mArray;
        }
        
        [self addDatLine:components_ with:thread count:&parsedCount];
        
        if (!titleParsed_) {
            NSString *title_ = [components_ objectAtIndex:5];
            if (![title_ isEqualToString:@""]) {
                NSRange     found;

                found = [thread rangeOfString:@"\n"];
                if (found.length != 0) {
                    [thread insertString:title_ atIndex:found.location];
                }
            }
            titleParsed_ = YES;
        }
    }
    if (lastCount != NULL) {
        *lastCount = parsedCount;
    }
  }
  @catch (NSException *exception) {
      // TODO このクラスで NSAlert 出すより、上位層にエスカレートさせて CMRThreadViewer あたりで出すべき
/*      if ([[exception name] isEqualToString:NSRangeException]) {
          NSAlert *alert = [[[NSAlert alloc] init] autorelease];
          [alert setMessageText:@"Exception Caught"];
          [alert setInformativeText:[exception description]];
          [alert setAlertStyle:NSCriticalAlertStyle];
          [alert runModal];
          if (lastCount != NULL) {
              *lastCount = parsedCount;
          }
      } else*/ if ([[exception name] isEqualToString:XmlPullParserException]) {
        NSLog(@"***LOCAL_EXCEPTION***%@", exception);
    } else {
        @throw;
    }
  }
    return thread;
}
@end


@implementation BSHostLivedoorHandler(WriteCGI)
- (NSURL *)threadCreationWriteURLWithBoard:(NSURL *)boardURL
{
    NSURL *foo = [self writeURLWithBoard:boardURL];
    if (!foo) return nil;

    NSString *host = [foo host];
    NSString *path = [foo path];
    NSString *newURL = [NSString stringWithFormat:@"http://%@%@%@/new/", host, path, [boardURL path]];
    return [NSURL URLWithString:newURL];
}
@end
