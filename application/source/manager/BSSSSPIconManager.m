//
//  BSSSSPIconManager.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/11/26.
//
//

#import "BSSSSPIconManager.h"
#import <SGAppKit/SGAppKit.h>
#import <CocoMonar/CocoMonar.h>
#import "BSSSSPIconAttachmentCell.h"

@interface BSSSSPIconAttachment : NSTextAttachment {
    NSURL *iconURL;
}
@property(readwrite, strong) NSURL *iconURL;

- (void)observeIconToFinishDownload:(id)notificationSender;
@end

@implementation BSSSSPIconAttachment
@synthesize iconURL;

- (void)dealloc
{
    [iconURL release];
    [super dealloc];
}

- (void)observeIconToFinishDownload:(id)notificationSender
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePlaceholderToIcon:) name:BSSSSPIconDidCacheNotification object:notificationSender];
}

- (void)changePlaceholderToIcon:(NSNotification *)notification
{
    UTILAssertNotificationName(notification, BSSSSPIconDidCacheNotification);
    NSURL *url = [[notification userInfo] objectForKey:kBSSSSPIconCachedURLKey];
    if ([self.iconURL isEqualTo:url]) {
        NSImage *image = [[notification userInfo] objectForKey:kBSSSSPIconCachedImageKey];
        [(NSCell *)[self attachmentCell] setImage:image];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}
@end

#pragma mark -

NSString *const BSSSSPIconPlaceholderDidUpdateNotification = @"jp.tsawada2.BathyScaphe.BSSSSPIconPlaceholderDidUpdateNotification";
NSString *const BSSSSPIconDidCacheNotification = @"jp.tsawada2.BathyScaphe.BSSSSPIconDidCacheNotification";

@interface BSSSSPIconManager ()
- (NSMutableDictionary *)cachedIconIndex;
- (NSURL *)cacheDirectory;
- (NSImage *)cachedIconOrPlaceholderImageForURL:(NSURL *)URL isPlaceholder:(BOOL *)placeholderFlagPtr;

- (void)addIconData:(NSData *)data forURL:(NSURL *)URL;
@end

@implementation BSSSSPIconManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager)

- (id)init
{
    if ((self = [super init])) {
        downloadingURLs = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:NSApp];
        
    }
    return self;
}

- (NSMutableDictionary *)cachedIconIndex
{
    if (!cachedIcons) {
        NSURL *indexFileURL = [[self cacheDirectory] URLByAppendingPathComponent:@"SSSPCacheIndex.plist" isDirectory:NO];
        NSMutableDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:indexFileURL options:NSDataReadingMappedIfSafe error:NULL]];
        if (dict) {
            cachedIcons = [dict retain];
        } else {
            cachedIcons = [[NSMutableDictionary alloc] init];
        }
    }
    return cachedIcons;
}

- (NSDictionary *)customSizeInfo
{
    static NSDictionary *g_sizeInfoDict = nil;
    if (!g_sizeInfoDict) {
        NSDictionary    *dict;
        
        dict = [NSBundle mergedDictionaryWithName:@"SSSPIconSizeData.plist"];
        UTILAssertKindOfClass(dict, NSDictionary);
        
        g_sizeInfoDict = [dict copy];
    }
    return g_sizeInfoDict;
}

