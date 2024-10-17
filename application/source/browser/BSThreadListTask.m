//
//  BSThreadListTask.m
//  BathyScaphe
//
//  Created by Hori,Masaki on 12/04/29.
//  Copyright 2012-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSThreadListTask.h"

#import "CMRTaskManager.h"

@interface BSThreadListTask()
@property (readwrite, copy) NSString *message;
@end


@implementation BSThreadListTask
@synthesize isInProgress = _isInProgress;
@synthesize isInterrupted = _isInterrupted;
@synthesize message = _message;
@synthesize amount = _amount;

@dynamic identifier, title;

- (id)init
{
	self = [super init];
	if (self) {
		_amount = -1;
	}
	return self;
}

- (void)dealloc
{
	[_message release];
	
	[super dealloc];
}

- (id)identifier
{
	return [NSString stringWithFormat:@"%@-%p", self, self];
}

- (void)run
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[CMRTaskManager defaultManager] taskWillStart:self];
		self.isInProgress = YES;
	});
				
    @try {
        [self excute];
    }
    @catch(NSException *localException) {
		NSString *name_ = [localException name];
		NSString *reason_ = [localException reason];
		NSLog(@"Exception was caught at %@ <Identifier=%@>:\n  Name: %@\n  Reason: %@", NSStringFromClass([self class]), [self identifier], name_, reason_);
        // 例外の再スローは行わない
    }
	@finally {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.isInProgress = NO;
			self.message = [self localizedString:@"Did Finish"];
			[[CMRTaskManager defaultManager] taskDidFinish:self];
		});
    }
}

- (void)excute
{
	/* Subclass should override this method */
}

- (void)cancel:(id)sender
{
	self.isInterrupted = YES;
}

#pragma mark Localized Strings
+ (NSString *)localizableStringsTableName
{
    return @"CMRTaskDescription";
}
@end
