//
//  CMXPopUpWindowController+View.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/10/23.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMXPopUpWindowController_p.h"

#import "SGContextHelpPanel.h"
#import "CMRMessageAttributesTemplate.h"
#import "AppDefaults.h"

#define POPUP_TEXTINSET			SGTemplateSize(kTextContainerInsetKey)
#define POPUP_SCAN_MAXLINE		40


@implementation CMXPopUpWindowController(ViewInitializer)
- (void)registerToNotificationCenter
{
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(threadViewMouseExited:)
			   name:SGHTMLViewMouseExitedNotification
			 object:[self textView]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beIconDidUpdate:) name:BSSSSPIconPlaceholderDidUpdateNotification object:[BSSSSPIconManager defaultManager]];
    // For Lion
    // 辞書のポップオーバーが消えないままになる問題への対処のため
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dictionaryPopoverDidShow:)
                                                 name:NSPopoverDidShowNotification
                                               object:nil];
}

- (void)createUIComponents
{
	[self createPopUpWindow];
	[self createScrollViewWithTitlebar];
	[self createHTMLTextView];
	[self registerToNotificationCenter];
}

- (void)createPopUpWindow
{
	NSPanel			*panel_;
	id				tmp;

	panel_ = [[SGContextHelpPanel alloc]
	             initWithContentRect:DEFAULT_CONTENT_RECT
						   styleMask:NSBorderlessWindowMask
						     backing:NSBackingStoreBuffered
							   defer:YES];

	[panel_ setOneShot:NO];
    [panel_ setOpaque:NO];
	tmp = SGTemplateResource(kPopUpIsFloatingPanelKey);
	UTILAssertKindOfClass(tmp, NSNumber);
	[panel_ setFloatingPanel:[tmp boolValue]];
	tmp = SGTemplateResource(kPopUpBecomesKeyOnlyIfNeededKey);
	UTILAssertKindOfClass(tmp, NSNumber);
	[panel_ setBecomesKeyOnlyIfNeeded:[tmp boolValue]];
	tmp = SGTemplateResource(kPopUpHasShadowKey);
	UTILAssertKindOfClass(tmp, NSNumber);
	[panel_ setHasShadow:[tmp boolValue]];
	
	[panel_ setDelegate:self];

	[self setWindow:panel_];

	[panel_ release];
}

- (void)createScrollViewWithTitlebar
{
	NSScrollView	*scrollview_;
	BSPopUpTitlebar	*bar_;
	NSRect			oFrame_,vFrame_,bFrame_;
	NSView			*contentView_;
	id				tmp;
	
	UTILAssertNotNil([self window]);

	contentView_ = [[self window] contentView];
	
	oFrame_ = [contentView_ frame];
	NSDivideRect(oFrame_, &bFrame_, &vFrame_, TITLEBAR_HEIGHT, NSMaxYEdge);

	scrollview_ = [[NSScrollView alloc] initWithFrame:oFrame_];

	tmp = SGTemplateResource(kPopUpBorderTypeKey);
	UTILAssertKindOfClass(tmp, NSNumber);
	[scrollview_ setBorderType:[tmp integerValue]];
    [scrollview_ setDrawsBackground:NO];
	[scrollview_ setHasVerticalScroller:YES];
	[scrollview_ setHasHorizontalScroller:NO];
	[scrollview_ setAutohidesScrollers:YES];
	[scrollview_ setAutoresizesSubviews:YES];
	
	[contentView_ addSubview:scrollview_];
	[scrollview_ release];

	bar_ = [[BSPopUpTitlebar alloc] initWithFrame:bFrame_];
	[bar_ setAutoresizingMask:(NSViewMinYMargin|NSViewWidthSizable)];
	[contentView_ addSubview:bar_];
	[[bar_ closeButton] setTarget:self];
	[[bar_ closeButton] setAction:@selector(myPerformClose:)];
	[bar_ setHidden:YES];
	[bar_ release];
	
	[self setScrollView:scrollview_];
	[self setTitlebar:bar_];
}

- (void)updateLinkTextAttributes
{
	NSTextView *textView_ = [self textView];
	if ([[self theme] popupUsesAlternateTextColor]) {
		if ([CMRPref hasMessageAnchorUnderline]) {
			[textView_ setLinkTextAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:NSUnderlineStyleSingle]
																		   forKey:NSUnderlineStyleAttributeName]];
		} else {
			[textView_ setLinkTextAttributes:[NSDictionary empty]];
		}
	} else {
		[textView_ setLinkTextAttributes:[[CMRMessageAttributesTemplate sharedTemplate] attributesForAnchor]];
	}
}

- (void)updateAntiAlias
{
	[(BSLayoutManager *)[[self textView] layoutManager] setShouldAntialias:[CMRPref shouldThreadAntialias]];
}

