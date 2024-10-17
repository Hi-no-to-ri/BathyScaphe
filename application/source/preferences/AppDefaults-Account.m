// encoding="UTF-8"

#import "AppDefaults_p.h"
#import "CMRKeychainManager.h"

#define APP_X2CH_AUTHENTICATION_REQUEST_KEY	@"System - 2channel Auth URL"

static NSString *const st_AppDefaultsX2chUserAccountKey = @"Account";
static NSString *const st_AppDefaultsUsesKeychainKey = @"Uses Keychain";
static NSString *const st_AppDefaultsUsesKeychainBeKey = @"Uses Keychain (Be)";
static NSString *const st_AppDefaultsUsesKeychainP2Key = @"Uses Keychain (p2.2ch.net)";
static NSString *const st_AppDefaultsShouldLoginKey = @"Should Login";
static NSString *const st_AppDefaultsUsesP22chKey = @"Uses p2.2ch.net";

static NSString *const st_AppDefaultsBe2chMailAddressKey = @"Be2ch Mail Address";
//static NSString *const st_AppDefaultsBe2chCodeKey = @"Be2ch Authorization Code";

static NSString *const st_AppDefaultsP22chUserAccountKey = @"P22ch Account";

static NSString *const st_AppDefaultsShouldLoginBe2chAnytimeKey = @"Always Login(Be-2ch)";

@implementation AppDefaults(Account)
- (NSURL *)URLForKey:(NSString *)aKey
{
    NSString *loc = SGTemplateResource(aKey);
    NSURL *URL = nil;
    
NS_DURING
    URL = [NSURL URLWithString:loc];
NS_HANDLER
    URL = nil;
NS_ENDHANDLER
    return URL;
}

- (void)loadAccountSettings
{
	;
}

#pragma mark Account Data Accessors
- (NSURL *)x2chAuthenticationRequestURL
{
    return [self URLForKey:APP_X2CH_AUTHENTICATION_REQUEST_KEY];
}

- (NSString *)x2chUserAccount
{
	return [[self defaults] stringForKey:st_AppDefaultsX2chUserAccountKey];
}

- (void)setX2chUserAccount:(NSString *)account
{
	if (!account || [account length] == 0) {
		[[self defaults] removeObjectForKey:st_AppDefaultsX2chUserAccountKey];
		return;
	}
	[[self defaults] setObject:account forKey:st_AppDefaultsX2chUserAccountKey];
}

- (NSString *)passwordForType:(BSKeychainAccountType)type
{
    return [self passwordForType:type error:NULL];
}

- (NSString *)passwordForType:(BSKeychainAccountType)type error:(NSError **)errorPtr
{
    if (![self hasAccountInKeychain:type]) {
        return nil;
    }
    return [[CMRKeychainManager defaultManager] passwordFromKeychain:type error:errorPtr];
}

- (NSString *)be2chAccountMailAddress
{
	return [[self defaults] stringForKey:st_AppDefaultsBe2chMailAddressKey];
}

- (void)setBe2chAccountMailAddress:(NSString *)address
{
	if (!address || [address length] == 0) {
		[[self defaults] removeObjectForKey:st_AppDefaultsBe2chMailAddressKey];
		return;
	}
	[[self defaults] setObject:address forKey:st_AppDefaultsBe2chMailAddressKey];
}

- (NSString *)p22chUserAccount
{
    return [[self defaults] stringForKey:st_AppDefaultsP22chUserAccountKey];
}

- (void)setP22chUserAccount:(NSString *)account
{
    if (!account || [account length] == 0) {
        [[self defaults] removeObjectForKey:st_AppDefaultsP22chUserAccountKey];
        return;
    }
    [[self defaults] setObject:account forKey:st_AppDefaultsP22chUserAccountKey];
}

- (NSURL *)be2chAuthenticationRequestURL
{
    return [self URLForKey:@"System - be2ch Auth URL"];
}

- (NSString *)be2chAuthenticationFormFormat
{
    return SGTemplateResource(@"System - be2ch Auth Format");
}

- (NSString *)accountForType:(BSKeychainAccountType)type
{
    if (type == BSKeychainAccountX2chAuth) {
        return [self x2chUserAccount];
    } else if (type == BSKeychainAccountBe2chAuth) {
        return [self be2chAccountMailAddress];
    } else if (type == BSKeychainAccountP22chNetAuth) {
        return [self p22chUserAccount];
    }
    return nil;
}

