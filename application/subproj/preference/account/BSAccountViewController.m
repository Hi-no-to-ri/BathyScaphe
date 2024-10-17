//
//  BSAccountViewContorller.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2014/05/04.
//
//

#import "BSAccountViewController.h"
#import "AppDefaults.h"
#import "PreferencePanes_Prefix.h"

@interface BSAccountViewController ()

@end

@implementation BSAccountViewController

@synthesize parentPrefController = _parentPrefController;
@synthesize accountType = _accountType;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        _isPasswordFilled = NO;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    [self updateUIComponents];
}

- (NSString *)localizedAccountKindForType:(BSKeychainAccountType)type
{
    if (type == BSKeychainAccountX2chAuth) {
        return PPLocalizedString(@"Account x2ch");
    } else if (type == BSKeychainAccountBe2chAuth) {
        return PPLocalizedString(@"Account be2ch");
    } else if (type == BSKeychainAccountP22chNetAuth) {
        return PPLocalizedString(@"Account p22ch");
    }
    return nil;
}

- (NSString *)localizedPasswordKindForType:(BSKeychainAccountType)type
{
    if (type == BSKeychainAccountX2chAuth) {
        return PPLocalizedString(@"Password x2ch");
    } else if (type == BSKeychainAccountBe2chAuth) {
        return PPLocalizedString(@"Password be2ch");
    } else if (type == BSKeychainAccountP22chNetAuth) {
        return PPLocalizedString(@"Password p22ch");
    }
    return nil;
}

- (NSString *)localizedMoreInfoURLStringForType:(BSKeychainAccountType)type
{
    if (type == BSKeychainAccountX2chAuth) {
        return PPLocalizedString(@"mi_ronin");
    } else if (type == BSKeychainAccountBe2chAuth) {
        return PPLocalizedString(@"mi_be2ch");
    } else if (type == BSKeychainAccountP22chNetAuth) {
        return PPLocalizedString(@"mi_p22ch_sc");
    }
    return nil;
}

- (void)updatePasswordField
{
    NSError *error = nil;
    NSString *password;
    
    password = [[[self parentPrefController] preferences] passwordForType:[self accountType] error:&error];
    if (error) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:[NSString stringWithFormat:PPLocalizedString(@"Can't get password Message"), [self localizedPasswordKindForType:[self accountType]]]];
        [alert setInformativeText:[error localizedFailureReason]];
        [alert runModal];
    }
    [passwordField setStringValue:(password ?: @"")];
}

- (void)updateUIComponents
{
    BSKeychainAccountType type = [self accountType];
    if (type == BSKeychainAccountX2chAuth) {
        [accountField setStringValue:([[[self parentPrefController] preferences] x2chUserAccount] ?: @"")];
    } else if (type == BSKeychainAccountBe2chAuth) {
        [accountField setStringValue:([[[self parentPrefController] preferences] be2chAccountMailAddress] ?: @"")];
    } else if (type == BSKeychainAccountP22chNetAuth) {
        [accountField setStringValue:([[[self parentPrefController] preferences] p22chUserAccount] ?: @"")];
    }
    if (!_isPasswordFilled) {
        [self updatePasswordField];
        _isPasswordFilled = YES;
    }
}

- (IBAction)accountChanged:(id)sender
{
    BSKeychainAccountType type = [self accountType];
    NSString *currentAccount = [[[self parentPrefController] preferences] accountForType:type];
    NSString *nextAccount = [sender stringValue];
    
    BOOL inKeychain = [[[self parentPrefController] preferences] hasAccountInKeychain:type];
    
    if (!currentAccount) {
        if ([nextAccount length] > 0) {
            [[[self parentPrefController] preferences] setAccount:nextAccount forType:type];
        }
        return;
    }
    
    if ([nextAccount isEqualToString:currentAccount]) {
        return;
    } else {
        if ([nextAccount isEmpty]) {
            if (inKeychain) {
                // Are you sure you want to delete account (including password) completely?
                // if YES,
                // 1. delete password from keychain
                // 2. delete account (via AppDefaults)
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setAlertStyle:NSCriticalAlertStyle];
                [alert setMessageText:[NSString stringWithFormat:PPLocalizedString(@"Empty Account Message"), [self localizedAccountKindForType:type]]];
                [alert setInformativeText:PPLocalizedString(@"Empty Account Info")];
                [alert addButtonWithTitle:PPLocalizedString(@"Empty Account Cancel")];
                [alert addButtonWithTitle:PPLocalizedString(@"Empty Account Delete")];
                if ([alert runModal] == NSAlertSecondButtonReturn) {
                    if ([[[self parentPrefController] preferences] setPassword:nil forType:type error:NULL]) {
                        [[[self parentPrefController] preferences] setAccount:nil forType:type];
                    }
                }
                [self updateUIComponents];
            } else {
                [[[self parentPrefController] preferences] setAccount:nextAccount forType:type];
            }
        } else {
            if (inKeychain) {
                // 1. delete password from keychain
                // 2. set account (AppDefaults)
                // 3. add password to keychain
                NSString *currentPassword = nil;
                if (sender == accountField) {
                    currentPassword = [passwordField stringValue];
                }
                
                NSString *tmp = [currentPassword copy];
                if ([[[self parentPrefController] preferences] setPassword:nil forType:type error:NULL]) {
                    [[[self parentPrefController] preferences] setAccount:nextAccount forType:type];
                    [[[self parentPrefController] preferences] setPassword:tmp forType:type error:NULL];
                }
                [tmp release];
            } else {
                [[[self parentPrefController] preferences] setAccount:nextAccount forType:type];
            }
        }
    }
}

- (IBAction)passwordChanged:(id)sender
{
    BSKeychainAccountType type = [self accountType];
    
    NSError *error = nil;
    if (![[[self parentPrefController] preferences] setPassword:[sender stringValue] forType:type error:&error] && error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:[[self parentPrefController] window] modalDelegate:self didEndSelector:NULL contextInfo:NULL];
    }
}

- (IBAction)showMoreInfo:(id)sender
{
    BSKeychainAccountType type = [self accountType];
    NSString *urlString = [self localizedMoreInfoURLStringForType:type];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if (control == passwordField) {
        _isPasswordFilled = NO;
    }
    return YES;
}
@end
