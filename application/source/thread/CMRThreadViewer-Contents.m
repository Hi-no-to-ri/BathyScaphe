//
//  CMRThreadViewer-Contents.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/19.
//  Copyright 2005-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadViewer_p.h"
//#import "BSRelatedKeywordsCollector.h"
#import "CMRHistoryManager.h"

@implementation CMRThreadViewer(ThreadContents)
- (BOOL)shouldShowContents
{
	return YES;
}

- (BOOL)shouldSaveThreadDataAttributes
{
	return ([self shouldShowContents] && (![self isInvalidate]));
}

- (BOOL)shouldLoadWindowFrameUsingCache
{
	return YES;
}

- (BOOL)canGenarateContents
{
	return (![self isInvalidate]);
}

- (BOOL)checkCanGenarateContents
{
	if ([self canGenarateContents]) return YES;

	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	NSString *informativeText;

//#warning 64BIT: Check formatting arguments
// 2010-03-28 tsawada2 検証済
	informativeText = [NSString stringWithFormat:[self localizedString:APP_TVIEWER_INVALID_THREAD_MSG_FMT],
		([self title] ? [self title] : @""), ([self path] ? [self path] : @"")];

	[alert setAlertStyle:NSWarningAlertStyle];
	[alert setMessageText:[self localizedString:APP_TVIEWER_INVALID_THREAD_TITLE]];
	[alert setInformativeText:informativeText];
	[alert addButtonWithTitle:[self localizedString:APP_TVIEWER_DO_RELOAD_LABEL]];
	[alert addButtonWithTitle:[self localizedString:APP_TVIEWER_NOT_RELOAD_LABEL]];

	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(threadStatusInvalidateAlertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];	
	return NO;
}

- (void)threadStatusInvalidateAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	switch(returnCode){
	case NSAlertFirstButtonReturn:
		[self loadFromContentsOfFile:[self path]];
		break;
	default:
		break;
	}	
}

- (void)setThreadAttributes:(CMRThreadAttributes *)newAttrs
{
	id		tmp;

	tmp = [self threadAttributes];
	if (tmp == newAttrs) return;

	[self disposeThreadAttributes];
	[[self document] setThreadAttributes:newAttrs];
	[self registerThreadAttributes:newAttrs];
}

- (void)disposeThreadAttributes
{
	CMRThreadAttributes *oldAttrs = [self threadAttributes];
	if (!oldAttrs) return;

	[self threadWillClose];
}

- (void)registerThreadAttributes:(CMRThreadAttributes *)newAttrs
{
	if (!newAttrs) return;

	[self synchronizeAttributes];
}

- (void)addThreadTitleToHistory
{
	NSString *title_ = [self title];
	UTILAssertNotNil(title_);

	id identifier = [self threadIdentifier];
	UTILAssertNotNil(identifier);

	[[CMRHistoryManager defaultManager] addItemWithTitle:title_ type:CMRHistoryThreadEntryType object:identifier];
}
/*
#pragma mark Keywords Support (Starlight Breaker Additions)
- (void)collector:(BSRelatedKeywordsCollector *)aCollector didCollectKeywords:(NSArray *)keywordsDict
{
	[self setCachedKeywords:keywordsDict];
}

- (void)collector:(BSRelatedKeywordsCollector *)aCollector didFailWithError:(NSError *)error
{
	[self setCachedKeywords:[NSArray array]];
}

- (void)updateKeywordsCache
{
	if (![CMRPref isOnlineMode]) {
		return;
	}

	BSRelatedKeywordsCollector *collector = [[self document] keywordsCollector];
	if ([collector isInProgress]) {
		[collector abortCollecting];
	}
	[collector setThreadURL:[self threadURL]];
	[collector setDelegate:self];
	[collector startCollecting];
}*/
@end


@implementation CMRThreadViewer(ThreadAttributesNotification)
- (void)synchronizeAttributes
{
	[self window];
	[self synchronizeWindowTitleWithDocumentName];
}

- (void)synchronizeLayoutAttributes
{
	if ([self shouldLoadWindowFrameUsingCache]) {
		[self setWindowFrameUsingCache];
	}
}
@end
