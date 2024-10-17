//
//  BSTitleRulerView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/09/22.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSTitleRulerView.h"
#import <SGAppKit/NSWorkspace-SGExtensions.h>
#import <SGAppKit/BSFlatTitleRulerAppearance.h>

#define	THICKNESS_FOR_TITLE	24.0
#define THICKNESS_FOR_TITLE_YOSEMITE    24.0
#define	THICKNESS_FOR_INFO	36.0
#define	TITLE_FONT_SIZE		11.0
#define TITLE_FONT_SIZE_YOSEMITE    11.0
#define	INFO_FONT_SIZE		13.0

@interface BSTitleRulerView ()
- (void)setTitleStrWithoutNeedingDisplay:(NSString *)aString;
- (void)setInfoStrWithoutNeedingDisplay:(NSString *)aString;
- (void)setAppearanceWithoutNeedingDisplay:(BSFlatTitleRulerAppearance *)anAppearance;
@end


@implementation BSTitleRulerView

#pragma mark Accessors
- (BSFlatTitleRulerAppearance *)appearance
{
	return m_appearance;
}

- (void)setAppearance:(BSFlatTitleRulerAppearance *)anAppearance
{
    [self setAppearanceWithoutNeedingDisplay:anAppearance];
    if ([self window]) {
        [m_titleField setTextColor:([[self window] isMainWindow] ? [anAppearance titleTextColor] : [anAppearance inactiveTitleTextColor])];
    }
    [self setNeedsDisplay:YES];
}

- (void)setAppearanceWithoutNeedingDisplay:(BSFlatTitleRulerAppearance *)anAppearance
{
	[anAppearance retain];
	[m_appearance release];
	m_appearance = anAppearance;
}

- (NSString *)titleStr
{
	return m_titleStr;
}

- (void)setTitleStr:(NSString *)aString
{
	[self setTitleStrWithoutNeedingDisplay:aString];
    [m_titleField setStringValue:aString];
}

- (void)setTitleStrWithoutNeedingDisplay:(NSString *)aString
{
	[aString retain];
	[m_titleStr release];
	m_titleStr = aString;
}

- (NSString *)infoStr
{
	return m_infoStr;
}

- (void)setInfoStr:(NSString *)aString
{
	[self setInfoStrWithoutNeedingDisplay:aString];
	[self setNeedsDisplay:YES];
}

- (void)setInfoStrWithoutNeedingDisplay:(NSString *)aString
{
	[aString retain];
	[m_infoStr release];
	m_infoStr = aString;
}

- (NSString *)pathStr
{
	return m_pathStr;
}

- (void)setPathStr:(NSString *)aString
{
	[aString retain];
	[m_pathStr release];
	m_pathStr = aString;
    [m_titleField setMenu:(m_pathStr ? createPathMenu(m_pathStr) : nil)];
}

- (BSTitleRulerModeType)currentMode
{
	return _currentMode;
}

- (void)setCurrentMode:(BSTitleRulerModeType)newType
{
	CGFloat newThickness;
    BOOL titleFieldHidden;
	_currentMode = newType;

	switch(newType) {
        case BSTitleRulerShowTitleOnlyMode:
            newThickness = isYosemite ? THICKNESS_FOR_TITLE_YOSEMITE : THICKNESS_FOR_TITLE;
            titleFieldHidden = NO;
            break;
        case BSTitleRulerShowInfoOnlyMode:
            newThickness = THICKNESS_FOR_INFO;
            titleFieldHidden = YES;
            break;
        case BSTitleRulerShowTitleAndInfoMode:
            newThickness = isYosemite ? (THICKNESS_FOR_TITLE_YOSEMITE + THICKNESS_FOR_INFO) : (THICKNESS_FOR_TITLE + THICKNESS_FOR_INFO);
            titleFieldHidden = NO;
            break;
        default:
            newThickness = isYosemite ? THICKNESS_FOR_TITLE_YOSEMITE : THICKNESS_FOR_TITLE;
            titleFieldHidden = NO;
            break;
	}
	
	[self setRuleThickness:newThickness];
    [m_titleField setHidden:titleFieldHidden];
}

#pragma mark Private Utilities
- (NSDictionary *)attrTemplateForInfo
{
	static NSDictionary	*tmp2 = nil;
	if (!tmp2) {
        NSFont *infoTextFont = [NSFont systemFontOfSize:INFO_FONT_SIZE];
		NSColor *infoTextColor = [[self appearance] infoTextColor];

		tmp2 = [[NSDictionary alloc] initWithObjectsAndKeys:infoTextFont, NSFontAttributeName, infoTextColor, NSForegroundColorAttributeName, nil];
	}
	return tmp2;
}

- (NSAttributedString *)infoForDrawing
{
	return [[[NSAttributedString alloc] initWithString:[self infoStr] attributes:[self attrTemplateForInfo]] autorelease];
}

