//
//  CMRDownloader-Task.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRDownloader_p.h"
#import "CMRTaskManager.h"

@implementation CMRDownloader(Description)
- (NSString *)categoryDescription
{
	return [[CMRDocumentFileManager defaultManager] boardNameWithLogPath:[self filePathToWrite]];
}

- (NSString *)simpleDescription
{
	return [self localizedDownloadString];
}

- (NSString *)resourceName
{
	UTILAbstractMethodInvoked;
	return nil;
}
@end


@implementation CMRDownloader(CMRLocalizableStringsOwner)
- (NSString *)localizedDownloadString
{
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 ���؍�
	return [NSString stringWithFormat:[self localizedString:APP_DOWNLOADER_DOWNLOAD], [self resourceName]];
}

- (NSString *)localizedErrorString
{
	return [self localizedString:APP_DOWNLOADER_ERROR];
}

- (NSString *)localizedCanceledString
{
	return [self localizedString:APP_DOWNLOADER_CANCEL];
}

- (NSString *)localizedUserCanceledString
{
	return [self localizedCanceledString];
}

- (NSString *)localizedNotModifiedString
{
	return [self localizedString:@"Not Modified"];
}

- (NSString *)localizedDetectingDatOchiString
{
	return [self localizedString:@"Detect Dat Ochi"];
}

- (NSString *)localizedSucceededString
{
	return [self localizedString:APP_DOWNLOADER_SUCCESS];
}

- (NSString *)localizedNotLoaded
{
	return [self localizedString:APP_DOWNLOADER_NOTLOADED];
}

- (NSString *)localizedTitleFormat
{
	return [self localizedString:APP_DOWNLOADER_TITLE];
}

- (NSString *)localizedMessageFormat
{
	return [self localizedString:APP_DOWNLOADER_MESSAGE];
}

+ (NSString *)localizableStringsTableName
{
	return APP_DOWNLOADER_TABLE_NAME;
}
@end


@implementation CMRDownloader(TaskNotification)
- (void)postTaskWillStartNotification
{
//	[[NSNotificationCenter defaultCenter] postNotificationName:CMRTaskWillStartNotification object:self];
    [[CMRTaskManager defaultManager] taskWillStart:self];
}

- (void)postTaskDidFinishNotification
{
//	[[NSNotificationCenter defaultCenter] postNotificationName:CMRTaskDidFinishNotification object:self];
    [[CMRTaskManager defaultManager] taskDidFinish:self];
}
@end
