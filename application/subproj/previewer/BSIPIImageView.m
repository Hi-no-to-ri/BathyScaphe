//
//  BSIPIImageView.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/01/07.
//  Copyright 2006-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSIPIImageView.h"


@implementation BSIPIImageCell
+ (NSFocusRingType)defaultFocusRingType
{
    return NSFocusRingTypeExterior;
}

- (void)dealloc
{
    [bsIPIImageCell_bgColor release];
    [super dealloc];
}

- (void)copyAttributesFromCell:(NSImageCell *)baseCell
{
    [self setImageAlignment:[baseCell imageAlignment]];
    [self setImageFrameStyle:[baseCell imageFrameStyle]];
    [self setImageScaling:[baseCell imageScaling]];
    if ([baseCell isKindOfClass:[BSIPIImageCell class]]) {
        [self setBackgroundColor:[(BSIPIImageCell *)baseCell backgroundColor]];
    }
}

- (NSColor *)backgroundColor
{
    return bsIPIImageCell_bgColor;
}

- (void)setBackgroundColor:(NSColor *)color
{
    [color retain];
    [bsIPIImageCell_bgColor release];
    bsIPIImageCell_bgColor = color;
    
    [[self controlView] setNeedsDisplay:YES];
}

// 少しだけ丸みを帯びた四角形
- (NSBezierPath *)calcRoundedRectForRect:(NSRect)bgRect
{
    NSInteger minX = NSMinX(bgRect);
    NSInteger midX = NSMidX(bgRect);
    NSInteger maxX = NSMaxX(bgRect);
    NSInteger minY = NSMinY(bgRect);
    NSInteger midY = NSMidY(bgRect);
    NSInteger maxY = NSMaxY(bgRect);
    CGFloat radius = 4.5; // 試行錯誤の末の値
    NSBezierPath *bgPath = [NSBezierPath bezierPath];
    
    // Bottom edge and bottom-right curve
    [bgPath moveToPoint:NSMakePoint(midX, minY)];
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, minY) toPoint:NSMakePoint(maxX, midY) radius:radius];
    
    // Right edge and top-right curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(maxX, maxY) toPoint:NSMakePoint(midX, maxY) radius:radius];
    
    // Top edge and top-left curve
    [bgPath appendBezierPathWithArcFromPoint:NSMakePoint(minX, maxY) toPoint:NSMakePoint(minX, midY) radius:radius];
    
    // Left edge and bottom-left curve
    [bgPath appendBezierPathWithArcFromPoint:bgRect.origin toPoint:NSMakePoint(midX, minY) radius:radius];

    [bgPath closePath];

    return bgPath;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSColor *color = [self backgroundColor];
    if (color) {
        [color set];
        NSRectFill(cellFrame);
    }
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];

    if ([self focusRingType] != NSFocusRingTypeNone && [self showsFirstResponder]) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[self calcRoundedRectForRect:cellFrame] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}
@end

#pragma mark -
@implementation BSIPIImageView
- (void)awakeFromNib
{
    BSIPIImageCell *cell_ = [[BSIPIImageCell alloc] init];
    [cell_ copyAttributesFromCell:[self cell]];
    [self setCell:cell_];
    [cell_ release];
}

- (id)delegate
{
    return bsIPIImageView_delegate;
}

- (void)setDelegate:(id)aDelegate
{
    bsIPIImageView_delegate = aDelegate;
}

- (NSColor *)backgroundColor
{
    if ([[self cell] isKindOfClass:[BSIPIImageCell class]]) {
        return [(BSIPIImageCell *)[self cell] backgroundColor];
    }
    
    return nil;
}

- (void)setBackgroundColor:(NSColor *)color
{
    if ([[self cell] isKindOfClass:[BSIPIImageCell class]]) {
        [(BSIPIImageCell *)[self cell] setBackgroundColor:color];
    }
}

- (void)dealloc
{
    bsIPIImageView_delegate = nil;
    [super dealloc];
}

