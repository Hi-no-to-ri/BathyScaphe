//
//  CMRThreadViewer-Download.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/08/23.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"
#import "CMRAbstructThreadDocument.h"
#import "CMRDATDownloader.h"
#import "CMRThreadHTMLDownloader.h"
#import "BSLoggedInDATDownloader.h"
#import "BSOfflaw2Downloader.h"

@implementation CMRThreadViewer(Download)
#pragma mark Start Downloading
- (void)downloadThread:(CMRThreadSignature *)aSignature title:(NSString *)threadTitle nextIndex:(NSUInteger)aNextIndex
{
	CMRDownloader			*downloader;
	NSNotificationCenter	*nc;
	
	nc = [NSNotificationCenter defaultCenter];
	downloader = [ThreadTextDownloader downloaderWithIdentifier:aSignature threadTitle:threadTitle nextIndex:aNextIndex];

	if (!downloader) return;
	
	/* NotificationCenter */
    [nc addObserver:self 
           selector:@selector(threadTextDownloaderConnectionDidFail:) 
               name:CMRDownloaderConnectionDidFailNotification 
             object:downloader];
	[nc addObserver:self
		   selector:@selector(threadTextDownloaderInvalidPerticalContents:)
			   name:ThreadTextDownloaderInvalidPerticalContentsNotification
			 object:downloader];
    if ([downloader isKindOfClass:[CMRDATDownloader class]]) {
        [nc addObserver:self
               selector:@selector(threadTextDownloaderDidDetectDatOchi:)
                   name:CMRDATDownloaderDidDetectDatOchiNotification
                 object:downloader];
        [nc addObserver:self
               selector:@selector(threadTextDownloaderDidSuspectBBON:)
                   name:CMRDATDownloaderDidSuspectBBONNotification
                 object:downloader];
    } else if ([downloader isKindOfClass:[CMRThreadHTMLDownloader class]]) {
        [nc addObserver:self
               selector:@selector(threadTextDownloaderDidDetectDatOchi:)
                   name:CMRThreadHTMLDownloaderThreadNotFoundNotification
                 object:downloader];
    }
	[nc addObserver:self
		   selector:@selector(threadTextDownloaderDidFinishLoading:)
			   name:ThreadTextDownloaderDidFinishLoadingNotification
			 object:downloader];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderContentsNotModified:)
               name:CMRDownloaderContentsNotModifiedNotification
             object:downloader];

	/* load */
	[downloader loadInBackground];
}

#pragma mark After Download (Success)
- (void)removeFromNotificationCenterWithDownloader:(CMRDownloader *)downloader
{
	NSNotificationCenter	*nc;

	if (!downloader) return;
	nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self
				  name:CMRDownloaderConnectionDidFailNotification
				object:downloader];
	[nc removeObserver:self
				  name:ThreadTextDownloaderInvalidPerticalContentsNotification
				object:downloader];
    if ([downloader isKindOfClass:[CMRDATDownloader class]]) {
        [nc removeObserver:self
                      name:CMRDATDownloaderDidDetectDatOchiNotification
                    object:downloader];
        [nc removeObserver:self
                      name:CMRDATDownloaderDidSuspectBBONNotification
                    object:downloader];
    } else if ([downloader isKindOfClass:[CMRThreadHTMLDownloader class]]) {
        [nc removeObserver:self
                      name:CMRThreadHTMLDownloaderThreadNotFoundNotification
                    object:downloader];
    }
	[nc removeObserver:self
				  name:ThreadTextDownloaderDidFinishLoadingNotification
				object:downloader];
    [nc removeObserver:self
                  name:CMRDownloaderContentsNotModifiedNotification
                object:downloader];
}

