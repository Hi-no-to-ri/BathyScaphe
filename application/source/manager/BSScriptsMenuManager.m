//
//  BSScriptsMenuManager.m
//  BachyScaphe
//
//  Created by Hori,Masaki on 05/05/29.
//  Copyright 2005 BathyScaphe Project. All rights reserved.
//	See http://sourceforge.jp/projects/bathyscaphe/
//  See the file LICENSE for copying permission.

#import "BSScriptsMenuManager.h"

#import "CMRMainMenuManager.h"

@implementation BSScriptsMenuManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (id)init
{
    if (self = [super init]) {
        if (floor(NSAppKitVersionNumber) > 1265) { // Yosemite
            [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScriptsMenuIcon:) name:@"" object:nil];
        }
    }
    return self;
}

+ (void) setupScriptsMenu
{
	NSString *scriptsDir = [[[CMRFileManager defaultManager] supportDirectoryWithName : @"Scripts"] filepath];
	NSMenuItem *scriptMenu = [[CMRMainMenuManager defaultManager] scriptsMenuItem];
	id submenu = [scriptMenu submenu];
//	NSImage *scriptImage;
	
	if (!submenu || ![submenu isKindOfClass : [BSScriptsMenu class]]) {
		NSLog(@"##### MENU IS NOT BSScriptsMenu class's instance! ####");
		return;
	}
	
	[submenu setDelegate : [self defaultManager]];
	[submenu setScriptsDirectoryPath : scriptsDir];
	
/*	if ((scriptImage = [NSImage imageNamed : @"ScriptsTemplate"])) {
		[scriptMenu setTitle : @""];
		[scriptMenu setImage : scriptImage];
	}*/
    [[CMRMainMenuManager defaultManager] updateScriptsMenuIcon];
	
	[[self defaultManager] buldScriptsMenu];
}

- (void) buldScriptsMenu
{	
	NSMenuItem *scriptMenu = [[CMRMainMenuManager defaultManager] scriptsMenuItem];
	id submenu = [scriptMenu submenu];
	
	if (submenu && [submenu isKindOfClass : [BSScriptsMenu class]]) {		
		[submenu synchronizeScriptsMenu];
	}
}

- (void)menuNeedsUpdate:(NSMenu*)menu
{
	if (![menu isKindOfClass : [BSScriptsMenu class]]) return;
	
	[self buldScriptsMenu];
}
@end

@implementation NSApplication(BSScriptsMenuManager)
- (IBAction) openScriptsDirectory : (id) sender
{
	NSString *scriptsDir = [[[CMRFileManager defaultManager] supportDirectoryWithName : @"Scripts"] filepath];
	
	[[NSWorkspace sharedWorkspace] openFile : scriptsDir];
}
@end

#pragma mark -
/**
NSMenuItem の tag に 1 が設定されている場合、管理下にないと判断する。
 **/
const NSInteger kNonManagementItemTag = 1;

@implementation BSScriptsMenu

