//
//  BSLPSPreviewerItemsController.m
//  BathyScaphe
//
//  Created by masakih on 12/09/12.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSPreviewerItemsController.h"

#import "BSLPSPreviewerItem.h"


@implementation BSLPSPreviewerItemsController

- (BOOL)canRemove
{
	 NSArray *selection = [self selectedObjects];
	if([selection count] == 0) return NO;
	
	for(BSLPSPreviewerItem *item in selection) {
		if([item.identifier isEqualToString:@"jp.tsawada2.bathyscaphe.ImagePreviewer"])
			return NO;
	}
	
	return [super canRemove];
	
}
@end
