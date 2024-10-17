//
//  BSLPSPreviewerItems.m
//  PreviewerSelector
//
//  Created by masakih on 10/09/12.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSPreviewerItems.h"
#import "BSLPSPreviewerItem.h"

#import "BSLinkPreviewSelector.h"
#import "BSLinkPreviewDelegating.h"


#define BSLINKPREVIEWSELECTOR_UNLOAD_SUPPORT 0

@interface NSObject(CMRTrashbox_Dummy)
+ (id)trash;
- (BOOL)performWithFiles:(NSArray *)filenames;
@end
#define CMRTrashbox NSClassFromString(@"CMRTrashbox")


#if BSLINKPREVIEWSELECTOR_UNLOAD_SUPPORT
@interface NSObject (BSLinkPreviewing_NewMethods)
- (BOOL)canUnload;
- (void)willUnload;
@end
#endif

@interface BSLPSPreviewerItems ()
- (void)loadPlugIns;
- (void)awakePreviewers;
@end

@implementation BSLPSPreviewerItems

- (id)init
{
	[super init];
	_previewerItems = [[NSMutableArray alloc] init];
	_deletedPreviewerItemIDs = [[NSMutableArray alloc] init];
	
	return self;
}

- (NSArray *)previewerItems
{
	return _previewerItems;
}

- (void)notifyItemsChangedWithUserInfo:(NSDictionary *)userInfo
{
	[[BSLinkPreviewSelector sharedInstance] rebuildPreviewers];
	[[NSNotificationCenter defaultCenter] postNotificationName:BSLinkPreviewSelectorDidChangeItemsNotification
														object:[BSLinkPreviewSelector sharedInstance]
													  userInfo:userInfo];
}

- (void)showAlertMessage:(NSString *)message informativeTextWithFormat:(NSString *)format, ...
{
	va_list ap;
	va_start(ap, format);
	NSString *text = [[[NSString alloc] initWithFormat:format arguments:ap] autorelease];
	va_end(ap);
	
	NSAlert *alert = [NSAlert alertWithMessageText:message
									 defaultButton:nil
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:@"%@", text];
	[alert runModal];
}

- (BOOL)validatePlugin:(NSURL *)fileURL
{
	NSBundle *plugInBundle = [NSBundle bundleWithURL:fileURL];
	NSString *fileDisplayName = [[NSFileManager defaultManager] displayNameAtPath:[fileURL path]];
	if(!plugInBundle) {
		NSLog(@"could not create bundle for %@", fileURL);
		[self showAlertMessage:@"Could not read Plugin" informativeTextWithFormat:@"'%@' is not plugin.", fileDisplayName];
		return NO;
	}
	
//	NSString *plugInName = [plugInBundle objectForInfoDictionaryKey:@"BSPreviewerDisplayName"];
//	if([plugInBundle isLoaded]) {
//		NSLog(@"################ PlugIn has loaded!! #############");
//	}
//	if(!plugInName) {
//		NSLog(@"bundle dose not have BSPreviewerDisplayName.");
//		[self showAlertMessage:@"Could not read Plugin" informativeTextWithFormat:@"'%@' is not plugin.", fileDisplayName];
//		return NO;
//	}
	NSString *bundleID = [plugInBundle bundleIdentifier];
	if([plugInBundle isLoaded]) {
		NSLog(@"################ PlugIn has loaded!! #############");
	}
	if(!bundleID) {
		NSLog(@"bundle dose not have bundle identifier.");
		[self showAlertMessage:@"Could not read Plugin" informativeTextWithFormat:@"'%@' is not plugin.", fileDisplayName];
		return NO;
	}
	if([_deletedPreviewerItemIDs containsObject:bundleID]) {
		[self showAlertMessage:PSLocalizedString(@"Selected plug-in has been deleted already.", @"")
	 informativeTextWithFormat:PSLocalizedString(@"You must restart BatyScaphe, if you want to install this plug-in.",@"")];
		return NO;
	}
	
	NSString *principalClassName = [plugInBundle objectForInfoDictionaryKey:@"NSPrincipalClass"];
	if([plugInBundle isLoaded]) {
		NSLog(@"################ PlugIn has loaded!! #############");
	}
	if(!principalClassName) {
		NSLog(@"bundle dose not have principal class name.");
		[self showAlertMessage:@"Could not read Plugin" informativeTextWithFormat:@"'%@' is not plugin.", fileDisplayName];
		return NO;
	}
	Class principalClass = NSClassFromString(principalClassName);
	if(principalClass) {
		NSLog(@"Principal class has already loaded.");
		[self showAlertMessage:@"Plug in is already loaded" informativeTextWithFormat:@"Plug in is already loaded."];
		return NO;
	}
	
	return YES;
}