- (void)threadTextDownloaderDidFinishLoading:(NSNotification *)notification
{
	ThreadTextDownloader	*downloader;
	NSDictionary			*userInfo;
	NSString				*contents;

	UTILAssertNotificationName(notification, ThreadTextDownloaderDidFinishLoadingNotification);
	
	userInfo = [notification userInfo];
	UTILAssertNotNil(userInfo);

	downloader = [[notification object] retain];
	contents = [userInfo objectForKey:CMRDownloaderUserInfoContentsKey];
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
	UTILAssertKindOfClass(contents, NSString);
	
	[self removeFromNotificationCenterWithDownloader:downloader];
    
    // 2ペイン表示のときはダウンロード後何もする必要が無い
    if (![self shouldShowContents]) {
        [downloader release];
        return;
    }

    // 3ペインで、ダウンロード対象のスレッドと表示中のスレッドが異なる場合
	if (![[self threadIdentifier] isEqual:[downloader identifier]]) {
        [downloader release];
		return;
	}

    // 3ペインで、ダウンロード対象のスレッド＝表示中のスレッド。または、新規ウインドウで開いたスレッドの場合
	[[self threadAttributes] addEntriesFromDictionary:[userInfo objectForKey:CMRDownloaderUserInfoAdditionalInfoKey]];
	[self composeDATContents:contents threadSignature:[downloader identifier] nextIndex:[downloader nextIndex]];
	[downloader autorelease];
}

- (void)threadTextDownloaderContentsNotModified:(NSNotification *)notification
{
	[self removeFromNotificationCenterWithDownloader:[notification object]];
}

#pragma mark After Download (Some Error)
- (void)threadTextDownloaderConnectionDidFail:(NSNotification *)notification
{
	ThreadTextDownloader	*downloader;
	
	UTILAssertNotificationName(notification, CMRDownloaderConnectionDidFailNotification);
    
	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
    
	[self removeFromNotificationCenterWithDownloader:downloader];

	NSAlert *alert = [NSAlert alertWithError:[[notification userInfo] objectForKey:@"Error"]];

    if ([self isRetrieving] || [self isNotShownThreadRetrieving]) {
        NSString *tmp = [(NSError *)[[notification userInfo] objectForKey:@"Error"] localizedRecoverySuggestion];
        [alert setInformativeText:[tmp stringByAppendingString:NSLocalizedStringFromTable(@"ConnectionFailedSuggestionRetrieving", @"Downloader", @"")]];
    }

	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(threadConnectionFailedSheetDidEnd:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)threadTextDownloaderInvalidPerticalContents:(NSNotification *)notification
{
	ThreadTextDownloader	*downloader;
	
	UTILAssertNotificationName(notification, ThreadTextDownloaderInvalidPerticalContentsNotification);

	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);

	[self removeFromNotificationCenterWithDownloader:downloader];

    // DAT の場合で、range ヘッダー付きで取得を試みて 416 が返ってきた場合は、
    // range ヘッダーを付けないでもう一度取得してみる。
    if ([downloader isKindOfClass:[CMRDATDownloader class]] && ![(CMRDATDownloader *)downloader shouldNotAppendRangeHeader]) {
        [self downloadThreadWithoutRangeHeader:downloader];
        [downloader autorelease];
        return;
    }
    NSAlert *alert = [NSAlert alertWithError:[[notification userInfo] objectForKey:@"Error"]];
    [alert setShowsHelp:YES];
    [alert setDelegate:[NSApp delegate]];
    [alert beginSheetModalForWindow:[self window]
                      modalDelegate:self
                     didEndSelector:@selector(threadInvalidParticalContentsSheetDidEnd:returnCode:contextInfo:)
                        contextInfo:downloader];
}

- (void)informDatOchiWithTitleRulerIfNeeded
{
	if ([CMRPref informWhenDetectDatOchi]) {
		BSTitleRulerView *ruler = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];

		[ruler setCurrentMode:[[self class] rulerModeForInformDatOchi]];
		[ruler setInfoStr:[self localizedString:@"titleRuler info auto-detected title"]];
		[[self scrollView] setRulersVisible:YES];

		[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(cleanUpTitleRuler:) userInfo:nil repeats:NO];
	}
}

- (void)informOfflaw2soUsedWithTitleRuler
{
    BSTitleRulerView *ruler = (BSTitleRulerView *)[[self scrollView] horizontalRulerView];
    
    [ruler setCurrentMode:[[self class] rulerModeForInformDatOchi]];
    [ruler setInfoStr:[self localizedString:@"titleRuler info offlaw2so-used title"]];
    [[self scrollView] setRulersVisible:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(cleanUpTitleRuler:) userInfo:nil repeats:NO];
}

