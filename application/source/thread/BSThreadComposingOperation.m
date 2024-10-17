//
//  BSThreadComposingOperation.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/11/22.
//
//

#import "BSThreadComposingOperation.h"
#import "CMRThreadMessageBuffer.h"
#import "CMRThreadMessage.h"
#import "CMRAttributedMessageComposer.h"
#import "CMRThreadContentsReader.h"
#import "BSSpamJudge.h"
#import "BSAsciiArtDetector.h"

@interface BSThreadComposingOperation(Private)
- (void)judgeSpam;
- (void)changeAllMessageAttributesToAA;
- (void)judgeAA;
- (void)collectReferences:(NSIndexSet *)references;
@end

@implementation BSThreadComposingOperation
@synthesize attrStrBuffer = m_attrStrBuffer, messageBuffer = m_buffer, rangeBuffer = m_ranges;
@synthesize signature = m_signature;
@synthesize spamJudgeEnabled = m_spamJudgeEnabled, isOnAAThread = m_isOnAAThread, aaJudgeEnabled = m_aaJudgeEnabled, referenceMarkerEnabled = m_referenceMarkerEnabled, prevRefMarkerUpdateNeeded = m_prevRefMarkerUpdateNeeded;
@synthesize countedSet = m_countedSet;
@synthesize reverseReferencesCountedSet = m_reverseReferencesCountedSet;
@synthesize messageIndexesForRefMarkerUpdateNeeded = m_messageIndexesForReferencesMarkerUpdateNeeded;

- (id)initWithThreadReader:(CMRThreadContentsReader *)aReader
{
	if (self = [super init]) {
        m_reader = [aReader retain];
        m_buffer = [[CMRThreadMessageBuffer alloc] init];
        m_attrStrBuffer = [[NSMutableAttributedString alloc] init];
        m_ranges = [[DTRangesArray alloc] init];
        m_signature = nil;
        m_countedSet = nil;
        m_reverseReferencesCountedSet = nil;
        m_messageIndexesForReferencesMarkerUpdateNeeded = nil;
        delegate = nil;
	}
	return self;
}

- (void)dealloc
{
	[m_reader release];
    [m_buffer release];
    [m_attrStrBuffer release];
    [m_ranges release];
    [m_signature release];
    [m_countedSet release];
    [m_reverseReferencesCountedSet release];
    [m_messageIndexesForReferencesMarkerUpdateNeeded release];
    
    delegate = nil;
    
	[super dealloc];
}

- (void)main
{
    CMRAttributedMessageComposer *composer;
    NSRange mesRange;
    
    // compose message buffer
    [m_reader composeWithComposer:m_buffer];
    
    if (m_spamJudgeEnabled) {
        [self judgeSpam];
    }
    
    if (m_isOnAAThread) {
        [self changeAllMessageAttributesToAA];
    }
    
    if (!m_isOnAAThread && m_aaJudgeEnabled) {
        [self judgeAA];
    }

    // compose text storage
    if (self.isCancelled) {
        return;
    }
    composer = [[CMRAttributedMessageComposer alloc] init];
    [composer setContentsStorage:m_attrStrBuffer];
    
    NSArray *messages = [m_buffer messages];
    
    for (CMRThreadMessage *message in messages) {
        if (self.isCancelled) {
            break;
        }
        mesRange = NSMakeRange([m_attrStrBuffer length], 0);
        [composer composeThreadMessage:message];
        mesRange.length = [m_attrStrBuffer length] - mesRange.location;
        [m_ranges addRange:mesRange];
        if ([message IDString]) {
            [m_countedSet addObject:[message IDString]];
        }
        
        if (m_referenceMarkerEnabled && [message referencingIndexes]) {
            [self collectReferences:[message referencingIndexes]];
        }
    }
    
    [composer release];

    if (!self.isCancelled) {
        [self.delegate mergeComposedResult:self];
    }
}

- (id<BSThreadComposingOperationDelegate>)delegate
{
    return delegate;
}

- (void)setDelegate:(id<BSThreadComposingOperationDelegate>)aDelegate
{
    delegate = aDelegate;
}

#pragma mark CMRTask
- (id)identifier
{
    return [NSString stringWithFormat:@"%@_%@", NSStringFromClass([self class]), [self.signature identifier]];;
}

- (id)title
{
    return NSLocalizedStringFromTable(@"Layouting...", @"CMRTaskDescription", nil);
}

- (id)message
{
    return NSLocalizedStringFromTable(@"Now Converting...", @"CMRTaskDescription", nil);
}

- (BOOL)isInProgress
{
    return self.isExecuting;
}

- (double)amount
{
    return -1;
}

- (IBAction)cancel:(id)sender
{
    [self cancel];
}
@end


@implementation BSThreadComposingOperation (Private)
- (void)judgeSpam
{
    if (self.isCancelled) {
        return;
    }
    BSSpamJudge *judge = [[BSSpamJudge alloc] initWithThreadSignature:m_signature];
    [judge judgeMessages:m_buffer];
    [judge release];
}

- (void)changeAllMessageAttributesToAA
{
    if (self.isCancelled) {
        return;
    }
    [m_buffer changeAllMessageAttributes:YES flags:CMRAsciiArtMask];
}

- (void)judgeAA
{
    if (self.isCancelled) {
        return;
    }
    [[BSAsciiArtDetector sharedInstance] runDetectorWithMessages:m_buffer with:m_signature allowConcurrency:YES];
}

- (void)collectReferences:(NSIndexSet *)references
{
    if (self.isCancelled) {
        return;
    }
    // -[NSIndexSet enumerateIndexesUsingBlock:] で回す方が楽だけど、
    // 少しこっちの方が速い（5000レスのスレッドで 0.2 秒程度の差）
    NSUInteger idx;
    NSUInteger size = [references lastIndex] + 1;
    NSRange e = NSMakeRange(0, size);
    while ([references getIndexes:&idx maxCount:1 inIndexRange:&e] > 0) {
        NSNumber *n = [NSNumber numberWithUnsignedInteger:idx];
        [m_reverseReferencesCountedSet addObject:n];
    }
    
    if (m_prevRefMarkerUpdateNeeded) {
        if (!m_messageIndexesForReferencesMarkerUpdateNeeded) {
            m_messageIndexesForReferencesMarkerUpdateNeeded = [[NSMutableIndexSet alloc] init];
        }
        [m_messageIndexesForReferencesMarkerUpdateNeeded addIndexes:references];
    }
}
@end
