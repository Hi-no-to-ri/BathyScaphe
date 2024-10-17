//
//  CMRTrashbox.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/21.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRTrashbox.h"
#import "CocoMonar_Prefix.h"
#import "DatabaseManager.h"
#import <AudioToolbox/AudioToolbox.h>

NSString *const CMRTrashboxDidPerformNotification	= @"CMRTrashboxDidPerformNotification";

NSString *const kAppTrashUserInfoFilesKey		= @"Files";
NSString *const kAppTrashUserInfoStatusKey		= @"Status";

@implementation CMRTrashbox
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(trash);

- (BOOL)performWithFiles:(NSArray *)filenames
{
    if (!filenames) {
        return NO;
    }
    
    NSMutableArray *urlsArray = [NSMutableArray array];
    for (NSString *path in filenames) {
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        if (fileURL) {
            [urlsArray addObject:fileURL];
        }
    }
    
    if ([urlsArray count] == 0) {
        return NO;
    }
    
    [[NSWorkspace sharedWorkspace] recycleURLs:urlsArray completionHandler:^(NSDictionary *newURLs, NSError *error) {
        if ([newURLs count] > 0) {
            AudioServicesPlaySystemSound(16);
            NSArray *trashedPaths = [[newURLs allKeys] valueForKey:@"path"];
            NSDictionary *info = @{kAppTrashUserInfoFilesKey: trashedPaths};
            [[DatabaseManager defaultManager] cleanUpItemsWhichHasBeenRemoved:trashedPaths];
            UTILNotifyInfo(CMRTrashboxDidPerformNotification, info);
        }
    }];
    
    return YES;
}
@end
