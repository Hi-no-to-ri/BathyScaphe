//
//  NSWorkspace-SGExtensions.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/25.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "NSWorkspace-SGExtensions.h"
#import "UTILKit.h"


@interface NSWorkspace(YosemiteStub)
- (NSRunningApplication *)openURLs:(NSArray *)urls withApplicationAtURL:(NSURL *)applicationURL options:(NSWorkspaceLaunchOptions)options configuration:(NSDictionary *)configuration error:(NSError **)error;
@end

@implementation NSWorkspace(BSExtensions)
- (BOOL)revealFilesInFinder:(NSArray *)filePaths
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[filePaths count]];
    for (NSString *path in filePaths) {
        [array addObject:[NSURL fileURLWithPath:path]];
    }
    [self activateFileViewerSelectingURLs:array];
    return YES;
}

/*- (BOOL)activateAppWithBundleIdentifier:(NSString *)bundleIdentifier
{
	if (!bundleIdentifier) return NO;
	const char		*bundleIdentifierStr;
	NSAppleEventDescriptor *targetDesc;
	NSAppleEventDescriptor *appleEvent;
	OSStatus err;

	bundleIdentifierStr = [bundleIdentifier UTF8String];
	targetDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplicationBundleID
																bytes:bundleIdentifierStr
															   length:strlen(bundleIdentifierStr)];
	if(!targetDesc) return NO;

	appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:kAEMiscStandards
														  eventID:kAEActivate
												 targetDescriptor:targetDesc
														 returnID:kAutoGenerateReturnID
													transactionID:kAnyTransactionID];
	if(!appleEvent) return NO;

	err = AESendMessage([appleEvent aeDesc], NULL, kAECanInteract, kAEDefaultTimeout);

	return (err == noErr);
}*/

#pragma mark Opening URL(s)
- (BOOL)openURLs:(NSArray *)urls inBackground:(BOOL)flag
{
	if (!urls || [urls count] == 0) return NO;

	NSWorkspaceLaunchOptions	options = NSWorkspaceLaunchDefault;

	if (flag) {
		options |= NSWorkspaceLaunchWithoutActivation;
	}

    // Yosemite 以降ではエラーを返してもらえるからこっちのメソッドを使おう。
    if (floor(NSAppKitVersionNumber) > 1265) {
        NSURL  *appURL = [self URLForDefaultWebBrowser];
        NSError *error = nil;

        if (![self openURLs:urls withApplicationAtURL:appURL options:options configuration:nil error:&error] && error) {
            // エラーをユーザに表示
            [[NSAlert alertWithError:error] runModal];
            return NO;
        }
        return YES;
    } else {
        NSString	*identifier = [self bundleIdentifierForDefaultWebBrowser];
        return [self openURLs:urls withAppBundleIdentifier:identifier options:options additionalEventParamDescriptor:nil launchIdentifiers:nil];
    }
}

- (BOOL)openURL:(NSURL *)url inBackground:(BOOL)flag
{
	return [self openURLs:[NSArray arrayWithObject:url] inBackground:flag];
}

#pragma mark Icon Services Wrapper
- (NSImage *)systemIconForType:(OSType)iconType
{
    NSImage *iconImage = [self iconForFileType:NSFileTypeForHFSTypeCode(iconType)];
    
    return iconImage;
}

#pragma mark Default Web Browser Utilities
/*- (NSString *)absolutePathForDefaultWebBrowser
{
	NSURL	*dummyURL = [NSURL URLWithString:@"http://www.apple.com/"];
	OSStatus	err;
	FSRef	outAppRef;
	CFURLRef	outAppURL;
	CFStringRef	appPath;
	NSString	*result_ = nil;

	err = LSGetApplicationForURL((CFURLRef )dummyURL, kLSRolesAll, &outAppRef, &outAppURL);
	if (err == noErr && outAppURL) {
		appPath = CFURLCopyFileSystemPath(outAppURL, kCFURLPOSIXPathStyle);
		result_ = [NSString stringWithString:(NSString *)appPath];
		CFRelease(appPath);
	}

	return result_;
}*/

- (NSURL *)URLForDefaultWebBrowser
{
    return [self URLForApplicationToOpenURL:[NSURL URLWithString:@"http://www.apple.com/"]];
}

/*- (NSImage *)iconForDefaultWebBrowser
{
	return [self iconForFile:[self absolutePathForDefaultWebBrowser]];
}*/

- (NSString *)bundleIdentifierForDefaultWebBrowser
{
//	NSBundle *bundle = [NSBundle bundleWithPath:[self absolutePathForDefaultWebBrowser]];
    NSBundle *bundle = [NSBundle bundleWithURL:[self URLForDefaultWebBrowser]];

	return [bundle bundleIdentifier];
}
@end
