//
//  BSIntroWindowController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2015/01/17.
//
//

#import "BSIntroWindowController.h"
#import "KBButton.h"
#import "CMRAppDelegate.h"

@implementation BSIntroWindowController
- (void)windowDidLoad {
    [super windowDidLoad];
    
    [[m_qsButton cell] setKBButtonType:BButtonTypeBathyScapheBlue];
    [[m_wnButton cell] setKBButtonType:BButtonTypeBathyScapheBlue];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    // 手っ取り早く背景を白にする
    m_baseView.wantsLayer = YES;
    CGColorRef white = CGColorCreateGenericGray(1.0f, 1.0f);
    m_baseView.layer.backgroundColor = white;
    CGColorRelease(white);
    
    // 下の区切り線
    CALayer *bottomBorder = [CALayer layer];
    CGColorRef gray = CGColorCreateGenericGray(0.75f, 1.0f);
    bottomBorder.borderColor = gray;
    CGColorRelease(gray);
    bottomBorder.borderWidth = 1.0f;
    CGRect baseViewFrame = NSRectToCGRect(m_baseView.frame);
    bottomBorder.frame = CGRectMake(-1.f, .0f, CGRectGetWidth(baseViewFrame) + 2.f, CGRectGetHeight(baseViewFrame) + 1.f);
    [m_baseView.layer addSublayer:bottomBorder];
}

- (IBAction)showQuickstart:(id)sender
{
    [[NSApp delegate] showQuickStart:sender];
    [[self window] performClose:sender];
}

- (IBAction)showWhatsnew:(id)sender
{
    [[NSApp delegate] showWhatsnew:sender];
    [[self window] performClose:sender];
}

- (IBAction)closeIntro:(id)sender
{
    [[self window] performClose:sender];
}
@end
