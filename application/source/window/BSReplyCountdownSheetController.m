//
//  BSRepllCountdownSheetController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/02/11.
//  Copyright 2011-2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSReplyCountdownSheetController.h"
#import "AppDefaults.h"

#define LEVEL_INDICATOR_MAX_VALUE   20.0 // xib 上の NSLevelIndicator の max value

@implementation BSReplyCountdownSheetController
@synthesize timerCount = m_timerCount;
@synthesize indicatorValue = m_indicatorValue;

- (NSString *)windowNibName
{
    return @"BSReplyCountdownSheet";
}

- (id)init
{
    return [self initWithTimerCount:[CMRPref timeIntervalForNinjaFirstWait]];
}

- (id)initWithTimerCount:(NSTimeInterval)seconds
{
    if (self = [super init]) {
        self.timerCount = seconds;
        self.indicatorValue = LEVEL_INDICATOR_MAX_VALUE;
        [autoRetryCheckbox setEnabled:YES];
        [autoRetryCheckbox setState:([CMRPref autoRetryAfterNinjaFirstWait] ? NSOnState : NSOffState)];
        [retryButton setEnabled:NO];
        m_rate = (self.timerCount / LEVEL_INDICATOR_MAX_VALUE);
        m_timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdown:) userInfo:nil repeats:YES] retain];
    }
    return self;
}

- (void)countdown:(NSTimer *)aTimer
{
    self.timerCount = (self.timerCount - 1);
    self.indicatorValue = (self.timerCount / m_rate);
    if (self.timerCount == 0) {
        [aTimer invalidate];
        if ([autoRetryCheckbox state] == NSOnState) {
            [[self window] orderOut:nil];
            [CMRPref setAutoRetryAfterNinjaFirstWait:YES];
            [NSApp endSheet:[self window] returnCode:NSAlertFirstButtonReturn];
        } else {
            [CMRPref setAutoRetryAfterNinjaFirstWait:NO];
            [autoRetryCheckbox setEnabled:NO];
            [retryButton setEnabled:YES];
        }
    }
}

- (void)dealloc
{
    [m_timer invalidate];
    [m_timer release];
    [super dealloc];
}

- (IBAction)endSheetWithCodeAsTag:(id)sender
{
	[m_timer invalidate];
	[super endSheetWithCodeAsTag:sender];
}

// 暫定上書き
- (void)showHelp:(id)sender
{
    NSString *helpURL = SGTemplateResource(@"System - Reply Countdown Info URL");
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:helpURL]];
}
@end