// ディレクトリとメニューを同期させる。
// サブディレクトリであればサブメニューを作成し、再帰呼び出しする。
static void appendDirectoryIntoMenu(BSScriptsMenu *inMenu, NSString *dir)
{
	NSArray *items;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if (nil == inMenu) return;
	if (nil == dir) return;
	
//    items = [fm contentsOfDirectoryAtPath:dir error:NULL];
//	items = [fm directoryContentsAtPath : dir];
    items = [fm contentsOfDirectoryAtURL:[NSURL fileURLWithPath:dir] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
	
//	for (NSString *item in items) {
    for (NSURL *fileURL in items) {
//		NSString *path = [dir stringByAppendingPathComponent : item];
        NSString *path = [fileURL path];
		NSInteger index;
		BSScriptsMenuItem *menuItem;
		BSScriptsMenu *submenu;
		
		if (![fm fileExistsAtPath : path]) continue;
		
		index = [inMenu indexOfItemWithScriptFilePath : path];
		if (-1 == index) {
			menuItem = [inMenu addBSScriptMenuItemWithScriptFilePath : path];
			if (directoryMenuItemType == [menuItem type]) {
				submenu = [[[BSScriptsMenu alloc] initWithScriptsDirectoryPath : path] autorelease];
				[menuItem setSubmenu : submenu];
				appendDirectoryIntoMenu(submenu, path);
			}
		} else {
			menuItem = (BSScriptsMenuItem *)[inMenu itemAtIndex : index];
			if (directoryMenuItemType == [menuItem type]) {
				submenu = (id)[menuItem submenu];
				if ([submenu isKindOfClass : [BSScriptsMenu class]]) {
					appendDirectoryIntoMenu(submenu, path);
				}
			}
		}
	}
}

// 有効でないメニューアイテムを削除する。
// サブディレクトリも対象にするため再帰呼び出しされる。
static void removeDeletedOrModifiedMenuItem(BSScriptsMenu *inMenu)
{
	if (nil == inMenu) return;
	
	for (id item in [inMenu itemArray]) {
		if (kNonManagementItemTag != [item tag] 
			&& [item isKindOfClass : [BSScriptsMenuItem class]]
			&& ![item isValid]) {
			[inMenu removeItem : item];
			continue;
		}
		if ([item hasSubmenu]) {
			BSScriptsMenu *submenu = (id)[item submenu];
			if ([submenu isKindOfClass : [BSScriptsMenu class]]) {
				removeDeletedOrModifiedMenuItem((BSScriptsMenu *)submenu);
			}
		}
	}
}

// スクリプトメニューに command + option + number のショートカットをつける。
// サブメニューも対象にするため再帰呼び出しされる。
static void setKeyEquivalent(BSScriptsMenu *inMenu, NSInteger *nextKeyEquivalent)
{
	if (nil == inMenu) return;
	if (nil == nextKeyEquivalent) return;
	
	for (NSMenuItem *item in [inMenu itemArray]) {		
		if (kNonManagementItemTag == [item tag]) continue;
		if ([item isSeparatorItem]) continue;
		
		if ([item hasSubmenu]) {
			id submenu = [item submenu];
			if ([submenu isKindOfClass : [BSScriptsMenu class]]) {
				setKeyEquivalent((BSScriptsMenu *)submenu, nextKeyEquivalent);
			}
		} else if (*nextKeyEquivalent < 10) {
			[item setKeyEquivalent : [NSString stringWithFormat: @"%ld", (long)(*nextKeyEquivalent)++]];
			[item setKeyEquivalentModifierMask : NSAlternateKeyMask | NSCommandKeyMask];
		} else {
			[item setKeyEquivalent : @""];
		}
	}
}

- (id) initWithScriptsDirectoryPath : (NSString *) path
{
	self = [super init];
	if (self) {
		[self setScriptsDirectoryPath : path];
		
		if (nil == [self scriptDirectoryPath]) {
			[self release];
			return nil;
		}
	}
	
	return self;
}

- (void) dealloc
{
	[scriptsDirectory release];
	
	[super dealloc];
}

- (void) setScriptsDirectoryPath : (NSString *) path
{
	BOOL isDirectory;
	
	if (![[NSFileManager defaultManager] fileExistsAtPath : path
											  isDirectory : &isDirectory]
		|| !isDirectory) {
		return;
	}
	
	scriptsDirectory = [path copy];
}

- (NSString *)scriptDirectoryPath
{
	if (scriptsDirectory) {
		return [NSString stringWithString : scriptsDirectory];
	}
	
	return nil;
}

- (void) synchronizeScriptsMenu
{
	NSInteger nextKeyEquivalentNumber = 0;
	
	removeDeletedOrModifiedMenuItem(self);
	appendDirectoryIntoMenu(self, scriptsDirectory);
	setKeyEquivalent(self, &nextKeyEquivalentNumber);
}

- (BSScriptsMenuItem *) addBSScriptMenuItemWithScriptFilePath : (NSString *) path
{
	BSScriptsMenuItem *newItem;
	NSString *lastPath = [path lastPathComponent];
	NSInteger i, itemsCount;
	id item;
	
	newItem = [[[BSScriptsMenuItem alloc] initWithScriptFilePath : path] autorelease];
	
	if (!newItem) return nil;
	
	itemsCount = [self numberOfItems];
	for (i = 0; i < itemsCount; i++ ) {
		NSString *filename;
		
		item = [self itemAtIndex : i];
		if (![item isKindOfClass : [BSScriptsMenuItem class]]) continue;
		
		filename = [item realFileName];
		if (NSOrderedDescending == [filename compare : lastPath]) {
			break;
		}
	}
	
	[self insertItem : newItem atIndex : i];
	
	return newItem;
}

- (NSInteger) indexOfItemWithScriptFilePath : (NSString *) path
{
	NSInteger i;
	NSInteger itemsCount = [self numberOfItems];
	id item;
	
	for (i = 0; i < itemsCount; i++) {
		item = [self itemAtIndex : i];
		if ([item isKindOfClass : [BSScriptsMenuItem class]] && [path isEqualTo : [item scriptsPath]]) {
			return i;
		}
	}
	
	return -1;
}
@end

@implementation BSScriptsMenuItem

// アプリケーション化されたアップルスクリプトに対応。
static inline BOOL isRunnableAppleScriptFile(NSString *path)
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDirectory;
	
	if( ![fm fileExistsAtPath:path isDirectory:&isDirectory] ) return NO;
	
	if( !isDirectory ) {
		NSDictionary *fileAttr;
		OSType creatorType, fileType;
		
        fileAttr = [fm attributesOfItemAtPath:path error:NULL];
//		fileAttr = [fm fileAttributesAtPath:path traverseLink:YES];
		
		fileType = [fileAttr fileHFSTypeCode];
		if( fileType != 'APPL' ) return NO;
		
		creatorType = [fileAttr fileHFSCreatorCode];
		if( creatorType != 'aplt' ) return NO;
		
	} else {
		NSBundle *b = [NSBundle bundleWithPath:path];
		id packageType, sig;
		
		if( !b ) return NO;
		
		packageType = [b objectForInfoDictionaryKey:@"CFBundlePackageType"];
		if( ![packageType isEqual:@"APPL"] ) return NO;
		
		sig = [b objectForInfoDictionaryKey:@"CFBundleSignature"];
		if( ![sig isEqualTo:@"aplt"] ) return NO;
	}
	
	return YES;
		
}

