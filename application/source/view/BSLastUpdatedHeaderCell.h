//
//  BSLastUpdatedHeaderCell.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 11/11/19.
//  Copyright 2011-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@interface BSLastUpdatedHeaderCell : NSTextAttachmentCell {
    // 左のイメージは、-[self image] に格納する
    NSImage *m_middleImage; // 真ん中のイメージ
    NSImage *m_rightImage; // 右のイメージ
}

- (id)initWithImageNameBase:(NSString *)imageNameBase searchCustomized:(BOOL)isCustomized;

@end
