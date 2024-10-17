//
//  CMRKeychainManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/01/13.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRKeychainManager.h"
#import "CocoMonar_Prefix.h"
#import "AppDefaults.h"
#import <AppKit/NSApplication.h>
#import <Security/Security.h>

@implementation CMRKeychainManager

@synthesize shouldCheckHasAccountInKeychain = m_shouldCheckHasAccountInKeychain;

APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (id)init
{
    if (self = [super init]) {
        m_shouldCheckHasAccountInKeychain = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive:)
                                                     name:NSApplicationDidBecomeActiveNotification
                                                   object:NSApp];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark Private
- (NSURL *)x2chAuthenticationRequestURL
{
    return [CMRPref x2chAuthenticationRequestURL];
}

- (NSURL *)be2chAuthenticationRequestURL
{
    return [CMRPref be2chAuthenticationRequestURL];
}

- (NSString *)accountForType:(BSKeychainAccountType)type
{
    return [CMRPref accountForType:type];
}

- (void)setHasAccountInKeychain:(BOOL)inKeychain forType:(BSKeychainAccountType)type
{
    [CMRPref setHasAccountInKeychain:inKeychain forType:type];
}

- (NSError *)errorFromKeychainServiceErr:(OSStatus)err
{
    NSInteger errCode = ((err == errSecItemNotFound) ? CMRKeychainManagerKeychainItemNotExistError : CMRKeychainManagerKeychainServiceError);
    CFStringRef errStrRef = SecCopyErrorMessageString(err, NULL);
    NSString *errorDescription = NSLocalizedStringFromTable(@"Keychain operation failed", @"KeychainManager", @"Keychain operation failed");
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorDescription, NSLocalizedDescriptionKey, (NSString *)errStrRef, NSLocalizedFailureReasonErrorKey, nil];
    CFRelease(errStrRef);
    return [NSError errorWithDomain:BSBathyScapheErrorDomain code:errCode userInfo:userInfo];
}

- (BOOL)checkAccountCondition:(NSString *)account error:(NSError **)errorPtr
{
    if (!account || [account length] == 0) {
        if (errorPtr != NULL) {
            *errorPtr = [NSError errorWithDomain:BSBathyScapheErrorDomain code:CMRKeychainManagerNoAccountError userInfo:nil];
        }
        return NO;
    }
    return YES;
}

- (BOOL)getKeychainItem:(SecKeychainItemRef *)itemRef forType:(BSKeychainAccountType)type error:(NSError **)errorPtr
{
    NSString *account = [self accountForType:type];
    if (![self checkAccountCondition:account error:errorPtr]) {
        return NO;
    }
    
    const char  *accountUTF8 = [account UTF8String];
    OSStatus    err;

    if (type == BSKeychainAccountP22chNetAuth) {
        const char  *serviceName = "jp.tsawada2.BathyScaphe.password.p22ch";
        
        err = SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, strlen(accountUTF8), accountUTF8, NULL, NULL, itemRef);
        if (err == noErr) {
            return YES;
        } else {
            if (errorPtr != NULL) {
                *errorPtr = [self errorFromKeychainServiceErr:err];
            }
            return NO;
        }
    } else {
        NSURL *url_ = nil;
        SecProtocolType protocolType;
        if (type == BSKeychainAccountX2chAuth) {
            url_ = [self x2chAuthenticationRequestURL];
            protocolType = kSecProtocolTypeHTTPS;
        } else if (type == BSKeychainAccountBe2chAuth) {
            url_ = [self be2chAuthenticationRequestURL];
            protocolType = kSecProtocolTypeHTTP;
        }
        if (!url_) {
            return NO;
        }
        NSString    *host_ = [url_ host];
        NSString    *path_ = [url_ path];
        
        const char  *hostUTF8 = [host_ UTF8String];
        const char  *pathUTF8 = [path_ UTF8String];
        
        err = SecKeychainFindInternetPassword(NULL,
                                              strlen(hostUTF8),
                                              hostUTF8,
                                              0,
                                              NULL,
                                              strlen(accountUTF8),
                                              accountUTF8,
                                              strlen(pathUTF8),
                                              pathUTF8,
                                              0,
                                              protocolType,
                                              kSecAuthenticationTypeDefault,
                                              NULL,
                                              NULL,
                                              itemRef);
        
        if (err == noErr) {
            return YES;
        } else {
            if (errorPtr != NULL) {
                *errorPtr = [self errorFromKeychainServiceErr:err];
            }
            return NO;
        }
    }
    return NO;
}