- (void)createHTMLTextView
{
	NSLayoutManager		*layoutManager_;
	NSTextContainer		*tcontainer_;
	NSTextView			*textView_;
	

	NSRect cFrame_;
	NSSize contentSize_;
	
	if ([self textView]) return;

	contentSize_ = [[self scrollView] contentSize];
	cFrame_ = NSMakeRect(0, 0, contentSize_.width, contentSize_.height);
	
	layoutManager_ = [[BSLayoutManager alloc] init];
	[[self textStorage] addLayoutManager:layoutManager_];
	[layoutManager_ release];

// #warning 64BIT: Inspect use of MAX/MIN constant; consider one of LONG_MAX/LONG_MIN/ULONG_MAX/DBL_MAX/DBL_MIN, or better yet, NSIntegerMax/Min, NSUIntegerMax, CGFLOAT_MAX/MIN
    // 2011-11-13 tsawada2 変更済
	tcontainer_ = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(contentSize_.width, CGFLOAT_MAX)];
	[layoutManager_ addTextContainer:tcontainer_];
	[tcontainer_ release];
	
	
	textView_ = [[CMRThreadView alloc] initWithFrame:cFrame_ textContainer:tcontainer_];
	[textView_ setMinSize:NSMakeSize(0, contentSize_.height)];
// #warning 64BIT: Inspect use of MAX/MIN constant; consider one of LONG_MAX/LONG_MIN/ULONG_MAX/DBL_MAX/DBL_MIN, or better yet, NSIntegerMax/Min, NSUIntegerMax, CGFLOAT_MAX/MIN
// #warning 64BIT: Inspect use of MAX/MIN constant; consider one of LONG_MAX/LONG_MIN/ULONG_MAX/DBL_MAX/DBL_MIN, or better yet, NSIntegerMax/Min, NSUIntegerMax, CGFLOAT_MAX/MIN
    // 2011-11-13 tsawada2 変更済
	[textView_ setMaxSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
	[textView_ setTextContainerInset:POPUP_TEXTINSET];
	[textView_ setVerticallyResizable:YES];
	[textView_ setHorizontallyResizable:NO];
	[textView_ setAutoresizingMask:NSViewWidthSizable];
	[textView_ setEditable:NO];
	[textView_ setSelectable:YES];
	[textView_ setAllowsUndo:NO];
    [textView_ setDrawsBackground:NO];

    // Leopard
    [textView_ setDisplaysLinkToolTips:NO];

    
    [textView_ setAutomaticSpellingCorrectionEnabled:NO];
    [textView_ setAutomaticTextReplacementEnabled:NO];

	[tcontainer_ setWidthTracksTextView:YES];
	[self setTextView:textView_];
	[textView_ setFieldEditor:NO];

	[[self scrollView] setDocumentView:textView_];
	[[self window] setInitialFirstResponder:textView_];
	[textView_ release];
}
@end



@implementation CMXPopUpWindowController(Resizing)
- (NSScreen *)screenForPopupOwnerWindow
{
	NSScreen *screen = [[self ownerWindow] screen];
	return screen ?: [NSScreen mainScreen];
}
		
- (NSRect)constrainWindowFrame:(NSRect)windowFrame
{
	NSPoint		wTopLeft_;
	NSPoint		scTopLeft_;
	NSRect		newFrame_;
	NSRect		visibleScreen_;
	
	newFrame_ = windowFrame;
	
	visibleScreen_ = [[self screenForPopupOwnerWindow] visibleFrame];
	scTopLeft_ = visibleScreen_.origin;
	scTopLeft_.y = NSMaxY(visibleScreen_);
	
	wTopLeft_ = newFrame_.origin;
	wTopLeft_.y = NSMaxY(newFrame_);
	
	// x
	{
		CGFloat	screenX_;
		CGFloat	windowX_;
		
		screenX_ = NSMaxX(visibleScreen_);
		windowX_ = NSMaxX(newFrame_);
		if (windowX_ > screenX_)
			newFrame_.origin.x -= (windowX_ - screenX_);
		
		screenX_ = NSMinX(visibleScreen_);
		windowX_ = NSMinX(newFrame_);
		if (windowX_ < screenX_)
			newFrame_.origin.x += (windowX_ - screenX_);
	}
	// y
	if (wTopLeft_.y > scTopLeft_.y) {
		wTopLeft_.y = scTopLeft_.y;
		newFrame_.origin.y = (wTopLeft_.y - newFrame_.size.height);
	}else if (newFrame_.origin.y < visibleScreen_.origin.y) {
		newFrame_.origin.y = visibleScreen_.origin.y;
	}

	return newFrame_;
}

- (NSSize)maxSize
{
	NSSize		maxSize_;
	NSRect		visibleScreen_;
	CGFloat		maxWidthRate_;
	
	visibleScreen_ = [[self screenForPopupOwnerWindow] visibleFrame];
	maxSize_ = visibleScreen_.size;
	maxWidthRate_ = [[self class] popUpMaxWidthRate];

	maxSize_.width *= maxWidthRate_;
	
	return maxSize_;
}

