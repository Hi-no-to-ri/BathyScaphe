//
//  CMRStatusLineWindowController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/02/14.
//  Copyright 2006-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRStatusLineWindowController.h"
#import "CMRTask.h"
#import "CMRTaskManager.h"
#import "BSTaskItemValueTransformer.h"
#import "AppDefaults.h"

NSString *const BSShouldValidateIdxNavNotification = @"BSShouldValidateIdxNavNotification";

@implementation CMRStatusLineWindowController
+ (void)initialize
{
	if (self == [CMRStatusLineWindowController class]) {
		id transformer = [[[BSTaskItemValueTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:transformer forName:@"BSTaskItemValueTransformer"];
	}
}

- (void)dealloc
{
	[[self taskObjectController] unbind:@"contentObject"];
    [[self taskObjectController] setContent:nil];
	[m_toolbarDelegateImp release];
	[super dealloc];
}

- (NSSegmentedControl *)indexingNavigator
{
    return m_indexingNavigator;
}

- (NSTextField *)statusMessageField
{
    return m_statusMessageField;
}

- (NSObjectController *)taskObjectController
{
    return m_taskObjectController;
}

- (NSTextField *)numberOfMessagesField
{
    return m_numberOfMessagesField;
}

- (NSProgressIndicator *)progressIndicator
{
    return m_progressIndicator;
}

+ (Class)toolbarDelegateImpClass
{
	return Nil;
}

- (id<CMRToolbarDelegate>)toolbarDelegate
{
	if (!m_toolbarDelegateImp) {
		Class		class_;
		
		class_ = [[self class] toolbarDelegateImpClass];
		UTILAssertConformsTo(class_, @protocol(CMRToolbarDelegate));

		m_toolbarDelegateImp = [[class_ alloc] init];
	}
	return m_toolbarDelegateImp;
}

// thread signature for historyManager .etc
- (id)threadIdentifier
{
	UTILAbstractMethodInvoked;
	return nil;
}

// Keybinding support
- (void)selectNextKeyView:(id)sender
{
	[[self window] selectNextKeyView:sender];
}

- (void)selectPreviousKeyView:(id)sender
{
	[[self window] selectPreviousKeyView:sender];
}

// Window Management
- (void)windowDidLoad
{
	[super windowDidLoad];
    [[self window] setCollectionBehavior:[[self class] defaultWindowCollectionBehaviorForLion]];
	[[self window] setAutodisplay:NO];
	[[self window] setViewsNeedDisplay:NO];
	[self setupUIComponents];
	[[self window] setViewsNeedDisplay:YES];
	[[self window] setAutodisplay:YES];
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action_ = [anItem action];
	if (action_ == @selector(cancelCurrentTask:)) {
		return [[CMRTaskManager defaultManager] isInProgress];
	} else if (action_ == @selector(toggleNavigationBarShown:)) {
        if ([(id)anItem isKindOfClass:[NSMenuItem class]]) {
            NSString *key = ([CMRPref navigationBarShownForClass:[self class]] ? @"Hide Navigation Bar" : @"Show Navigation Bar");
            [(NSMenuItem *)anItem setTitle:NSLocalizedString(key, key)];
        }
    }
	
	return YES; // For Example, @selector(saveAsDefaultFrame:) -- always YES.
}
@end


@implementation CMRStatusLineWindowController(ViewInitializer)
- (void)setupNavigationBarComponents:(BOOL)isShown isFirst:(BOOL)isFirst
{
    UTILAbstractMethodInvoked;
}

- (void)setupUIComponents
{
    [[self taskObjectController] bind:@"contentObject" toObject:[CMRTaskManager defaultManager] withKeyPath:@"currentTask" options:nil];
    [[[self statusMessageField] cell] setBackgroundStyle:NSBackgroundStyleRaised];
    [[self numberOfMessagesField] setStringValue:@""];
    [[[self numberOfMessagesField] cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[[self toolbarDelegate] attachToolbarWithWindow:[self window]];
	[[self window] setDelegate:self];
    
    [self setupNavigationBarComponents:[CMRPref navigationBarShownForClass:[self class]] isFirst:YES];
}

+ (NSUInteger)defaultWindowCollectionBehaviorForLion
{
    return NSWindowCollectionBehaviorFullScreenAuxiliary;
}

- (void)setNavigationBarControlsHidden:(BOOL)isHidden
{
    [[self statusMessageField] setHidden:isHidden];
    [[self numberOfMessagesField] setHidden:isHidden];
    [[self indexingNavigator] setHidden:isHidden];
    [[self progressIndicator] setHidden:isHidden];
}
@end


@implementation CMRStatusLineWindowController(Action)
// 「ウインドウの位置と領域を記憶」
- (IBAction)saveAsDefaultFrame:(id)sender
{
	UTILAbstractMethodInvoked;
}

- (IBAction)cancelCurrentTask:(id)sender
{
	[[CMRTaskManager defaultManager] cancel:sender];
}

- (IBAction)toggleNavigationBarShown:(id)sender
{
    BOOL currentState = [CMRPref navigationBarShownForClass:[self class]];
    [CMRPref setNavigationBarShown:!currentState forClass:[self class]];
    
    [self setupNavigationBarComponents:!currentState isFirst:NO];
    [[self window] displayIfNeeded];
}
@end
