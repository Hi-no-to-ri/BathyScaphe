//
//  BSThreadComposingOperation.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/11/22.
//
//

#import <Foundation/Foundation.h>
#import "CMRTask.h"

@class CMRThreadContentsReader, CMRThreadMessageBuffer, CMRThreadSignature;
@class DTRangesArray;
@protocol BSThreadComposingOperationDelegate;

@interface BSThreadComposingOperation : NSOperation<CMRTask> {
    CMRThreadContentsReader *m_reader;

    NSMutableAttributedString *m_attrStrBuffer;
    CMRThreadMessageBuffer *m_buffer;
    DTRangesArray *m_ranges;
    CMRThreadSignature *m_signature;
    
    NSCountedSet *m_countedSet; // ID カウント用
    
    NSCountedSet *m_reverseReferencesCountedSet; // 逆参照用
    NSMutableIndexSet *m_messageIndexesForReferencesMarkerUpdateNeeded; // 逆参照マーカーの更新が必要なメッセージインデックス
    
    // operationQueue に add する前に設定
    BOOL    m_spamJudgeEnabled; // 迷惑レスフィルタの実行が必要
    BOOL    m_isOnAAThread; // AAスレッド上のレンダリング（すべてのレスにAA属性が必要）
    BOOL    m_aaJudgeEnabled; // AA自動判定の実行が必要
    BOOL    m_referenceMarkerEnabled; // 逆参照の演算が必要
    BOOL    m_prevRefMarkerUpdateNeeded; // 既存の逆参照マーカーの更新が必要
    
    id<BSThreadComposingOperationDelegate> delegate;
}

- (id)initWithThreadReader:(CMRThreadContentsReader *)aReader;

@property(readwrite, strong) CMRThreadSignature *signature;

@property(readwrite, assign) BOOL spamJudgeEnabled;
@property(readwrite, assign, setter = setOnAAThread:) BOOL isOnAAThread;
@property(readwrite, assign) BOOL aaJudgeEnabled;
@property(readwrite, assign) BOOL referenceMarkerEnabled;
@property(readwrite, assign) BOOL prevRefMarkerUpdateNeeded;

@property(readonly, strong) NSMutableAttributedString *attrStrBuffer;
@property(readonly, strong) CMRThreadMessageBuffer *messageBuffer;
@property(readonly, strong) DTRangesArray *rangeBuffer;

@property(readwrite, strong) NSCountedSet *countedSet;

@property(readwrite, strong) NSCountedSet *reverseReferencesCountedSet;
@property(readonly, strong) NSMutableIndexSet *messageIndexesForRefMarkerUpdateNeeded;

- (id<BSThreadComposingOperationDelegate>)delegate;
- (void)setDelegate:(id<BSThreadComposingOperationDelegate>)aDelegate;
@end


@protocol BSThreadComposingOperationDelegate <NSObject>
- (void)mergeComposedResult:(BSThreadComposingOperation *)operation;
@end