- (void)informDatOchiWithAlert:(ThreadTextDownloader *)downloader
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:[self localizedString:@"titleRuler info auto-detected title"]];
    [alert addButtonWithTitle:[self localizedString:@"threadViewer-download cancel"]];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(threadNotFoundSheetDidEnd:returnCode:contextInfo:) contextInfo:downloader];
}

- (void)beginNotFoundAlertSheetWithDownloader:(ThreadTextDownloader *)downloader error:(NSError *)error
{
	NSString	*filePath;
	filePath = [downloader filePathToWrite];

	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        if (![self shouldShowContents]) {
            [self informDatOchiWithAlert:downloader];
            return;
        }

        if (![self isRetrieving]) {
            if ([[self threadIdentifier] isEqual:[downloader identifier]]) {
                [(CMRAbstructThreadDocument *)[self document] setIsDatOchiThread:YES];
                [self informDatOchiWithTitleRulerIfNeeded];
                [downloader autorelease];
                return;
            } else {
                [self informDatOchiWithAlert:downloader];
                return;
            }
        }
	}

	const char *hs;
    
	hs = [[[downloader resourceURL] host] UTF8String];
    
    if (hs != NULL && is_2channel(hs)) {
        [self downloadThreadUsingOfflaw2so:downloader];
        [downloader autorelease];
    } else {
        NSAlert *alert = [NSAlert alertWithError:error];

        if ([self isRetrieving] || [self isNotShownThreadRetrieving]) {
            [alert setInformativeText:NSLocalizedStringFromTable(@"DatOchiSuggestionRetrieving", @"Downloader", @"")];
        }
        [alert setShowsHelp:YES];
        [alert setDelegate:[NSApp delegate]];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(threadNotFoundSheetDidEnd:returnCode:contextInfo:)
                            contextInfo:downloader];
    }
}

- (void)validateWhetherDatOchiWithDownloader:(ThreadTextDownloader *)downloader error:(NSError *)error
{
	NSUInteger	resCount;
	resCount = [downloader nextIndex];

    if ((resCount < 1001) || [self isRetrieving] || [self isNotShownThreadRetrieving]) {
		[self beginNotFoundAlertSheetWithDownloader:downloader error:error];
	} else {
		if ([[self threadIdentifier] isEqual:[downloader identifier]]) {
			[(CMRAbstructThreadDocument *)[self document] setIsDatOchiThread:YES];
			[self informDatOchiWithTitleRulerIfNeeded];
			[downloader autorelease];
		} else {
            [self beginNotFoundAlertSheetWithDownloader:downloader error:error];
        }
	}
}

- (void)threadTextDownloaderDidDetectDatOchi:(NSNotification *)notification
{
	CMRDATDownloader	*downloader;
	
//	UTILAssertNotificationName(notification, CMRDATDownloaderDidDetectDatOchiNotification);
		
	downloader = [[notification object] retain];
//	UTILAssertKindOfClass(downloader, CMRDATDownloader);

	[self removeFromNotificationCenterWithDownloader:downloader];

	[self validateWhetherDatOchiWithDownloader:downloader error:[[notification userInfo] objectForKey:@"Error"]];
//    [downloader autorelease]; // 禁止！
}

- (void)threadConnectionFailedSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
    
	if (returnCode == NSAlertFirstButtonReturn) {
        if ([self isRetrieving] || [self isNotShownThreadRetrieving]) {
            [self restoreFromRetrieving:[downloader filePathToWrite] error:NULL];
        }
	}
	[downloader autorelease];
}

- (void)threadInvalidParticalContentsSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSString				*path;
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);
	path = [downloader filePathToWrite];

	switch (returnCode) {
	case NSAlertFirstButtonReturn: // Delete and try again
	{
		if (![self retrieveThreadAtPath:path title:[downloader threadTitle]]) {
			NSBeep();
			NSLog(@"Deletion failed : %@\n...So reloading operation has been canceled.", path);
		}
		break;
	}
	case NSAlertSecondButtonReturn: // Cancel
		break;
	default:
		UTILUnknownSwitchCase(returnCode);
		break;
	}
	[downloader autorelease];
}

