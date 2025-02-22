//
//  BSImagePreviewInspector.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/10/10.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSImagePreviewInspector.h"
#import "BSIPIArrayController.h"
#import "BSIPIFullScreenController.h"
#import "BSIPIPathTransformer.h"
#import "BSIPIImageView.h"
#import "BSIPIToken.h"
#import "BSIPIDefaults.h"
#import "BSIPIPreferencesController.h"
#import "BSIPIPreferencesViewController.h"
#import <SGAppKit/NSWorkspace-SGExtensions.h>
#import <CocoMonar/CMRPropertyKeys.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BSIPILeopardSlideshowHelper.h"

@class BSIPITableView;
@class BSIPIFullScreenWindow;

static NSString *const kIPINibFileNameKey		= @"BSImagePreviewInspector3";

@implementation BSImagePreviewInspector
- (id)initWithPreferences:(AppDefaults *)prefs
{
	if (self = [super initWithWindowNibName:kIPINibFileNameKey]) {
		NSNotificationCenter	*dnc = [NSNotificationCenter defaultCenter];
		BSIPIDefaults			*defaults = [BSIPIDefaults sharedIPIDefaults];

		[defaults setAppDefaults:prefs];

		id transformer = [[[BSIPIPathTransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:transformer forName:@"BSIPIPathTransformer"];

		id anotherTransformer = [[[BSIPIImageIgnoringDPITransformer alloc] init] autorelease];
		[NSValueTransformer setValueTransformer:anotherTransformer forName:@"BSIPIImageIgnoringDPITransformer"];

		[dnc addObserver:self
				selector:@selector(applicationWillTerminate:)
					name:NSApplicationWillTerminateNotification
				  object:NSApp];
		[dnc addObserver:self
				selector:@selector(makeWindowOpaqueWithFade:)
					name:BSIPITokenDownloadDidFinishNotification
				  object:nil];
		[dnc addObserver:self
				selector:@selector(tokenDidFailDownload:)
					name:BSIPITokenDownloadErrorNotification
				  object:nil];

		[defaults addObserver:self forKeyPath:@"alwaysBecomeKey" options:NSKeyValueObservingOptionNew context:kBSIPIDefaultsContext];
		[defaults addObserver:self forKeyPath:@"floating" options:NSKeyValueObservingOptionNew context:kBSIPIDefaultsContext];
		[defaults addObserver:self forKeyPath:@"alphaValue" options:NSKeyValueObservingOptionNew context:kBSIPIDefaultsContext];
		[defaults addObserver:self forKeyPath:@"imageViewBgColorData" options:NSKeyValueObservingOptionNew context:kBSIPIDefaultsContext];
        [defaults addObserver:self forKeyPath:@"autoCollectImages" options:NSKeyValueObservingOptionNew context:kBSIPIDefaultsContext];
        
        m_mp_isFirstFoundCache = YES;
        m_mp_newSelectedIndex = NSNotFound;
	}
	return self;
}

- (void)dealloc
{
    [[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"autoCollectImages"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"imageViewBgColorData"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"alphaValue"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"floating"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"alwaysBecomeKey"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [m_fadeOutTimer invalidate];
    [m_fadeOutTimer release];
    [m_recoveringURLs release];
    [m_toolbarItems release];
	[super dealloc];
}

- (id)historyManager
{
	return [BSIPIHistoryManager sharedManager];
}

- (NSTimer *)fadeOutTimer
{
    return m_fadeOutTimer;
}

- (void)setFadeOutTimer:(NSTimer *)aTimer
{
    if (aTimer != m_fadeOutTimer) {
        [aTimer retain];
        [m_fadeOutTimer invalidate];
        [m_fadeOutTimer release];
        m_fadeOutTimer = aTimer;
    }
}

- (id)recoveringURLs
{
    return m_recoveringURLs;
}

- (void)setRecoveringURLs:(id)obj
{
    [obj retain];
    [m_recoveringURLs release];
    m_recoveringURLs = obj;
}

- (IBAction)togglePreviewPanel:(id)sender
{
	if ([self isWindowLoaded] && [[self window] isVisible]) {
		// orderOut: では windowWillClose: はもちろん呼ばれない。
		if ([[BSIPIDefaults sharedIPIDefaults] resetWhenHide]) [[self tripleGreenCubes] setSelectionIndex:NSNotFound];
		[[self window] orderOut:sender];
	} else {
		[self showWindow:sender];
	}
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
    if (sender != self) {
        [self makeWindowOpaqueWithFade:nil];
    }
}

- (NSView *)preferenceView
{
    BSIPIPreferencesViewController *viewController = [BSIPIPreferencesViewController sharedPreferencesController];
    return [viewController view];
}

#pragma mark Actions
- (IBAction)showPreviewerPreferences:(id)sender
{
	[[BSIPIPreferencesController sharedPreferencesController] showWindow:sender];
}

- (IBAction)resetPreviewer:(id)sender
{
    [[self tripleGreenCubes] removeAll:nil];
}

- (IBAction)forceRunTbCustomizationPalette:(id)sender
{
	[[self window] runToolbarCustomizationPalette:self];
}

- (IBAction)copyURL:(id)sender
{
	[[self historyManager] writeTokensAtIndexes:[self validIndexesForAction:sender] toPasteboard:[NSPasteboard generalPasteboard]];
}

- (IBAction)openImage:(id)sender
{
	[[self historyManager] openURLForTokenAtIndexes:[self validIndexesForAction:sender]
									   inBackground:[[[BSIPIDefaults sharedIPIDefaults] appDefaults] openInBg]];
}

- (IBAction)openImageWithPreviewApp:(id)sender
{
	[[self historyManager] openCachedFileForTokenAtIndexesWithPreviewApp:[self validIndexesForAction:sender]];
}

- (IBAction)startFullscreen:(id)sender
{
	static BOOL	isBinded = NO;
    NSIndexSet *tmp_ = [self validIndexesForAction:sender];
//    if ([tmp_ count] > 1) {
        [[self tripleGreenCubes] setSelectionIndex:[tmp_ firstIndex]];
//    }

	if ([[BSIPIDefaults sharedIPIDefaults] useIKSlideShowOnLeopard]) {
		id<BSIPILeopardSlideshowHelperProtocol> instance = [BSIPILeopardSlideshowHelper sharedInstance];
		[instance setArrayController:[self tripleGreenCubes]];
		[instance startSlideshow];
	} else {
		m_shouldRestoreKeyWindow = [[self window] isKeyWindow];
/*
		NSIndexSet *tmp_ = [[self tripleGreenCubes] selectionIndexes];
		if ([tmp_ count] > 1) {
			[[self tripleGreenCubes] setSelectionIndex:[tmp_ firstIndex]];
		}
*/
		[[BSIPIFullScreenController sharedInstance] setDelegate:self];

		if (!isBinded) {
			[[BSIPIFullScreenController sharedInstance] bind:@"windowBackgroundColor"
													toObject:[BSIPIDefaults sharedIPIDefaults]
												 withKeyPath:@"fullScreenBgColorData"
													 options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
																						 forKey:NSValueTransformerNameBindingOption]];
			isBinded = YES;
		}

		[[BSIPIFullScreenController sharedInstance] setArrayController:[self tripleGreenCubes]];
		[[BSIPIFullScreenController sharedInstance] startFullScreen:[[self window] screen]];
	}
}

- (IBAction)saveImage:(id)sender
{
    if ([[BSIPIDefaults sharedIPIDefaults] autoCollectImages]) {
        [[self historyManager] revealCachedFileForTokenAtIndexes:[self validIndexesForAction:sender]];
    } else {
        NSError *error;
        NSString *destinationPath = [[BSIPIDefaults sharedIPIDefaults] saveDirectory];
        BOOL saveResult = [[self historyManager] copyCachedFileForTokenAtIndexes:[self validIndexesForAction:sender] intoFolder:destinationPath error:&error];
        if (!saveResult && error) {
            [self presentError:error modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentSaveImageErrorWithRecovery:contextInfo:) contextInfo:nil];
            return;
        }
        AudioServicesPlaySystemSound(1);
    }
}

- (void)didPresentSaveImageErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{
    if (didRecover) {
        [self saveImage:self];
    }
}

- (IBAction)saveImageAs:(id)sender
{
	m_shouldRestoreKeyWindow = [[self window] isKeyWindow];

	[[self historyManager] saveCachedFileForTokenAtIndex:[[self validIndexesForAction:sender] firstIndex]
								 savePanelAttachToWindow:[self window]];
}

- (IBAction)removeImage:(id)sender
{
    [[self tripleGreenCubes] removeObjectsAtArrangedObjectIndexes:[self validIndexesForAction:sender]];
}

- (IBAction)cancelDownload:(id)sender
{
	[[self historyManager] makeTokensCancelDownloadAtIndexes:[[self tripleGreenCubes] selectionIndexes]];
}

- (IBAction)retryDownload:(id)sender
{
    NSError *error;
    NSString *destinationPath = [[BSIPIDefaults sharedIPIDefaults] autoCollectImages] ? [[self historyManager] dlDateFolderPath:&error] : [[self historyManager] dlFolderPath:&error];
    if (!destinationPath && error) {
        [self presentError:error modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentRetryDownloadErrorWithRecovery:contextInfo:) contextInfo:nil];
        return;
    }
	[[self historyManager] makeTokensRetryDownloadToPath:destinationPath atIndexes:[[self tripleGreenCubes] selectionIndexes]];
}

- (void)didPresentRetryDownloadErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{
    if (didRecover) {
        [self retryDownload:self];
    }
}

- (IBAction)historyNavigationPushed:(id)sender
{
	NSInteger segNum = [sender selectedSegment];
	if (segNum == 0) {
		[[self tripleGreenCubes] selectPrevious:sender];
	} else if (segNum == 1) {
		[[self tripleGreenCubes] selectNext:sender];
	}
}

- (IBAction)changePane:(id)sender
{
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		[[self tabView] selectTabViewItemAtIndex:[sender selectedSegment]];
	} else {
		NSInteger current_ = [[self tabView] indexOfTabViewItem:[[self tabView] selectedTabViewItem]];
		[[self tabView] selectTabViewItemAtIndex:(current_ == 0) ? 1 : 0];
		[[self paneChangeBtn] setSelectedSegment:(current_ == 0) ? 1 : 0];
	}
}