- (void)checkHasAccountInKeychainImpl:(BSKeychainAccountType)type
{
    SecKeychainItemRef item = NULL;
    NSError *error = nil;
    BOOL result;
    
    NSString *account = [self accountForType:type];
    if (![self checkAccountCondition:account error:NULL]) {
        result = NO;
    } else {
        result = [self getKeychainItem:&item forType:type error:&error];
        if (result) {
            CFRelease(item);
        } else {
            if (error && ([error code] != CMRKeychainManagerKeychainItemNotExistError)) {
                [NSApp presentError:error];
            }
        }
    }

    [self setHasAccountInKeychain:result forType:type];
}    

#pragma mark Public
- (void)checkHasAccountInKeychainIfNeeded
{
    if ([self shouldCheckHasAccountInKeychain]) {
        [self checkHasAccountInKeychainImpl:BSKeychainAccountX2chAuth];
        [self checkHasAccountInKeychainImpl:BSKeychainAccountBe2chAuth];
        [self checkHasAccountInKeychainImpl:BSKeychainAccountP22chNetAuth];
        [self setShouldCheckHasAccountInKeychain:NO];
    }
}

- (BOOL)deletePasswordForType:(BSKeychainAccountType)type error:(NSError **)errorPtr
{
    SecKeychainItemRef  item;
    NSError             *underlyingError = nil;
    
    if ([self getKeychainItem:&item forType:type error:&underlyingError]) {
        OSStatus err;
        err = SecKeychainItemDelete(item);
        CFRelease(item);
        
        if (err == noErr) {
            [self setHasAccountInKeychain:NO forType:type];
            return YES;
        } else {
            if (errorPtr != NULL) {
                *errorPtr = [self errorFromKeychainServiceErr:err];
            }
            return NO;
        }
        
    } else {
        if (underlyingError && ([underlyingError code] == CMRKeychainManagerKeychainItemNotExistError)) {
            [self setHasAccountInKeychain:NO forType:type];
            return YES;
        } else {
            if (errorPtr != NULL) {
                *errorPtr = underlyingError;
            }
            return NO;
        }
    }
    
    return NO;
}

- (NSString *)passwordFromKeychain:(BSKeychainAccountType)type error:(NSError **)errorPtr
{
    NSString *account = [self accountForType:type];
    if (![self checkAccountCondition:account error:errorPtr]) {
        return nil;
    }

    OSStatus    err;
    const char  *accountUTF8 = [account UTF8String];
    UInt32      passwordLength;
    char        *passwordData;

    if (type == BSKeychainAccountP22chNetAuth) {
        const char  *serviceName = "jp.tsawada2.BathyScaphe.password.p22ch";
        
        err = SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, strlen(accountUTF8), accountUTF8, &passwordLength, (void **)&passwordData, NULL);
        
        if (err == noErr) {
            NSString *passwordString = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
            SecKeychainItemFreeContent(NULL, passwordData);
            return [passwordString autorelease];
        } else {
            if (errorPtr != NULL) {
                *errorPtr = [self errorFromKeychainServiceErr:err];
            }
            return nil;
        }
    } else {
        NSURL *url_ = nil;
        SecProtocolType protocolType;
        if (type == BSKeychainAccountX2chAuth) {
            url_ = [self x2chAuthenticationRequestURL];
            protocolType = kSecProtocolTypeHTTPS;
        } else if (type == BSKeychainAccountBe2chAuth) {
            url_ = [self be2chAuthenticationRequestURL];
            protocolType = kSecProtocolTypeHTTP;
        }
        if (!url_) {
            return nil;
        }

        NSString        *host_ = [url_ host];
        NSString        *path_ = [url_ path];

        const char      *hostUTF8 = [host_ UTF8String];
        const char      *pathUTF8 = [path_ UTF8String];

        err = SecKeychainFindInternetPassword(NULL,
                                              strlen(hostUTF8),
                                              hostUTF8,
                                              0,
                                              NULL,
                                              strlen(accountUTF8),
                                              accountUTF8,
                                              strlen(pathUTF8),
                                              pathUTF8,
                                              0,
                                              protocolType,
                                              kSecAuthenticationTypeDefault,
                                              &passwordLength,
                                              (void **)&passwordData,
                                              NULL);

        if (err == noErr) {
            NSString *result_ = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
            SecKeychainItemFreeContent(NULL, passwordData);
            return [result_ autorelease];
        } else {
            if (errorPtr != NULL) {
                *errorPtr = [self errorFromKeychainServiceErr:err];
            }
            return nil;
        }
    }
    return nil;
}

