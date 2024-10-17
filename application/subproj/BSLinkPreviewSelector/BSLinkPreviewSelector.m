//
//  BSLinkPreviewSelector.m
//  PreviewerSelector
//
//  Created by masakih on 06/05/07.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLinkPreviewSelector.h"
//#import "BSLPSPreference.h"
#import <objc/objc-class.h>

#import "BSLPSPreviewerItem.h"
#import "BSLPSPreviewerItems.h"
//#import "BSLPSPreferenceViewController.h"
#import "BSLPSSImplePreferenceViewController.h"

#import "AppDefaults.h"


#import "BSLPSPreferenceWindow.h"



#pragma mark -
#pragma mark CMRFileManager Dummy
@interface NSObject(CMRFileManagerDummy)
+ (id)defaultManager;
- (id)supportDirectoryWithName:(NSString *)dirName;
- (NSString *)filepath;
@end
#define CMRFileManager NSClassFromString(@"CMRFileManager")

@interface NSObject (CMRThreadViewDummy)
- (NSArray *)previewlinksArrayForRange:(NSRange)range;
@end

#pragma mark -
#pragma mark## NSDictionary Keys ##
static NSString *keyPlugInObject = @"PlugInObjectKey";
static NSString *keyActionLink = @"ActionLinkKey";

static NSString *keyPrefPlugInsDir = AppIdentifierString @"." @"PlugInsDir";

NSString *keyPrefPlugInsInfo = AppIdentifierString @"." @"PlugInsInfo";


#pragma mark## Static Variable ##
static IMP orignalIMP;

@interface BSLinkPreviewSelector ()
- (NSMenuItem *)previewMenuItemForLink:(id)link
								 title:(NSString *)title
							 validator:(BOOL (^)(id previewItem, id link))validator;
@end

@implementation BSLinkPreviewSelector(MethodExchange)
- (NSMenuItem *)replacementCommandItemWithLink:(id)link command:(Class)class title:(NSString *)title
{
	Class class_ = NSClassFromString(@"SGPreviewLinkCommand");
	NSMenuItem *res;
	
	if(class_ == class) {
		id obj = [BSLinkPreviewSelector sharedInstance];
		res = [obj previewMenuItemForLink:[NSURL URLWithString:link]
									title:title
								validator:^(id previewer, id link) {
									return [previewer validateLink:link];
								}];
		if(!res ) {
			res = [[[NSMenuItem alloc] initWithTitle:title action:Nil keyEquivalent:@""] autorelease];
		}
	} else {
		res = orignalIMP(self, _cmd, link, class, title);
	}
	
	return res;
}
@end
id multiPreviewMenuItemForRange(id self, SEL _cmd, NSRange range)
{
	BSLinkPreviewSelector *linkPreviewSelector = [BSLinkPreviewSelector sharedInstance];
	
	NSArray *links = [self previewlinksArrayForRange:range];
	if (!links) {
		return nil;
	}
	
	// count valid link.
	NSArray *items = linkPreviewSelector.loadedPlugInsInfo;
	NSMutableArray *validURLs = [NSMutableArray array];
	for(NSURL *link in links) {
		for(BSLPSPreviewerItem *item in items) {
			if(!item.displayInMenu) continue;
			if([item.previewer validateLink:link]) {
				[validURLs addObject:link];
				break;
			}
		}
	}
	// hide menu item if there is no valid link.
	if([validURLs count] == 0) return nil;
	
	NSString *title = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Preview %lu Links", @"HTMLView", @""), (unsigned long)[validURLs count]];
	NSMenuItem *newItem = [linkPreviewSelector previewMenuItemForLink:links
																title:title
															validator:^(id previewer, id link) {
																for(id url in link) {
																	if([previewer validateLink:url]) return YES;
																}
																return NO;
															}];
	
	return newItem;
}

static void psSwapMethod()
{
	Class target = NSClassFromString(@"SGHTMLView");
	Method method;
	
    method = class_getInstanceMethod(target, @selector(commandItemWithLink:command:title:));
	orignalIMP = class_getMethodImplementation(target, @selector(commandItemWithLink:command:title:));
	if(method) {		
		Method newMethod = class_getInstanceMethod([BSLinkPreviewSelector class], @selector(replacementCommandItemWithLink:command:title:));
		method_exchangeImplementations(method, newMethod);
	}
	
	target = NSClassFromString(@"CMRThreadView");
	method = class_getInstanceMethod(target, @selector(previewLinksMenuItemForRange:));
	if(method) {
		method_setImplementation(method, (IMP)multiPreviewMenuItemForRange);
	}
}

#pragma mark-
#pragma mark## Class variables ##
static BSLinkPreviewSelector *sSharedInstance;

#pragma mark-

@interface BSLinkPreviewSelector (PSPreviewerInterfaceMethods)
- (BOOL)openURL:(NSURL *)url withPreviewer:(id)previewer;
- (BOOL)openURLs:(NSArray *)url withPreviewer:(id)previewer;
@end