- (IBAction)changePaneAndShow:(id)sender
{
	NSUInteger	modifier_ = [[NSApp currentEvent] modifierFlags];
	if (modifier_ & NSAlternateKeyMask) {
		[self startFullscreen:sender];
		return;
	}
	[[self tabView] selectTabViewItemAtIndex:0];
	[[self paneChangeBtn] setSelectedSegment:0];
}

- (BOOL)previewLink:(NSURL *)url
{
	/* showWindow:
	   If the window is an NSPanel object and has its becomesKeyOnlyIfNeeded flag set to YES, the window is displayed in front of
	   all other windows but is not made key; otherwise it is displayed in front and is made key. This method is useful for menu actions.
	*/
	[self showWindow:self];
	NSUInteger	index = [[self historyManager] cachedTokenIndexForURL:url];
	if (index == NSNotFound) {
        NSError *error;
        NSString *destinationPath = [[BSIPIDefaults sharedIPIDefaults] autoCollectImages] ? [[self historyManager] dlDateFolderPath:&error] : [[self historyManager] dlFolderPath:&error];
        if (!destinationPath && error) {
            [self setRecoveringURLs:url];
            [self presentError:error modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentPreviewErrorWithRecovery:contextInfo:) contextInfo:nil];
            return YES;
        }
		BSIPIToken *token = [[BSIPIToken alloc] initWithURL:url destination:destinationPath];
		[[self tripleGreenCubes] addObject:token];
		[token release];
	} else {
		[[self tripleGreenCubes] setSelectionIndex:index];
	}
	return YES;
}