static inline BOOL isAppleScriptFile(NSString *path)
{
	NSString *extension = [path pathExtension];
	NSString *filetype;
	
	if ([@"scpt" isEqualTo : extension]) {
		return YES;
	} else if ([@"applescript" isEqualTo : extension]) {
		return YES;
	} else if ([@"scptd" isEqualTo : extension]) {
		return YES;
	}
	
	filetype = NSHFSTypeOfFile(path);
	if ([@"'osas'" isEqualTo : filetype]) {
		return YES;
	}
	
	if (isRunnableAppleScriptFile(path)) {
		return YES;
	}
	
	return NO;
}

// 入力イメージを 16*16bit に変換し、それを返す。
// 入力イメージ自体を変換する。
static inline NSImage *imageForMenuIcon(NSImage *image)
{
	NSSize menuIconSize = NSMakeSize(16,16);
	
	if (!NSEqualSizes(menuIconSize,[image size]) ) {
		[image setScalesWhenResized : YES];
		[image setSize : menuIconSize];
	}
	
	return image;
}

// extension と数字の接頭辞を削除する。
static inline NSString *titleForScriptsMenuFromPath(NSString *path)
{
	NSString *temp;
	NSUInteger length;
	NSRange newRange;
	NSCharacterSet *decSet;
	NSUInteger i;
	
	if (!path) return nil;
	
	temp = [[path lastPathComponent] stringByDeletingPathExtension];
	if (0 == (length = [temp length])) return @"";
	
	decSet = [NSCharacterSet decimalDigitCharacterSet];
	for (i = 0; i < length; i++) {
		if (![decSet characterIsMember : [temp characterAtIndex : i]])
			break;
	}
	if (0 == i) return temp;
	
	newRange.location = i;
	newRange.length = length - i;
	
	return [temp substringWithRange : newRange];
}

