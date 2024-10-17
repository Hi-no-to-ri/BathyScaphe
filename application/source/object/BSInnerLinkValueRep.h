//
//  BSInnerLinkValueRep.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/03/23.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@interface BSInnerLinkValueRep : NSObject<NSCopying> {
    NSString *m_originalString;
    NSIndexSet *m_indexes;
    
    BOOL m_localAbonePreview; // このリンクが「ローカルあぼーん」の「レスを表示」リンクか？
}

- (id)initWithOriginalString:(NSString *)string;

// 「ローカルあぼーん」リンク用
- (id)initWithIndex:(NSUInteger)index;
- (BOOL)isLocalAbonedPreviewLink;
- (void)setLocalAbonedPreviewLink:(BOOL)flag;

- (NSIndexSet *)indexes;
- (NSString *)originalString;
- (NSString *)stringValue;
@end
