//
//  p22chConnector.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/06/29.
//  encoding="UTF-8"
//

#import "p22chConnector.h"
#import "SG2chConnector_p.h"

@implementation p22chConnector
- (id)initWithUserInfo:(NSDictionary *)userInfo
{
    if ((self = [super init])) {
        m_userInfo = [userInfo copy];
        m_confirmationFormData = nil;
    }
    return self;
}

- (void)dealloc
{
    [m_userInfo release];
    [m_confirmationFormData release];
    [super dealloc];
}

#pragma mark Overrides
- (void)loadInBackground
{
    // サポートしないのでブロック
    NSLog(@"Oh! not supported! You should not call this method on p22chConnector.");
}

- (BOOL)writeForm:(NSDictionary *)forms
{
    // サポートしないのでブロック
    return NO;
}

#pragma mark P2 writing
- (NSDictionary *)userInfo
{
    return m_userInfo;
}

- (id)confirmationFormData
{
    return m_confirmationFormData;
}

- (void)setConfirmationFormData:(id)data
{
    [data retain];
    [m_confirmationFormData release];
    m_confirmationFormData = data;
}

- (BOOL)postUsingP22ch:(NSError **)error
{
    BOOL    isSuretate = NO;
    NSString *cookie = [[self userInfo] objectForKey:P22chPostUserInfoCookieKey];
    
    if (!cookie) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteUnknownError userInfo:nil];
        }
        return NO;
    }
    
    NSString *p2Host = [[self userInfo] objectForKey:P22chPostUserInfoActualHostKey];
    
    NSString *bbs = [[self userInfo] objectForKey:P22chPostUserInfoThreadBBSKey];
    NSString *host = [[self userInfo] objectForKey:P22chPostUserInfoThreadHostKey];
    
    NSString *datIdentifier = [[self userInfo] objectForKey:P22chPostUserInfoThreadIdKey];
    if (!datIdentifier) {
        if ([[self userInfo] objectForKey:P22chPostUserInfoSubjectKey]) {
            isSuretate = YES;
        } else {
            if (error != NULL) {
                *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteUnknownError userInfo:nil];
            }
            return NO;            
        }
    }
    
    if (m_confirmationFormData) {
        // 確認データのポストをすればよい
        NSString *confirmPostingBody = nil;
        NSString *confirmPostPath = nil;
        
        if (![self getEncodedConfirmationForm:&confirmPostingBody actionPath:&confirmPostPath error:error]) {
            return NO;
        }
//        NSLog(@"check body:\n%@\n\nactionPath=%@", confirmPostingBody, confirmPostPath);
        
        return [self postToHost:p2Host path:confirmPostPath data:confirmPostingBody cookie:cookie error:error];
    }
    
    NSError *underlyingError;
    
    NSMutableDictionary *forms = [NSMutableDictionary dictionary];
    
    NSString *url = isSuretate ? [NSString stringWithFormat:@"http://%@/p2/post_form.php?host=%@&bbs=%@&newthread=1", p2Host, host, bbs] : [NSString stringWithFormat:@"http://%@/p2/post_form.php?host=%@&bbs=%@&key=%@", p2Host, host, bbs, datIdentifier];
    
    NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    [urlRequest setHTTPShouldHandleCookies:NO];
    [urlRequest setHTTPMethod:@"GET"];
    [urlRequest addValue:cookie forHTTPHeaderField:HTTP_COOKIE_HEADER_KEY];
    
    NSURLResponse *response;
    NSData *result = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&underlyingError];
    if (!result) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 11);
        }
        return NO;
    }
    
    NSXMLDocument *document = [[[NSXMLDocument alloc] initWithData:result options:NSXMLDocumentTidyHTML error:&underlyingError] autorelease];
    if (!document) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 12);
        }
        return NO;
    }
    NSArray *objects = [document objectsForXQuery:@".//form[@action and @id=\"resform\"]" error:NULL];
    if (!objects || [objects count] == 0) {
        // かわりにログインフォームがあれば、再ログインが必要
        if ([document objectsForXQuery:@".//form[@action and @id=\"login\"]" error:NULL]) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteLoginNeededError userInfo:nil];
            }
            return NO;
        } else {
            if (error != NULL) {
                *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteNoPostFormError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:PluginLocalizedStringFromTable(@"Error p2Post no post form message", nil, @""), NSLocalizedDescriptionKey, PluginLocalizedStringFromTable(@"Error p2Post no post form info", nil, @""), NSLocalizedRecoverySuggestionErrorKey, nil]];
            }
        }
        return NO;
    } else if ([objects count] == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteNoPostFormError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:PluginLocalizedStringFromTable(@"Error p2Post no post form message", nil, @""), NSLocalizedDescriptionKey, PluginLocalizedStringFromTable(@"Error p2Post no post form info", nil, @""), NSLocalizedRecoverySuggestionErrorKey, nil]];
        }
        return NO;
    }
    NSString *actionString = [[[objects objectAtIndex:0] attributeForName:@"action"] stringValue];
    //    NSLog(@"Postform action= %@", actionString);
    
    NSArray *forms2 = [[objects objectAtIndex:0] objectsForXQuery:@".//input[@name and @value]" error:&underlyingError];
    if (!forms2) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 13);
        }
        return NO;
    }

    id postingBody;
    NSString *submitValue = nil;
    NSString *submitValueForBe = nil;
    NSString *submitValueForMaru = nil;

    for (id form in forms2) {
        NSString *formName = [[form attributeForName:@"name"] stringValue];
        NSString *formValue;
        if ([formName isEqualToString:@"FROM"]) {
            formValue = [[self userInfo] objectForKey:P22chPostUserInfoNameKey];
        } else if ([formName isEqualToString:@"mail"]) {
            formValue = [[self userInfo] objectForKey:P22chPostUserInfoMailKey];
        } else if ([formName isEqualToString:@"subject"]) { // スレ立て時のみ
            formValue = [[self userInfo] objectForKey:P22chPostUserInfoSubjectKey];
        } else if ([formName isEqualToString:@"submit"]) {
            submitValue = [[form attributeForName:@"value"] stringValue];
            continue;
        } else if ([formName isEqualToString:@"submit_beres"]) {
            submitValueForBe = [[form attributeForName:@"value"] stringValue];
            continue;
        } else if ([formName isEqualToString:@"ttitle_en"]) {
            NSString *tmp = [[self userInfo] objectForKey:P22chPostUserInfoTitleKey];
            formValue = (tmp ? [tmp stringByBase64EncodingUsingCFEncoding:kCFStringEncodingDOSJapanese] : [[form attributeForName:@"value"] stringValue]);
        } else if ([formName isEqualToString:@"maru_kakiko"]) {
            submitValueForMaru = [[form attributeForName:@"value"] stringValue];
            continue;
        } else {
            formValue = [[form attributeForName:@"value"] stringValue];
        }
        
        [forms setObject:formValue forKey:formName];
    }
    
    if ([[[self userInfo] objectForKey:P22chPostUserInfoBeKey] boolValue]) {
        if (submitValueForBe) {
            [forms setObject:submitValueForBe forKey:@"submit_beres"];
        } else {
            // p2.2ch.net 側で設定ができていない
            if (error != NULL) {
                *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteNoBeSettingError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:PluginLocalizedStringFromTable(@"Warning p2Post no be message", nil, @""), NSLocalizedDescriptionKey, PluginLocalizedStringFromTable(@"Warning p2Post no be info", nil, @""), NSLocalizedRecoverySuggestionErrorKey, [NSArray arrayWithObjects:PluginLocalizedStringFromTable(@"Warning p2Post no be recovery option 1", nil, @""), PluginLocalizedStringFromTable(@"Warning p2Post no be recovery option 2", nil, @""), nil], NSLocalizedRecoveryOptionsErrorKey, nil]];
            }
            return NO;
        }
    } else {
        if (submitValue) {
            [forms setObject:submitValue forKey:@"submit"];
        } else {
            // なぜか書き込みボタンのラベルが得られず
            return NO;
        }
    }
    
    // ●が p2.2ch.net 側でログイン済みで、かつ、BathyScaphe の設定も「●を使用する」になっている場合
    if (submitValueForMaru && [[[self userInfo] objectForKey:P22chPostUserInfoMaruKey] boolValue]) {
        [forms setObject:submitValueForMaru forKey:@"maru_kakiko"];
    }
    
    // 本文
    [forms setObject:[[self userInfo] objectForKey:P22chPostUserInfoBodyKey] forKey:@"MESSAGE"];
    
    // URL エンコードもここでやる
    postingBody = [self parameterWithForm:forms error:error];
    if (!postingBody) { // どこかで URL エンコードに失敗
        return NO;
    }
    
    return [self postToHost:p2Host path:actionString data:postingBody cookie:cookie error:error];
}