#pragma mark Drag and Drop, Mouse Events
- (NSRect)draggingImageRect
{
    NSRect drwaingRect = [[self cell] drawingRectForBounds:[self bounds]];
    NSSize targetSize = drwaingRect.size;
    NSSize originalSize = [[self image] size];
    NSSize imageSize;
    
    CGFloat dx, dy;
    dx = targetSize.width / originalSize.width;
    dy = targetSize.height / originalSize.height;
    if (dx > dy) {
        dx = dy;
    } else {
        dy = dx;
    }
    // オリジナルより大きくしない。
    if (dx > 1) {
        dx = dy = 1;
    }
    
    imageSize = NSMakeSize(originalSize.width * dx, originalSize.height * dy);
    
    CGFloat offsetX, offsetY;
    
    switch ([self imageAlignment]) {
        case NSImageAlignCenter:
        case NSImageAlignTop:
        case NSImageAlignBottom:
            offsetX = NSMidX([self frame]) - imageSize.width * 0.5;
            break;
        case NSImageAlignTopLeft:
        case NSImageAlignLeft:
        case NSImageAlignBottomLeft:
            offsetX = NSMinX(drwaingRect);
            break;
        case NSImageAlignTopRight:
        case NSImageAlignBottomRight:
        case NSImageAlignRight:
            offsetX = NSMaxX(drwaingRect) - imageSize.width;
            break;
        default:
            offsetX = NSMidX([self frame]) - imageSize.width * 0.5;
            break;
    }
    
    switch ([self imageAlignment]) {
        case NSImageAlignCenter:
        case NSImageAlignLeft:
        case NSImageAlignRight:
            offsetY = NSMidY([self frame]) - imageSize.height * 0.5;
            break;
        case NSImageAlignTop:
        case NSImageAlignTopLeft:
        case NSImageAlignTopRight:
            offsetY = NSMinY(drwaingRect);
            break;
        case NSImageAlignBottom:
        case NSImageAlignBottomLeft:
        case NSImageAlignBottomRight:
            offsetY = NSMaxY(drwaingRect) - imageSize.height;
            break;
        default:
            offsetY = NSMidY([self frame]) - imageSize.height * 0.5;
            break;
    }
    
    return NSMakeRect(offsetX, offsetY, imageSize.width, imageSize.height);
}

- (NSSize)fitSizeForDragging
{
    return [self draggingImageRect].size;
}

// サイズ調整された、半透明画像
- (NSImage *)imageForDragging
{
    NSImage *image = [[[NSImage alloc] initWithSize:[[self image] size]] autorelease];
    [image lockFocus];
    [[self image] drawAtPoint:NSZeroPoint
                     fromRect:NSZeroRect
                    operation:NSCompositeCopy
                     fraction:0.75];
    [image unlockFocus];
    
    [image setScalesWhenResized:YES];
    [image setSize:[self fitSizeForDragging]];
    
    return image;
}

// マウスが四方に delta 移動するまでドラッグを開始しない
- (void)dragImageFileWithEvent:(NSEvent *)theEvent
{
    NSRect koreguraiHaNotDragRect;
    NSPoint clickPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    const CGFloat delta = 5;
    
    koreguraiHaNotDragRect = NSMakeRect(clickPoint.x - delta / 2.0, clickPoint.y - delta / 2.0, delta, delta);
    
    while (YES) {
        NSPoint mouse;
        theEvent = [NSApp nextEventMatchingMask:(NSLeftMouseUpMask|NSLeftMouseDraggedMask)
                                      untilDate:[NSDate distantFuture]
                                         inMode:NSEventTrackingRunLoopMode
                                        dequeue:YES];
        if ([theEvent type] == NSLeftMouseUp) {
            if (([theEvent clickCount] == 2) && [[self delegate] respondsToSelector:@selector(imageView:mouseDoubleClicked:)]) {
                [[self delegate] imageView:self mouseDoubleClicked:theEvent];
            }
            break;
        }
        mouse = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        if (!NSMouseInRect(mouse, koreguraiHaNotDragRect, [self isFlipped])) {
            NSImage *image;
            NSPoint imageLoc;
            NSPasteboard *pb;
            NSSize offset;
            
            pb = [NSPasteboard pasteboardWithName:NSDragPboard];

            [[self delegate] imageView:self writeSomethingToPasteboard:pb];
            
            image = [self imageForDragging];
            imageLoc = [self draggingImageRect].origin;
            offset = NSMakeSize(mouse.x - clickPoint.x, mouse.y - clickPoint.y);
            
            [self dragImage:image
                         at:imageLoc
                     offset:offset
                      event:theEvent
                 pasteboard:pb
                     source:self
                  slideBack:YES];
            
            break;
        }
    }
}
        
- (void)mouseDown:(NSEvent *)theEvent
{
    id delegate = [self delegate];
    if ([self image] && delegate && [delegate respondsToSelector:@selector(imageView:writeSomethingToPasteboard:)]) {
        [self dragImageFileWithEvent:theEvent];
    } else {
        [super mouseDown:theEvent];
    }
}

/*- (void)swipeWithEvent:(NSEvent *)theEvent
{
    id delegate = [self delegate];
    if (delegate && [delegate respondsToSelector:@selector(imageView:swiped:)]) {
        [delegate imageView:self swiped:theEvent];
    }
}*/

// キーウインドウにしなくてもドラッグを開始できるように
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return ([self image] != nil);
}

#pragma mark Perform Key Equivalent
- (BOOL)needsPanelToBecomeKey
{
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if ([theEvent type] == NSKeyDown) { // keyUp で二重に呼び出されるのを防ぐ
        id delegate = [self delegate];
        if(delegate && [delegate respondsToSelector:@selector(imageView:shouldPerformKeyEquivalent:)]) {
            return [delegate imageView:self shouldPerformKeyEquivalent:theEvent];
        }
    }

    return [super performKeyEquivalent:theEvent];
}
@end
