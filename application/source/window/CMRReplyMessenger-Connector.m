//
//  CMRReplyMessenger-Connector.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 05/07/04.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRReplyMessenger_p.h"
#import "CMRThreadSignature.h"
#import "CMRHostHandler.h"
#import "BSReplyAlertSheetController.h"
#import "BSReplyCountdownSheetController.h"


@implementation CMRReplyMessenger(Private)
- (CMRReplyController *)replyControllerRespondsTo:(SEL)aSelector
{
    NSEnumerator        *iter_;
    CMRReplyController  *controller_;
    
    iter_ = [[self windowControllers] objectEnumerator];
    while (controller_ = [iter_ nextObject]) {
        if (aSelector != NULL && ![controller_ respondsToSelector:aSelector]) continue;
        if (![controller_ isKindOfClass:[CMRReplyController class]]) continue;
        
        return controller_;
    }
    return nil;
}

- (void)setValueConsideringNilValue:(id)value forPlistKey:(NSString *)key
{
    if (!value) {
        // 将来は removeObjectForKey: に変更するかもしれない
        [[self mutableInfoDictionary] setObject:@"" forKey:key];
    } else {
        [[self mutableInfoDictionary] setObject:value forKey:key];
    }
}

- (void)synchronizeDocumentContentsWithWindowControllers
{
    CMRReplyController  *controller_;
    
    controller_ = [self replyControllerRespondsTo:@selector(synchronizeMessengerWithData)];
    [controller_ synchronizeMessengerWithData];

    // reset undoManager
    [[self undoManager] removeAllActions];
}

+ (NSURL *)targetURLWithBoardURL:(NSURL *)boardURL
{
    return [[CMRHostHandler hostHandlerForURL:boardURL] writeURLWithBoard:boardURL];
}

+ (NSString *)formItemBBSWithBoardURL:(NSURL *)boardURL
{
    return [[boardURL path] lastPathComponent];
}

+ (NSString *)formItemDirectoryWithBoardURL:(NSURL *)boardURL
{
    return [[[boardURL path] stringByDeletingLastPathComponent] lastPathComponent];
}
@end


@implementation CMRReplyMessenger(PrivateAccessor)
- (NSMutableDictionary *)mutableInfoDictionary
{
    if (!_attributes) {
        _attributes = [[NSMutableDictionary alloc] init];
    }
    return _attributes;
}

- (NSDictionary *)infoDictionary
{
    return [self mutableInfoDictionary];
}

- (NSString *)threadTitle
{
    return [[self infoDictionary] objectForKey:CMRThreadTitleKey];
}

- (NSString *)formItemBBS
{
    return [[self class] formItemBBSWithBoardURL:[self boardURL]];
}

- (NSString *)formItemKey
{
    return [[self infoDictionary] objectForKey:ThreadPlistIdentifierKey];
}

- (NSString *)formItemDirectory
{
    return [[self class] formItemDirectoryWithBoardURL:[self boardURL]];
}

- (NSString *)replyMessage
{
    return [[self infoDictionary] objectForKey:ThreadPlistContentsMessageKey];
}

- (void)setReplyMessage:(NSString *)aMessage
{
    [self setValueConsideringNilValue:aMessage forPlistKey:ThreadPlistContentsMessageKey];
}

- (void)setModifiedDate:(NSDate *)aModifiedDate
{
    [[self mutableInfoDictionary] setObject:aModifiedDate forKey:CMRThreadModifiedDateKey];
}

- (void)setIsEndPost:(BOOL)anIsEndPost
{
    _isEndPost = anIsEndPost;
}

- (NSDictionary *)additionalForms
{
    return _additionalForms;
}

- (void)setAdditionalForms:(NSDictionary *)anAdditionalForms
{
    [anAdditionalForms retain];
    [_additionalForms release];
    _additionalForms = anAdditionalForms;
}
@end


@implementation CMRReplyMessenger(ConnectClient)
- (void)didFinish
{
    [self setIsInProgress:NO];
    [[CMRTaskManager defaultManager] taskDidFinish:self];
}

