//
//  CMRDATDownloader.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/07/22.
//  Copyright 2007-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRDATDownloader.h"
#import "ThreadTextDownloader_p.h"
#import "CMRServerClock.h"
#import "CMRHostHandler.h"
#import "DatabaseManager.h"
#import "missing.h"


// for debugging only
#define UTIL_DEBUGGING		0
#import "UTILDebugging.h"

NSString *const CMRDATDownloaderDidDetectDatOchiNotification = @"CMRDATDownloaderDidDetectDatOchiNotification";
NSString *const CMRDATDownloaderDidSuspectBBONNotification = @"CMRDATDownloaderDidSuspectBBONNotification";
NSString *const CMRDATDownloaderDidDetectInvalidHEADUpdatedNotification = @"CMRDATDownloaderDidDitectIHUNotification";


@implementation CMRDATDownloader
@synthesize shouldNotAppendRangeHeader = m_shouldNotAppendRangeHeader;

+ (BOOL)canInitWithURL:(NSURL *)url
{
	CMRHostHandler	*handler_;

	handler_ = [CMRHostHandler hostHandlerForURL:url];
	return handler_ ? [handler_ canReadDATFile] : NO;
}

- (NSURL *)threadURL
{
	CMRHostHandler	*handler_;
	NSURL			*boardURL_ = [self boardURL];

	UTILAssertNotNil([self threadSignature]);

	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
	return [handler_ readURLWithBoard:boardURL_ datName:[[self threadSignature] identifier]];
}

- (NSURL *)resourceURL
{
	CMRHostHandler	*handler_;
	NSURL			*boardURL_ = [self boardURL];

	UTILAssertNotNil([self threadSignature]);

	handler_ = [CMRHostHandler hostHandlerForURL:boardURL_];
	return [handler_ datURLWithBoard:boardURL_ datName:[[self threadSignature] datFilename]];
}

- (void)setRokkaLastError:(NSInteger)error
{
    ; // Dummy
}

- (void)cancelDownloadWithDetectingDatOchi:(NSString *)movedLocation
{
	NSArray			*recoveryOptions;
	NSDictionary	*dict;
	NSError			*error;
    NSString *description;
    NSString *suggestion;
    if ([self threadTitle]) {
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 検討済
        description = [NSString stringWithFormat:[self localizedString:@"DatOchiDescription"], [self threadTitle]];
        suggestion = [self localizedString:@"DatOchiSuggestion"];
    } else {
        NSString *tmp;
        description = [self localizedString:@"DatOchiDescription2"];
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 検討済
        tmp = [NSString stringWithFormat:[self localizedString:@"DatOchiSuggestion2"], [[self threadURL] absoluteString]];
        suggestion = [tmp stringByAppendingString:[self localizedString:@"DatOchiSuggestion"]];
    }

	recoveryOptions = [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], [self localizedString:@"DatOchiRetry"], nil];
	dict = [NSDictionary dictionaryWithObjectsAndKeys:
				recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
				description, NSLocalizedDescriptionKey,
				suggestion, NSLocalizedRecoverySuggestionErrorKey,
                [self localizedString:@"DatOchiHelpAnchor"], NSHelpAnchorErrorKey,
				NULL];
	error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSDATDownloaderThreadNotFoundError userInfo:dict];
	UTILNotifyInfo3(CMRDATDownloaderDidDetectDatOchiNotification, error, @"Error");
}

- (void)cancelDownloadWithSuspectingBBON
{
    NSArray *recoveryOptions;
    NSDictionary *dict;
    NSError *error;

    recoveryOptions = [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], [self localizedString:@"BBONInfo"], nil];
    dict = [NSDictionary dictionaryWithObjectsAndKeys:
                recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
                [self localizedString:@"BBONDescription"], NSLocalizedDescriptionKey,
                [self localizedString:@"BBONSuggestion"], NSLocalizedRecoverySuggestionErrorKey,
                NULL];
    error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:403 userInfo:dict];
    UTILNotifyInfo3(CMRDATDownloaderDidSuspectBBONNotification, error, @"Error");
}
@end


@implementation CMRDATDownloader(PrivateAccessor)
- (void)setupRequestHeaders:(NSMutableDictionary *)mdict
{
	[super setupRequestHeaders:mdict];

	if ([self partialContentsRequested]) {
		NSNumber *byteLenNum_;
		NSDate *lastDate_;
		NSInteger bytelen;
		NSString *rangeString;
		
		byteLenNum_ = [[self localThreadsDict] objectForKey:ThreadPlistLengthKey];
		UTILAssertNotNil(byteLenNum_);
		lastDate_ = [[self localThreadsDict] objectForKey:CMRThreadModifiedDateKey];

		[mdict setObject:@"identity" forKey:HTTP_ACCEPT_ENCODING_KEY];

		bytelen = [byteLenNum_ integerValue];
		bytelen -= 1; // Get Extra 1 byte, then check received data. if 1st byte is not \n, it's error.
// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 修正済
		rangeString = [NSString stringWithFormat:@"bytes=%ld-", (long)bytelen];
        if (![self shouldNotAppendRangeHeader]) {
            [mdict setNoneNil:rangeString forKey:HTTP_RANGE_KEY];
        }
        NSString *rfc1123dateString = [[BSHTTPDateFormatter sharedHTTPDateFormatter] stringFromDate:lastDate_];
        [mdict setNoneNil:rfc1123dateString forKey:HTTP_IF_MODIFIED_SINCE_KEY];
	}
}
@end


