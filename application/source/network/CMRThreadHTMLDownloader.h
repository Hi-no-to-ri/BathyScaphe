//
//  CMRThreadHTMLDownloader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/27.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "ThreadTextDownloader.h"



@interface CMRThreadHTMLDownloader : ThreadTextDownloader
@end

extern NSString *const CMRThreadHTMLDownloaderThreadNotFoundNotification; // Available in BathyScaphe 2.4.1 and later.