+ (BOOL) isDirectory : (NSString *) path
{
	BOOL isDirectory;
	
	[[NSFileManager defaultManager] fileExistsAtPath : path isDirectory : &isDirectory];
	
	return isDirectory;
}

- (id) initWithScriptFilePath : (NSString *) path
{
	self = [super initWithTitle : titleForScriptsMenuFromPath(path)
						 action : @selector(handleScriptMenuItem:)
				  keyEquivalent : @""];
	
	if (self) {
		appleScriptPath = [path copy];
		
		if (invalidMenuItemType == [self type]) {
			[self release];
			return nil;
		}
		
		[self setImage : imageForMenuIcon([[NSWorkspace sharedWorkspace] iconForFile : path])]; 
		
		// バンドルでない普通のディレクトリなら
		if (directoryMenuItemType == [self type]) {
			[self setAction : nil];
		} else {
			[self setTarget : self];
		}
	}
	
	return self;
}

- (void) dealloc
{
	[appleScriptPath release];
	
	[super dealloc];
}

- (NSString *) scriptsPath
{
	return appleScriptPath;
}

- (NSString *) realFileName
{
	return [appleScriptPath lastPathComponent];
}

- (BSScriptMenuItemType) type
{
	if (unknownMenuItemType == type) {
		if (isRunnableAppleScriptFile(appleScriptPath)) {
			type = runnablescriptMenuItemType;
		} else if (isAppleScriptFile(appleScriptPath)) {
			type = scriptMenuItemType;
		} else if ([[self class] isDirectory : appleScriptPath]) {
			type = directoryMenuItemType;
		} else {
			type = invalidMenuItemType;
		}
	}
	
	return type;
}

- (void) excute
{
	NSAppleScript *as;
	NSURL *url;
	NSDictionary *error = nil;
	
	if (runnablescriptMenuItemType == [self type]) {
		[[NSWorkspace sharedWorkspace] openFile : appleScriptPath];
		return;
	}
	
	url = [[[NSURL alloc] initWithScheme : @"file"
									host : @""
									path : appleScriptPath] autorelease];
	if (!url) {
		type = invalidMenuItemType;
		return;
	}
	
	as = [[[NSAppleScript alloc] initWithContentsOfURL : url
												error : &error] autorelease];
	if (error) {
		type = invalidMenuItemType;
		return;
		//			NSLog(@"ERROR -> %@", error);
	}
	[as executeAndReturnError : &error];
	if (error) {
		//			NSLog(@"ERROR -> %@", error);
	}
}

- (BOOL) isValid
{
	if (![[NSFileManager defaultManager] fileExistsAtPath : appleScriptPath]) {
		type = invalidMenuItemType;
		return NO;
	}
	
	return (invalidMenuItemType == [self type]) ? NO : YES;
}

// 現在の innerLinkRangeCharacters.txt と同じものから NSCharacterSet を作成して。
// title の一文字目と比べる方が丁寧です。 これは手抜き。 by masakih
- (BOOL)isSeparatorItem
{
	if ( [@"-" isEqualTo : [self title]] ) {
		return YES;
	}
	
	return NO;
}

- (IBAction) handleScriptMenuItem : (id) item
{
	if ([item isKindOfClass : [BSScriptsMenuItem class]]) {
		[item excute];
	}
}

@end