- (void)threadNotFoundSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);

	switch (returnCode) {
	case NSAlertFirstButtonReturn:
        {
            if ([self isRetrieving] || [self isNotShownThreadRetrieving]) {
                [self restoreFromRetrieving:[downloader filePathToWrite] error:NULL];
            } else {
                [self closeWindowOfAlert:sheet downloaderFilePath:[downloader filePathToWrite]];
            }
        }
		break;
	case NSAlertSecondButtonReturn:
        [self downloadThreadUsingMaru:downloader fromAlert:sheet];
		break;
	default:
		UTILUnknownSwitchCase(returnCode);
		break;
	}
	[downloader autorelease];
}

- (void)threadTextDownloaderDidSuspectBBON:(NSNotification *)notification
{
	CMRDATDownloader	*downloader;
	
	UTILAssertNotificationName(notification, CMRDATDownloaderDidSuspectBBONNotification);
		
	downloader = [[notification object] retain];
	UTILAssertKindOfClass(downloader, CMRDATDownloader);

	[self removeFromNotificationCenterWithDownloader:downloader];

	NSAlert *alert = [NSAlert alertWithError:[[notification userInfo] objectForKey:@"Error"]];

	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(suspectingBBONSheetDidEnd:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)suspectingBBONSheetDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
	UTILAssertKindOfClass(downloader, ThreadTextDownloader);

	switch (returnCode) {
	case NSAlertFirstButtonReturn: // Cancel
		break;
	case NSAlertSecondButtonReturn: // Info
    {
        NSString *urlString = SGTemplateResource(@"System - BBON Info URL");
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
		break;
    }
	default:
		UTILUnknownSwitchCase(returnCode);
		break;
	}
	[downloader autorelease];
}

#pragma mark Offlaw2.so/Maru-Login Downloading
- (void)registerNotificationAndStartDownloadingDatOchiDat:(CMRDATDownloader *)downloader
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(datOchiDatDownloadDidFinish:) name:ThreadTextDownloaderDidFinishLoadingNotification object:downloader];
	[nc addObserver:self selector:@selector(datOchiDownloadDidFail:) name:CMRDATDownloaderDidDetectDatOchiNotification object:downloader];
    
	// load
	[downloader loadInBackground];
}

- (void)downloadThreadWithoutRangeHeader:(id)primaryDownloader
{
    CMRDATDownloader *downloader;
    downloader = [CMRDATDownloader downloaderWithIdentifier:[primaryDownloader threadSignature] threadTitle:[primaryDownloader threadTitle] nextIndex:[primaryDownloader nextIndex]];
    downloader.shouldNotAppendRangeHeader = YES;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderConnectionDidFail:)
               name:CMRDownloaderConnectionDidFailNotification
             object:downloader];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderInvalidPerticalContents:)
               name:ThreadTextDownloaderInvalidPerticalContentsNotification
             object:downloader];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderDidDetectDatOchi:)
               name:CMRDATDownloaderDidDetectDatOchiNotification
             object:downloader];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderDidSuspectBBON:)
               name:CMRDATDownloaderDidSuspectBBONNotification
             object:downloader];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderDidFinishLoading:)
               name:ThreadTextDownloaderDidFinishLoadingNotification
             object:downloader];
    [nc addObserver:self
           selector:@selector(threadTextDownloaderContentsNotModified:)
               name:CMRDownloaderContentsNotModifiedNotification
             object:downloader];
    
    /* load */
    [downloader loadInBackground];
}

- (void)downloadThreadUsingOfflaw2so:(id)primaryDownloader
{
	BSOfflaw2Downloader *downloader;
    
	downloader = [BSOfflaw2Downloader downloaderWithIdentifier:[primaryDownloader threadSignature]
                                                   threadTitle:[primaryDownloader threadTitle]
                                                 candidateHost:[[self document] candidateHost]];
    
	[self registerNotificationAndStartDownloadingDatOchiDat:downloader];
}