@interface BSLinkPreviewSelector()
@property (retain, nonatomic) BSLPSPreferenceWindow *preferenceWindow;

@property (retain, nonatomic, readonly) BSLPSPreviewerItems *items;
@end

#pragma mark-
@implementation BSLinkPreviewSelector
@synthesize preferenceWindow = _preferenceWindow;

+ (void)initialize
{
	static BOOL isFirst = YES;
	if(isFirst) {
		isFirst = NO;
		psSwapMethod();
	}
}

+ (BSLinkPreviewSelector *)sharedInstance
{
	if (sSharedInstance == nil) {
		sSharedInstance = [[super allocWithZone:NULL] init];
	}
	return sSharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [[self sharedInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (NSUInteger)retainCount
{
	return NSUIntegerMax;  //denotes an object that cannot be released
}

- (oneway void)release
{
	//do nothing
}

- (id)autorelease
{
	return self;
}



- (void)addItem:(BSLPSPreviewerItem *)item
{
	[self.items addItem:item];
	[self savePlugInsInfo];
}
- (void)addItemFromBundle:(NSBundle *)plugin
{
	[self.items addItemFromBundle:plugin];
	[self savePlugInsInfo];
}
- (void)addItemFromURL:(NSURL *)url
{
	[self.items addItemFromURL:url];
	[self savePlugInsInfo];
}
- (void)removeItem:(BSLPSPreviewerItem *)item
{
	[self.items removeItem:item];
	[self savePlugInsInfo];
}
- (void)moveItem:(BSLPSPreviewerItem *)item toIndex:(NSUInteger)index
{
	[self.items moveItem:item toIndex:index];
	[self savePlugInsInfo];
}
- (NSUInteger)itemCount
{
	return [self.items itemCount];
}
- (BSLPSPreviewerItem *)itemAtIndex:(NSUInteger)index
{
	return [self.items itemAtIndex:index];
}


- (NSArray *)loadedPlugInsInfo
{
	return [self.items previewerItems];
}

- (void)savePlugInsInfo
{
	NSData *itemsData = [NSKeyedArchiver archivedDataWithRootObject:[self loadedPlugInsInfo]];
	
	[self setPreference:itemsData forKey:keyPrefPlugInsInfo];
}

- (NSMenuItem *)previewMenuItemForLink:(id)link
								 title:(NSString *)title
							 validator:(BOOL (^)(id previewItem, id link))validator
{
	id res = [[[NSMenuItem alloc] initWithTitle:title action:Nil keyEquivalent:@""] autorelease];
	
	NSArray *pluginItems = [self loadedPlugInsInfo];	
	NSArray *showInMenuItems = [pluginItems filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"displayInMenu = YES"]];
	
	// メニューに表示するプラグインが一つのときはサブメニューを持たない
	if([showInMenuItems count] == 0) {
		// メニューに表示するプラグインがない時は非表示
		return nil;
	} else if([showInMenuItems count] == 1) {
		BSLPSPreviewerItem *pluginItem = [showInMenuItems objectAtIndex:0];
		if(validator(pluginItem.previewer, link)) {
			[res setAction:@selector(performLinkAction:)];
			[res setTarget:self];
			[res setRepresentedObject:
			 [NSDictionary dictionaryWithObjectsAndKeys:pluginItem, keyPlugInObject, link, keyActionLink, nil]];
		}
	} else {
		id submenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
		[res setSubmenu:submenu];
		for(BSLPSPreviewerItem *item in showInMenuItems) {			
			NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:item.displayName
															   action:@selector(performLinkAction:)
														keyEquivalent:@""] autorelease];
			
			if(validator(item.previewer, link)) {
				[menuItem setTarget:self];
				[menuItem setRepresentedObject:
				 [NSDictionary dictionaryWithObjectsAndKeys:item, keyPlugInObject, link, keyActionLink, nil]];
			} else {
				[menuItem setEnabled:NO];
			}
			
			[submenu addItem:menuItem];
		}
	}
	
	return res;
}

#pragma mark## Actions ##
- (void)performLinkAction:(id)sender
{
	if(![sender respondsToSelector:@selector(representedObject)]) return;
	
	id rep = [sender representedObject];
	if(![rep isKindOfClass:[NSDictionary class]]) return;
	
	id obj = [[rep objectForKey:keyPlugInObject] previewer];
	id link = [rep objectForKey:keyActionLink];
	
	if([link isKindOfClass:[NSArray class]]) {
		[self openURLs:link withPreviewer:obj];
	} else if([link isKindOfClass:[NSURL class]]) {
		[self openURL:link withPreviewer:obj];
	}
}

