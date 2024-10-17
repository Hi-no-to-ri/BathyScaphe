//
//  BSYosemiteNoThreadsView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/12/07.
//
//

#import "BSYosemiteNoThreadsView.h"

@implementation BSYosemiteNoThreadsView
- (BOOL)isOpaque
{
    // to make the intent clear
    return NO;
}

- (BOOL)allowsVibrancy
{
    return YES;
}
@end