- (BOOL)postToHost:(NSString *)p2Host path:(NSString *)actionPath data:(NSString *)encodedString cookie:(NSString *)cookie error:(NSError **)error
{
    NSError *underlyingError;
    NSString *postToUrl = [NSString stringWithFormat:@"http://%@/p2/%@", p2Host, actionPath];
    
    NSMutableURLRequest *postRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:postToUrl]] autorelease];
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[encodedString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    [postRequest setHTTPShouldHandleCookies:NO];
    [postRequest addValue:cookie forHTTPHeaderField:HTTP_COOKIE_HEADER_KEY];
    
    NSURLResponse *response2;
    NSData *result2 = [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&response2 error:&underlyingError];
    if (!result2) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 21);
        }
        return NO;
    }
    
    return [self detectIsP2PostSuccess:result2 error:error];
}

- (BOOL)detectIsP2PostSuccess:(NSData *)responseData error:(NSError **)error
{
    NSString *string = [[[NSString alloc] initWithData:responseData encoding:NSShiftJISStringEncoding] autorelease];
    
    NSString *successHint = PluginLocalizedStringFromTable(@"p2Post success hint", nil, @"");
    
    if ([string rangeOfString:successHint options:NSLiteralSearch].location != NSNotFound) {
        [self setConfirmationFormData:nil];
        return YES;
    } else if ([string rangeOfString:PluginLocalizedStringFromTable(@"p2Post no activation hint", nil, @"") options:NSLiteralSearch].location != NSNotFound) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteNoActivationError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:PluginLocalizedStringFromTable(@"Error p2Post no activation message", nil, @""), NSLocalizedDescriptionKey, PluginLocalizedStringFromTable(@"Error p2Post no activation info", nil, @""), NSLocalizedRecoverySuggestionErrorKey, nil]];
        }
        return NO;
    } else if ([string rangeOfString:PluginLocalizedStringFromTable(@"p2Post confirm hint", nil, @"") options:NSLiteralSearch].location != NSNotFound) {
        // まずは確認ダイアログを出す必要がある
        NSDictionary *attr;
        NSAttributedString *tmp = [[[NSAttributedString alloc] initWithHTML:responseData documentAttributes:&attr] autorelease];
        NSString *confirmMsg = [tmp string];
        NSString *confirmTitle = [attr objectForKey:NSTitleDocumentAttribute] ?: @"Confirmation";
        if (error != NULL) {
            *error = [NSError errorWithDomain:SG2chErrorHandlerErrorDomain code:BSP22chWriteConfirmNeededError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:confirmTitle, SG2chErrorTitleErrorKey, confirmMsg, SG2chErrorMessageErrorKey, nil]];
        }
        // responseData をインスタンス変数へ格納（確認後、再投稿のために）
        [self setConfirmationFormData:responseData];
        
        return NO;
    } else {
        // 手抜き...
        NSAttributedString *tmp = [[[NSAttributedString alloc] initWithHTML:responseData documentAttributes:NULL] autorelease];
        NSString *reason = [tmp string];
        if (error != NULL) {
            *error = [NSError errorWithDomain:SG2chErrorHandlerErrorDomain code:BSP22chWriteUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ERROR!", SG2chErrorTitleErrorKey, reason, SG2chErrorMessageErrorKey, nil]];
        }
        return NO;
    }
}

