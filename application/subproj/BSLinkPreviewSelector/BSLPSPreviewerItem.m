//
//  PSPreviewerItem.m
//  PreviewerSelector
//
//  Created by masakih on 09/02/14.
//  Copyright 2012, 2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSPreviewerItem.h"


static NSString *const BSLPSIdentifierKey = @"BSLPSIdentifierKey";
static NSString *const BSLPSDisplayNameKey = @"BSLPSDisplayNameKey";
static NSString *const BSLPSPathKey = @"BSLPSPathKey";
static NSString *const BSLPSVersionKey = @"BSLPSVersionKey";
static NSString *const BSLPSTryCheckKey = @"BSLPSTryCheckKey";
static NSString *const BSLPSDisplayInMenuKey = @"BSLPSDisplayInMenuKey";

static NSMutableDictionary *previewerInfo = nil;

@implementation BSLPSPreviewerItem

@synthesize identifier = _identifier;
@synthesize previewer = _previewer;
@synthesize displayName = _displayName, path = _path, version = _version;
@synthesize tryCheck = _tryCheck, displayInMenu = _displayInMenu;

+ (void)initialize
{
	static BOOL isFirst = YES;
	if(isFirst) {
		isFirst = NO;
		
		previewerInfo = [[NSMutableDictionary alloc] init];
	}
}

- (id)initWithIdentifier:(NSString *)inIdentifier
{
	if(self = [super init]) {
		_identifier = [inIdentifier copy];
	}
	
	return self;
}

- (void)dealloc
{
	[_previewer release];
	[_displayName release];
	[_path release];
	[_version release];
	
	[_identifier release];
	
	[super dealloc];
}

- (void)setPreviewer:(id)newPreviewer
{
	if(_previewer == newPreviewer) return;
	
	[_previewer autorelease];
	
	if(!newPreviewer) return;
	
	_previewer = [newPreviewer retain];
	[previewerInfo setObject:_previewer forKey:_identifier];
}

- (NSString *)copyright
{
	NSBundle *bundle = [NSBundle bundleForClass:[self.previewer class]];
	return [bundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"];
}
- (BOOL)hasPreviewPanel
{
	return [self.previewer respondsToSelector:@selector(togglePreviewPanel:)];
}
- (BOOL)hasPreferencePanel
{
	return [self.previewer respondsToSelector:@selector(showPreviewerPreferences:)];
}
- (NSImage *)icon
{
	NSBundle *bundle = [NSBundle bundleForClass:[self.previewer class]];
	NSString *iconName = [bundle objectForInfoDictionaryKey:@"CFBundleIconFile"];
/*	NSString *path = [bundle pathForImageResource:iconName];
	NSImage *icon = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];*/
    NSImage *icon = [bundle imageForResource:iconName];
	if(icon) return icon;
	return [[NSWorkspace sharedWorkspace] iconForFile:self.path];
}


- (BOOL)isEqual:(id)object
{
	if(self == object) return YES;
	if(![object isMemberOfClass:[self class]]) return NO;
	
	return [self.identifier isEqualToString:[object identifier]];
}
- (NSUInteger)hash
{
	return [self.identifier hash];
}

- (id)description
{
	return [NSString stringWithFormat:@"%@ <%p> identifier = %@",
			NSStringFromClass([self class]), self, self.identifier];
}

- (id)copyWithZone:(NSZone *)zone
{
	BSLPSPreviewerItem *result = [[[self class] allocWithZone:zone] initWithIdentifier:_identifier];
	result.previewer = _previewer;
	result.displayName = _displayName;
	result.version = _version;
	result.path = _path;
	result.tryCheck = _tryCheck;
	result.displayInMenu = _displayInMenu;
	
	return result;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:_identifier forKey:BSLPSIdentifierKey];
	[aCoder encodeObject:_displayName forKey:BSLPSDisplayNameKey];
	[aCoder encodeObject:_path forKey:BSLPSPathKey];
	[aCoder encodeObject:_version forKey:BSLPSVersionKey];
	[aCoder encodeBool:_tryCheck forKey:BSLPSTryCheckKey];
	[aCoder encodeBool:_displayInMenu forKey:BSLPSDisplayInMenuKey];
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
	[self initWithIdentifier:[aDecoder decodeObjectForKey:BSLPSIdentifierKey]];
	self.displayName = [aDecoder decodeObjectForKey:BSLPSDisplayNameKey];
	self.path = [aDecoder decodeObjectForKey:BSLPSPathKey];
	self.version = [aDecoder decodeObjectForKey:BSLPSVersionKey];
	self.tryCheck = [aDecoder decodeBoolForKey:BSLPSTryCheckKey];
	self.displayInMenu = [aDecoder decodeBoolForKey:BSLPSDisplayInMenuKey];
	
	self.previewer = [previewerInfo objectForKey:_identifier];
	
	return self;
}

@end