#pragma mark## Key Value Coding ##
- (BSLPSPreviewerItems *)items
{
	if(_items) return _items;
	
	_items = [[BSLPSPreviewerItems alloc] init];
	[_items setPreference:[self preferences]];
	
	return _items;
}
- (void)setPreference:(id)pref forKey:(id)key
{
	[[[self preferences] imagePreviewerPrefsDict] setObject:pref forKey:key];
}
- (id)preferenceForKey:(id)key
{
	return [[[self preferences] imagePreviewerPrefsDict] objectForKey:key];
}

- (NSString *)plugInsDirectory
{
	NSString *path;
	
	path = [self preferenceForKey:keyPrefPlugInsDir];
	
	if(!path) {
		id fm = [CMRFileManager defaultManager];
		id pathRef = [fm supportDirectoryWithName:@"PlugIns"];
		path = [pathRef filepath];
	}
	
	return path;
}
- (NSView *)preferenceView
{
	if(prefViewController) {
		return prefViewController.view;
	}
#if 0
	prefViewController = [[BSLPSPreferenceViewController alloc] init];
	[prefViewController setPlugInList:[self loadedPlugInsInfo]];
#else
	prefViewController = [[BSLPSSImplePreferenceViewController alloc] init];
#endif
	return prefViewController.view;
}

- (NSString *)identifierString
{
	NSString *myVersionStringFormat = PSLocalizedString(@"%@ (%@/%@)\nInstalled Plugins:\n    %@", @"");
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	NSString *myID = [myBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	NSString *myShortVersion = [myBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	NSString *myBundleVersion = [myBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	
	NSString *pluginVersionStringFormat = @"%@ (%@/%@)";
	NSMutableArray *pluginNames = [NSMutableArray array];
	NSArray *loaded = [self loadedPlugInsInfo];
	for(BSLPSPreviewerItem *item in loaded) {
		NSString *pluginName = nil;
		if([item.previewer respondsToSelector:@selector(identifierString)]) {
			pluginName = [item.previewer identifierString];
		}
		if(!pluginName) {
			NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:item.identifier];
			NSString *pluginBundleVersion = [pluginBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
			pluginName = [NSString stringWithFormat:pluginVersionStringFormat, item.identifier, item.version, pluginBundleVersion];
		}
		[pluginNames addObject:pluginName];
	}
	NSString *pluginNamesString = [pluginNames componentsJoinedByString:PSLocalizedString(@"\n    ", @"")];
	NSString *versionString = [NSString stringWithFormat:myVersionStringFormat, myID, myShortVersion, myBundleVersion, pluginNamesString];
	return versionString;
}

#pragma mark-
// Designated Initializer
- (id)initWithPreferences:(AppDefaults *)prefs
{
	self = [self init];
	[self setPreferences:prefs];
	
	// load previewers
	if([prefs preloadPreviewers]) {
		[self itemCount];
	}
	
	return self;
}
	// Accessor
- (AppDefaults *)preferences
{
	return _preferences;
}
- (void)setPreferences:(AppDefaults *)aPreferences
{
	id temp = _preferences;
	_preferences = [aPreferences retain];
	[temp release];
}
	// Action
- (BOOL)showImageWithURL:(NSURL *)imageURL
{
	BOOL result = NO;
	
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		if(!item.isTryCheck) continue;
		
		id previewer = item.previewer;
		if([previewer validateLink:imageURL]) {
			result =  [self openURL:imageURL withPreviewer:previewer];
		}
		if(result) return YES;
	}
	
	return NO;
}
- (BOOL)previewLink:(NSURL *)url
{
	return [self showImageWithURL:url];
}
- (BOOL)validateLink:(NSURL *)anURL
{
	if([[anURL scheme] isEqualToString:@"cmonar"]) return NO;
	
	return YES;
}
- (IBAction)resetPreviewer:(id)sender
{
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		id previewer = item.previewer;
		if([previewer respondsToSelector:_cmd]) {
			[previewer performSelector:_cmd withObject:sender];
		}
	}
}

- (BSLPSPreferenceWindow *)preferenceWindow
{
	if(_preferenceWindow) return _preferenceWindow;
	_preferenceWindow = [[BSLPSPreferenceWindow alloc] init];
	[_preferenceWindow setItems:[self loadedPlugInsInfo]];
	return _preferenceWindow;
}
- (IBAction) togglePreviewPanel : (id) sender
{
//	[self.preferenceWindow showWindow:nil];
    for (BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
        if ([item hasPreviewPanel]) {
            [item.previewer performSelector:_cmd withObject:sender];
        }
    }
}

- (IBAction)showPreviewerPreferences:(id)sender
{
    [self.preferenceWindow showWindow:nil];
}

- (BOOL)previewLinks:(NSArray *)urls
{
	return [self showImagesWithURLs:urls];
}
- (BOOL)showImagesWithURLs:(NSArray *)urls
{
	BOOL result = NO;
	
	for(BSLPSPreviewerItem *item in [self loadedPlugInsInfo]) {
		result = [self openURLs:urls withPreviewer:item.previewer];
		if(result) return YES;
	}
	
	return NO;
}

@end
