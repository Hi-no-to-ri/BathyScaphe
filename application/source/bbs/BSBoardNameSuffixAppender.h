//
//  BSBoardNameSuffixAppender.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/05/06.
//
//

#import <Foundation/Foundation.h>

@interface BSBoardNameSuffixAppender : NSObject {
    NSArray *_sameBoardNameArray;
    NSArray *_targetBoardNames;
}

@property(readonly) NSArray *targetBoardNames;

+ (id)sharedInstance;

- (NSString *)boardNameByAppendingAppropriateSuffix:(NSString *)baseName forURL:(NSString *)boardURL;
@end