- (NSDictionary *)customSizeInfoForPremium
{
    static NSDictionary *g_premiumSizeInfoDict = nil;
    if (!g_premiumSizeInfoDict) {
        NSDictionary    *dict;
        
        dict = [NSBundle mergedDictionaryWithName:@"SSSPPremiumIconSizeData.plist"];
        UTILAssertKindOfClass(dict, NSDictionary);
        
        g_premiumSizeInfoDict = [dict copy];
    }
    return g_premiumSizeInfoDict;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    if (cachedIcons && ([cachedIcons count] > 0)) {
        NSURL *indexFileURL = [[self cacheDirectory] URLByAppendingPathComponent:@"SSSPCacheIndex.plist" isDirectory:NO];
        [[NSKeyedArchiver archivedDataWithRootObject:cachedIcons] writeToURL:indexFileURL options:NSDataWritingAtomic error:NULL];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [downloadingURLs release];
    [cachedIcons release];
    [super dealloc];
}

- (NSURL *)cacheDirectory
{
    if (!cacheDirectory) {
//        NSURL *baseDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        NSURL  *baseDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
        NSString *pathComponent = [NSString stringWithFormat:@"%@/SSSPIcons", [[NSBundle mainBundle] bundleIdentifier]];
        cacheDirectory = [[baseDirectory URLByAppendingPathComponent:pathComponent isDirectory:YES] retain];
        [[NSFileManager defaultManager] createDirectoryAtURL:cacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return cacheDirectory;
}

- (void)removeAllCachedIcons
{
    if (cacheDirectory) {
        [[NSFileManager defaultManager] removeItemAtURL:cacheDirectory error:NULL];
        [cacheDirectory release];
        cacheDirectory = nil;
    } else {
        NSURL  *baseDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:NULL];
        if (baseDirectory) {
            NSString *pathComponent = [NSString stringWithFormat:@"%@/SSSPIcons", [[NSBundle mainBundle] bundleIdentifier]];
            NSURL *folderURLToBeRemoved = [baseDirectory URLByAppendingPathComponent:pathComponent isDirectory:YES];
            [[NSFileManager defaultManager] removeItemAtURL:folderURLToBeRemoved error:NULL]; // folderURLToBeRemoved が指し示すフォルダが存在しなくても問題無い
        }
    }
    
    if (cachedIcons) {
        [cachedIcons removeAllObjects];
    }
}

- (NSImage *)cachedIconOrPlaceholderImageForURL:(NSURL *)URL isPlaceholder:(BOOL *)placeholderFlagPtr
{
    NSImage *image = nil;
    NSURL *cachedFileURL = [[self cachedIconIndex] objectForKey:URL];
    if (cachedFileURL) {
        image = [[[NSImage alloc] initWithContentsOfURL:cachedFileURL] autorelease];
        if (!image) {
            // cache is invalid?
            [[self cachedIconIndex] removeObjectForKey:URL];
        } else {
            if (placeholderFlagPtr != NULL) {
                *placeholderFlagPtr = NO;
            }
        }
    }

    // キャッシュデータがない場合は、プレースホルダを返す
    if (!image)  {
        image = [[NSWorkspace sharedWorkspace] systemIconForType:kUnknownFSObjectIcon];
        NSString *key = [URL lastPathComponent];
        NSString *key2 = [[URL URLByDeletingLastPathComponent] lastPathComponent];
        if ([key2 isEqualToString:@"premium"]) {
            NSDictionary *premiumDict = [self customSizeInfoForPremium];
            if ([premiumDict objectForKey:key]) {
                [image setSize:NSSizeFromString([premiumDict objectForKey:key])];
            } else {
                [image setSize:NSMakeSize(48, 48)];
            }
        } else {
            NSDictionary *dict = [self customSizeInfo];
            if ([dict objectForKey:key]) {
                NSSize size = NSSizeFromString([dict objectForKey:key]);
                [image setSize:size];
            }
        }
        if (placeholderFlagPtr != NULL) {
            *placeholderFlagPtr = YES;
        }
    }
    return image;
}

- (void)addIconData:(NSData *)data forURL:(NSURL *)URL
{
    NSString *path = [URL lastPathComponent];
    NSURL *localURL = [[self cacheDirectory] URLByAppendingPathComponent:path isDirectory:NO];
    if ([data writeToURL:localURL options:NSDataWritingAtomic error:NULL]) {
        [[self cachedIconIndex] setObject:localURL forKey:URL];
    }
}

- (NSTextAttachment *)SSSPIconAttachmentForURL:(NSURL *)URL
{
    NSTextAttachmentCell *cell_;
    BOOL shouldDownload = NO;
    NSImage *image = [self cachedIconOrPlaceholderImageForURL:URL isPlaceholder:&shouldDownload];
    cell_ = [[BSSSSPIconAttachmentCell alloc] initImageCell:image];
    
    BSSSSPIconAttachment *attachment_ = [[BSSSSPIconAttachment alloc] init];
    [attachment_ setAttachmentCell:cell_];
    [cell_ release];

    if (shouldDownload) {
        // 現在ダウンロード中でない
        if (![downloadingURLs containsObject:URL]) {
            // 絶妙なタイミングでキャッシュが済んでいるかもしれないので、念のためもう一度探す
            if ([[self cachedIconIndex] objectForKey:URL]) {
                NSImage *cachedImage = [[[NSImage alloc] initWithContentsOfURL:[[self cachedIconIndex] objectForKey:URL]] autorelease];
                if (cachedImage) {
                    [(NSCell *)[attachment_ attachmentCell] setImage:cachedImage];
                    return attachment_;
                }
            }
            
            NSURLRequest *req = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
            [downloadingURLs addObject:URL];
            [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *resp, NSData *imageData, NSError *error) {
                if (imageData) {
                    [self addIconData:imageData forURL:URL];
                    NSImage *image = [[NSImage alloc] initWithData:imageData];
                    if (image) {
                        [(NSCell *)[attachment_ attachmentCell] setImage:image];
                        NSDictionary *userInfo = @{kBSSSSPIconCachedURLKey: URL, kBSSSSPIconCachedImageKey: image};
                        UTILNotifyInfo(BSSSSPIconDidCacheNotification, userInfo);
                        [image release];
                        UTILNotifyName(BSSSSPIconPlaceholderDidUpdateNotification);
                    }
                }
                [downloadingURLs removeObject:URL];
            }];
        } else {
            attachment_.iconURL = URL;
            [attachment_ observeIconToFinishDownload:self];
        }
    }
    return [attachment_ autorelease];
}
@end
