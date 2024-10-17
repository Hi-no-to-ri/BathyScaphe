//
//  BSBoardNameSuffixAppender.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/05/06.
//
//

#import "BSBoardNameSuffixAppender.h"
#import "CocoMonar_Prefix.h"

@implementation BSBoardNameSuffixAppender
@synthesize targetBoardNames = _targetBoardNames;

APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(sharedInstance)

- (id)init
{
    self = [super init];
    if (self) {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"SameBoardName" ofType:@"plist"];
        _sameBoardNameArray = [[NSArray alloc] initWithContentsOfFile:plistPath];
        _targetBoardNames = [[_sameBoardNameArray valueForKey:@"BoardName"] retain];
    }
    return self;
}

- (void)dealloc
{
    [_targetBoardNames release];
    [_sameBoardNameArray release];
    [super dealloc];
}

- (NSString *)boardNameByAppendingAppropriateSuffix:(NSString *)baseName forURL:(NSString *)boardURL
{
    NSUInteger idx = [[self targetBoardNames] indexOfObject:baseName];
    if (idx == NSNotFound) {
        return baseName;
    }
    
    NSArray *suffixes = [[_sameBoardNameArray objectAtIndex:idx] objectForKey:@"Suffixes"];
    for (NSDictionary *data in suffixes) {
        if ([boardURL hasSuffix:[data objectForKey:@"URLPattern"]]) {
            return [baseName stringByAppendingString:[data objectForKey:@"Suffix"]];
        }
    }
    
    // 通常、ここには来ないはず…
    return [baseName stringByAppendingString:@"(2)"];
}
@end
