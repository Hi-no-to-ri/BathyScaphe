//
//  p22chAuthenticator.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/06/01.
//  Copyright 2013-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "p22chAuthenticator.h"
#import <SGFoundation/String+Utils.h>
#import <CocoMonar/CMRSingletonObject.h>
#import "LoginController.h"


static AppDefaults *st_defaults = nil;

@interface p22chAuthenticator(private)
+ (AppDefaults *)preferences;
- (AppDefaults *)preferences;

- (void)setCookieHeader:(NSString *)cookieString;
- (void)setLastError:(NSError *)error;
- (BOOL)loginWithUserName:(NSString *)userName password:(NSString *)password error:(NSError **)error;

- (NSError *)errorFromLoginFailedHtmlData:(NSData *)data;
@end


@implementation p22chAuthenticator(private)
+ (AppDefaults *)preferences
{
	return st_defaults;
}

- (AppDefaults *)preferences
{
	return [[self class] preferences];
}

- (void)setCookieHeader:(NSString *)cookieString
{
    [cookieString retain];
    [cookieHeader release];
    cookieHeader = cookieString;
}

- (void)setLastError:(NSError *)error
{
    [error retain];
    [lastError release];
    lastError = error;
}

- (BOOL)loginWithUserName:(NSString *)userName password:(NSString *)password error:(NSError **)error
{
    NSError *underlyingError;
    NSURL *loginUrl = [NSURL URLWithString:@"http://p2.2ch.sc/p2/"];
    NSXMLDocument *xmlDoc = [[[NSXMLDocument alloc] initWithContentsOfURL:loginUrl options:NSXMLDocumentTidyHTML error:&underlyingError] autorelease];
    if (!xmlDoc) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 1);
        }
        return NO;
    }
    
    NSArray *objects = [xmlDoc objectsForXQuery:@".//form[@action and @id=\"login\"]" error:&underlyingError];
    if (!objects || [objects count] == 0) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 2);
        }
        return NO;
    }
    
    NSArray *forms = [[objects objectAtIndex:0] objectsForXQuery:@".//input[@name and @value]" error:&underlyingError];
    if (!forms) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 3);
        }
        return NO;
    }
    
    NSMutableString *bodyString = [NSMutableString string];
    for (id form in forms) {
        NSString *formName = [[form attributeForName:@"name"] stringValue];
        NSString *formValue;
        if ([formName isEqualToString:@"form_login_id"]) {
            formValue = userName;
        } else if ([formName isEqualToString:@"form_login_pass"]) {
            formValue = password;
        } else {
            formValue = [[form attributeForName:@"value"] stringValue];
        }
        formValue = [formValue stringByURIEncodedUsingCFEncoding:kCFStringEncodingDOSJapanese convertToCharRefIfNeeded:NO unableToEncode:NULL];
        [bodyString appendFormat:@"%@=%@&", formName, formValue];
    }
    
    NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] initWithURL:loginUrl] autorelease];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[bodyString dataUsingEncoding:NSASCIIStringEncoding]];
    [urlRequest setHTTPShouldHandleCookies:NO];
    
    NSURLResponse *response;
    NSData *result = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&underlyingError];
    if (!result) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 4);
        }
        return NO;
    }
    NSString *setCookieHeader = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Set-Cookie"];
    if (!setCookieHeader) {
        if (error != NULL) {
            *error = [self errorFromLoginFailedHtmlData:result];
        }
        return NO;
    }
    
    self.cookieHeader = setCookieHeader;
    self.actualHost = [[response URL] host];
    
    return YES;
}

- (NSError *)errorFromLoginFailedHtmlData:(NSData *)data
{
    NSError *error;
    NSXMLDocument *xmlDoc = [[[NSXMLDocument alloc] initWithData:data options:NSXMLDocumentTidyHTML error:&error] autorelease];
    if (!xmlDoc) {
        return errorWithUnderlyingCocoaError(error, 21);
    }
    
    NSArray *objects = [xmlDoc objectsForXQuery:@".//p[@class=\"infomsg\"]" error:&error];
    if (!objects) {
        return errorWithUnderlyingCocoaError(error, 22);
    }
    
    NSMutableString *string = [NSMutableString string];
    for (id pObj in objects) {
        [string appendString:[pObj stringValue]];
    }
    return [NSError errorWithDomain:SG2chErrorHandlerErrorDomain code:BSP22chLoginFailedError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:string, NSLocalizedFailureReasonErrorKey, nil]];
}