- (void)didFailPosting
{
    [self didFinish];
    [self setIsEndPost:NO]; //再送信を試みることができるように
}

- (void)didFinishPosting
{
    [self didFinish];
    [self saveDocument:nil];

    UTILNotifyInfo3(CMRReplyMessengerDidFinishPostingNotification, [self threadIdentifier], kUserInfoPostedThreadIdentifierKey);
    [self close]; // notification の後に移動
}

/* 書き込みエラー */
- (void)cookieOrContributionCheckSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [[sheet windowController] autorelease];
    if (NSAlertFirstButtonReturn == returnCode) {
        [self startSendingMessage];
    } else if (NSAlertSecondButtonReturn == returnCode) {
        if ([(NSNumber *)contextInfo boolValue]) {
            [self setAdditionalForms:nil];
        }
    }
}

- (void)p2ConfirmationSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [[sheet windowController] autorelease];
    id<p22chPosting> connector_ = (id<p22chPosting>)contextInfo;
    if (NSAlertFirstButtonReturn == returnCode) {
        NSError *error = nil;
        if ([(id<p22chPosting>)connector_ postUsingP22ch:&error]) {
            [self setModifiedDate:[NSDate date]];
            [self didFinishPosting];
        } else {
            [self didFailPosting];
            if (error) {
                [self handleP2WriteError:error forConnector:connector_];
            }
        }
    } else {
        [connector_ setConfirmationFormData:nil];
    }
    [connector_ autorelease];
}

- (void)failedBeLoginAlertDidEnd:(NSAlert *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (NSAlertFirstButtonReturn == returnCode) {
        [[CookieManager defaultManager] setBeCookies:nil];
        [self startSendingMessage];
    }
}

- (void)beginP22chErrorInfoAlertSheet:(NSError *)error forConnector:(id<p22chPosting>)connector contribution:(BOOL)contribution
{
    NSString    *info;
    NSString    *firstBtnLabel;
    SEL         didEndSelector;
    
    NSDictionary    *alertContent;
    BSReplyAlertSheetController *alert;
    
    NSString    *message_ = [[error userInfo] objectForKey:SG2chErrorMessageErrorKey];
    NSString    *title = [[error userInfo] objectForKey:SG2chErrorTitleErrorKey];
    NSString    *secondBtnLabel = NSLocalizedString(@"Cancel", @"Cancel");
    
    if (contribution) {
        info = [self localizedString:@"ErrorAlertContributionInfoText"];
        firstBtnLabel = [self localizedString:@"Try Again"];
        didEndSelector = @selector(p2ConfirmationSheetDidEnd:returnCode:contextInfo:);
    } else {
        info = [self localizedString:@"ErrorAlertNoContributionInfoText"];
        firstBtnLabel = @"OK";
        didEndSelector = NULL;
    }
    
    alertContent = [NSDictionary dictionaryWithObjectsAndKeys:title, kAlertMessageTextKey, info, kAlertInformativeTextKey,
                    message_, kAlertAgreementTextKey, [NSNumber numberWithBool:contribution], kAlertIsContributionKey,
                    firstBtnLabel, kAlertFirstButtonLabelKey, secondBtnLabel, kAlertSecondButtonLabelKey, NULL];
    
    alert = [[BSReplyAlertSheetController alloc] init];
    [alert setAlertContent:alertContent];
    [alert setHelpAnchor:[self localizedString:@"Reply Error Sheet Help Anchor"]];
    
    [NSApp beginSheet:[alert window]
       modalForWindow:[self windowForSheet]
        modalDelegate:((didEndSelector != NULL) ? self : nil)
       didEndSelector:didEndSelector
          contextInfo:((didEndSelector != NULL) ? [connector retain] : NULL)];
}

