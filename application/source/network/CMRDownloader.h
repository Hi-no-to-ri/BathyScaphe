//
//  CMRDownloader.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "CMRTask.h"

enum {
    CMRDownloaderDataProcessSuccess = 1,
    CMRDownloaderDataProcessNoData = -1,
    CMRDownloaderDataProcessFailed = 0,
};
typedef NSInteger CMRDownloaderDataProcessResult;

@interface CMRDownloader : NSObject<CMRTask>
{
	@private
	id					m_identifier;
	NSURLConnection		*m_connector;
	NSMutableData		*m_data;
	NSString			*m_statusMessage;
	BOOL				m_isInProgress;
	double				m_amount;
	double				m_expectedLength;
}

- (NSDictionary *)requestHeaders;
+ (NSMutableDictionary *)defaultRequestHeaders;

- (NSURLConnection *)currentConnector;

- (NSURL *)boardURL;
- (NSURL *)resourceURL;
- (NSString *)filePathToWrite;

- (NSMutableData *)resourceData;
- (void)setResourceData:(NSMutableData *)data;

- (BOOL)reusesDownloader;
- (void)setReusesDownloader:(BOOL)willReuse;

- (NSString *)connectionFailedErrorMessageText;
- (NSString *)unexpectedStatusErrorMessageText:(NSInteger)status;
- (void)cancelDownloadWithConnectionFailed:(NSError *)underlyingError;
- (void)cancelDownloadWithDetectingDatOchi:(NSString *)movedLocation;
- (void)cancelDownloadWithNoUpdatedContents;

- (void)checkResponse:(NSHTTPURLResponse *)response statusCode:(NSInteger)status forConnection:(NSURLConnection *)connection;
@end


@interface CMRDownloader(LoadingResourceData)
- (void)loadInBackground;
- (CMRDownloaderDataProcessResult)dataProcess:(NSData *)resourceData withConnector:(NSURLConnection *)connector;
- (void)didFinishLoading;
@end

extern NSString *const CMRDownloaderConnectionDidFailNotification;

extern NSString *const CMRDownloaderContentsNotModifiedNotification; // Available in BathyScaphe 2.3 "Bright Stream" and later.

// UserInfo
#define CMRDownloaderUserInfoContentsKey		@"Contents"
//#define CMRDownloaderUserInfoResourceURLKey		@"ResourceURL"
//#define CMRDownloaderUserInfoIdentifierKey		@"Identifier"
// for thread only.
#define CMRDownloaderUserInfoNextIndexKey		@"NextIndex"