- (NSRect)usedFullRectForTextContainer
{
	NSSize				newSize_;
	NSTextContainer		*container_ = [[self textView] textContainer];
	NSLayoutManager		*lm         = [container_ layoutManager];

	NSUInteger	nLines_  = 0;
	NSUInteger	nGlyphs_ = 0;
	NSUInteger	index_   = 0;
	NSRect		bodyRect_ = NSZeroRect;
	NSRect		usedRect_ = NSZeroRect;

	newSize_ = [[self textView] frame].size;
	newSize_.width = [self maxSize].width;
	[[self textView] setFrameSize:newSize_];
	
	
	// [Mac OS X 10.3]
	// - [NSLayoutManager usedRectForTextContainer:]
	// なぜか、複数行の場合、boundingRectを返す。
/*
	rect_ = [lm usedRectForTextContainer:container_];
*/
	
	bodyRect_ = [lm boundingRectForTextContainer:container_];
	nGlyphs_ = [lm numberOfGlyphs];
	
	// 最大 POPUP_SCAN_MAXLINE 行までスキャン
	while (index_ < nGlyphs_ && nLines_++ < POPUP_SCAN_MAXLINE) {
		NSRect		rect_;
		NSRange		efRange_;
		CGFloat		width_;
		
		rect_ = [lm lineFragmentUsedRectForGlyphAtIndex:index_ effectiveRange:&efRange_];
		// 左マージンを考慮
		width_ = ceil(NSMaxX(rect_));
		
		if (width_ > NSWidth(usedRect_))
			usedRect_.size.width = width_;
		
		index_ = NSMaxRange(efRange_);
	}
	
	usedRect_.size.height = NSHeight(bodyRect_);
	
	return usedRect_;
}

- (void)updateScrollerSize
{
	NSScroller		*scroller_ = [[self scrollView] verticalScroller];

	if ([CMRPref popUpWindowVerticalScrollerIsSmall]) {
		[scroller_ setControlSize:NSSmallControlSize];
	} else {
		[scroller_ setControlSize:NSRegularControlSize];
	}

    [scroller_ setKnobStyle:[self appropriateKnobStyleForBGColor]];
}

- (void)sizeToFit
{
	NSScrollView		*scrollView_ = [self scrollView];
	NSTextView			*textView_   = [self textView];
	
	NSSize		textViewSize_;
	NSSize		scrollViewSize_;
	NSSize		windowContentSize_;

	NSSize		maxSize_ = [self maxSize];
	NSRect		fixRect_;
	NSSize		textInset_  = [textView_ textContainerInset];

	fixRect_ = [self usedFullRectForTextContainer];
	fixRect_.size.height += textInset_.height * 2;
	fixRect_.size.width += textInset_.width * 2;
	
	textViewSize_ = fixRect_.size;
//	scrollViewSize_ = [scrollView_ frameSizeForContentSize:textViewSize_];
	// 2008-11-23
	scrollViewSize_ = [[scrollView_ class] frameSizeForContentSize:textViewSize_
											 hasHorizontalScroller:NO
											   hasVerticalScroller:[scrollView_ hasVerticalScroller]
														borderType:[scrollView_ borderType]];

	if (scrollViewSize_.width > maxSize_.width) {
		scrollViewSize_.width = maxSize_.width;
	}

	if (scrollViewSize_.height > maxSize_.height - 12) {
		scrollViewSize_.height = maxSize_.height;
	}

	windowContentSize_ = scrollViewSize_;
    // 丸み分
    windowContentSize_.height += 12;

	[scrollView_ setFrameSize:scrollViewSize_];
//	[scrollView_ setFrameOrigin:NSMakePoint(0,0)];
    [scrollView_ setFrameOrigin:NSMakePoint(0,6)];
	[[self window] setContentSize:windowContentSize_];
	
	// ScrollViewにtextViewを合わせて、再度レイアウト
	textViewSize_.width = [scrollView_ contentSize].width;
	[textView_ setFrameSize:textViewSize_];
	
	// Scroller
	[self updateScrollerSize];
    [(SGContextHelpPanel *)[self window] updateBackgroundColorWithRoundedCorner:[[self theme] popupBackgroundColor]];
}
@end



@implementation CMXPopUpWindowController(Accessor)
- (NSScrollerKnobStyle)appropriateKnobStyleForBGColor
{
    NSColor *color = [[[self theme] popupBackgroundColorIgnoringAlpha] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    CGFloat brightness = [color brightnessComponent];
    return (brightness < 0.5) ? NSScrollerKnobStyleLight : NSScrollerKnobStyleDefault;
}

- (BSThreadViewTheme *)theme
{
	return m_theme;
}
- (void)setTheme:(BSThreadViewTheme *)aTheme
{
	m_theme = aTheme;
	[self updateLinkTextAttributes];

	[self updateScrollerSize];
}
@end
