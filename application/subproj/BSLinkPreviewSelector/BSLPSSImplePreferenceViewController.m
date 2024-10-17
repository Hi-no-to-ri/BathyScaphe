//
//  BSLPSSImplePreferenceViewController.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 2012/12/27.
//  Copyright 2012 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSLPSSImplePreferenceViewController.h"

#import "BSLinkPreviewSelector.h"


@interface BSLPSSImplePreferenceViewController ()

@end

@implementation BSLPSSImplePreferenceViewController

- (id)init
{
	self = [super initWithNibName:@"BSLPSSImplePreferenceViewController"
						   bundle:[NSBundle bundleForClass:[self class]]];
	return self;
}


- (IBAction)showPreviewerPreference:(id)sender
{
//	[[BSLinkPreviewSelector sharedInstance] togglePreviewPanel:nil];
    [[BSLinkPreviewSelector sharedInstance] showPreviewerPreferences:nil];
}
@end
