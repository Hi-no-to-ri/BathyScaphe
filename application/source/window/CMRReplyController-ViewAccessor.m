//
//  CMRReplyController-ViewAccessor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/24.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRReplyController_p.h"
#import "CMRReplyControllerTbDelegate.h"
#import <SGAppKit/BSReplyTextView.h>
#import <SGAppKit/BSLayoutManager.h>

static void *kReplySettingsContext = @"EternalBlaze";

@implementation CMRReplyController(View)
+ (Class)toolbarDelegateImpClass 
{ 
	return [CMRReplyControllerTbDelegate class];
}

/*- (NSString *)statusLineFrameAutosaveName 
{
	return APP_REPLY_STATUSLINE_IDENTIFIER;
}*/

#pragma mark Accessors
- (NSComboBox *)nameComboBox
{
	return _nameComboBox;
}

- (NSTextField *)mailField
{
	return _mailField;
}

- (NSTextView *)textView
{
	return _textView;
}

- (NSScrollView *)scrollView
{
	return _scrollView;
}

- (NSButton *)sageButton
{
	return _sageButton;
}

- (NSButton *)deleteMailButton
{
	return _deleteMailButton;
}

- (NSPopUpButton *)templateInsertionButton
{
	return m_templateInsertionButton;
}

- (NSObjectController *)objectController
{
	return m_controller;
}

//- (NSButton *)toggleBeButton
//{
//    return m_toggleBeButton;
//}

/*- (NSSegmentedControl *)accountsSelector
{
    return m_accountsSelector;
}*/