- (void)beginErrorInformationalAlertSheet:(NSError *)error contribution:(BOOL)contribution
{
    NSString    *info;
    NSString    *firstBtnLabel;
    SEL         didEndSelector;
    BOOL    resetHanaMogeraIfNeeded;

    NSDictionary    *alertContent;
    BSReplyAlertSheetController *alert;

    NSString    *message_ = [[error userInfo] objectForKey:SG2chErrorMessageErrorKey];
    NSString    *title = [[error userInfo] objectForKey:SG2chErrorTitleErrorKey];
    NSString    *secondBtnLabel = NSLocalizedString(@"Cancel", @"Cancel");

    if (contribution) {
        info = [self localizedString:@"ErrorAlertContributionInfoText"];
        firstBtnLabel = [self localizedString:@"Try Again"];
        didEndSelector = @selector(cookieOrContributionCheckSheetDidEnd:returnCode:contextInfo:);
        resetHanaMogeraIfNeeded = YES;
    } else {
        info = [self localizedString:@"ErrorAlertNoContributionInfoText"];
        firstBtnLabel = @"OK";
        didEndSelector = NULL;
        resetHanaMogeraIfNeeded = NO;
    }

    alertContent = [NSDictionary dictionaryWithObjectsAndKeys:title, kAlertMessageTextKey, info, kAlertInformativeTextKey,
                        message_, kAlertAgreementTextKey, [NSNumber numberWithBool:contribution], kAlertIsContributionKey,
                        firstBtnLabel, kAlertFirstButtonLabelKey, secondBtnLabel, kAlertSecondButtonLabelKey, NULL];

    alert = [[BSReplyAlertSheetController alloc] init];
    [alert setAlertContent:alertContent];
    [alert setHelpAnchor:[self localizedString:@"Reply Error Sheet Help Anchor"]];

    [NSApp beginSheet:[alert window]
       modalForWindow:[self windowForSheet]
        modalDelegate:((didEndSelector != NULL) ? self : nil)
       didEndSelector:didEndSelector
          contextInfo:[NSNumber numberWithBool:resetHanaMogeraIfNeeded]];
}

- (void)beginCountdownAlertSheet:(NSError *)error
{
    SEL didEndSelector;    
    NSDictionary *alertContent;
    id alert;
    
    NSString *host;
    NSString *bbs;
    
    NSString *title;
    NSTimeInterval timerCount = [CMRPref timeIntervalForNinjaFirstWait];
    
    CMRHostHandler *handler = [CMRHostHandler hostHandlerForURL:[self boardURL]];
    [handler parseBoardURL:[self boardURL] host:&host bbs:&bbs];
    
    NSTimeInterval sambaInterval = [[BoardManager defaultManager] samba24ValueForHost:host bbs:bbs];
    if ((sambaInterval == 0) || (timerCount >= sambaInterval)) {
        title = [[error userInfo] objectForKey:SG2chErrorTitleErrorKey];
    } else {
        title = [NSString stringWithFormat:[self localizedString:@"SambaAndNinjaAlertTitleFormat"], sambaInterval];
        timerCount = sambaInterval + 1; // 余裕を持って samba 値に1秒追加
    }

    alertContent = [NSDictionary dictionaryWithObjectsAndKeys:title, kAlertMessageTextKey, NULL];
    
    alert = [[BSReplyCountdownSheetController alloc] initWithTimerCount:timerCount];
    didEndSelector = @selector(cookieOrContributionCheckSheetDidEnd:returnCode:contextInfo:);

    [alert setAlertContent:alertContent];
    
    [NSApp beginSheet:[alert window]
       modalForWindow:[self windowForSheet]
        modalDelegate:self
       didEndSelector:didEndSelector
          contextInfo:[NSNumber numberWithBool:NO]];
}

