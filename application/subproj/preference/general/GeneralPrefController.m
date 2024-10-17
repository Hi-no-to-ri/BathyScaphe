//
//  GeneralPrefController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/07/19.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "GeneralPrefController.h"
#import "PreferencePanes_Prefix.h"


#define kLabelKey   @"General Label"
#define kToolTipKey @"General ToolTip"
// #define kImageName  @"GeneralPreferences"


@implementation GeneralPrefController
- (NSString *)mainNibName
{
    return @"GeneralPreferences";
}

- (IBAction)changeAutoscrollSettings:(id)sender
{
    CMRAutoscrollCondition mask = CMRAutoscrollNone;
 
    if ([[[self autoscrollRadioButtons] selectedCell] tag] == 0) {
        mask = CMRAutoscrollStandard;
    }

    [[self preferences] setThreadsListAutoscrollMask:mask];
}

- (NSMatrix *)autoscrollRadioButtons
{
    return m_autoscrollRadioButtons;
}

- (void)updateUIComponents
{
    CMRAutoscrollCondition mask = [[self preferences] threadsListAutoscrollMask];
    BOOL isScrollEnable = (mask != CMRAutoscrollNone);
    
    [[[self autoscrollRadioButtons] cellWithTag:0] setState:(isScrollEnable ? NSOnState : NSOffState)];
    [[[self autoscrollRadioButtons] cellWithTag:1] setState:(isScrollEnable ? NSOffState : NSOnState)];
}

- (void)setupUIComponents
{
    if (!_contentView) {
        return;
    }
    [self updateUIComponents];
}
@end


@implementation GeneralPrefController(Toolbar)
- (NSString *)identifier
{
    return PPGeneralPreferencesIdentifier;
}

- (NSString *)helpKeyword
{
    return PPLocalizedString(@"Help_General");
}

- (NSString *)label
{
    return PPLocalizedString(kLabelKey);
}

- (NSString *)paletteLabel
{
    return PPLocalizedString(kLabelKey);
}

- (NSString *)toolTip
{
    return PPLocalizedString(kToolTipKey);
}

- (NSString *)imageName
{
    return NSImageNamePreferencesGeneral; // kImageName;
}
@end
