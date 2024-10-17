//
//  HMPlugInPaneViewController.m
//  BathyScaphe
//
//  Created by masakih on 12/08/04.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSPSPlugInPaneViewController.h"

#import "BSLinkPreviewSelector.h"
#import "BSLPSPreviewerItem.h"

static NSString *const BSLPSItemPastboardType = @"PSPItemPastboardType";
static NSString *const BSLPSRowIndexType = @"PSPRowIndexType";

@interface BSPSPlugInPaneViewController ()

@property (retain, nonatomic) NSArray *items;
@property (assign, nonatomic) NSView *currentItemPreferenceView;

@end

@implementation BSPSPlugInPaneViewController
@synthesize itemsController = _itemsController;
@synthesize items = _items;
@synthesize currentItemPreferenceView = _currentItemPreferenceView;
@synthesize defaultPreferenceView = _defaultPreferenceView;
@synthesize itemPreferencePlaceholder = _itemPreferencePlaceholder;
@synthesize itemsListView = _itemsListView;
@synthesize scrollView = _scrollView;

- (id)init
{
	self = [super initWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
		
	return self;
}

- (void)awakeFromNib
{	
	[self.itemsListView registerForDraggedTypes:
	 [NSArray arrayWithObjects:BSLPSItemPastboardType, NSFilenamesPboardType, nil]];
	[self.itemsController addObserver:self
						   forKeyPath:@"selection"
							  options:0
							  context:self.itemsController];
	[self.itemsController addObserver:self
						   forKeyPath:@"selection.displayInMenu"
							  options:0
							  context:self.itemsController];
	[self.itemsController addObserver:self
						   forKeyPath:@"selection.tryCheck"
							  options:0
							  context:self.itemsController];
	
	[self.itemsController bind:NSContentArrayBinding
					  toObject:[BSLinkPreviewSelector sharedInstance]
				   withKeyPath:@"items.previewerItems"
					   options:nil];
}

- (void)setRepresentedObject:(id)representedObject
{
	[super setRepresentedObject:representedObject];
	self.items = representedObject;
}

- (BSLPSPreviewerItem *)selection
{
	return [[self.itemsController selectedObjects] lastObject];
}

inline BOOL containsSize(NSSize aSize, NSSize bSize)
{
	return aSize.width > bSize.width && aSize.height > bSize.height;
}
- (void)setCurrentItemPreferenceView:(NSView *)currentItemPreferenceView
{
	[self.currentItemPreferenceView removeFromSuperview];
	[self.scrollView removeFromSuperview];
	
	NSView *targetView = currentItemPreferenceView;
	
	NSRect placeholderFrame = [self.itemPreferencePlaceholder frame];
	NSRect itemViewFrame = [currentItemPreferenceView frame];
	NSRect containerFrame = placeholderFrame;
	
	if(!containsSize(placeholderFrame.size, itemViewFrame.size)) {
		[self.scrollView setFrameSize:placeholderFrame.size];
		
		NSRect docRect = [self.scrollView documentVisibleRect];
		docRect.size.width = MAX(docRect.size.width, itemViewFrame.size.width);
		docRect.size.height = MAX(docRect.size.height, itemViewFrame.size.height);
		NSView *docView = [self.scrollView documentView];
		[docView setFrame:docRect];
		[docView addSubview:currentItemPreferenceView];
				
		targetView = self.scrollView;
		containerFrame = docRect;
	}
	itemViewFrame.origin.x = 0;
	itemViewFrame.origin.y = NSHeight(containerFrame) - NSHeight(itemViewFrame);
	[currentItemPreferenceView setFrame:itemViewFrame];
	[self.itemPreferencePlaceholder addSubview:targetView];
	
	_currentItemPreferenceView = currentItemPreferenceView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(context == self.itemsController) {
		if([keyPath isEqualToString:@"selection"]) {
			id preview = self.selection.previewer;
			NSView *preferenceView = nil;
			if([preview respondsToSelector:@selector(preferenceView)]) {
				preferenceView = [preview preferenceView];
			}
			if(!preferenceView) {
				preferenceView = self.defaultPreferenceView;
			}
			self.currentItemPreferenceView = preferenceView;
			
			return;
		}
		if([keyPath isEqualToString:@"selection.displayInMenu"]
		   || [keyPath isEqualToString:@"selection.tryCheck"]) {
			[[BSLinkPreviewSelector sharedInstance] savePlugInsInfo];
			return;
		}
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)toggleAPlugin:(id)sender
{
	BSLPSPreviewerItem *obj = [self selection];
	if(!obj) return;
	
	if([obj.previewer respondsToSelector:@selector(togglePreviewPanel:)]) {
		[obj.previewer performSelector:@selector(togglePreviewPanel:) withObject:self];
	}
}
- (IBAction)openPreferences:(id)sender
{
	BSLPSPreviewerItem *obj = [self selection];
	if(!obj) return;
	
	if([obj.previewer respondsToSelector:@selector(showPreviewerPreferences:)]) {
		[obj.previewer performSelector:@selector(showPreviewerPreferences:) withObject:self];
	}
}

- (void)addPulgInWithURL:(NSURL *)fileURL
{
	[[BSLinkPreviewSelector sharedInstance] addItemFromURL:fileURL];
}

- (IBAction)addPlugIn:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setResolvesAliases:YES];
	[panel setAllowsMultipleSelection:YES];
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"bundle", @"plugin", nil]];
	[panel beginSheetModalForWindow:[self.view window]
				  completionHandler:^(NSInteger result) {
					  if(result == NSFileHandlingPanelCancelButton) return;
					  
					  for(NSURL *fileURL in [panel URLs]) {
						  [self addPulgInWithURL:fileURL];
					  }
				  }];
}