#pragma mark UI SetUp
- (void)updateTextView
{
	BSReplyTextView	*textView_ = (BSReplyTextView *)[self textView];
	
	if (!textView_) return;

	[(BSLayoutManager *)[textView_ layoutManager] setShouldAntialias:[CMRPref shouldThreadAntialias]];
    textView_.shouldOverrideCompletion = ![CMRPref abondonAllReplyTextViewFeatures];
	[textView_ setNeedsDisplay:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == kReplySettingsContext && object == CMRPref) {
		NSColor *newColor = [change objectForKey:NSKeyValueChangeNewKey];
		NSTextView *textView = [self textView];
		if (!newColor) {
			NSLog(@"Warning! -[observeValueForKeyPath:ofObject:change:context:] color is nil.");
			return;
		}
		if ([keyPath isEqualToString:@"threadViewTheme.replyColor"]) {
			[textView setTextColor:newColor];
			[textView setInsertionPointColor:newColor];
		} else if ([keyPath isEqualToString:@"threadViewTheme.replyBackgroundColor"]) {
            if ([newColor alphaComponent] < 1.0) {
                [[textView enclosingScrollView] setBackgroundColor:[NSColor clearColor]];
            }
			[textView setBackgroundColor:newColor];
		}
		[textView setNeedsDisplay:YES];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)setupScrollView
{
	NSScrollView	*scrollView_ = [self scrollView];

	[scrollView_ setBorderType:NSNoBorder];
	[scrollView_ setHasHorizontalScroller:NO];
	[scrollView_ setHasVerticalScroller:YES];
    // Lion: スクロールしたときの弾性衝突的なアレを取り除く
    if ([scrollView_ respondsToSelector:@selector(setVerticalScrollElasticity:)]) {
        [scrollView_ setVerticalScrollElasticity:NSScrollElasticityNone];
    }
}

- (void)setupTextView
{
	NSLayoutManager	*layout;
	NSTextContainer	*container;
	NSTextView		*view;
	NSRect			cFrame;
	BSThreadViewTheme *theme;
	
	[self setupScrollView];
	
	cFrame.origin = NSZeroPoint; 
	cFrame.size = [[self scrollView] contentSize];
	
	/* LayoutManager */
	layout = [[BSLayoutManager alloc] init];
	[[[self document] textStorage] addLayoutManager:layout];
	[layout release];

	/* TextContainer */
// #warning 64BIT: Inspect use of MAX/MIN constant; consider one of LONG_MAX/LONG_MIN/ULONG_MAX/DBL_MAX/DBL_MIN, or better yet, NSIntegerMax/Min, NSUIntegerMax, CGFLOAT_MAX/MIN
// 2011-08-27 tsawada2 修正済
	container = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(NSWidth(cFrame), CGFLOAT_MAX)];
	[layout addTextContainer:container];
	[container release];

	/* TextView */
	view = [[[BSReplyTextView alloc] initWithFrame:cFrame textContainer:container] autorelease];

	[view setMinSize:NSMakeSize(0.0, NSHeight(cFrame))];
// #warning 64BIT: Inspect use of MAX/MIN constant; consider one of LONG_MAX/LONG_MIN/ULONG_MAX/DBL_MAX/DBL_MIN, or better yet, NSIntegerMax/Min, NSUIntegerMax, CGFLOAT_MAX/MIN
// #warning 64BIT: Inspect use of MAX/MIN constant; consider one of LONG_MAX/LONG_MIN/ULONG_MAX/DBL_MAX/DBL_MIN, or better yet, NSIntegerMax/Min, NSUIntegerMax, CGFLOAT_MAX/MIN
// 2011-08-27 tsawada2 修正済
	[view setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
	[view setVerticallyResizable:YES];
	[view setHorizontallyResizable:NO];
	[view setAutoresizingMask:NSViewWidthSizable];

	[container setWidthTracksTextView:YES];

	[view setTypingAttributes:[[self document] textAttributes]];
	[view setAllowsUndo:YES];
	[view setEditable:YES];
	[view setSelectable:YES];
	[view setImportsGraphics:NO];
	[view setRichText:NO];

	theme = [CMRPref threadViewTheme];
	[view setTextColor:[theme replyColor]];
	[view setInsertionPointColor:[theme replyColor]];

	[view setDelegate:self];

	_textView = view;
	[[self scrollView] setDocumentView:_textView];

	[view setDrawsBackground:YES];
    NSColor *bgColor = [theme replyBackgroundColor];
    if ([bgColor alphaComponent] < 1.0) {
        [[view enclosingScrollView] setBackgroundColor:[NSColor clearColor]];
    }
	[view setBackgroundColor:bgColor];
	[self updateTextView];

	[view bind:@"font" toObject:CMRPref withKeyPath:@"threadViewTheme.replyFont" options:nil];

	// textColor だけ変えるなら KVB でも良いが、一緒に insertionPointColor も
	// 変えたいので、KVO で行くことにする。
	[CMRPref addObserver:self
			  forKeyPath:@"threadViewTheme.replyColor"
				 options:NSKeyValueObservingOptionNew
				 context:kReplySettingsContext];
	[CMRPref addObserver:self
			  forKeyPath:@"threadViewTheme.replyBackgroundColor"
			     options:NSKeyValueObservingOptionNew
				 context:kReplySettingsContext];
}

- (void)setupWindowFrameWithMessenger
{
	NSRect		windowFrame_;
	
	windowFrame_ = [[self document] windowFrame];
	if (NSEqualRects(NSZeroRect, windowFrame_)) {
		NSString	*fs;
		
		if ((fs = [CMRPref replyWindowDefaultFrameString])) {
			[[self window] setFrameFromString:fs];
		}
	} else {
		[[self window] setFrame:windowFrame_ display:YES];
	}
	
	[[self window] useOptimizedDrawing:YES];
}

- (void)setupButtons
{
	NSMenu		*menu;
	[[[self templateInsertionButton] cell] setUsesItemFromMenu:YES];

	menu = [[self templateInsertionButton] menu];
	[menu setDelegate:[BSReplyTextTemplateManager defaultManager]];

	// Leopard
	NSMenuItem	*item = [menu itemAtIndex:0];
    [item setHidden:YES];
    
    NSSearchFieldCell *cell = [[NSSearchFieldCell alloc] initTextCell:@""];
    [[[self deleteMailButton] cell] setImage:[[cell cancelButtonCell] image]];
    [cell release];
}

- (void)setupKeyLoops
{
	[[self nameComboBox] setNextKeyView:[self mailField]];
	[[self mailField] setNextKeyView:[self sageButton]];
	[[self sageButton] setNextKeyView:[self deleteMailButton]];
	[[self deleteMailButton] setNextKeyView:[self textView]];
	[[self textView] setNextKeyView:[self nameComboBox]];
	[[self window] setInitialFirstResponder:[self textView]];
	[[self window] makeFirstResponder:[self textView]];
}

- (void)setupNavigationBarComponents:(BOOL)isShown isFirst:(BOOL)isFirst
{
    ;
}

- (void)setupUIComponents
{
	[super setupUIComponents];

	[self setupWindowFrameWithMessenger];

	[[self nameComboBox] reloadData];

	[self setupButtons];
	[self setupTextView];
	[self setupKeyLoops];

	[[NSNotificationCenter defaultCenter]
			 addObserver:self
			    selector:@selector(applicationUISettingsUpdated:)
			        name:AppDefaultsLayoutSettingsUpdatedNotification
			      object:CMRPref];
}
@end


@implementation CMRReplyController (Delegate)
#pragma mark Notification
- (void)applicationUISettingsUpdated:(NSNotification *)notification
{
	UTILAssertNotificationName(
		notification,
		AppDefaultsLayoutSettingsUpdatedNotification);
	[self updateTextView];
}

#pragma mark NSTextView Delegate
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if ([CMRPref abondonAllReplyTextViewFeatures]) {
        return NO;
    }

	if (aSelector == @selector(insertTab:)) { // tab
		[[self window] makeFirstResponder:[aTextView nextValidKeyView]];
		return YES;
	}
	
	if (aSelector == @selector(insertBacktab:)) { // shift-tab
		[[self window] makeFirstResponder:[aTextView previousValidKeyView]];
		return YES;
	}
	
	return NO;
}

- (NSArray *)availableCompletionPrefixesForTextView:(NSTextView *)aTextView
{
	return [[[BSReplyTextTemplateManager defaultManager] templates] valueForKey:@"shortcutKeyword"];
}

- (NSString *)textView:(NSTextView *)aTextView completedStringForCompletionPrefix:(NSString *)prefix
{
	return [[BSReplyTextTemplateManager defaultManager] templateForShortcutKeyword:prefix];
}

#pragma mark NSComboBoxDataSource
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return [[CMRPref defaultKoteHanList] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index
{
    return [[CMRPref defaultKoteHanList] objectAtIndex:index];
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)string
{
    return [[CMRPref defaultKoteHanList] indexOfObject:string];
}

- (NSString *)firstGenreMatchingPrefix:(NSString *)prefix
{
    NSString *string = nil;
    NSString *lowercasePrefix = [prefix lowercaseString];
    NSEnumerator *stringEnum = [[CMRPref defaultKoteHanList] objectEnumerator];
    while ((string = [stringEnum nextObject])) {
		if ([[string lowercaseString] hasPrefix:lowercasePrefix]) return string;
    }
    return nil;
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)inputString
{
    NSString *candidate = [self firstGenreMatchingPrefix:inputString];
    return (candidate ? candidate : inputString);
}
@end