- (BOOL)getEncodedConfirmationForm:(NSString **)encodedStr actionPath:(NSString **)pathStr error:(NSError **)error
{
    NSError *underlyingError;

    NSXMLDocument *document = [[[NSXMLDocument alloc] initWithData:m_confirmationFormData options:NSXMLDocumentTidyHTML error:&underlyingError] autorelease];
    if (!document) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 31);
        }
        return NO;
    }
    NSArray *objects = [document objectsForXQuery:@".//form[@action]" error:NULL];
    if (!objects || [objects count] == 0) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSP22chWriteNoPostFormError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:PluginLocalizedStringFromTable(@"Error p2Post no post form message", nil, @""), NSLocalizedDescriptionKey, PluginLocalizedStringFromTable(@"Error p2Post no post form info", nil, @""), NSLocalizedRecoverySuggestionErrorKey, nil]];
        }
        return NO;
    }
    NSString *actionString = [[[objects objectAtIndex:0] attributeForName:@"action"] stringValue];
    if (actionString) {
        if (pathStr != NULL) {
            *pathStr = actionString;
        }
    }
    
    NSArray *forms2 = [[objects objectAtIndex:0] objectsForXQuery:@".//input[@name and @value]" error:&underlyingError];
    if (!forms2) {
        if (error != NULL) {
            *error = errorWithUnderlyingCocoaError(underlyingError, 32);
        }
        return NO;
    }

    NSMutableString *postingBody = [NSMutableString string];
    
    for (id form in forms2) {
        NSString *formName = [[form attributeForName:@"name"] stringValue];
        NSString *formValue = [[form attributeForName:@"value"] stringValue]; // ここでは entityReference になっている。悪いことに「&」は「&amp;amp;」に！
//        NSLog(@"check before %@", formValue);
        formValue = [formValue stringByReplaceEntityReference]; // これをしないとダメ。でもこれでも「&amp;amp;」が「&amp;」になるだけで足りない
//        NSLog(@"check ...... %@", formValue);
        formValue = [formValue stringByReplaceCharacters:@"&amp;" toString:@"&"]; //「&amp;」を「&」に戻す
//        NSLog(@"check ...... %@", formValue);
        formValue = [formValue stringByURIEncodedUsingCFEncoding:kCFStringEncodingDOSJapanese convertToCharRefIfNeeded:NO unableToEncode:NULL];
//        NSLog(@"check after  %@", formValue);
        if (formValue) {
            [postingBody appendFormat:@"%@=%@&", formName, formValue];
        }
    }
    
    if ([postingBody length] > 1) {
        [postingBody deleteCharactersInRange:NSMakeRange([postingBody length] - 1, 1)];
    }
    
    if (encodedStr != NULL) {
        *encodedStr = [NSString stringWithString:postingBody];
    }
    return YES;
}
@end