- (void)setAccount:(NSString *)account forType:(BSKeychainAccountType)type
{
    if (type == BSKeychainAccountX2chAuth) {
        [self setX2chUserAccount:account];
    } else if (type == BSKeychainAccountBe2chAuth) {
        [self setBe2chAccountMailAddress:account];
    } else if (type == BSKeychainAccountP22chNetAuth) {
        [self setP22chUserAccount:account];
    }
}

#pragma mark Account Settings Accessors
- (BOOL)shouldLoginIfNeeded
{
	return [[self defaults] boolForKey:st_AppDefaultsShouldLoginKey defaultValue:DEFAULT_LOGIN_MARU_IF_NEEDED];
}

- (void)setShouldLoginIfNeeded:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:st_AppDefaultsShouldLoginKey];
}

- (BOOL)shouldLoginBe2chAnyTime
{
	return [[self defaults] boolForKey:st_AppDefaultsShouldLoginBe2chAnytimeKey defaultValue:DEFAULT_LOGIN_BE_ANY_TIME];
}

- (void)setShouldLoginBe2chAnyTime:(BOOL)flag
{
	[[self defaults] setBool:flag forKey:st_AppDefaultsShouldLoginBe2chAnytimeKey];
}

- (BOOL)usesP22chForReply
{
    return [[self defaults] boolForKey:st_AppDefaultsUsesP22chKey defaultValue:DEFAULT_LOGIN_P22CH];
}

- (void)setUsesP22chForReply:(BOOL)flag
{
    [[self defaults] setBool:flag forKey:st_AppDefaultsUsesP22chKey];
}

- (BOOL)hasAccountInKeychain:(BSKeychainAccountType)type
{
    NSString *key;
	[[CMRKeychainManager defaultManager] checkHasAccountInKeychainIfNeeded];
    if (type == BSKeychainAccountX2chAuth) {
        key = st_AppDefaultsUsesKeychainKey;
    } else if (type == BSKeychainAccountBe2chAuth) {
        key = st_AppDefaultsUsesKeychainBeKey;
    } else if (type == BSKeychainAccountP22chNetAuth) {
        key = st_AppDefaultsUsesKeychainP2Key;
    } else {
        return NO;
    }

	return [[self defaults] boolForKey:key defaultValue:DEFAULT_USE_KEYCHAIN];
}

- (void)setHasAccountInKeychain:(BOOL)usesKeychain forType:(BSKeychainAccountType)type
{
    NSString *key;
    if (type == BSKeychainAccountX2chAuth) {
        key = st_AppDefaultsUsesKeychainKey;
    } else if (type == BSKeychainAccountBe2chAuth) {
        key = st_AppDefaultsUsesKeychainBeKey;
    } else if (type == BSKeychainAccountP22chNetAuth) {
        key = st_AppDefaultsUsesKeychainP2Key;
    } else {
        return;
    }
    [[self defaults] setBool:usesKeychain forKey:key];
}

- (BOOL)availableBe2chAccount
{
	NSString	*dmdm_;
	dmdm_ = [self be2chAccountMailAddress];
	if (!dmdm_ || [dmdm_ length] == 0) {
        return NO;
    }
	return YES;
}

- (BOOL)setPassword:(NSString *)password forType:(BSKeychainAccountType)type error:(NSError **)errorPtr
{
    if ([self hasAccountInKeychain:type]) {
        if (!password || [password length] == 0) {
            return [[CMRKeychainManager defaultManager] deletePasswordForType:type error:errorPtr];
        }
    }
    return [[CMRKeychainManager defaultManager] addPassword:password forType:type error:errorPtr];
}

#pragma mark For Login Dialog
- (BOOL)changeAccount:(NSString *)newAccount password:(NSString *)newPassword forType:(BSKeychainAccountType)type error:(NSError **)errorPtr
{
    // チェックは呼び出し側で済ませておくべき。ここではアサーションしかしない
    NSAssert((newAccount && [newAccount length]), @"account must be filled");
    NSAssert((newPassword && [newPassword length]), @"password must be filled");

    NSString *backup = [NSString stringWithString:[self accountForType:type]];
    
    [self setAccount:newAccount forType:type];

	if (![[CMRKeychainManager defaultManager] addPassword:newPassword forType:type error:errorPtr]) {
        // パスワードが更新できなかった。アカウントを元に戻す
        [self setAccount:backup forType:type];
        return NO;
    }
    
    return YES;
}
@end
