//
//  NSArray-SGExtensions.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 10/03/20.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


@interface NSArray(SGExtensions)
+ (id)empty;
- (BOOL)isEmpty;
@end


#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_8
@interface NSArray(MavericksDummy)
// 10.9 の Header で初公開されたが
// Foundation Release Note にも記載あるように「available back in OS X v10.6.」
// ここでは宣言だけしておく
- (id)firstObject;
@end
#endif
