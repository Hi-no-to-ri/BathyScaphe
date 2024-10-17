//
//  HMPreferenceWindow.m
//  BathyScaphe
//
//  Created by masakih on 12/08/04.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSPreferenceWindow.h"

#import "BSPSPlugInPaneViewController.h"


@interface BSLPSPreferenceWindow ()
@property (retain, nonatomic) IBOutlet BSPSPlugInPaneViewController *viewController;
@end

@implementation BSLPSPreferenceWindow
@synthesize viewController = _viewController;

- (id)init
{
	self = [super initWithWindowNibName:@"BSLPSPreferenceWindow"];
	
	_viewController = [[BSPSPlugInPaneViewController alloc] init];
	
	return self;
}
- (void)dealloc
{
	[_viewController release];
	
	[super dealloc];
}
- (void)windowDidLoad
{
    [super windowDidLoad];
	
	[[self window] setContentView:self.viewController.view];
	[[self window] makeFirstResponder:self.viewController];
}

- (void)setItems:(id)items
{
	[self.viewController setRepresentedObject:items];
}

- (IBAction)revealInFinder:(id)sender
{
	id obj = [self.viewController selection];
    NSString *path = [obj path];
    if (path) {
        NSURL *url = [NSURL fileURLWithPath:path];
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:url]];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([menuItem action] == @selector(revealInFinder:)) {
        id obj = [self.viewController selection];
        if (obj && ![[obj identifier] isEqualToString:@"jp.tsawada2.bathyscaphe.ImagePreviewer"]) {
            return YES;
        }
        return NO;
    }
    return [super validateMenuItem:menuItem];
}
@end