- (void)downloadThreadUsingMaru:(id)primaryDownloader fromAlert:(NSAlert *)alert
{
	BSLoggedInDATDownloader *downloader;

	downloader = [BSLoggedInDATDownloader downloaderWithIdentifier:[primaryDownloader threadSignature]
                                                       threadTitle:[primaryDownloader threadTitle]
                                                     candidateHost:[[self document] candidateHost]];
	if (!downloader) {
        [self closeWindowOfAlert:alert downloaderFilePath:[primaryDownloader filePathToWrite]];
        return;
    }

	[self registerNotificationAndStartDownloadingDatOchiDat:downloader];
}

- (void)datOchiDatDownloadDidFinish:(NSNotification *)notification
{
	CMRDATDownloader	*downloader;
	NSDictionary			*userInfo;
	NSString				*contents;

	UTILAssertNotificationName(notification, ThreadTextDownloaderDidFinishLoadingNotification);
	
	userInfo = [notification userInfo];
	UTILAssertNotNil(userInfo);

	downloader = [[notification object] retain];
	contents = [userInfo objectForKey:CMRDownloaderUserInfoContentsKey];
//	UTILAssertKindOfClass(downloader, BSLoggedInDATDownloader);
	UTILAssertKindOfClass(contents, NSString);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ThreadTextDownloaderDidFinishLoadingNotification
                                                  object:downloader];
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:CMRDATDownloaderDidDetectDatOchiNotification
                                                  object:downloader];
    
    if (![self shouldShowContents]) {
        [downloader release];
        return;
    }
    
	if (![[self threadIdentifier] isEqual:[downloader identifier]]) {
        [downloader release];
		return;
	}

	[[self threadAttributes] addEntriesFromDictionary:[userInfo objectForKey:CMRDownloaderUserInfoAdditionalInfoKey]];
	[(CMRAbstructThreadDocument *)[self document] setIsDatOchiThread:YES];
    if ([downloader isKindOfClass:[BSOfflaw2Downloader class]]) {
        [self informOfflaw2soUsedWithTitleRuler];
    }
	[self composeDATContents:contents threadSignature:[downloader identifier] nextIndex:[downloader nextIndex]];
	[downloader autorelease];
}

- (void)datOchiDownloadDidFail:(NSNotification *)notification
{
	CMRDATDownloader *downloader;
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSError *error;
    
	UTILAssertNotificationName(notification, CMRDATDownloaderDidDetectDatOchiNotification);
    
	downloader = [[notification object] retain];
//	UTILAssertKindOfClass(downloader, BSLoggedInDATDownloader);
    
	[nc removeObserver:self
				  name:CMRDATDownloaderDidDetectDatOchiNotification
				object:downloader];
	[nc removeObserver:self
				  name:ThreadTextDownloaderDidFinishLoadingNotification
				object:downloader];
    
    error = [[notification userInfo] objectForKey:@"Error"];
	NSAlert *alert = [NSAlert alertWithError:error];

    if ([self isRetrieving] || [self isNotShownThreadRetrieving]) {
        NSString *tmp = [error localizedRecoverySuggestion];
        NSString *newSuggestion = [tmp stringByAppendingString:NSLocalizedStringFromTable(@"DatOchiDownloadFailSuggestionRetrievingAppend", @"Downloader", @"")];
        [alert setInformativeText:newSuggestion];
    }
    
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(datOchiDatDownloadFailAlertDidEnd:returnCode:contextInfo:)
						contextInfo:downloader];
}

- (void)datOchiDatDownloadFailAlertDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	id	downloader;
	downloader = (id)contextInfo;
//	UTILAssertKindOfClass(downloader, BSLoggedInDATDownloader);
    
	switch (returnCode) {
        case NSAlertFirstButtonReturn:
        {
            if ([self isRetrieving] || [self isNotShownThreadRetrieving]) {
                [self restoreFromRetrieving:[downloader filePathToWrite] error:NULL];
            } else {
                [self closeWindowOfAlert:sheet downloaderFilePath:[downloader filePathToWrite]];
            }
        }
            break;
        case NSAlertSecondButtonReturn:
            [self downloadThreadUsingMaru:downloader fromAlert:sheet];
            break;
        default:
            UTILUnknownSwitchCase(returnCode);
            break;
	}

	[downloader autorelease];
}
@end