#pragma mark Setup & Cleanup
- (id)initWithScrollView:(NSScrollView *)aScrollView appearance:(BSFlatTitleRulerAppearance *)appearance
{
	if (self = [super initWithScrollView:aScrollView orientation:NSHorizontalRuler]) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		// Original NSRulerView Properties
		[self setMarkers:nil];
		[self setReservedThicknessForMarkers:0.0];
        
        // Yosemite 判定
        isYosemite = (floor(NSAppKitVersionNumber) > 1265);

		// Notifications
		[nc addObserver:self selector:@selector(mainWindowDidChange:) name:NSWindowDidBecomeMainNotification object:nil];
		[nc addObserver:self selector:@selector(mainWindowDidChange:) name:NSWindowDidResignMainNotification object:nil];

		// BSTitleRulerView Properties
		[self setCurrentMode:BSTitleRulerShowTitleOnlyMode];
		m_appearance = [appearance retain];
        
        // Title Text Field Attributes
        NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(5, (isYosemite ? 5 : 5/*2*/), [self frame].size.width - 10, 16)];
        [field setAutoresizingMask:NSViewWidthSizable];
        if (isYosemite)  {
            [field setFont:[NSFont boldSystemFontOfSize:TITLE_FONT_SIZE_YOSEMITE]];
        } else {
            [field setFont:[NSFont boldSystemFontOfSize:TITLE_FONT_SIZE]];
        }
        [field setDrawsBackground:NO];
        [field setBordered:NO];
        [field setRefusesFirstResponder:YES];
        [field setEditable:NO];
        [field setSelectable:NO];
        [[field cell] setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [field setMenu:nil];

        [field setTextColor:[[self appearance] titleTextColor]];

        m_titleField = field;

        [self setAutoresizesSubviews:YES];
        [self addSubview:field];
        [field release];
	}
	return self;
}

- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
	[nc removeObserver:self name:NSWindowDidResignMainNotification object:nil];

	[m_titleStr release];
	[m_infoStr release];
	[m_pathStr release];
	[m_appearance release];

	[super dealloc];
}

#pragma mark Drawing
- (void)drawTitleBarInRect:(NSRect)aRect
{
    [[[self appearance] bottomBorderColor] set];
    NSRect borderRect = NSMakeRect(aRect.origin.x, aRect.origin.y + aRect.size.height - 1, aRect.size.width, 1.0);
    NSRectFill(borderRect);
    aRect.size.height -= 1;

    NSColor *fillColor = ([[self window] isMainWindow] ? [[self appearance] titleBackgroundColor] : [[self appearance] inactiveTitleBackgroundColor]);
    [fillColor set];
    NSRectFill(aRect);
}

- (BOOL)isOpaque
{
	return YES;
}

- (void)drawInfoBarInRect:(NSRect)aRect
{
	NSRect	iconRect;
	NSImage *icon_ = [[NSWorkspace sharedWorkspace] systemIconForType:kAlertNoteIcon];
	[icon_ setSize:NSMakeSize(32, 32)];

	[[[self appearance] infoBackgroundColor] set];
	NSRectFill(aRect);	

	iconRect = NSMakeRect(NSMinX(aRect)+5.0, NSMinY(aRect)+2.0, 32, 32);

    [icon_ drawInRect:iconRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

	aRect = NSInsetRect(aRect, 5.0, 7.0);
	aRect.origin.x += 36.0;
	[[self infoForDrawing] drawInRect:NSInsetRect(aRect, 5.0, 2.0)];
}

- (void)drawRect:(NSRect)aRect
{
    NSRect bRect = [self frame];
	switch ([self currentMode]) {
	case BSTitleRulerShowTitleOnlyMode:
		[self drawTitleBarInRect:bRect];
		break;
	case BSTitleRulerShowInfoOnlyMode:
		[self drawInfoBarInRect:bRect];
		break;
	case BSTitleRulerShowTitleAndInfoMode:
		{
			NSRect titleRect, infoRect;
			NSDivideRect(bRect, &infoRect, &titleRect, THICKNESS_FOR_INFO, NSMaxYEdge);
			[self drawTitleBarInRect:titleRect];
			[self drawInfoBarInRect:infoRect];
		}
		break;
	}
}

#pragma mark Path Popup Menu Support
- (IBAction)revealPathComponent:(id)sender
{
	NSString *path = [sender representedObject];
    if (path) {
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:[path stringByDeletingLastPathComponent]];
    }
}

static NSMenu *createPathMenu(NSString *fullPath)
{
	NSFileManager	*fm = [NSFileManager defaultManager];
	NSWorkspace		*ws = [NSWorkspace sharedWorkspace];
	NSMenu			*menu = [[NSMenu alloc] initWithTitle:@"Path"];
	NSMenuItem		*menuItem;
	NSImage			*img;
	NSSize			size16 = NSMakeSize(16,16);
	SEL				mySel = @selector(revealPathComponent:);

	menuItem = [[NSMenuItem alloc] initWithTitle:[fm displayNameAtPath:fullPath] action:mySel keyEquivalent:@""];
	img = [ws iconForFile:fullPath];
	[img setSize:size16];
	[menuItem setImage:img];
	[menu addItem:menuItem];
	[menuItem release];

	NSString *bar = fullPath;
	NSString *foo;

	while (![bar isEqualToString:@"/"]) {
		foo = [bar stringByDeletingLastPathComponent];
		menuItem = [[NSMenuItem alloc] initWithTitle:[fm displayNameAtPath:foo] action:mySel keyEquivalent:@""];
		img = [ws iconForFile:foo];
		[img setSize:size16];
		[menuItem setRepresentedObject:bar];
		[menuItem setImage:img];
		[menu addItem:menuItem];
		[menuItem release];
		bar = foo;
	}
	return [menu autorelease];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSUInteger flag = [theEvent modifierFlags];
	if ([self pathStr] && (flag & NSCommandKeyMask)) {
		[NSMenu popUpContextMenu:createPathMenu([self pathStr]) withEvent:theEvent forView:self];
	}
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	if ([self pathStr]) {
		return createPathMenu([self pathStr]);
	}
	return [super menuForEvent:theEvent];
}

#pragma mark Notifications
- (void)mainWindowDidChange:(NSNotification *)theNotification
{
    if (![self window]) {
        return;
    }

    id notificationObject = [theNotification object];
    if (notificationObject != [self window]) {
        return;
    }
    
    BSFlatTitleRulerAppearance *appearance = [self appearance];

    [m_titleField setTextColor:([notificationObject isMainWindow] ? [appearance titleTextColor] : [appearance inactiveTitleTextColor])];

	[self setNeedsDisplay:YES];
}
@end
