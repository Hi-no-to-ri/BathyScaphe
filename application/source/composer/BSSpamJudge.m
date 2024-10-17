//
//  BSSpamJudge.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/04/11.
//  Copyright 2010-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CocoMonar_Prefix.h"
#import "BSSpamJudge.h"
#import "CMRThreadSignature.h"
#import "CMRThreadMessage.h"
#import "CMRThreadMessageBuffer.h"
#import "BSNGExpression.h"
#import "CMRSpamFilter.h"
#import "AppDefaults.h"
#import "BoardManager.h"
#import "CMXTextParser.h"
#import <CocoaOniguruma/OnigRegexp.h>

@interface BSSpamJudge(Private)
- (NSSet *)mergedSpamHostSymbolsForThreadSignature:(CMRThreadSignature *)signature;
- (NSArray *)mergedNGExpressionsForThreadSignature:(CMRThreadSignature *)signature;

- (BOOL)isSpamIDWithHostSymbol:(NSString *)idString;
- (BOOL)isSpamWithNGExpressionsMatch:(CMRThreadMessage *)message;
- (BOOL)isSpamWithSamplesMatch:(CMRThreadMessage *)message;
@end


@implementation BSSpamJudge
- (id)initWithThreadSignature:(CMRThreadSignature *)signature
{
    if (self = [super init]) {
        m_spamHostSymbols = [[self mergedSpamHostSymbolsForThreadSignature:signature] retain];
        m_NGExpressions = [[self mergedNGExpressionsForThreadSignature:signature] retain];

        [[CMRSpamFilter sharedInstance] getSpamSampleObjectsForBoard:[signature boardName]
                                                            idString:&m_idSamples
                                                                name:&m_nameSamples
                                                                mail:&m_mailSamples];
        [m_idSamples retain];
        [m_nameSamples retain];
        [m_mailSamples retain];
        m_treatsNoSageAsSpamFlag = [[BoardManager defaultManager] treatsNoSageAsSpamAtBoard:[signature boardName]];
    }
    return self;
}

- (void)dealloc
{
    [m_spamHostSymbols release];
    [m_NGExpressions release];
    [m_idSamples release];
    [m_nameSamples release];
    [m_mailSamples release];

    [super dealloc];
}

- (void)judgeMessages:(CMRThreadMessageBuffer *)aBuffer
{
    [self judgeMessages:aBuffer spamIndexes:NULL];
}

- (void)judgeMessages:(CMRThreadMessageBuffer *)aBuffer spamIndexes:(NSIndexSet **)indexesPtr

{
    if (!aBuffer || [aBuffer count] == 0) {
        return;
    }

    NSArray *messages = [aBuffer messages];
    if (!messages) {
        return;
    }

    BOOL shouldCheckHost = ([m_spamHostSymbols count] > 0);
    BOOL shouldCheckNGs = ([m_NGExpressions count] > 0);
    
    __block NSMutableIndexSet *indexes;
    
    if (indexesPtr != NULL) {
        indexes = [NSMutableIndexSet indexSet];
        [messages makeObjectsPerformSelector:@selector(setPostsAttributeChangedNotifications:) withObject:[NSNumber numberWithBool:NO]];
    } else {
        indexes = nil;
    }

    [messages enumerateObjectsWithOptions:0 usingBlock:^(CMRThreadMessage *message, NSUInteger idx, BOOL *stop) {
        NSString *idString;
        NSString *hostString;
        NSString *mailString;

        if ([message isSpam]) {
            return;
        }
        
        idString = [message IDString];
        
        if (shouldCheckHost) {
            // 禁止投稿元記号集合との比較
            if (idString) {
                if ([self isSpamIDWithHostSymbol:idString]) {
                    [message setSpam:YES];
                    [indexes addIndex:idx];
                    return;
                }
            } else {
                hostString = [message host];
                if (hostString) {
                    if ([hostString length] == 1) {
                        if ([m_spamHostSymbols containsObject:hostString]) {
                            [message setSpam:YES];
                            [indexes addIndex:idx];
                            return;
                        }
                    } else if ([hostString length] > 1) { // 「(IPaddress (携帯固有番号orべっかんこ番号)) 投稿元記号（+「!」）」
                        NSString *lastComponent = [[hostString componentsSeparatedByString:@" "] lastObject];
                        if ([lastComponent length] == 1) {
                            // 投稿元記号のみ
                            if ([m_spamHostSymbols containsObject:lastComponent]) {
                                [message setSpam:YES];
                                [indexes addIndex:idx];
                                return;
                            }
                        } else if ([lastComponent length] == 2) {
                            // 投稿元記号＋海外「!」
                            // 例えば「!」を禁止していなくても「T」を禁止しているとき、「T!」は禁止と判定する
                            
                            // 投稿元記号
                            if ([m_spamHostSymbols containsObject:[lastComponent substringWithRange:NSMakeRange(0,1)]]) {
                                [message setSpam:YES];
                                [indexes addIndex:idx];
                                return;
                            }
                             // 海外ホストを表す「!」を迷惑レス対象にしている場合
                            NSString *last = [lastComponent substringWithRange:NSMakeRange(1, 1)]; // 最後の1文字が「!」かどうか調べる
                            if ([m_spamHostSymbols containsObject:@"!"] && [last isEqualToString:@"!"]) {
                                [message setSpam:YES];
                                [indexes addIndex:idx];
                                return;
                            }
                        }
                    }
                }
            }
        }
        
        if (m_treatsNoSageAsSpamFlag) {
            // メール欄が sage 以外かどうか判定
            mailString = [message mail];
            if (mailString && ![mailString isEqualToString:CMRThreadMessage_SAGE_String]) {
                [message setSpam:YES];
                [indexes addIndex:idx];
                return;
            }
        }
        
        if (shouldCheckNGs) {
            // 禁止語句集合との比較
            if ([self isSpamWithNGExpressionsMatch:message]) {
                [message setSpam:YES];
                [indexes addIndex:idx];
                return;
            }
        }
        
        // サンプルとの比較
        if ([self isSpamWithSamplesMatch:message]) {
            [message setSpam:YES];
            [indexes addIndex:idx];
        }
    }];

    if (indexesPtr != NULL) {
        *indexesPtr = indexes;
        [messages makeObjectsPerformSelector:@selector(setPostsAttributeChangedNotifications:) withObject:[NSNumber numberWithBool:YES]];
    }
}
@end


