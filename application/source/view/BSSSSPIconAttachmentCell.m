//
//  BSSSSPIconAttachmentCell.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2015/01/04.
//
//

#import "BSSSSPIconAttachmentCell.h"

@implementation BSSSSPIconAttachmentCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager
{
    if (!NSEqualSizes(cellFrame.size, [[self image] size])) {
        [layoutManager setAttachmentSize:[[self image] size] forGlyphRange:NSMakeRange(charIndex, 1)];
        [layoutManager invalidateLayoutForCharacterRange:NSMakeRange(charIndex, 1) actualCharacterRange:NULL];
    }
    [super drawWithFrame:cellFrame inView:controlView characterIndex:charIndex layoutManager:layoutManager];
}
@end