- (void)beginBeLoginErrorAlert:(NSError *)error
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setMessageText:[[error userInfo] objectForKey:SG2chErrorTitleErrorKey]];
    [alert setInformativeText:[self localizedString:@"k2chBeLoginErrorAlertInfo"]];
    [alert addButtonWithTitle:[self localizedString:@"Try Again"]];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
    [alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(failedBeLoginAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)connector:(id<w2chConnect>)sender didFailURLEncoding:(NSError *)error
{
    NSIndexSet *indexes = [[error userInfo] objectForKey:BS2chConnectInvalidCharIndexSetErrorKey];
    if (indexes && [indexes count] > 0) {
        NSString *formKey = [[error userInfo] objectForKey:BS2chConnectFailedParameterNameErrorKey];
        [[self replyControllerRespondsTo:NULL] markUnableToEncodeCharacters:indexes forKey:formKey];
    }
    NSAlert *alert_ = [NSAlert alertWithError:error]; 
    
    [alert_ beginSheetModalForWindow:[self windowForSheet]
                       modalDelegate:self
                      didEndSelector:nil
                         contextInfo:nil];
}   

- (void)connector:(id<w2chConnect>)sender resourceDidFailLoadingWithErrorHandler:(id<w2chErrorHandling>)handler
{
    NSError *error = [handler recentError];
    
    [self didFailPosting];

    [self receiveCookiesWithResponse:(NSHTTPURLResponse *)[sender response]];

    switch ([error code]) {
        case k2chContributionCheckErrorType: // 書き込み確認
        case k2chSPIDCookieErrorType: // クッキー確認
            [self setAdditionalForms:[handler additionalFormsData]];
            [self beginErrorInformationalAlertSheet:error contribution:YES];
            break;
        case k2chBeLoginErrorType: // Beクッキー無効、再ログイン必要時
            [self beginBeLoginErrorAlert:error];
            break;
        case k2chNinjaFirstAlertType: // 冒険の書作成中
            [self beginCountdownAlertSheet:error];
            break;
        default: // 上記以外の書き込みエラー
            [self beginErrorInformationalAlertSheet:error contribution:NO];
            break;
    }
}

- (void)connectorResourceDidFinishLoading:(id<w2chConnect>)sender
{
    [self receiveCookiesWithResponse:(NSHTTPURLResponse *)[sender response]];
    [self didFinishPosting];
}

- (void)connectorResourceDidCancelLoading:(id<w2chConnect>)sender
{
    [self didFailPosting];
}

- (void)connector:(id<w2chConnect>)sender resourceDidFailLoadingWithError:(NSError *)error
{
    [self didFailPosting];

    NSAlert *alert_ = [[[NSAlert alloc] init] autorelease];

    [alert_ setAlertStyle:NSWarningAlertStyle];
    [alert_ setMessageText:[self localizedString:MESSENGER_ERROR_POST]];
    [alert_ setInformativeText:[error localizedDescription]];
    
    [alert_ beginSheetModalForWindow:[self windowForSheet]
                       modalDelegate:self
                      didEndSelector:nil
                         contextInfo:nil];
}
@end


@implementation CMRReplyMessenger(SendMeesage)
- (NSString *)preparedStringForPost:(NSString *)str
{
    if ([[BoardManager defaultManager] allowsCharRefAtBoard:[self boardName]]) {
        NSString *backSlashConverted = [str stringByReplaceCharacters:[NSString backslash] toString:[NSString yenmark]];
        NSString *yenConverted = [backSlashConverted stringByReplaceCharacters:[NSString yenmark] toString:@"&#165;"];

        return yenConverted;
    } else {
        NSString *yenConverted2 = [str stringByReplaceCharacters:[NSString yenmark] toString:[NSString backslash]];
        return yenConverted2;
    }
}

- (NSDictionary *)p22chUserInfoDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *name = [self name];
    NSString *mail = [self mail];
    NSString *replyMessage = [self replyMessage];
    NSString *host;
    NSString *bbs;

    CMRHostHandler *handler;
    
    if (!name || !mail || !replyMessage) {
        return nil;
    }

    handler = [CMRHostHandler hostHandlerForURL:[self targetURL]];
    if (![handler parseBoardURL:[self boardURL] host:&host bbs:&bbs]) {
        return nil;
    }

    [dict setNoneNil:name forKey:P22chPostUserInfoNameKey];
    [dict setNoneNil:mail forKey:P22chPostUserInfoMailKey];
    [dict setNoneNil:replyMessage forKey:P22chPostUserInfoBodyKey];
    [dict setNoneNil:host forKey:P22chPostUserInfoThreadHostKey];
    [dict setNoneNil:bbs forKey:P22chPostUserInfoThreadBBSKey];
    [dict setNoneNil:[NSNumber numberWithBool:[self shouldSendBeCookie]] forKey:P22chPostUserInfoBeKey];
    [dict setNoneNil:[NSNumber numberWithBool:[self shouldUseMaru]] forKey:P22chPostUserInfoMaruKey];
    [dict setNoneNil:[self datIdentifier] forKey:P22chPostUserInfoThreadIdKey];
    [dict setNoneNil:[[CookieManager defaultManager] cookiesForP22ch] forKey:P22chPostUserInfoCookieKey];
    [dict setNoneNil:[[CMRPref sharedP22chAuthenticator] actualHost] forKey:P22chPostUserInfoActualHostKey];
    [dict setNoneNil:[self threadTitle] forKey:P22chPostUserInfoTitleKey];
    
    return dict;
}

