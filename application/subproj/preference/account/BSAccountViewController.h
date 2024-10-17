//
//  BSAccountViewContorller.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/05/04.
//
//

#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"

@interface BSAccountViewController : NSViewController {
    PreferencesController   *_parentPrefController;
    BSKeychainAccountType _accountType;

    IBOutlet NSTextField *accountField;
    IBOutlet NSSecureTextField *passwordField;

    BOOL _isPasswordFilled;
}

@property(readwrite, assign) PreferencesController *parentPrefController;
@property(readwrite, assign) BSKeychainAccountType accountType;

- (IBAction)accountChanged:(id)sender;
- (IBAction)passwordChanged:(id)sender;

- (IBAction)showMoreInfo:(id)sender;
@end
