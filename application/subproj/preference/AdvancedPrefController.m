//
//  AdvancedPrefController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/05/22.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "AdvancedPrefController.h"
#import "PreferencePanes_Prefix.h"

static NSString *const kAdvancedPaneLabelKey = @"Advanced Label";
static NSString *const kAdvancedPaneToolTipKey = @"Advanced ToolTip";
static NSString *const kAdvancedPaneHelpAnchorKey = @"Help_Advanced";

@interface NSObject(CMRAppDelegateStub)
- (void)runBoardWarrior:(id)sender;
@end


@implementation AdvancedPrefController
- (NSString *)mainNibName
{
	return @"AdvancedPreferences";
}

- (NSComboBox *)bbsMenuURLChooser
{
    return m_bbsMenuURLChooser;
}

- (void)updateUIComponents
{
    [[self bbsMenuURLChooser] setStringValue:[[[self preferences] BBSMenuURL] absoluteString]];
}

- (void)setupUIComponents
{
	if (!_contentView) {
        return;
    }
	[self updateUIComponents];
}

- (IBAction)didChooseBbsMenuURL:(id)sender
{
	NSString *typedText = [sender stringValue];
	NSString *currentURLStr = [[[self preferences] BBSMenuURL] absoluteString];

	if (!typedText || [typedText isEqualToString:@""]) {
		[sender setStringValue:currentURLStr];
		return;
	}

	if ([typedText isEqualToString:currentURLStr]) {
        return;
    }

	[[self preferences] setBBSMenuURL:[NSURL URLWithString:typedText]];
    [self performSelector:@selector(showConfirmSyncAlert:) withObject:sender afterDelay:0.3];
}

- (void)showConfirmSyncAlert:(id)sender
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:PPLocalizedString(@"Confirm Sync Alert Message")];
    [alert setInformativeText:PPLocalizedString(@"Confirm Sync Alert Informative")];
    [alert addButtonWithTitle:PPLocalizedString(@"Confirm Sync Alert OK")];
    [alert addButtonWithTitle:PPLocalizedString(@"Confirm Sync Alert Not Yet")];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[NSApp delegate] runBoardWarrior:sender];
    }
}
@end


@implementation AdvancedPrefController(Toolbar)
- (NSString *)identifier
{
	return PPAdvancedPreferencesIdentifier;
}
- (NSString *)helpKeyword
{
	return PPLocalizedString(kAdvancedPaneHelpAnchorKey);
}
- (NSString *)label
{
	return PPLocalizedString(kAdvancedPaneLabelKey);
}
- (NSString *)paletteLabel
{
	return PPLocalizedString(kAdvancedPaneLabelKey);
}
- (NSString *)toolTip
{
	return PPLocalizedString(kAdvancedPaneToolTipKey);
}
- (NSString *)imageName
{
	return NSImageNameAdvanced;
}
@end

