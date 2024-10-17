//
//  BSSSSPIconManager.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/11/26.
//
//

#import <Foundation/Foundation.h>
@class NSTextAttachment;


@interface BSSSSPIconManager : NSObject {
    NSMutableDictionary *cachedIcons; // key: Icon URL - value: Image file URL (on local disk)
    
    NSMutableArray *downloadingURLs; // ちょうど今ダウンロード中の URL（重複してダウンロードする必要はない）
    
    NSURL *cacheDirectory;
}

+ (id)defaultManager;

- (NSTextAttachment *)SSSPIconAttachmentForURL:(NSURL *)URL;

- (void)removeAllCachedIcons;
@end


extern NSString *const BSSSSPIconPlaceholderDidUpdateNotification;
extern NSString *const BSSSSPIconDidCacheNotification;

// Userinfo keys for BSSSSPIconDidCacheNotification
#define kBSSSSPIconCachedURLKey     @"URL" // NSURL
#define kBSSSSPIconCachedImageKey   @"Image" // NSImage