- (BSLPSPreviewerItem *)loadPlugin:(NSURL *)fileURL
{
	NSBundle *plugInBundle = [NSBundle bundleWithURL:fileURL];
	NSString *fileDisplayName = [[NSFileManager defaultManager] displayNameAtPath:[fileURL path]];
	
	// loading plug-in
	Class principalClass = [plugInBundle principalClass];
	if(!principalClass) {
		NSLog(@"could not load principal class.");
		[self showAlertMessage:@"Plug in is broken" informativeTextWithFormat:@"%@ is broken.", fileDisplayName];
		return nil;
	}
	if(![principalClass conformsToProtocol:@protocol(BSImagePreviewerProtocol)]
	   && ![principalClass conformsToProtocol:@protocol(BSLinkPreviewing)]) {
		NSLog(@"Principal class do not comform to require protocol.");
		[self showAlertMessage:@"Plug in is broken" informativeTextWithFormat:@"%@ is broken.", fileDisplayName];
		return nil;
	}
	id plugin = [[[principalClass alloc] initWithPreferences:[[BSLinkPreviewSelector sharedInstance] preferences]] autorelease];
	if(!plugin) {
		NSLog(@"Principal class can not allocate or initialize.");
		[self showAlertMessage:@"Plug in is broken" informativeTextWithFormat:@"%@ is broken.", fileDisplayName];
		return nil;
	}
	
	BSLPSPreviewerItem *item = [[[BSLPSPreviewerItem alloc] initWithIdentifier:[plugInBundle bundleIdentifier]] autorelease];
	item.tryCheck = YES;
	item.displayInMenu = YES;
	item.previewer = plugin;
	item.path = [plugInBundle bundlePath];
	
	id v = [plugInBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	item.version = v ?: @"";
	
	v = [plugInBundle objectForInfoDictionaryKey:@"BSPreviewerDisplayName"];
	item.displayName = v ?: item.identifier;
	
	return item;
}

- (void)addItem:(BSLPSPreviewerItem *)item
{
	@synchronized(_previewerItems) {
		if([_previewerItems containsObject:item]) return;
		
		[self willChangeValueForKey:@"previewerItems"];
		[_previewerItems addObject:item];
		[self didChangeValueForKey:@"previewerItems"];
	}
	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
						  item.previewer, BSLinkPreviewSelectorChangedItemNotificationKey,
						  item.displayName, BSLinkPreviewSelectorChangedItemNameNotificationKey,
						  item.identifier, BSLinkPreviewSelectorChangedItemIdentifierNotificationKey,
						  [NSNumber numberWithInteger:BSLinkPreviewSelectorAddItemType], BSLinkPreviewSelectorItemChangeTypeNotificationKey,
						  nil];
	[self notifyItemsChangedWithUserInfo:info];
}
- (void)addItemFromBundle:(NSBundle *)plugin
{
	NSLog(@"%s is not implement", __PRETTY_FUNCTION__);
	[self notifyItemsChangedWithUserInfo:nil];
}
- (void)addItemFromURL:(NSURL *)fileURL
{
	if(![self validatePlugin:fileURL]) return;
	
	NSString *plugInDirectory = [[BSLinkPreviewSelector sharedInstance] plugInsDirectory];
	NSURL *plugInDirectoryURL = [NSURL fileURLWithPath:plugInDirectory];
	
	NSError *error = nil;
	NSURL *newURL = [plugInDirectoryURL URLByAppendingPathComponent:[fileURL lastPathComponent]];
	BOOL isOK = [[NSFileManager defaultManager] copyItemAtURL:fileURL
														toURL:newURL
														error:&error];
	if(!isOK) {
		NSLog(@"plugin could not copy to plug-in Directory");
		[NSApp presentError:error];
		return;
	}
	
	BSLPSPreviewerItem *item = [self loadPlugin:newURL];
	if(!item) {
		error = nil;
		if(![[NSFileManager defaultManager] removeItemAtURL:newURL error:&error]) {
			if(error) {
				NSLog(@"Could not remove broken plugin. %@", error);
			} else {
				NSLog(@"Could not remove broken plugin.");
			}
		}
		
		return;
	}
	
	[self addItem:item];
	
	if([item.previewer respondsToSelector:@selector(awakeByPreviewerSelector:)]) {
		[item.previewer performSelector:@selector(awakeByPreviewerSelector:)
							 withObject:[BSLinkPreviewSelector sharedInstance]];
	}
	
	NSLog(@"bundle %@ loaded.", item.displayName);
}

