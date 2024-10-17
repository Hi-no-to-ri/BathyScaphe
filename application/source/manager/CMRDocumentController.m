//
//  CMRDocumentController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/19.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRDocumentController.h"
#import "CMRThreadDocument.h"
#import "CMRThreadViewer_p.h"
#import "Browser.h"
#import "CMRReplyMessenger.h"

#import "CMRBrowser_p.h"
#import "CMRReplyController_p.h"

@implementation CMRDocumentController
- (void)noteNewRecentDocumentURL:(NSURL *)aURL
{
	// ブロックして、アップルメニューの「最近使った項目」への追加を抑制する
}

- (NSUInteger)maximumRecentDocumentCount
{
	// BathyScaphe の「ファイル」＞「最近使った書類」サブメニューの生成を抑制する
	return 0;
}

- (NSDocument *)documentAlreadyOpenForURL:(NSURL *)absoluteDocumentURL
{
	NSString		*fileName;
	NSString		*documentPath;

	if (![absoluteDocumentURL isFileURL]) return nil;
	documentPath = [absoluteDocumentURL path];

    for (NSDocument *document in [self documents]) {
		fileName = [[document fileURL] path];
		if (!fileName && [document isKindOfClass:[Browser class]]) {
			fileName = [[(Browser *)document threadAttributes] path];
		}
		if (fileName && [fileName isEqualToString:documentPath]) {
			return document;
		}
	}
	return nil;
}

- (NSArray *)documentsForBoardName:(NSString *)boardName
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSDocument *document in [self documents]) {
        NSString *docBoardName = nil;
        if ([document isKindOfClass:[CMRAbstructThreadDocument class]]) {
            docBoardName = [[(CMRAbstructThreadDocument *)document threadAttributes] boardName];
        } else if ([document isKindOfClass:[CMRReplyMessenger class]]) {
            docBoardName = [(CMRReplyMessenger *)document boardName];
        } else {
            continue;
        }
        
        if ([docBoardName isEqualToString:boardName]) {
            [array addObject:document];
        }
    }
    
    return ([array count] > 0) ? array : nil;
}

- (BOOL)safelyCloseAllDocumentsForBoardName:(NSString *)boardName
{
    NSArray *documentsForBoardName = [self documentsForBoardName:boardName];
    
    if (!documentsForBoardName) {
        // Nothing to do
        return YES;
    }

    for (NSDocument *document in documentsForBoardName) {
        NSArray *windowControllers = [document windowControllers];
        if (!windowControllers || ([windowControllers count] == 0)) {
            continue;
        }
        
        id windowController = [windowControllers lastObject];
        if ([windowController isKindOfClass:[CMRBrowser class]]) {
            NSString *threadPath = [[(Browser *)document threadAttributes] path];
            if (threadPath) {
                [(CMRBrowser *)windowController cleanUpItemsToBeRemoved:[NSArray arrayWithObject:threadPath]];
            }
        } else if ([windowController isKindOfClass:[CMRThreadViewer class]]) {
            [[(CMRThreadViewer *)windowController window] performClose:self];
        } else if ([windowController isKindOfClass:[CMRReplyController class]]) {
            if ([document isDocumentEdited]) {
                [document saveDocument:self];
            };
            [[(CMRReplyController *)windowController window] performClose:self];
        }
    }
    return YES;
}

- (BOOL)showDocumentWithContentOfFile:(NSURL *)fileURL boardInfo:(NSDictionary *)info
{
	NSDocument *document;
	CMRThreadViewer *viewer;
    NSString *filepath;

	if (!fileURL || !info) {
        return NO;
	}

    filepath = [fileURL path];
	document = [self documentAlreadyOpenForURL:fileURL];
	if (document) {
        if ([document isKindOfClass:[Browser class]] && ![(Browser *)document showsThreadDocument]) {
            id wc = [[document windowControllers] objectAtIndex:0];
            [wc cleanUpItemsToBeRemoved:[NSArray arrayWithObject:filepath]];
            document = nil;
        } else {
            [document showWindows];
            return YES;
        }
	}

    NSMutableDictionary *tmp = nil;

	viewer = [[CMRThreadViewer alloc] init];
	document = [[CMRThreadDocument alloc] initWithThreadViewer:viewer];
    [document setFileURL:fileURL];

    if ([info objectForKey:@"candidateHost"]) {
        [(CMRThreadDocument *)document setCandidateHost:[info objectForKey:@"candidateHost"]];
        tmp = [[info mutableCopy] autorelease];
        [tmp removeObjectForKey:@"candidateHost"];
    }
	[self addDocument:document];
	[viewer setThreadContentWithFilePath:filepath boardInfo:(tmp ?: info)];
	[viewer release];
	[document release];
	
	return YES;
}

- (BOOL)showDocumentWithHistoryItem:(CMRThreadSignature *)historyItem
{
	NSDictionary	*info_;
	NSString		*path_ = [historyItem threadDocumentPath];
	
	info_ = [NSDictionary dictionaryWithObjectsAndKeys:[historyItem boardName], ThreadPlistBoardNameKey,
													   [historyItem identifier], ThreadPlistIdentifierKey, NULL];
	return [self showDocumentWithContentOfFile:[NSURL fileURLWithPath:path_] boardInfo:info_];	
}

#pragma mark Window Restoration (Lion)
// See NSWindowRestration.h, CMRThreadDocument.m, Browser.m, and CMRBrowser-Delegate.m
+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    NSString *className = [state decodeObjectForKey:@"BS_DocumentClass"];
    if (className && [className isEqualToString:@"CMRThreadDocument"]) {
        id object = [state decodeObjectForKey:@"BS_ThreadSignature"];
        if (object) {
            NSString *path = [(CMRThreadSignature *)object threadDocumentPath];
            NSDictionary *boardInfo = [NSDictionary dictionaryWithObjectsAndKeys:[(CMRThreadSignature *)object boardName], ThreadPlistBoardNameKey,
                         [(CMRThreadSignature *)object identifier], ThreadPlistIdentifierKey,
                         NULL];
            [[self sharedDocumentController] showDocumentWithContentOfFile:[NSURL fileURLWithPath:path] boardInfo:boardInfo];
        }
    }
    [super restoreWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}
@end
