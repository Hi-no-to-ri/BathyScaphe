//
//  PreviewerSelectorPreferenceViewController.m
//  PreviewerSelector
//
//  Created by masakih on 12/07/15.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSPreferenceViewController.h"

#import "BSLinkPreviewSelector.h"
#import "BSLPSPreviewerItem.h"


@implementation BSLPSPreferenceViewController

static NSString *const BSLPSItemPastboardType = @"PSPItemPastboardType";
static NSString *const BSLPSRowIndexType = @"PSPRowIndexType";


@synthesize tableView = _tableView;

- (id)init
{
    self = [super initWithNibName:@"BSLPSPreferenceView"
						   bundle:[NSBundle bundleForClass:[self class]]];    
    return self;
}

- (void)awakeFromNib
{	
	[self.tableView setDoubleAction:@selector(toggleAPlugin:)];
	[self.tableView setTarget:self];
	
	[self.tableView registerForDraggedTypes:[NSArray arrayWithObject:BSLPSItemPastboardType]];
	
	[itemsController addObserver:self forKeyPath:@"selection.tryCheck" options:0 context:itemsController];
	[itemsController addObserver:self forKeyPath:@"selection.displayInMenu" options:0 context:itemsController];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(context == itemsController) {
		[[BSLinkPreviewSelector sharedInstance] savePlugInsInfo];
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setPlugInList:(id)list
{
	id temp = plugInList;
	plugInList = [list retain];
	[temp release];
}

- (IBAction)toggleAPlugin:(id)sender
{
	int selectedRow = [self.tableView selectedRow];
	if(selectedRow == -1) return;
	
	id info = [plugInList objectAtIndex:selectedRow];
	id obj = [info previewer];
	if(!obj) return;
	
	if([obj respondsToSelector:@selector(togglePreviewPanel:)]) {
		[obj performSelector:@selector(togglePreviewPanel:) withObject:self];
	}
}

- (IBAction)openPreferences:(id)sender
{
	int selectedRow = [self.tableView selectedRow];
	if(selectedRow == -1) return;
	
	id info = [plugInList objectAtIndex:selectedRow];
	id obj = [info previewer];
	if(!obj) return;
	
	if([obj respondsToSelector:@selector(showPreviewerPreferences:)]) {
		[obj performSelector:@selector(showPreviewerPreferences:) withObject:self];
	}
}

#pragma mark## NSTableView Delegate ##

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	if([rowIndexes count] != 1) return NO;
	
	NSUInteger index = [rowIndexes firstIndex];
	
	[pboard declareTypes:[NSArray arrayWithObjects:BSLPSItemPastboardType, BSLPSRowIndexType, nil] owner:nil];
	[pboard setData:[NSKeyedArchiver archivedDataWithRootObject:[plugInList objectAtIndex:index]]
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
	if(![[pboard types] containsObject:BSLPSItemPastboardType]) {
		return NSDragOperationNone;
	}
	
	if(dropOperation == NSTableViewDropOn) {
        [targetTableView setDropRow:row dropOperation:NSTableViewDropAbove];
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
	if(![[pboard types] containsObject:BSLPSItemPastboardType]) {
		return NO;
	}
	
	if(row < 0) row = 0;
	
	NSUInteger originalRow = [[pboard propertyListForType:BSLPSRowIndexType] unsignedIntegerValue];
	
	NSData *itemData = [pboard dataForType:BSLPSItemPastboardType];
	BSLPSPreviewerItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
	if(![item isKindOfClass:[BSLPSPreviewerItem class]]) {
		return NO;
	}
	
	[self willChangeValueForKey:@"plugInList"];
	[[BSLinkPreviewSelector sharedInstance] moveItem:item toIndex:row];
	[self didChangeValueForKey:@"plugInList"];
		
	return YES;
}

@end