- (BOOL)previewLinksImpl:(NSDictionary *)contextInfo
{
    NSArray *urls = [contextInfo objectForKey:@"URLs"];
    NSUInteger contextNum = [[contextInfo objectForKey:@"ContextNumber"] unsignedIntegerValue];

    if (contextNum == 0) {
        [self showWindow:self];
    }

	BSIPIArrayController *controller = [self tripleGreenCubes];

	NSUInteger index = NSNotFound;
//    NSUInteger tmpIndex = [controller countOfArrangedObjects];
//    BOOL isFirst = YES;
    
    if (contextNum == 0) {
        m_mp_isFirstFoundCache = YES;
        m_mp_newSelectedIndex = [controller countOfArrangedObjects];
        [controller setSelectsInsertedObjects:NO];
    }
	for (NSURL *url in urls) {
		index = [[self historyManager] cachedTokenIndexForURL:url];
		if (index == NSNotFound) {
            NSError *error;
            NSString *destinationPath = [[BSIPIDefaults sharedIPIDefaults] autoCollectImages] ? [[self historyManager] dlDateFolderPath:&error] : [[self historyManager] dlFolderPath:&error];
            if (!destinationPath && error) {
//                [self setRecoveringURLs:urls];
//                [self presentError:error modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentPreviewErrorWithRecovery:contextInfo:) contextInfo:nil];
                // 後続の遅延プレビューもすべてキャンセル
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                return YES;
            }
			BSIPIToken *token = [[BSIPIToken alloc] initWithURL:url destination:destinationPath];
			[controller addObject:token];
			[token release];
		} else {
/*            if (isFirst) {
                tmpIndex = index;
                isFirst = NO;
            }*/
            if (m_mp_isFirstFoundCache) {
                m_mp_newSelectedIndex = index;
                m_mp_isFirstFoundCache = NO;
            }
        }
	}
    if (contextNum == 2) {
//        [controller setSelectionIndex:tmpIndex];
        [controller setSelectionIndex:m_mp_newSelectedIndex];
        [controller setSelectsInsertedObjects:YES];
    }
	return YES;
}

