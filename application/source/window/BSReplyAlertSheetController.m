//
//  BSReplyAlertSheetController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/02/10.
//  Copyright 2008-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSReplyAlertSheetController.h"
#import "CocoMonar_Prefix.h"

NSString *const kAlertMessageTextKey = @"messageText";
NSString *const kAlertInformativeTextKey = @"informativeText";
NSString *const kAlertAgreementTextKey = @"agreementText";
NSString *const kAlertIsContributionKey = @"isContribution";
NSString *const kAlertFirstButtonLabelKey = @"firstButtonLabel";
NSString *const kAlertSecondButtonLabelKey = @"secondButtonLabel";

@implementation BSReplyAlertSheetController
- (NSString *)windowNibName
{
    return @"BSReplyAlertSheet";
}

- (id)init
{
	if (self = [super initWithWindowNibName:[self windowNibName]]) {
		[self window];
	}
	return self;
}

- (void)dealloc
{
	[self setAlertContent:nil]; // -dealloc でのアクセサ使用禁止対象外
	[m_helpAnchor release];
	[super dealloc];
}

- (NSString *)helpAnchor
{
	return m_helpAnchor;
}

- (void)setHelpAnchor:(NSString *)anchor
{
	[anchor retain];
	[m_helpAnchor release];
	m_helpAnchor = anchor;
}

- (id)alertContent
{
	return [alertContentController content];
}

- (void)setAlertContent:(id)content
{
	[alertContentController setContent:content];
}

- (IBAction)endSheetWithCodeAsTag:(id)sender
{
	[[self window] orderOut:sender];
	[NSApp endSheet:[self window] returnCode:[sender tag]];
}

- (void)showHelp:(id)sender
{
	[[NSHelpManager sharedHelpManager] openHelpAnchor:[self helpAnchor] inBook:[NSBundle applicationHelpBookName]];
}
@end
