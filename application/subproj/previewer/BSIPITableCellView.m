//
//  BSIPITableCellView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2015/01/13.
//
//

#import "BSIPITableCellView.h"
#import "BSIPIToken.h"

@implementation BSIPITableCellView
- (void)awakeFromNib
{
    [BSIPIToken setRequestedThumbnailSize:[self convertSizeToBacking:([[self imageView] frame].size)]];
}

- (void)setObjectValue:(id)objectValue
{
    [super setObjectValue:objectValue];
    if ([objectValue isKindOfClass:[BSIPIToken class]]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateThumbnailIfNeeded:) name:BSIPITokenDidUpdateThumbnailNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:BSIPITokenDidUpdateThumbnailNotification object:nil];
    }
}

- (void)updateThumbnailIfNeeded:(NSNotification *)aNotification
{
    [[self imageView] setNeedsDisplay:YES];
}
@end
