//
//  BSNewThreadMessenger.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/02/09.
//  Copyright 2008-2009 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSNewThreadMessenger.h"
#import "CMRReplyMessenger_p.h"
#import "BSNewThreadController.h"
#import "CMRHostHandler.h"
#import "AppDefaults.h"
#import "missing.h"
#import "CMRBrowser.h"
#import "CMRThreadsList.h"
#import "CMRDocumentController.h"

NSString *const BSNewThreadMessengerDidFinishPostingNotification = @"jp.tsawada2.BathyScaphe.notification.BSNewThreadMessengerDidFinishPosting";

@implementation BSNewThreadMessenger
- (BOOL)isDocumentEdited
{
	return NO;
}

- (id)initWithBoardName:(NSString *)boardName
{
	if (self = [super init]) {
		BoardManager	*bm = [BoardManager defaultManager];
		NSDictionary	*dict;
		NSArray	*values, *keys;
		
		values = [NSArray arrayWithObjects:boardName, [bm defaultKotehanForBoard:boardName], [bm defaultMailForBoard:boardName], nil];
		keys = [NSArray arrayWithObjects:ThreadPlistBoardNameKey, ThreadPlistContentsNameKey, ThreadPlistContentsMailKey, nil];

		dict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
		[self replaceInfoDictionary:dict];
		[self setupAccountSettings];
	}

	return self;
}
		
- (void)makeWindowControllers
{
	NSWindowController		*controller_;
	
	controller_ = [[BSNewThreadController alloc] initWithWindowNibName:@"BSNewThreadWindow"];
	[controller_ setShouldCloseDocument:YES];
	[controller_ setShouldCascadeWindows:YES];
	[self addWindowController:controller_];
	[controller_ release];
}

- (NSString *)displayName
{
	return [NSString stringWithFormat:[self localizedString:@"Window Title (New Thread)"], [self boardName]];
}

- (void)dealloc
{
	[m_subject release];
	[super dealloc];
}

- (NSString *)subject
{
	return m_subject;
}

- (void)setSubject:(NSString *)string
{
	[string retain];
	[m_subject release];
	m_subject = string;
}

- (BOOL)validateMenuItem:(NSMenuItem *)theItem
{
	SEL action_ = [theItem action];
	
	if (action_ == @selector(saveDocumentAs:) || action_ == @selector(revealInFinder:)) {
		return NO;
	}

	return [super validateMenuItem:theItem];
}
@end


@implementation BSNewThreadMessenger(Private)
+ (NSURL *)targetURLWithBoardURL:(NSURL *)boardURL
{
	return [[CMRHostHandler hostHandlerForURL:boardURL] threadCreationWriteURLWithBoard:boardURL];
}
@end


@implementation BSNewThreadMessenger(ConnectClient)
- (void)mainBrowserDidFinishReloadingThList:(NSNotification *)notification
{
	CMRThreadSignature *signature = [[CMRMainBrowser currentThreadsList] threadSignatureWithTitle:[self subject]];
	if (signature) {
        [[CMRDocumentController sharedDocumentController] showDocumentWithHistoryItem:signature];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self close];
}

- (void)reloadThreadsListAfterPosting
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainBrowserDidFinishReloadingThList:)
		name:CMRBrowserThListUpdateDelegateTaskDidFinishNotification object:CMRMainBrowser];
	[CMRMainBrowser selectRowOfName:[self boardName] forceReload:YES];
}

- (void)playFinishedSound
{
	NSSound		*replyFinishedSound;
	NSString	*replyFinishedSoundName;

	replyFinishedSoundName = [CMRPref replyDidFinishSound];
	if (replyFinishedSoundName && ![replyFinishedSoundName isEqualToString:@""]) {
		replyFinishedSound = [NSSound soundNamed:replyFinishedSoundName];
	} else {
		replyFinishedSound = nil;
	}
	
	[replyFinishedSound play];
}

- (void)didFinishPosting
{
	NSDictionary *userInfo;
	[self didFinish];

	userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self subject], kPostedSubjectKey, [self boardName], kPostedBoardNameKey, NULL];
	UTILNotifyInfo(BSNewThreadMessengerDidFinishPostingNotification, userInfo);

	[self playFinishedSound];

	[self performSelector:@selector(reloadThreadsListAfterPosting) withObject:nil afterDelay:1.0];
}
@end


@implementation BSNewThreadMessenger(SendMeesage)
- (NSDictionary *)p22chUserInfoDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *name = [self name];
    NSString *mail = [self mail];
    NSString *replyMessage = [self replyMessage];
    NSString *subject = [self subject];
    NSString *host;
    NSString *bbs;

    CMRHostHandler *handler;
    
    if (!name || !mail || !replyMessage || !subject) {
        return nil;
    }

    handler = [CMRHostHandler hostHandlerForURL:[self targetURL]];
    if (![handler parseBoardURL:[self boardURL] host:&host bbs:&bbs]) {
        return nil;
    }

    [dict setNoneNil:name forKey:P22chPostUserInfoNameKey];
    [dict setNoneNil:mail forKey:P22chPostUserInfoMailKey];
    [dict setNoneNil:replyMessage forKey:P22chPostUserInfoBodyKey];
    [dict setNoneNil:subject forKey:P22chPostUserInfoSubjectKey];
    [dict setNoneNil:host forKey:P22chPostUserInfoThreadHostKey];
    [dict setNoneNil:bbs forKey:P22chPostUserInfoThreadBBSKey];
    [dict setNoneNil:[NSNumber numberWithBool:[self shouldSendBeCookie]] forKey:P22chPostUserInfoBeKey];
    [dict setNoneNil:[NSNumber numberWithBool:[self shouldUseMaru]] forKey:P22chPostUserInfoMaruKey];
    [dict setNoneNil:[[CookieManager defaultManager] cookiesForP22ch] forKey:P22chPostUserInfoCookieKey];
    [dict setNoneNil:[[CMRPref sharedP22chAuthenticator] actualHost] forKey:P22chPostUserInfoActualHostKey];
    
    return dict;
}

- (NSMutableDictionary *)formDictionary
{
	NSString *name = [self name];
	NSString *mail = [self mail];
	NSString *replyMessage = [self replyMessage];
	NSString *newTitle = [self subject];

	CMRHostHandler		*handler_;
	NSDictionary		*formKeys_;
	NSString			*key_;
	
	NSMutableDictionary	*form_ = [NSMutableDictionary dictionary];
	NSDate				*date_;
	NSString			*time_;
	
	if (!name || !mail || !replyMessage || !newTitle) return nil;

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
	time_ = [[NSNumber numberWithInt:[date_ timeIntervalSince1970]] stringValue];
	
	
	key_ = [formKeys_ stringForKey:CMRHostFormSubmitKey];
	[form_ setNoneNil:[handler_ submitNewThreadValue] forKey:key_];
	
	key_ = [formKeys_ stringForKey:CMRHostFormNameKey];
	[form_ setNoneNil:name forKey:key_];
	
	key_ = [formKeys_ stringForKey:CMRHostFormMailKey];
	[form_ setNoneNil:mail forKey:key_];

	key_ = [formKeys_ stringForKey:CMRHostFormSubjectKey];
	[form_ setNoneNil:newTitle forKey:key_];

	key_ = [formKeys_ stringForKey:CMRHostFormMessageKey];
	[form_ setNoneNil:[self preparedStringForPost:replyMessage] forKey:key_];

	key_ = [formKeys_ stringForKey:CMRHostFormBBSKey];
	[form_ setNoneNil:[self formItemBBS] forKey:key_];

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
@end