- (NSMutableDictionary *)formDictionary
{
    NSString *name = [self name];
    NSString *mail = [self mail];
    NSString *replyMessage = [self replyMessage];

    CMRHostHandler      *handler_;
    NSDictionary        *formKeys_;
    NSString            *key_;
    
    NSMutableDictionary *form_ = [NSMutableDictionary dictionary];
    NSDate              *date_;
    NSString            *time_;
    
    if (!name || !mail || !replyMessage) {
        return nil;
    }
    handler_ = [CMRHostHandler hostHandlerForURL:[self boardURL]];
    formKeys_ = [handler_ formKeyDictionary];
    if (!formKeys_ || !handler_) {
        NSLog(@"Can't find hostHandler for %@", [[self boardURL] stringValue]);
        return nil;
    }
    
    // 2002/12/31
    //「餅つけ」対策
    date_ = [[CMRServerClock sharedInstance] lastAccessedDateForURL:[self targetURL]];
    if (!date_) date_ = [NSDate date];
    time_ = [[NSNumber numberWithInteger:[date_ timeIntervalSince1970]] stringValue];
    
    
    key_ = [formKeys_ stringForKey:CMRHostFormSubmitKey];
    [form_ setNoneNil:[handler_ submitValue] forKey:key_];
    
    key_ = [formKeys_ stringForKey:CMRHostFormNameKey];
    [form_ setNoneNil:name forKey:key_];
    
    key_ = [formKeys_ stringForKey:CMRHostFormMailKey];
    [form_ setNoneNil:mail forKey:key_];

    // 本文のみ円記号とバックスラッシュを実体参照で置換する。
    key_ = [formKeys_ stringForKey:CMRHostFormMessageKey];
    [form_ setNoneNil:[self preparedStringForPost:replyMessage] forKey:key_];

    key_ = [formKeys_ stringForKey:CMRHostFormBBSKey];
    [form_ setNoneNil:[self formItemBBS] forKey:key_];

    key_ = [formKeys_ stringForKey:CMRHostFormIDKey];
    [form_ setNoneNil:[self formItemKey] forKey:key_];

    key_ = [formKeys_ stringForKey:CMRHostFormTimeKey];
    [form_ setNoneNil:time_ forKey:key_];

    // for 2ch (after 2006-05-27, hana=mogera)
    if ([self additionalForms]) {
        [form_ addEntriesFromDictionary:[self additionalForms]];
    }
    // for Jbbs_shita
    key_ = [formKeys_ stringForKey:CMRHostFormDirectoryKey];
    if (key_ && ![key_ isEmpty]) {
        [form_ setNoneNil:[self formItemDirectory] forKey:key_];
    }
    return form_;
}

- (void)waitForDetecting
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(detectingDidEnd:) name:BoardManagerDidFinishDetectingSettingTxtNotification object:[BoardManager defaultManager]];

    [[BoardManager defaultManager] startDownloadSettingTxtForBoard:[self boardName] askIfOffline:NO allowToInputManually:NO];
}

