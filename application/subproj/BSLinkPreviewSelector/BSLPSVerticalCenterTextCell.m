//
//  BSLPSVerticalCenterTextCell.m
//  BathyScaphe
//
//  Created by masakih on 12/09/12.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSVerticalCenterTextCell.h"

@implementation BSLPSVerticalCenterTextCell

static inline BOOL isBlack(NSColor *color)
{
	NSColor *rgbColor = [color colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"];
	CGFloat red, green, blue, alpha;
	[rgbColor getRed:&red green:&green blue:&blue alpha:&alpha];
	
	return (red + green + blue == 0 && alpha == 1);
}

static NSShadow *textShadow()
{
	static NSShadow *_textShadow = nil;
	if(_textShadow) return _textShadow;

	_textShadow = [[NSShadow alloc] init];
	[_textShadow setShadowOffset:NSMakeSize(0.8, -1.0)];
	[_textShadow setShadowBlurRadius:2.0];
	[_textShadow setShadowColor:[NSColor darkGrayColor]];
	
	return _textShadow;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSFont *font = [self font];
	NSColor *fontColor = [self textColor];
	NSShadow *shadow = nil;
	if([self backgroundStyle] == NSBackgroundStyleDark
	   && isBlack(fontColor)) {
		fontColor = [NSColor whiteColor];
		shadow = textShadow();
		
		NSFontManager *fm = [NSFontManager sharedFontManager];
		font = [fm fontWithFamily:[font familyName]
						   traits:NSBoldFontMask
						   weight:0
							 size:[font pointSize] + 0.5];
	}
	
	cellFrame.origin.y += cellFrame.size.height / 2;
	cellFrame.origin.y -= [font pointSize] / 2;
	cellFrame.origin.y += [font descender];
	cellFrame.size.height = [font boundingRectForFont].size.height;
	
	[[self stringValue] drawWithRect:cellFrame
							 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
						  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
									  font, NSFontAttributeName,
									  fontColor, NSForegroundColorAttributeName,
									  shadow, NSShadowAttributeName,
									  nil]];
}

@end
