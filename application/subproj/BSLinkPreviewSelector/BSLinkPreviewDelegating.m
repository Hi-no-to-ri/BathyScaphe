//
//  PSPreviewerInterface.m
//  PreviewerSelector
//
//  Created by masakih on 10/09/13.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "PSPreviewerInterface.h"
#import "BSLinkPreviewDelegating.h"
#import "BSLinkPreviewSelector.h"
#import "BSLPSPreviewerItem.h"


NSString *BSLinkPreviewSelectorDidChangeItemsNotification = @"BSLinkPreviewSelectorDidChangeItemsNotification";
NSString *BSLinkPreviewSelectorItemChangeTypeNotificationKey = @"BSLinkPreviewSelectorItemChangeTypeNotificationKey";
NSString *BSLinkPreviewSelectorChangedItemNameNotificationKey = @"BSLinkPreviewSelectorChangedItemNameNotificationKey";
NSString *BSLinkPreviewSelectorChangedItemNotificationKey = @"BSLinkPreviewSelectorChangedItemNotificationKey";
NSString *BSLinkPreviewSelectorChangedItemIdentifierNotificationKey = @"BSLinkPreviewSelectorChangedItemIdentifierNotificationKey";


@interface BSLinkPreviewSelector (BSLinkPreviewDelegating) <PSPreviewerInterface, BSLinkPreviewDelegating>
@end

@implementation BSLinkPreviewSelector (BSLinkPreviewDelegating)
static NSArray *previewerDisplayNames = nil;
static NSArray *previewerIdentifiers = nil;
static NSArray *previewers = nil;

static NSObject *mutex = nil;

- (id)mutex
{
	if(mutex) return mutex;
	
	mutex = [[NSObject alloc] init];
	return mutex;
}
- (void)buildArrays
{
	NSMutableArray *names = [NSMutableArray array];
	NSMutableArray *ids = [NSMutableArray array];
	NSMutableArray *pvs = [NSMutableArray array];
	
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		[names addObject:item.displayName];
		[ids addObject:item.identifier];
		[pvs addObject:item.previewer];
	}
	
	@synchronized([self mutex]) {
		previewerDisplayNames = [[NSArray arrayWithArray:names] retain];
		previewerIdentifiers = [[NSArray arrayWithArray:ids] retain];
		previewers = [[NSArray arrayWithArray:pvs] retain];
	}
}
- (void)rebuildPreviewers
{
	@synchronized([self mutex]) {
		[previewerDisplayNames release];
		previewerDisplayNames = nil;
		[previewerIdentifiers release];
		previewerIdentifiers = nil;
		[previewers release];
		previewers = nil;
	}
}
- (NSArray *)previewerDisplayNames
{
	if(previewerDisplayNames) return previewerDisplayNames;
	
	[self buildArrays];
	
	return previewerDisplayNames;
}

- (NSArray *)previewerIdentifires
{
	if(previewerIdentifiers) return previewerIdentifiers;
	
	[self buildArrays];
	
	return previewerIdentifiers;
}
- (BOOL)openURL:(NSURL *)url withPreviewer:(id)previewer
{
	if([previewer conformsToProtocol:@protocol(BSLinkPreviewing)]) {
		return [previewer previewLink:url];
	}
	
	return [previewer showImageWithURL:url];
}

- (NSArray *)filteredURLs:(NSArray *)urls validForPreviewer:(id)previewer
{
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[urls count]];
	
	for(NSURL *url in urls) {
		if([previewer validateLink:url]) {
			[result addObject:url];
		}
	}
	return result;
}
- (BOOL)openURLs:(NSArray *)url withPreviewer:(id)previewer
{
	if([previewer respondsToSelector:@selector(previewLinks:)]) {
		return [previewer previewLinks:[self filteredURLs:url validForPreviewer:previewer]];
	}
	if([previewer respondsToSelector:@selector(showImagesWithURLs:)]) {
		return [previewer showImagesWithURLs:[self filteredURLs:url validForPreviewer:previewer]];
	}
	return NO;
}

- (BOOL)openURL:(NSURL *)url inPreviewerByName:(NSString *)previewerName
{
	BOOL result = NO;
	
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		NSString *displayName = item.displayName;
		
		if([displayName isEqualToString:previewerName]) {
			id previewer = item.previewer;
			if([previewer validateLink:url]) {
				result =  [self openURL:url withPreviewer:previewer];;
			}
			return result;
		}
	}
	
	return NO;
}
- (BOOL)openURL:(NSURL *)url inPreviewerByIdentifier:(NSString *)target
{
	BOOL result = NO;
	
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		if([item.identifier isEqualToString:target]) {
			id previewer = item.previewer;
			if([previewer validateLink:url]) {
				result =  [self openURL:url withPreviewer:previewer];;
			}
			return result;
		}
	}
	
	return NO;
}

- (NSArray *)previewerItems
{
	return [NSArray arrayWithArray:[self loadedPlugInsInfo]];
}

// for direct controll previewers.
- (NSArray *)previewers
{
	if(previewers) return previewers;
	
	[self buildArrays];
	
	return previewers;
}
- (id <BSLinkPreviewing>)previewerByName:(NSString *)previewerName
{
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		if([item.displayName isEqualToString:previewerName]) {
			return item.previewer;
		}
	}
	
	return nil;
}
- (id <BSLinkPreviewing>)previewerByIdentifier:(NSString *)previewerIdentifier
{
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		if([item.identifier isEqualToString:previewerIdentifier]) {
			return item.previewer;
		}
	}
	
	return nil;
}
@end

@implementation NSObject (PSPreviewerInterface)
+ (id <BSLinkPreviewDelegating>)BSLinkPreviewSelector
{
	return [BSLinkPreviewSelector sharedInstance];
}
+ (id <PSPreviewerInterface>)PSPreviewerSelector
{
	return [BSLinkPreviewSelector sharedInstance];
}
@end
