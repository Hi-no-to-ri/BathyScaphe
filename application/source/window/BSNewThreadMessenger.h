//
//  BSNewThreadMessenger.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/02/09.
//  Copyright 2008 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRReplyMessenger.h"


@interface BSNewThreadMessenger : CMRReplyMessenger {
	NSString	*m_subject;
}

- (id)initWithBoardName:(NSString *)boardName;

- (NSString *)subject;
- (void)setSubject:(NSString *)string;
@end

extern NSString *const BSNewThreadMessengerDidFinishPostingNotification;

#define kPostedSubjectKey	@"subject"
#define kPostedBoardNameKey	@"boardName"
