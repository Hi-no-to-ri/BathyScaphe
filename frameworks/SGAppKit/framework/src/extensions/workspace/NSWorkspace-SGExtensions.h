//
//  NSWorkspace-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/25.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>


@interface NSWorkspace(BSExtensions)
// NSString filePath version of -activateFileViewerSelectingURLs:.
- (BOOL)revealFilesInFinder:(NSArray *)filePaths;

// Open URL(s) with or without activating default Web browser. 
- (BOOL)openURL:(NSURL *)url inBackground:(BOOL)flag;
- (BOOL)openURLs:(NSArray *)urls inBackground:(BOOL)flag;

// Icon Services Wrapper
- (NSImage *)systemIconForType:(OSType)iconType;

// Utilities for Default Web Browser
- (NSURL *)URLForDefaultWebBrowser;
- (NSString *)bundleIdentifierForDefaultWebBrowser;
@end