- (void)handleP2WriteError:(NSError *)error forConnector:(id<p22chPosting>)connector
{
    NSString *domain = [error domain];
    NSInteger code = [error code];

    if ([domain isEqualToString:BSBathyScapheErrorDomain]) {
        if (code == BSP22chWriteLoginNeededError) {
            // p2.2ch.net ログインのやり直しが必要
            [[CookieManager defaultManager] setP2Cookies:nil];
            [self startSendingMessageImpl:NO];
            return;
        } else if (code == BS2chConnectDidFailURLEncodingError) {
            [self connector:nil didFailURLEncoding:error];
            return;
        } else if (code == BSP22chWriteUnknownError) {
            // あまり予期していないエラー
            NSAlert *unknownErrorAlert = [[[NSAlert alloc] init] autorelease];
            [unknownErrorAlert setAlertStyle:NSWarningAlertStyle];
            [unknownErrorAlert setMessageText:NSLocalizedStringFromTable(@"Error p2Post cocoa error message", @"Messenger", @"")];
            [unknownErrorAlert setInformativeText:NSLocalizedStringFromTable(@"Error p2Post unknown error info", @"Messenger", @"")];
            [unknownErrorAlert runModal];
            return;
        } else {
            // ひとまずアラートは表示する
            NSInteger answer = [[NSAlert alertWithError:error] runModal];
            if (code == BSP22chWriteNoBeSettingError) {
                if (answer == NSAlertFirstButtonReturn) {
                    // Be ログインを無効にして再度書き込み
                    [self toggleBeLogin:self];
                    [self startSendingMessageImpl:NO];
                }
                return;
            } else if (code == BSP22chWriteNoActivationError) {
                // 書き込みが有効化されていない
                // 次回書き込み時に備えて、クッキーを破棄しておく必要がある
                // （Web からログインして書き込み有効化などする可能性が高いため）
                [[CookieManager defaultManager] setP2Cookies:nil];
                return;
            }
        }
        
    } else if ([domain isEqualToString:SG2chErrorHandlerErrorDomain]) {
        if ([[error userInfo] objectForKey:BSP22chErrorPointCodeKey]) {
            NSUInteger errorPointCode = [[[error userInfo] objectForKey:BSP22chErrorPointCodeKey] unsignedIntegerValue];
            NSError *underlyingError = [[error userInfo] objectForKey:NSUnderlyingErrorKey];
            NSString *informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Error p2Post cocoa error info", @"Messenger", @""), (unsigned long)errorPointCode, [underlyingError domain], (long)[underlyingError code]];
            NSAlert *alert = [[[NSAlert alloc] init] autorelease];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert setMessageText:NSLocalizedStringFromTable(@"Error p2Post cocoa error message", @"Messenger", @"")];
            [alert setInformativeText:informativeText];
            [alert runModal];
            return;
        } else if ([[error userInfo] objectForKey:SG2chErrorTitleErrorKey]) {
            // 長いエラー本文の可能性があるので BSReplyAlertSheetController を使う。
            [self beginP22chErrorInfoAlertSheet:error forConnector:connector contribution:(code == BSP22chWriteConfirmNeededError)];
            return;
        }

    } else {
        [[NSAlert alertWithError:error] runModal];
    }
}

