//
//  BSThreadFileLoadingOperation.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/11/22.
//
//

#import "BSThreadComposingOperation.h"

@protocol BSThreadFileLoadingOperationDelegate;

@interface BSThreadFileLoadingOperation : BSThreadComposingOperation {
    NSURL *m_fileURL;
    NSDictionary *m_attrDict;
}

- (id)initWithURL:(NSURL *)url;

@property(readonly, strong) NSDictionary *attrDict;

- (id<BSThreadFileLoadingOperationDelegate>)delegate;
- (void)setDelegate:(id<BSThreadComposingOperationDelegate>)delegate;
@end


@protocol BSThreadFileLoadingOperationDelegate <BSThreadComposingOperationDelegate, NSObject>
- (void)threadAttributesDidLoadFromFile:(BSThreadFileLoadingOperation *)operation;
@end