@implementation BSSpamJudge(Private)
- (NSSet *)mergedSpamHostSymbolsForThreadSignature:(CMRThreadSignature *)signature
{
    return [[BoardManager defaultManager] spamHostSymbolsForBoard:[signature boardName]];
}

- (NSArray *)mergedNGExpressionsForThreadSignature:(CMRThreadSignature *)signature
{
    NSArray *baseArray = [CMRPref spamMessageCorpus];
    NSArray *additionalArray = [[BoardManager defaultManager] spamMessageCorpusForBoard:[signature boardName]];
    return additionalArray ? [baseArray arrayByAddingObjectsFromArray:additionalArray] : baseArray;
}

- (BOOL)isSpamIDWithHostSymbol:(NSString *)idString
{
    NSUInteger length = [idString length];
    if (length == 9) { // ID: HOGEHOGEx
        return [m_spamHostSymbols containsObject:[idString substringWithRange:NSMakeRange(8, 1)]];
    } else if (length == 4) { // ID: ???x
        return [m_spamHostSymbols containsObject:[idString substringWithRange:NSMakeRange(3, 1)]];
    } else if (length > 9) { // ID: HOGEHOGEx! or ID: HOGEHOGEyyyyy or ID: HOGEHOGEyyyyy! (yyyyy は 1文字から5文字の間）
        NSString *first = [idString substringWithRange:NSMakeRange(8, 1)];
        if ([m_spamHostSymbols containsObject:first]) {
            return YES;
        }
        // 海外ホストを表す「!」を迷惑レス対象にしている場合
        NSString *last = [idString substringWithRange:NSMakeRange(length-1, 1)]; // 最後の1文字が「!」かどうか調べる
        if ([m_spamHostSymbols containsObject:@"!"] && [last isEqualToString:@"!"]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isSpamWithNGExpressionsMatch:(CMRThreadMessage *)message
{
    OnigRegexp *regex;
    NSString *sourceBody = [message cachedMessage];
    NSString *sourceName = [message name];
    NSString *sourceMail = [message mail];
    NSString *convertedName;
    NSString *convertedMail;

    BOOL shouldCheckBody = (sourceBody && ([sourceBody length] > 0));
    if (sourceName && [sourceName length] > 0) {
        convertedName = [CMXTextParser cachedMessageWithMessageSource:sourceName];
    } else {
        convertedName = nil;
    }
    if (sourceMail) {
        NSUInteger mailLength = [sourceMail length];
        if (mailLength > 4) {
            convertedMail = [CMXTextParser stringByReplacingEntityReference:sourceMail];
        } else if (mailLength > 0) {
            convertedMail = sourceMail;
        } else {
            convertedMail = nil;
        }
    } else {
        convertedMail = nil;
    }

    for (BSNGExpression *expression in m_NGExpressions) {
        regex = [expression regex];
        if (regex) {
            if (shouldCheckBody && [expression checksMessage]) {
                if ([regex search:sourceBody]) {
                    return YES;
                }
            }
            if (convertedName && [expression checksName]) {
                if ([regex search:convertedName]) {
                    return YES;
                }
            }
            if (convertedMail && [expression checksMail]) {
                if ([regex search:convertedMail]) {
                    return YES;
                }
            }
        } else {
            NSString *NGExpression = [expression ngExpression];
            if (!NGExpression) {
                continue;
            }
            if (shouldCheckBody && [expression checksMessage]) {
                if ([sourceBody rangeOfString:NGExpression options:NSLiteralSearch].length != 0) {
                    return YES;
                }
            }
            if (convertedName && [expression checksName]) {
                if ([convertedName rangeOfString:NGExpression options:NSLiteralSearch].length != 0) {
                    return YES;
                }
            }
            if (convertedMail && [expression checksMail]) {
                if ([convertedMail rangeOfString:NGExpression options:NSLiteralSearch].length != 0) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (BOOL)isSpamWithSamplesMatch:(CMRThreadMessage *)message
{
    BOOL shouldCheckIDSample = ([m_idSamples count] > 0);
    BOOL shouldCheckNameSample = ([m_nameSamples count] > 0);
    BOOL shouldCheckMailSample = ([m_mailSamples count] > 0);

    if (shouldCheckIDSample) {
        NSString *idString = [message IDString];
        if (idString) {
            for (NSString *idSample in m_idSamples) {
                if ([idSample isEqualToString:idString]) {
                    return YES;
                }
            }
        }
    }

    if (shouldCheckNameSample) {
        NSString *nameString = [message name];
        if (nameString) {
            for (NSString *nameSample in m_nameSamples) {
                if ([nameSample isEqualToString:nameString]) {
                    return YES;
                }
            }
        }
    }

    if (shouldCheckMailSample) {
        NSString *mailString = [message mail];
        if (mailString) {
            for (NSString *mailSample in m_mailSamples) {
                if ([mailSample isEqualToString:mailString]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}
@end