- (IBAction)removePlugIn:(id)sender
{
	BSLPSPreviewerItem *obj = [self selection];
	BSLinkPreviewSelector *previewerSelector = [BSLinkPreviewSelector sharedInstance];
	[previewerSelector removeItem:obj];
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (BOOL)becomeFirstResponder
{
	[[[self view] window] makeFirstResponder:self.itemsListView];
	return YES;
}
#pragma mark## NSTableView Delegate ##

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	if([rowIndexes count] != 1) return NO;
	
	NSUInteger index = [rowIndexes firstIndex];
	
	[pboard declareTypes:[NSArray arrayWithObjects:BSLPSItemPastboardType, BSLPSRowIndexType, nil] owner:nil];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[self.items objectAtIndex:index]]
			forType:BSLPSItemPastboardType];
	[pboard setPropertyList:[NSNumber numberWithUnsignedInteger:index] forType:BSLPSRowIndexType];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)targetTableView
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	
	if(![[pboard types] containsObject:BSLPSItemPastboardType]
	   && ![[pboard types] containsObject:NSFilenamesPboardType]) {
		return NSDragOperationNone;
	}
	
	if(dropOperation == NSTableViewDropOn) {
        [targetTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	}
	
	if([[pboard types] containsObject:NSFilenamesPboardType]) {
		return NSDragOperationCopy;
	}
	
	NSUInteger originalRow = [[pboard propertyListForType:BSLPSRowIndexType] unsignedIntegerValue];
	if(row == originalRow || row == originalRow + 1) {
		return NSDragOperationNone;
	}
	
	return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView*)tableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pboard = [info draggingPasteboard];
	if(![[pboard types] containsObject:BSLPSItemPastboardType]
	   && ![[pboard types] containsObject:NSFilenamesPboardType]) {
		return NO;
	}
	
	if(row < 0) row = 0;
	
	BSLinkPreviewSelector *linkSelector = [BSLinkPreviewSelector sharedInstance];
	
	if([[pboard types] containsObject:NSFilenamesPboardType]) {
		NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
		for(NSString *name in filenames) {
			NSURL *fileURL = [NSURL fileURLWithPath:name];
			[self addPulgInWithURL:fileURL];
			id item = [linkSelector itemAtIndex:[linkSelector itemCount] - 1];
			[linkSelector moveItem:item toIndex:row];
		}
		return NSDragOperationCopy;
	}
	
	NSUInteger originalRow = [[pboard propertyListForType:BSLPSRowIndexType] unsignedIntegerValue];
	
	NSData *itemData = [pboard dataForType:BSLPSItemPastboardType];
	BSLPSPreviewerItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
	if(![item isKindOfClass:[BSLPSPreviewerItem class]]) {
		return NO;
	}
	
	[linkSelector moveItem:item toIndex:row];
		
	return YES;
}

@end
