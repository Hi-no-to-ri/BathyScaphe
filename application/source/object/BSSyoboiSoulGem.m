//
//  BSSyoboiSoulGem.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/03/27.
//
//

#import "BSSyoboiSoulGem.h"
#import "BSTGrepResult.h"

@implementation BSSyoboiSoulGem
- (NSString *)queryStringForSearchString:(NSString *)searchStr
{
    NSString *encodedString = [searchStr stringByURLEncodingUsingEncoding:NSUTF8StringEncoding];
    if (!encodedString || [encodedString isEqualToString:@""]) {
        return nil;
    }
    NSString *queryString = [NSString stringWithFormat:@"http://ff2ch.syoboi.jp/?q=%@", encodedString];
    return queryString;
}

- (NSTimeInterval)cacheTimeInterval
{
    return 180;
}

- (BOOL)canHandleSearchOptionType:(BSTGrepSearchOptionType)type
{
    return (type == BSTGrepSearchByNew);
}

- (NSArray *)parseHTMLSource:(NSString *)source error:(NSError **)errorPtr
{
    NSXMLDocument *xmlDoc = [[[NSXMLDocument alloc] initWithXMLString:source options:NSXMLDocumentTidyHTML error:errorPtr] autorelease];
    if (!xmlDoc) {
        return [NSArray empty];
    }
    NSArray *results = [xmlDoc objectsForXQuery:@".//li" error:errorPtr];
    if (!results) {
        return [NSArray empty];
    }
    NSMutableArray *bar = [NSMutableArray arrayWithCapacity:[results count]];
    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *foo = [obj objectsForXQuery:@".//a[@href]" error:errorPtr];
        NSString *threadURL = [[[foo objectAtIndex:0] attributeForName:@"href"] stringValue];
        NSString *threadTitle = [[foo objectAtIndex:0] stringValue];
        BSTGrepResult *result = [[BSTGrepResult alloc] initWithOrderNo:(idx+1) URL:threadURL titleWithoutBoldTag:threadTitle];
        [bar addObject:result];
        [result release];
    }];
    return bar;
}
@end