- (BOOL)runModalForLoginWindow:(NSString **)mailAddressPtr password:(NSString **)passwordPtr shouldUseKeychain:(BOOL *)savePassPtr
{
	NSString			*account_;
	NSString			*password_;
	LoginController		*lgin_;
	BOOL				result_;
	
	if (mailAddressPtr != NULL) *mailAddressPtr = nil;
	if (passwordPtr != NULL) *passwordPtr = nil;
    
	lgin_ = [[LoginController alloc] initWithType:BSKeychainAccountP22chNetAuth];
	result_ = [lgin_ runModalForLoginWindow:&account_ password:&password_ shouldUseKeychain:savePassPtr];
	[lgin_ release];
	
	if (!result_) {
        [self setLastError:[NSError errorWithDomain:BSBathyScapheErrorDomain code:BS2chConnectLoginUserCanceledError userInfo:nil]];
		return NO;
	}
	
	if (mailAddressPtr != NULL) *mailAddressPtr = account_;
	if (![[self preferences] p22chUserAccount] && account_) {
        [[self preferences] setP22chUserAccount:account_];
    }
	if (passwordPtr != NULL) *passwordPtr = password_;
	return YES;
}

- (BOOL)updateMailAddress:(NSString **)newAccountPtr password:(NSString **)newPasswordPtr shouldUseKeychain:(BOOL *)savePassPtr
{
    NSString *currentMailAddress = [[self preferences] p22chUserAccount];
	if (currentMailAddress && [[self preferences] hasAccountInKeychain:BSKeychainAccountP22chNetAuth]) {
		if (newAccountPtr != NULL) *newAccountPtr = currentMailAddress;
		if (newPasswordPtr != NULL) *newPasswordPtr = [[self preferences] passwordForType:BSKeychainAccountP22chNetAuth error:NULL];
		if (savePassPtr != NULL) *savePassPtr = NO;
		return YES;
	} else {
		return [self runModalForLoginWindow:newAccountPtr password:newPasswordPtr shouldUseKeychain:savePassPtr];
	}
}

@end


@implementation p22chAuthenticator
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultAuthenticator)

@synthesize actualHost;

- (void)dealloc
{
    [actualHost release];
    [lastError release];
    [cookieHeader release];
    [super dealloc];
}

- (NSString *)cookieHeader
{
    return cookieHeader;
}

- (NSError *)lastError
{
    return lastError;
}

- (BOOL)invalidate
{
    NSString    *mailAddress;
    NSString    *password;
    BOOL        usesKeychain;

    [self setLastError:nil];
    [self setCookieHeader:nil];
    
    if (![self updateMailAddress:&mailAddress password:&password shouldUseKeychain:&usesKeychain]) {
        return NO;
    }
    
    NSError *error;
    
    if (![self loginWithUserName:mailAddress password:password error:&error] && error) {
        [self setLastError:error];
        return NO;
    } else {
        if (usesKeychain) {
            if (![[self preferences] changeAccount:mailAddress password:password forType:BSKeychainAccountP22chNetAuth error:&error] && error) {
                [[NSAlert alertWithError:error] runModal];
            }
        }
    }
    return YES;
}

+ (void)setPreferencesObject:(AppDefaults *)defaults
{
	st_defaults = defaults;
}
@end

NSError *errorWithUnderlyingCocoaError(NSError *cocoaError, NSUInteger pointNumber)
{
    NSError *error = [NSError errorWithDomain:SG2chErrorHandlerErrorDomain code:BSP22chLoginCocoaError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:cocoaError, NSUnderlyingErrorKey, [NSNumber numberWithUnsignedInteger:pointNumber], BSP22chErrorPointCodeKey, nil]];
    return error;
}
