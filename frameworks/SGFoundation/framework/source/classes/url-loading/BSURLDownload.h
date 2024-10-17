//
//  BSURLDownload.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/10/27.
//  Copyright 2007-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@interface BSURLDownload : NSObject<NSURLDownloadDelegate> {
    NSURL           *m_targetURL;
    NSURLDownload   *m_download;
    NSString        *m_downloadedFilePath;
    NSString        *m_destination;

    long long lExLength;
    NSUInteger lDlLength;
    
    id      m_delegate;
    BOOL    m_allowsOverwrite;
}

// Designated Initializer
- (id)initWithURL:(NSURL *)url delegate:(id)delegate destination:(NSString *)path referer:(NSString *)refererString cachePolicy:(NSURLRequestCachePolicy)policy; // Available in BathyScaphe 2.4.2 and later.
- (id)initWithURL:(NSURL *)url delegate:(id)delegate destination:(NSString *)path;

- (NSURL *)URL;
- (NSURLDownload *)URLDownload;
- (NSString *)destination;
- (NSString *)downloadedFilePath;

- (void)cancel;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)allowsOverwriteDownloadedFile;
- (void)setAllowsOverwriteDownloadedFile:(BOOL)flag;
@end


@interface NSObject(BSURLDownloadDelegate)
- (void)bsURLDownload:(BSURLDownload *)download willDownloadContentOfSize:(NSUInteger)expectedLength; // expectedLength が不明な場合は呼ばれない
- (void)bsURLDownloadWillDownloadContentOfUnknownSize:(BSURLDownload *)download; // expectedLength が不明な場合のみ呼ばれる。Available in BathyScaphe 2.3 "Bright Stream" and later.
- (void)bsURLDownload:(BSURLDownload *)download didDownloadContentOfSize:(NSUInteger)downloadedLength; // expectedLength に関係なく呼ばれる

- (void)bsURLDownloadDidFinish:(BSURLDownload *)download;

- (BOOL)bsURLDownload:(BSURLDownload *)download shouldRedirectToURL:(NSURL *)newURL;
- (void)bsURLDownload:(BSURLDownload *)download didAbortRedirectionToURL:(NSURL *)canceledURL;

- (void)bsURLDownload:(BSURLDownload *)download didFailWithError:(NSError *)error;

// Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
- (BOOL)bsURLDownload:(BSURLDownload *)download shouldDownloadWithDestinationFileName:(NSString *)filename;
- (void)bsURLDownloadDidAbortForDenyingSuggestedFileName:(BSURLDownload *)download;
- (BOOL)bsURLDownload:(BSURLDownload *)download shouldDownloadWithMIMEType:(NSString *)type; // called before -bsURLDownload:willDownloadContentOfSize:.
- (void)bsURLDownloadDidAbortForDenyingResponsedMIMEType:(BSURLDownload *)download;
@end