@implementation CMRDATDownloader(ResourceManagement)
// 2ch の場合 Last-Modified がレスポンスヘッダに存在するので、それを解析
- (void)synchronizeServerClock:(NSHTTPURLResponse *)response
{
	[super synchronizeServerClock:response];
	NSString *dateString2;
	NSDate *date2;

	dateString2 = [[response allHeaderFields] stringForKey:HTTP_LAST_MODIFIED_KEY];
	if (!dateString2) {
		return;
	} else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** synchronizeServerClock: OK.");
        }
	}
	date2 = [[BSHTTPDateFormatter sharedHTTPDateFormatter] dateFromString:dateString2];
	if (!date2) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** ERROR - Why? failed to convert. String: %@", dateString2);
        }
	} else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:BSUserDebugEnabledKey]) {
            NSLog(@"** USER DEBUG ** dateString2 -> date2: OK.");
        }
	}

	[self setLastDate:date2];
    
    // ステータスコードを覚えておく
    httpStatusCode = [response statusCode];
}
@end


@implementation CMRDATDownloader(LoadingResourceData)
- (void)fixDatabaseStatus:(ThreadStatus)validStatus
{
    CMRThreadSignature *signature = [self threadSignature];
    DatabaseManager *dbm = [DatabaseManager defaultManager];
    
    [dbm updateStatus:validStatus modifiedDate:[self lastDate] forThreadSignature:signature];
}

- (CMRDownloaderDataProcessResult)dataProcess:(NSData *)resourceData withConnector:(NSURLConnection *)connector
{
	NSString			*datContents_;

	if (!resourceData || [resourceData length] == 0) {
		return CMRDownloaderDataProcessNoData;
	}
    
    NSData *resourceData2;

	if ([self partialContentsRequested]) {
        if (httpStatusCode == 200) {
            // 2015-01-15 えーっ、部分リクエストなのにステータス200で全データ来たのかい？
            NSUInteger cutLength = [[[self localThreadsDict] objectForKey:ThreadPlistLengthKey] unsignedIntegerValue] - 1;
            if (cutLength + 1 > [resourceData length]) { // ローカルDAT > リモートDATA i.e. 新着なしであぼーんあり
                [self cancelDownloadWithInvalidPartial];
                return CMRDownloaderDataProcessFailed;
            }
            NSUInteger sabunLength = [resourceData length] - cutLength;
            // あたかも差分データのみ取れたようにここですり替える
            resourceData2 = [resourceData subdataWithRange:NSMakeRange(cutLength, sabunLength)];
        } else {
            resourceData2 = resourceData;
        }
        
		const char		*p = NULL;
		p = (const char *)[resourceData2 bytes];
		if (*p != '\n') {
			[self cancelDownloadWithInvalidPartial];
			return CMRDownloaderDataProcessFailed;
		}
    } else {
        resourceData2 = resourceData;
    }
	
	datContents_ = [self contentsWithData:resourceData2];
    if ([datContents_ length] == 1) {
        // データが「\n」のみ＝実際には新着レスが無い
        [self setAmount:-1];
        [self fixDatabaseStatus:ThreadLogCachedStatus];
        return CMRDownloaderDataProcessNoData;
    }
    
    if ([self isKindOfClass:NSClassFromString(@"BSOfflaw2Downloader")] && [datContents_ hasPrefix:@"ERROR"]) {
        [self cancelDownloadWithDetectingDatOchi:nil];
        return CMRDownloaderDataProcessFailed;
    }

    if ([self useMaru]) {
        NSString *firstLine;
        // 最初の行を切り取る
        NSRange firstLineRange = [datContents_ lineRangeForRange:NSMakeRange(0, 1)];
        NSUInteger secondLineHead = NSMaxRange(firstLineRange);

        if (secondLineHead < [datContents_ length]) {
             // firstLineRange には、1行目の改行文字も含まれる
            firstLine = [datContents_ substringWithRange:firstLineRange];
        } else {
            // 1行しか無い（Error 13などの場合ありうる）
           firstLine = [NSString stringWithString:datContents_];
        }
        
        NSScanner *scanner = [NSScanner scannerWithString:firstLine];
        NSInteger errorCode = 0;
        
        while (![scanner isAtEnd]) {
            if ([scanner scanString:@"Success" intoString:NULL]) {
                if ([scanner scanString:@"Pool" intoString:NULL]) {
                    // dat is neither live nor archived
                    errorCode = -2;
                } else if ([scanner scanString:@"Archive" intoString:NULL]) {
                    datContents_ = [datContents_ substringFromIndex:secondLineHead];
                } else if ([scanner scanString:@"Live" intoString:NULL]) {
                    // dat 落ちしていない（Live）スレッドも Rokka で取れちゃうみたいなので、ひとまず
                    // 正常系同様に処理しておく
                    datContents_ = [datContents_ substringFromIndex:secondLineHead];
                } else {
                    // 想定外の書式
                    errorCode = -1;
                    break;
                }
            } else if ([scanner scanString:@"Error" intoString:NULL] && [scanner scanInteger:&errorCode]) {
                // Error.
            } else {
                // 想定外の書式
                errorCode = -1;
                break;
            }
        }
        
        if (errorCode != 0) {
            [self setRokkaLastError:errorCode];
            [self cancelDownloadWithDetectingDatOchi:nil];
            return CMRDownloaderDataProcessFailed;
        }
    }

	return [self synchronizeLocalDataWithContents:datContents_ dataLength:[resourceData2 length] error:NULL];
}
@end