- (void)removeItem:(BSLPSPreviewerItem *)item
{
#if BSLINKPREVIEWSELECTOR_UNLOAD_SUPPORT
	[item retain];
#endif
	NSString *path = item.path;
	[_deletedPreviewerItemIDs addObject:[item identifier]];
	@synchronized(_previewerItems) {
		[self willChangeValueForKey:@"previewerItems"];
		[_previewerItems removeObject:item];
		[self didChangeValueForKey:@"previewerItems"];
	}
	[[CMRTrashbox trash] performWithFiles:[NSArray arrayWithObject:path]];
	
	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
						  item.previewer, BSLinkPreviewSelectorChangedItemNotificationKey,
						  item.displayName, BSLinkPreviewSelectorChangedItemNameNotificationKey,
						  item.identifier, BSLinkPreviewSelectorChangedItemIdentifierNotificationKey,
						  [NSNumber numberWithInteger:BSLinkPreviewSelectorRemoveItemType], BSLinkPreviewSelectorItemChangeTypeNotificationKey,
						  nil];
	[self notifyItemsChangedWithUserInfo:info];
	
#if BSLINKPREVIEWSELECTOR_UNLOAD_SUPPORT
	id previewer = item.previewer;
	if(![previewer respondsToSelector:@selector(canUnload)]) {
		[item release];
		return;
	}
	if(![previewer canUnload]) {
		[item release];
		return;
	}
	if([previewer respondsToSelector:@selector(willUnload)]) {
		[previewer willUnload];
	}
	NSBundle *plugInBundle = [NSBundle bundleWithIdentifier:item.identifier];
	[item release];
	[plugInBundle unload];
#endif
}
- (void)moveItem:(BSLPSPreviewerItem *)item toIndex:(NSUInteger)index
{
	@synchronized(_previewerItems) {
		NSUInteger fromIndex = [_previewerItems indexOfObject:item];
		
		[self willChangeValueForKey:@"previewerItems"];
		[_previewerItems insertObject:item atIndex:index];
		if(fromIndex > index) fromIndex++;
		[_previewerItems removeObjectAtIndex:fromIndex];
		[self didChangeValueForKey:@"previewerItems"];
	}
}
- (NSUInteger)itemCount
{
	return [self.previewerItems count];
}
- (BSLPSPreviewerItem *)itemAtIndex:(NSUInteger)index
{
	return [self.previewerItems objectAtIndex:index];
}

- (void)setPreference:(id)pref
{
	[self loadPlugIns];
	
	NSMutableArray *newItems = [NSMutableArray array];
	NSArray *restoredItems = nil;
	
	NSData *itemsData = [[[[BSLinkPreviewSelector sharedInstance] preferences] imagePreviewerPrefsDict] objectForKey:keyPrefPlugInsInfo];
	if(!itemsData) {
		[self awakePreviewers];
		return;
	} else {
		restoredItems = [NSKeyedUnarchiver unarchiveObjectWithData:itemsData];
	}
	
	// リストアされ且つロード済のプラグインを追加
	for(BSLPSPreviewerItem *item in restoredItems) {
		if([_previewerItems containsObject:item]) {
			[newItems addObject:item];
		}
	}
	
	// リストアされていないがロード済のプラグインを追加
	for(BSLPSPreviewerItem *item in _previewerItems) {
		if(![newItems containsObject:item]) {
			[newItems addObject:item];
		} else {
			NSInteger index = [newItems indexOfObject:item];
			BSLPSPreviewerItem *restoredItem = [newItems objectAtIndex:index];
			if(![restoredItem.version isEqualToString:item.version]) {
				[newItems replaceObjectAtIndex:index withObject:item];
			}
		}
	}
	
	[_previewerItems autorelease];
	_previewerItems = [newItems retain];
	[self awakePreviewers];
}