- (void)startSendingMessageImpl:(BOOL)startTask
{
    id<w2chConnect>     connector_;
    NSMutableDictionary *headers_;
    NSString            *referer_;
    NSString            *cookies_;
    
    BOOL useP22ch = [self shouldUseP22ch];

    if (startTask) {
        [self setIsInProgress:YES];
    
        [[CMRTaskManager defaultManager] taskWillStart:self];
    }

    [self synchronizeDocumentContentsWithWindowControllers];

    [self setIsEndPost:YES];
    headers_ = [NSMutableDictionary dictionary];
    referer_ = [self refererParameter];
    
    if (![[BoardManager defaultManager] hasAllowsCharRefEntryAtBoard:[self boardName]]) {
        [self waitForDetecting];
        return; // ここで taskFinish, -isInProgress:NO は行わない
    }

    //プラグインをロード
    if (useP22ch) {
        connector_ = [CMRPref p22chConnectWithUserInfo:[self p22chUserInfoDictionary]];
    } else {
        cookies_ = [[CookieManager defaultManager] cookiesForRequestURL:[self targetURL] withBeCookie:[self shouldSendBeCookie]];
        if (referer_ && [referer_ length] > 0) {
            [headers_ setObject:referer_ forKey:HTTP_REFERER_KEY];
        }
        if (cookies_ && [cookies_ length] > 0) {
            [headers_ setObject:cookies_ forKey:HTTP_COOKIE_HEADER_KEY];
        }
        connector_ = [CMRPref w2chConnectWithURL:[self targetURL] properties:headers_];
        [connector_ setDelegate:self];
    }

    [connector_ setAllowsCharRef:[[BoardManager defaultManager] allowsCharRefAtBoard:[self boardName]]];
    
    if (useP22ch) {
        NSError *error = nil;
        if ([(id<p22chPosting>)connector_ postUsingP22ch:&error]) {
            [self setModifiedDate:[NSDate date]];
            [self didFinishPosting];
        } else {
            [self didFailPosting];
            if (error) {
                [self handleP2WriteError:error forConnector:(id<p22chPosting>)connector_];
            }
        }
        return;

    } else {
        NSMutableDictionary *formDictionary_ = [self formDictionary];

        UTILDebugWrite1(@"targetURL = %@", [[self targetURL] absoluteString]);
        UTILDebugWrite2(@"name = %@, mail = %@", [self name], [self mail]);
        UTILDebugWrite1(@"referer = %@", referer_);
        UTILDebugWrite1(@"cookie = %@", cookies_);
        UTILDebugWrite1(@"formDictionary = %@", [formDictionary_ description]);
        
        if ([self shouldUseMaru]) {
            // ● セッションIDの付加
            NSString    *sessionID_ = [[CMRPref shared2chAuthenticator] sessionID];
            
            if (sessionID_) {
                [formDictionary_ setObject:sessionID_ forKey:@"sid"];
            } else if ([[CMRPref shared2chAuthenticator] recentErrorType] != w2chNoError) {
                // ● セッションIDの取得に失敗
                [self didFailPosting];
                return;
            }
        }

        if (![connector_ writeForm:formDictionary_]) {
            UTILDebugWrite(@"[FATAL] Can't write form data as URL encoded.");
            [self didFailPosting];
            return;
        }
        
        [connector_ loadInBackground];
        [self setModifiedDate:[NSDate date]];
    }
}

- (void)startSendingMessage
{
    if ([self isInProgress]) {
        return;
    }
    [self startSendingMessageImpl:YES];
}

- (void)detectingDidEnd:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BoardManagerDidFinishDetectingSettingTxtNotification object:[BoardManager defaultManager]];
    if (![[BoardManager defaultManager] hasAllowsCharRefEntryAtBoard:[self boardName]]) {
        [[BoardManager defaultManager] setAllowsCharRef:NO atBoard:[self boardName]];
    }
    [self startSendingMessageImpl:NO];
}

- (NSString *)refererParameter
{
    NSString *host_;
    
    UTILAssertNotNil([self targetURL]);
    UTILAssertNotNil([self formItemBBS]);
    
    host_ = [[self targetURL] host];
    
    const char *hostChar_ = [host_ UTF8String];
    if (is_jbbs_livedoor(hostChar_)) {
        NSString *path = [[self boardURL] path];
        // 2015-02-11 ユーザは、掲示板を jbbs.livedoor.jp ホストで登録したままかもしれない。
        // そこで、host_ に頼らず、MESSENGER_SHITARABA_REFERER で jbbs.shitaraba.net 決め打ちしてある。
        return [NSString stringWithFormat:MESSENGER_SHITARABA_REFERER, path];
    }

// #warning 64BIT: Check formatting arguments
// 2012-03-17 tsawada2 検証済
    return [NSString stringWithFormat:MESSENGER_REFERER_FORMAT, host_, [self formItemBBS], MESSENGER_REFERER_INDEX_HTML];
}

- (void)receiveCookiesWithResponse:(NSHTTPURLResponse *)response
{
    NSDictionary    *headers = [response allHeaderFields];  
    NSString        *cookies;
    
    if (!headers || [headers count] == 0) return;

    cookies = [headers objectForKey:HTTP_SET_COOKIE_HEADER_KEY];
    if (!cookies || [cookies length] == 0) return;

    [[CookieManager defaultManager] addCookies:cookies fromServer:[[response URL] host]];
}
@end