- (BOOL)addPassword:(NSString *)password forType:(BSKeychainAccountType)type error:(NSError **)errorPtr
{
    if (!password || [password length] == 0) {
        return NO;
    }
    
    const char          *passwordUTF8 = [password UTF8String];
    UInt32              passwordLength = strlen(passwordUTF8);
    SecKeychainItemRef  item;
    NSError             *underlyingError = nil;
    
    if ([self getKeychainItem:&item forType:type error:&underlyingError]) {
        OSStatus err;
        err = SecKeychainItemModifyContent(item, NULL, passwordLength, passwordUTF8);
        CFRelease(item);
        
        if (err == noErr) {
            [self setHasAccountInKeychain:YES forType:type];
            return YES;
        } else {
            if (errorPtr != NULL) {
                *errorPtr = [self errorFromKeychainServiceErr:err];
            }
            return NO;
        }
        
    } else {
        if (underlyingError && ([underlyingError code] == CMRKeychainManagerKeychainItemNotExistError)) {
            // 新規作成
            NSString *account = [self accountForType:type];
            if (![self checkAccountCondition:account error:errorPtr]) {
                return NO;
            }
            
            OSStatus    err;
            const char  *accountUTF8 = [account UTF8String];

            if (type == BSKeychainAccountP22chNetAuth) {
                const char  *serviceName = "jp.tsawada2.BathyScaphe.password.p22ch";

                err = SecKeychainAddGenericPassword(NULL, strlen(serviceName), serviceName, strlen(accountUTF8), accountUTF8, passwordLength, passwordUTF8, NULL);
                if (err == noErr) {
                    [self setHasAccountInKeychain:YES forType:type];
                    return YES;
                } else {
                    if (errorPtr != NULL) {
                        *errorPtr = [self errorFromKeychainServiceErr:err];
                    }
                    return NO;
                }
            } else {
                NSURL *url_ = nil;
                SecProtocolType protocolType;
                if (type == BSKeychainAccountX2chAuth) {
                    url_ = [self x2chAuthenticationRequestURL];
                    protocolType = kSecProtocolTypeHTTPS;
                } else if (type == BSKeychainAccountBe2chAuth) {
                    url_ = [self be2chAuthenticationRequestURL];
                    protocolType = kSecProtocolTypeHTTP;
                }
                if (!url_) {
                    return NO;
                }
                NSString        *host_ = [url_ host];
                NSString        *path_ = [url_ path];
                
                const char      *hostUTF8 = [host_ UTF8String];
                const char      *pathUTF8 = [path_ UTF8String];
                
                err = SecKeychainAddInternetPassword(NULL,
                                                     strlen(hostUTF8),
                                                     hostUTF8,
                                                     0,
                                                     NULL,
                                                     strlen(accountUTF8),
                                                     accountUTF8,
                                                     strlen(pathUTF8),
                                                     pathUTF8,
                                                     0,
                                                     protocolType,
                                                     kSecAuthenticationTypeDefault,
                                                     passwordLength,
                                                     passwordUTF8,
                                                     NULL);
                if (err == noErr) {
                    [self setHasAccountInKeychain:YES forType:type];
                    return YES;
                } else {
                    if (errorPtr != NULL) {
                        *errorPtr = [self errorFromKeychainServiceErr:err];
                    }
                    return NO;
                }
            }
        }
    }
    
    return NO;
}

#pragma mark Notifications
- (void)applicationDidBecomeActive:(NSNotification *)theNotification
{
    UTILAssertNotificationName(theNotification, NSApplicationDidBecomeActiveNotification);
    UTILAssertNotificationObject(theNotification, NSApp);

    [self setShouldCheckHasAccountInKeychain:YES];
}
@end
