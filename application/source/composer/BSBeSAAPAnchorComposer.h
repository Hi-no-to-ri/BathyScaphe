//
//  BSBeSAAPAnchorComposer.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/10/12.
//  Copyright 2008-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSBeSAAPAnchorComposer : NSObject {
    NSMutableIndexSet  *m_replacingRanges; // 複数の NSRange の集合体を NSIndexSet で保持
}

+ (BOOL)showsSAAPIcon;
+ (void)setShowsSAAPIcon:(BOOL)flag;

- (void)addSaapLinkRange:(NSRange)range;
- (void)composeAllSAAPAnchorsIfNeeded:(NSMutableAttributedString *)message;
@end
