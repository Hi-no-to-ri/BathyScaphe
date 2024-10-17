//
//  CMRThreadLayout.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/05/08.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import "CMRTask.h"

@protocol CMRThreadLayoutTask;
@class DTRangesArray;
@class CMRThreadView;
@class CMRThreadMessage;
@class CMRThreadMessageBuffer;
@class BSThreadComposingOperation;


@interface CMRThreadLayout : NSObject {
    @private
    CMRThreadView       *_textView;

    NSLock                  *_messagesLock;
    DTRangesArray           *_messageRanges;
    CMRThreadMessageBuffer  *_messageBuffer;
    
    // Test
    NSOperationQueue *m_operationQueue;
    
    NSCountedSet *m_countedSet;
    NSCountedSet *m_reverseReferencesCountedSet;
    
    BOOL        _isMessagesEdited;
}
- (id)initWithTextView:(NSTextView *)aTextView;

- (NSOperationQueue *)operationQueue;

- (void)addOperation:(NSOperation *)operation;
//- (void)push:(id<CMRThreadLayoutTask>)aTask;
- (void)doDeleteAllMessages;

/*** Worker context ***/
- (BOOL)isInProgress;

// delete contents, properties
- (void)clear;
- (void)clear:(id)object; // Available in SilverGull and later.
- (void)disposeLayoutContext;

- (void)ensureLayoutForThreadView;

- (BOOL)isMessagesEdited;
- (void)setMessagesEdited:(BOOL)flag;
@end


@interface CMRThreadLayout(MessageRange)
- (NSUInteger)numberOfReadedMessages;
- (NSUInteger)firstUnlaidMessageIndex;

/* [self numberOfReadedMessages] == [self firstUnlaidMessageIndex] */
- (BOOL)isCompleted;

- (NSRange)rangeAtMessageIndex:(NSUInteger)index;

- (NSUInteger)messageIndexForRange:(NSRange)aRange;
- (NSUInteger)lastMessageIndexForRangeSilverGull:(NSRange)aRange;
- (NSUInteger)lastMessageIndexForRange:(NSRange)aRange;

- (NSAttributedString *)contentsAtIndex:(NSUInteger)index;

// Available in Twincam Angel.
- (NSAttributedString *)contentsForIndexes:(NSIndexSet *)indexes;
- (NSAttributedString *)localAbonedContentsForIndexes:(NSIndexSet *)indexes;
- (NSAttributedString *)contentsForIndexes:(NSIndexSet *)indexes
                             composingMask:(UInt32)composingMask
                                   compose:(BOOL)doCompose
                            attributesMask:(UInt32)attributesMask;

// For Reverse Anchor Popup. Available in BathyScaphe 1.6.1.
- (NSAttributedString *)contentsForTargetIndex:(NSUInteger)messageIndex
                                 composingMask:(UInt32)composingMask
                                       compose:(BOOL)doCompose
                                attributesMask:(UInt32)attributesMask;

// 次／前のレス
- (NSUInteger)nextMessageIndexOfIndex:(NSUInteger)index
                            attribute:(UInt32)flags
                                value:(BOOL)attributeIsSet;
- (NSUInteger)previousMessageIndexOfIndex:(NSUInteger)index
                                attribute:(UInt32)flags
                                    value:(BOOL)attributeIsSet;

// 移動可能なインデックス
- (NSUInteger)nextVisibleMessageIndex;
- (NSUInteger)previousVisibleMessageIndex;
- (NSUInteger)nextVisibleMessageIndexOfIndex:(NSUInteger)index;
- (NSUInteger)previousVisibleMessageIndexOfIndex:(NSUInteger)index;

// ブックマークされたレスの移動
- (NSUInteger)nextBookmarkIndex;
- (NSUInteger)previousBookmarkIndex;
- (NSUInteger)nextBookmarkIndexOfIndex:(NSUInteger)index;
- (NSUInteger)previousBookmarkIndexOfIndex:(NSUInteger)index;

// Available in Starlight Breaker.
- (NSUInteger)messageIndexOfLaterDate:(NSDate *)baseDate;
@end


@interface CMRThreadLayout(DocuemntVisibleRect)
- (NSUInteger)firstMessageIndexForDocumentVisibleRect;
- (NSUInteger)lastMessageIndexForDocumentVisibleRect;

- (void)scrollMessageWithRange:(NSRange)aRange;
- (void)scrollMessageAtIndex:(NSUInteger)anIndex;
- (IBAction)scrollToLastUpdatedIndex:(id)sender;
@end


@interface CMRThreadLayout(Attachment)
- (NSDate *)lastUpdatedDateFromHeaderAttachment;
- (NSRange)firstLastUpdatedHeaderAttachmentRange;
- (NSDate *)lastUpdatedDateFromFirstHeaderAttachmentEffectiveRange:(NSRangePointer)effectiveRange;

- (void)appendLastUpdatedHeader;
- (void)clearLastUpdatedHeader;
- (void)insertLastUpdatedHeader;

//- (void)updateReferencedCountMarkers DEPRECATED_ATTRIBUTE;

- (void)updateReferencedCountMarkersAtIndexes:(NSIndexSet *)indexes;

- (void)clearReferencedCountStrings:(NSMutableAttributedString *)attrs range:(NSRange)sourceRange;
- (void)insertReferencedCountStrings:(NSMutableAttributedString *)attrs range:(NSRange)range;
- (void)insertReferencedCountStrings:(NSMutableAttributedString *)attrs range:(NSRange)range adjustRange:(BOOL)flag;

- (void)colorizeIDImpl:(NSAttributedString *)attrs range:(NSRange)range layoutManager:(NSLayoutManager *)layoutManager;

- (void)mergeComposingResult:(BSThreadComposingOperation *)operation;
- (void)appendComposingAttrString:(BSThreadComposingOperation *)operation;
@end


@interface CMRThreadLayout(Accessor)
- (CMRThreadView *)textView;
- (void)setTextView:(CMRThreadView *)aTextView;

- (NSLayoutManager *)layoutManager;
- (NSTextContainer *)textContainer;
- (NSTextStorage *)textStorage;
- (NSScrollView *)scrollView;

- (CMRThreadMessage *)messageAtIndex:(NSUInteger)anIndex;
- (NSArray *)messagesAtIndexes:(NSIndexSet *)indexes; // array of CMRThreadMessage
- (void)updateMessageAtIndex:(NSUInteger)anIndex;
- (void)changeAllMessageAttributes:(BOOL)onOffFlag flags:(UInt32)mask;
- (NSUInteger)numberOfMessageAttributes:(UInt32)mask;

- (BOOL)onlySingleMessageInRange:(NSRange)range; // Available in Twincam Angel.
- (DTRangesArray *)messageRanges;
- (void)addMessageRange:(NSRange)range;

- (void)slideMessageRanges:(NSInteger)changeInLength fromLocation:(NSUInteger)fromLocation;
- (void)slideMessageRanges:(NSInteger)changeInLength firstTargetMessageIndex:(NSUInteger)baseIndex;
- (void)extendMessageRange:(NSInteger)extensionLength forMessageIndex:(NSUInteger)baseIndex;

- (CMRThreadMessageBuffer *)messageBuffer;
- (NSArray *)allMessages;

- (NSCountedSet *)countedSet;
- (void)setCountedSet:(NSCountedSet *)set;
- (NSCountedSet *)reverseReferencesCountedSet;

- (void)addMessagesFromBuffer:(CMRThreadMessageBuffer *)otherBuffer;
@end
