//
//  BoardManager-SpamFilter.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 10/05/22.
//  Copyright 2010-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BoardManager_p.h"
#import "CMRDocumentFileManager.h"
#import "CMRSpamFilter.h"
#import "BSBoardInfoInspector.h"

@implementation BoardManager(SpamFilter)
- (NSString *)corpusFilePathForBoard:(NSString *)boardName
{
    NSString *folderPath = [[CMRDocumentFileManager defaultManager] directoryWithBoardName:boardName];
	return [folderPath stringByAppendingPathComponent:BSNGExpressionsFile];
}

- (BOOL)copySpamCorpusFileFrom:(NSString *)oldBoardName to:(NSString *)newBoardName error:(NSError **)errorPtr
{
    if ([oldBoardName isEqualToString:newBoardName]) {
        // Nothing to do
        return YES;
    }
    
    NSString *fromPath = [self corpusFilePathForBoard:oldBoardName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fromPath]) {
        // Nothing to do
        return YES;
    }

    // SpamSamples.plist には掲示板名の情報は含まれていないので、単にコピーするだけでいい
    NSString *toPath = [self corpusFilePathForBoard:newBoardName];
    return [[NSFileManager defaultManager] copyItemAtPath:fromPath toPath:toPath error:errorPtr];
}

- (NSDictionary *)parseBBSSlipData:(NSURL *)url
{
    NSString *fileContents = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
    if (!fileContents) {
        return nil;
    }
    
    __block NSMutableDictionary *mutableDict = [[NSMutableDictionary alloc] init];
    
    [fileContents enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        if (![line hasPrefix:@"//"]) {
            NSArray *array = [line componentsSeparatedByString:@"="];
            [mutableDict setObject:[[array objectAtIndex:1] componentsSeparatedByString:@","] forKey:[array objectAtIndex:0]];
        }
    }];
    
    NSDictionary *dict = [NSDictionary dictionaryWithDictionary:mutableDict];
    [mutableDict release];
    return dict;
}

- (NSArray *)availableHostSymbolsForBoard:(NSString *)boardName
{
    static NSDictionary *store = nil;
    if (!store) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"BBS_SLIP" withExtension:@"txt"];
        store = [[self parseBBSSlipData:url] retain];
    }
    NSString *slipType = [self BBSSlipValueForBoard:boardName];
    
    return ([store objectForKey:slipType] ?: [store objectForKey:@""]);
}

- (NSMutableDictionary *)corpusCache
{
    if (!m_corpusCache) {
        m_corpusCache = [[NSMutableDictionary alloc] init];
        [[NSTimer scheduledTimerWithTimeInterval:600 // 10 minutes
                                          target:self
                                        selector:@selector(saveSpamCorpusIfNeeded:)
                                        userInfo:nil
                                         repeats:YES] retain];
    }
    return m_corpusCache;
}

- (NSSet *)spamHostSymbolsForBoard:(NSString *)boardName
{
    id obj = [self valueForKey:@"SpamHostSymbols" atBoard:boardName defaultValue:nil];
    if (obj && [obj isKindOfClass:[NSArray class]]) {
        return [NSSet setWithArray:obj];
    }
    return [CMRPref spamHostSymbols];
}

- (void)setSpamHostSymbols:(NSSet *)set forBoard:(NSString *)boardName
{
    if (!set) {// || [set count] < 1) {
        [self removeValueForKey:@"SpamHostSymbols" atBoard:boardName];
    } else {
        if ([set isEqualToSet:[CMRPref spamHostSymbols]]) {
            [self removeValueForKey:@"SpamHostSymbols" atBoard:boardName];
        } else {
            [self setValue:[set allObjects] forKey:@"SpamHostSymbols" atBoard:boardName];
        }
    }
}

- (BOOL)treatsNoSageAsSpamAtBoard:(NSString *)boardName
{
    return [self boolValueForKey:@"TreatsNoSageAsSpam" atBoard:boardName defaultValue:[CMRPref treatsNoSageAsSpam]];
}

- (void)setTreatsNoSageAsSpam:(BOOL)flag atBoard:(NSString *)boardName
{
    [self setBoolValue:flag forKey:@"TreatsNoSageAsSpam" atBoard:boardName];
}

- (BOOL)treatsAsciiArtAsSpamAtBoard:(NSString *)boardName
{
    return [self boolValueForKey:@"TreatsAsciiArtAsSpam" atBoard:boardName defaultValue:[CMRPref treatsAsciiArtAsSpam]];
}

- (void)setTreatsAsciiArtAsSpam:(BOOL)flag atBoard:(NSString *)boardName
{
    [self setBoolValue:flag forKey:@"TreatsAsciiArtAsSpam" atBoard:boardName];
}

- (BOOL)registrantShouldConsiderNameAtBoard:(NSString *)boardName
{
    return [self boolValueForKey:@"RegistrantConsidersName" atBoard:boardName defaultValue:[CMRPref registrantShouldConsiderName]];
}

- (void)setRegistrantShouldConsiderName:(BOOL)flag atBoard:(NSString *)boardName
{
    [self setBoolValue:flag forKey:@"RegistrantConsidersName" atBoard:boardName];
}

- (NSMutableArray *)spamMessageCorpusForBoard:(NSString *)boardName
{
    id cachedCorpus = [[self corpusCache] objectForKey:boardName];
    if (cachedCorpus) {
        return cachedCorpus;
    }

    CMRSpamFilter *sf = [CMRSpamFilter sharedInstance];
    NSArray *plist = [sf readFromContentsOfPropertyListFile:[self corpusFilePathForBoard:boardName]];
    if (!plist) {
        [[self corpusCache] setObject:[NSMutableArray array] forKey:boardName];
    } else {
        [[self corpusCache] setObject:[sf restoreFromPlistToCorpus:plist] forKey:boardName];
    }
    return [[self corpusCache] objectForKey:boardName];
}

- (void)setSpamMessageCorpus:(NSMutableArray *)mutableArray forBoard:(NSString *)boardName
{
    [[self corpusCache] setObject:mutableArray forKey:boardName];
}

- (NSString *)BBSSlipValueForBoard:(NSString *)boardName
{
    id obj = [self valueForKey:@"BBS_SLIP" atBoard:boardName defaultValue:nil];
    if (obj) {
        return obj;
    }
    return @""; // とりあえずこれを返しておく
}

- (void)setBBSSlipValue:(NSString *)value forBoard:(NSString *)boardName
{
    [self setValue:(value ?: @"") forKey:@"BBS_SLIP" atBoard:boardName];
}

- (void)saveSpamCorpusIfNeeded:(NSTimer *)timer
{
    if (!m_corpusCache) {
        return;
    }
    NSMutableDictionary *corpusCache = [self corpusCache];
    CMRSpamFilter *sf = [CMRSpamFilter sharedInstance];
    for (NSString *boardName in corpusCache) {
        id rep = [sf propertyListRepresentation:[corpusCache objectForKey:boardName]];
        if (rep) {
            [sf saveRepresentation:rep toFile:[self corpusFilePathForBoard:boardName]];
        }
    }
}

- (void)addNGExpression:(BSNGExpression *)expression forBoard:(NSString *)boardName
{
	[[BSBoardInfoInspector sharedInstance] willChangeValueForKey:@"spamCorpusForTargetBoard"];
	[[self spamMessageCorpusForBoard:boardName] addObject:expression];
	[[BSBoardInfoInspector sharedInstance] didChangeValueForKey:@"spamCorpusForTargetBoard"];
}
@end