- (BOOL)previewLinksBeforeCheck:(NSArray *)allURLs error:(NSError **)errorPtr
{
    NSUInteger index = NSNotFound;
    for (NSURL *url in allURLs) {
        index = [[self historyManager] cachedTokenIndexForURL:url];
        if (index == NSNotFound) {
            NSString *destinationPath = [[BSIPIDefaults sharedIPIDefaults] autoCollectImages] ? [[self historyManager] dlDateFolderPath:errorPtr] : [[self historyManager] dlFolderPath:errorPtr];
            if (!destinationPath) {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)previewLinks:(NSArray *)urls
{
    NSError *error;
    if (![self previewLinksBeforeCheck:urls error:&error] && error) {
        [self setRecoveringURLs:urls];
        [self presentError:error modalForWindow:[self window] delegate:self didPresentSelector:@selector(didPresentPreviewErrorWithRecovery:contextInfo:) contextInfo:nil];
        return YES;
    }
    
    int division;
    NSTimeInterval interval;
    
    NSUInteger count = [urls count];
    
    if (count < 6) {
        division = 1;
        interval = 0.0;
    } else if (count < 51) {
        division = 5;
        interval = 1.5;
    } else if (count < 101) {
        division = 3;
        interval = 1.5;
    } else {
        division = 2;
        interval = 2.0;
    }

    int times = [urls count] / division;
    int moduro = [urls count] % division;
    NSUInteger tmp = 0;
    for (int i = 0; i < times; i++) {
        if (i == 0) {
            tmp = 0;
        } else if (i == (times - 1)) {
            if (moduro == 0) {
                tmp = 2;
            } else {
                tmp = 1;
            }
        } else {
            tmp = 1;
        }
        [self performSelector:@selector(previewLinksImpl:) withObject:@{@"URLs": [urls subarrayWithRange:NSMakeRange(i * division, division)], @"ContextNumber": [NSNumber numberWithUnsignedInteger:tmp]} afterDelay:(i * interval)];
    }
    if (moduro != 0) {
        [self performSelector:@selector(previewLinksImpl:) withObject:@{@"URLs": [urls subarrayWithRange:NSMakeRange(times * division, ([urls count] % division))], @"ContextNumber" : @2} afterDelay:(times * interval)];
    }
    return YES;
}


- (void)didPresentPreviewErrorWithRecovery:(BOOL)didRecover contextInfo:(void *)contextInfo
{
    if (didRecover && [self recoveringURLs]) {
        if ([[self recoveringURLs] isKindOfClass:[NSURL class]]) {
            NSURL *url = [[(NSURL *)[self recoveringURLs] copy] autorelease];
            [self previewLink:url];
        } else if ([[self recoveringURLs] isKindOfClass:[NSArray class]]) {
            NSArray *urls = [[(NSArray *)[self recoveringURLs] copy] autorelease];
            [self previewLinks:urls];
        }
    }
    [self setRecoveringURLs:nil];
}

- (BOOL)validateQueryURL:(NSURL *)anURL
{
    NSString *stringRep = [anURL absoluteString];
    NSRange extensionRange = [stringRep rangeOfString:@"." options:(NSBackwardsSearch|NSLiteralSearch)];
    NSUInteger start = NSMaxRange(extensionRange);
    if (extensionRange.location == NSNotFound || start == [stringRep length]) {
        return NO;
    }
    NSString *extension = [stringRep substringFromIndex:start];
    return [[NSImage imageFileTypes] containsObject:extension];
}

- (BOOL)validateLink:(NSURL *)url
{
    if ([url query]) {
        return [self validateQueryURL:url];
    }
	CFStringRef extensionRef = CFURLCopyPathExtension((CFURLRef)url);
	if (!extensionRef) {
		return NO;
	}

	NSString *extension = [(NSString *)extensionRef lowercaseString];
	CFRelease(extensionRef);

	return [[NSImage imageFileTypes] containsObject:extension];
}

#pragma mark Notifications
- (void)applicationWillTerminate:(NSNotification *)aNotification
{		
	[[self historyManager] flushCache];
    [[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"autoCollectImages"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"imageViewBgColorData"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"alphaValue"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"floating"];
	[[BSIPIDefaults sharedIPIDefaults] removeObserver:self forKeyPath:@"alwaysBecomeKey"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setFadeOutTimer:nil];
    [m_toolbarItems release];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([[BSIPIDefaults sharedIPIDefaults] resetWhenHide]) [[self tripleGreenCubes] setSelectionIndex:NSNotFound];
}

- (void)windowWillBeginSheet:(NSNotification *)aNotification
{
	NSWindow *window_ = [aNotification object];
	m_shouldRestoreKeyWindow = [window_ isKeyWindow];
	[window_ setAlphaValue:1.0];
}

- (void)windowDidEndSheet:(NSNotification *)aNotification
{
	NSWindow *window_ = [aNotification object];
	[window_ setAlphaValue:[[BSIPIDefaults sharedIPIDefaults] alphaValue]];
	if (m_shouldRestoreKeyWindow) {
		[window_ makeKeyWindow];
	}
	m_shouldRestoreKeyWindow = NO;
}

- (void)fullScreenDidEnd:(NSWindow *)fullScreenWindow
{
	if (m_shouldRestoreKeyWindow) {
		[[self window] makeKeyWindow];
	}
	m_shouldRestoreKeyWindow = NO;
}

- (void)tokenDidFailDownload:(NSNotification *)aNotification
{
    BSIPIToken *token = [aNotification object];
    BOOL forceLeave = [[[aNotification userInfo] objectForKey:@"forceLeaving"] boolValue];
    if (forceLeave) {
        [[NSWorkspace sharedWorkspace] openURL:[token sourceURL] inBackground:[[[BSIPIDefaults sharedIPIDefaults] appDefaults] openInBg]];
    }
	if (forceLeave || ![[BSIPIDefaults sharedIPIDefaults] leaveFailedToken]) {
		[[self tripleGreenCubes] removeObject:token];
		[[self tripleGreenCubes] setSelectionIndex:NSNotFound];
	}
}

#pragma mark NSTableView Delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *tableView = [aNotification object];
	[tableView scrollRowToVisible:[tableView selectedRow]];
}

- (BOOL)tableView:(BSIPITableView *)aTableView shouldPerformKeyEquivalent:(NSEvent *)theEvent
{
	if ([aTableView selectedRow] == -1) return NO;
	
	NSInteger whichKey_ = [theEvent keyCode];

	if (whichKey_ == 51) { // delete key
		[[self tripleGreenCubes] remove:aTableView];
		return YES;
	}
	
	if (whichKey_ == 36) { // return key, option-return ro start fullscreen
		[self changePaneAndShow:aTableView];
		return YES;
	}
	return NO;
}

#pragma mark NSTabView Delegate
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSIndexSet *tmp_ = [[self tripleGreenCubes] selectionIndexes];
	if ([tmp_ count] > 1) {
		[[self tripleGreenCubes] setSelectionIndex:[tmp_ firstIndex]];
	}
	[[BSIPIDefaults sharedIPIDefaults] setLastShownViewTag:[tabView indexOfTabViewItem:tabViewItem]];
}

#pragma mark BSIPIImageView Delegate
- (BOOL)imageView:(BSIPIImageView *)aImageView writeSomethingToPasteboard:(NSPasteboard *)pboard
{
	return [[self historyManager] writeTokensAtIndexes:[[self tripleGreenCubes] selectionIndexes] toPasteboard:pboard];
}

- (void)imageView:(BSIPIImageView *)aImageView mouseDoubleClicked:(NSEvent *)theEvent
{
	if ([aImageView image]) [self startFullscreen:aImageView];
}

/*- (void)imageView:(BSIPIImageView *)aImageView swiped:(NSEvent *)theEvent
{
	CGFloat dX = [theEvent deltaX];
	BSIPIArrayController *controller = [self tripleGreenCubes];
	
	if (dX == 1.0) { // 右へスワイプ
        [controller selectPrevious:aImageView];
	} else if (dX == -1.0) { // 左へスワイプ
        [controller selectNext:aImageView];
	}
}*/

- (BOOL)imageView:(BSIPIImageView *)aImageView shouldPerformKeyEquivalent:(NSEvent *)theEvent
{
	BSIPIArrayController *controller = [self tripleGreenCubes];
	NSInteger modFlags = [theEvent modifierFlags];

	NSString	*pressedKey = [theEvent charactersIgnoringModifiers];
	unichar		keyChar = 0;

	NSUInteger length = [pressedKey length];
	if (length != 1) {
		return NO;
	}

	keyChar = [pressedKey characterAtIndex:0];

	if (keyChar == NSLeftArrowFunctionKey) {
		if (modFlags & NSAlternateKeyMask) {
			[controller selectFirst:aImageView];
			return YES;
		} else if ([controller canSelectPrevious]) {
			[controller selectPrevious:aImageView];
			return YES;
		}
	}
	
	if (keyChar == NSRightArrowFunctionKey) {
		if (modFlags & NSAlternateKeyMask) {
			[controller selectLast:aImageView];
			return YES;
		} else if ([controller canSelectNext]) {
			[controller selectNext:aImageView];
			return YES;
		}
	}
	
	if (keyChar == NSDeleteCharacter) {
		[controller remove:aImageView];
		return YES;
	}

	if (keyChar == NSCarriageReturnCharacter) {
		if ([aImageView image]) {
			[self startFullscreen:aImageView];
			return YES;
		}
	}

	return NO;
}
@end
