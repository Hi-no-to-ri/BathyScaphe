//
//  CMRKeychainManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/01/13.
//  Copyright 2005-2011 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "AppDefaults.h"

@interface CMRKeychainManager : NSObject {
    BOOL m_shouldCheckHasAccountInKeychain;
}

+ (id)defaultManager;

- (void)checkHasAccountInKeychainIfNeeded;

// Kazusa-Ushiku New API
- (NSString *)passwordFromKeychain:(BSKeychainAccountType)type error:(NSError **)errorPtr;
- (BOOL)addPassword:(NSString *)password forType:(BSKeychainAccountType)type error:(NSError **)errorPtr;
- (BOOL)deletePasswordForType:(BSKeychainAccountType)type error:(NSError **)errorPtr;

@property(readwrite, assign) BOOL shouldCheckHasAccountInKeychain;

@end
