//
//  CMRReplyMessenger_p.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/28.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRReplyMessenger.h"
#import "CocoMonar_Prefix.h"

#import "AppDefaults.h"
#import "BoardManager.h"
#import "CMRReplyController.h"
#import "CMRReplyDocumentFileManager.h"

#import "CMRTaskManager.h"
#import "w2chConnect.h"
#import "CMRServerClock.h"

#import "Cookie.h"
#import "CookieManager.h"


#define MESSENGER_REFERER_FORMAT		@"http://%@/%@/%@"
#define MESSENGER_REFERER_INDEX_HTML	@"index.html"
#define MESSENGER_SHITARABA_REFERER     @"http://jbbs.shitaraba.net%@/index.html"

#define MESSENGER_TABLE_NAME					@"Messenger"
#define MESSENGER_SEND_MESSAGE					@"Send Message to %@..."
#define MESSENGER_END_POST						@"EndPost"
#define MESSENGER_ERROR_POST					@"ERROR Send Message"
#define REPLY_MESSENGER_WINDOW_TITLE_FORMAT		@"Window Title"
//#define REPLY_MESSENGER_SUBMIT					@"submit"

#define kToolTipForNeededLogin		@"BeLoginOnNeededToolTip"
#define kToolTipForTrivialLoginOff	@"BeLoginOffTrivialToolTip"
#define kToolTipForCantLoginOn		@"BeLoginOffCantLoginToolTip"
#define kToolTipForLoginOn			@"BeLoginOnToolTip"
#define kToolTipForLoginOff			@"BeLoginOffToolTip"

#define kLabelForLoginOn			@"Be Login On"
#define kLabelForLoginOff			@"Be Login Off"

//#define kImageForLoginOn			@"beEnabled"
//#define kImageForLoginOff			@"beDisabled"

#define kToolTipForNeededLoginRonin		@"RoninOnNeededToolTip"
#define kToolTipForTrivialLoginOffRonin	@"RoninOffTrivialToolTip"
#define kToolTipForCantLoginOnRonin		@"RoninOffCantLoginToolTip"
#define kToolTipForLoginOnRonin			@"RoninOnToolTip"
#define kToolTipForLoginOffRonin			@"RoninOffToolTip"

#define kLabelForLoginOnRonin			@"Ronin On"
#define kLabelForLoginOffRonin			@"Ronin Off"

#define kToolTipForTrivialLoginOffP2	@"P2OffTrivialToolTip"
#define kToolTipForCantLoginOnP2		@"P2OffCantLoginToolTip"
#define kToolTipForLoginOnP2			@"P2OnToolTip"
#define kToolTipForLoginOffP2			@"P2OffToolTip"

#define kLabelForLoginOnP2			@"P2 On"
#define kLabelForLoginOffP2			@"P2 Off"


@interface CMRReplyMessenger(Private)
- (CMRReplyController *)replyControllerRespondsTo:(SEL)aSelector;
- (void)setValueConsideringNilValue:(id)value forPlistKey:(NSString *)key;
- (void)synchronizeDocumentContentsWithWindowControllers;

+ (NSURL *)targetURLWithBoardURL:(NSURL *)boardURL;
+ (NSString *)formItemBBSWithBoardURL:(NSURL *)boardURL;
+ (NSString *)formItemDirectoryWithBoardURL:(NSURL *)boardURL;
@end


@interface CMRReplyMessenger(ConnectClient)
- (void)didFinish;
@end


@interface CMRReplyMessenger(SendMeesage)
- (NSMutableDictionary *)formDictionary;
- (void)startSendingMessage;

- (NSString *)refererParameter;
- (void)receiveCookiesWithResponse:(NSHTTPURLResponse *)response;
- (NSString *)preparedStringForPost:(NSString *)str;

- (void)handleP2WriteError:(NSError *)error forConnector:(id<p22chPosting>)connector;
@end


@interface CMRReplyMessenger(PrivateAccessor)
- (NSMutableDictionary *)mutableInfoDictionary;
- (NSDictionary *)infoDictionary;
- (NSString *)threadTitle;

- (NSString *)formItemBBS;
- (NSString *)formItemKey;
- (NSString *)formItemDirectory; // require for Jbbs_shita

- (NSString *)replyMessage;
- (void)setReplyMessage:(NSString *)aMessage;
- (void)setModifiedDate:(NSDate *)aModifiedDate;
- (void)setIsEndPost:(BOOL)flag;
- (NSDictionary *)additionalForms;
- (void)setAdditionalForms:(NSDictionary *)anAdditionalForms;
@end