- (void)awakePreviewers
{
	for(BSLPSPreviewerItem *item in _previewerItems) {
		id previewer = [item previewer];
		if([previewer respondsToSelector:@selector(awakeByPreviewerSelector:)]) {
			[previewer performSelector:@selector(awakeByPreviewerSelector:)
							withObject:[BSLinkPreviewSelector sharedInstance]];
			continue;
		}
		if([previewer respondsToSelector:@selector(awakeByLinkPreviewSelector:)]) {
			[previewer performSelector:@selector(awakeByLinkPreviewSelector:)
							withObject:[BSLinkPreviewSelector sharedInstance]];
		}
	}
}

- (void)registPlugIn:(NSBundle *)pluginBundle
{
	if([pluginBundle isLoaded]) return;
	
	NSURL *fileURL = [pluginBundle bundleURL];
	if(![self validatePlugin:fileURL]) return;
	
	BSLPSPreviewerItem *item = [self loadPlugin:fileURL];
	if(!item) return;
	
	if(![_previewerItems containsObject:item]) {
		[_previewerItems addObject:item];
	}
}

BOOL isPreviewerselector(NSBundle *pluginBundle)
{
	NSString *bundleIdentifier = [pluginBundle bundleIdentifier];
	return [bundleIdentifier isEqualToString:@"com.masakih.previewerSelector"];
}
void removePreviewerSelector(NSString *previewerSelectorPath)
{
	NSAlert *alert = [NSAlert alertWithMessageText:PSLocalizedString(@"Remove PreviewerSelector plugin", @"")
									 defaultButton:@"OK"
								   alternateButton:nil
									   otherButton:nil
						 informativeTextWithFormat:PSLocalizedString(@"Remove previewerSelector information", @"")];
	[alert runModal];
	
	[[CMRTrashbox trash] performWithFiles:[NSArray arrayWithObject:previewerSelectorPath]];
}
- (void)loadDefaultPreviewer
{
	NSBundle *b = [NSBundle mainBundle];
	id pluginDirPath = [b builtInPlugInsPath];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSArray *files = [dfm contentsOfDirectoryAtPath:pluginDirPath error:NULL];
	
	for(NSString *file in files) {
		NSString *fullpath = [pluginDirPath stringByAppendingPathComponent:file];
		NSBundle *pluginBundle;
		
		pluginBundle = [NSBundle bundleWithPath:fullpath];
		if(!pluginBundle) return;
		
		if(isPreviewerselector(pluginBundle)) {
			removePreviewerSelector(fullpath);
			continue;
		}
		if(![[pluginBundle bundleIdentifier] isEqualToString:@"jp.tsawada2.bathyscaphe.ImagePreviewer"]) {
			continue;
		}
		
		[self registPlugIn:pluginBundle];
	}
}

- (void)loadPlugIns
{
	NSString *path = [[BSLinkPreviewSelector sharedInstance] plugInsDirectory];
	NSFileManager *dfm = [NSFileManager defaultManager];
	NSArray *files = [dfm contentsOfDirectoryAtPath:path error:NULL];
	
	[self loadDefaultPreviewer];
	
	for(NSString *file in files) {
		NSString *fullpath = [path stringByAppendingPathComponent:file];
		NSBundle *pluginBundle;
				
		pluginBundle = [NSBundle bundleWithPath:fullpath];
		if(!pluginBundle) continue;
		
		if(isPreviewerselector(pluginBundle)) {
			removePreviewerSelector(fullpath);
			continue;
		}
		
		[self registPlugIn:pluginBundle];
	}
}

@end
