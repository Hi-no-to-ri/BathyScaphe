//
//  CMRExports.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/06/28.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//


#ifndef CMREXPORTS_H_INCLUDED
#define CMREXPORTS_H_INCLUDED

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

@class CMRBrowser;
// main browser
extern CMRBrowser			*CMRMainBrowser;

/*!
    @defined    CMXFavoritesDirectoryName
    @abstract   「お気に入り」項目
    @discussion 「お気に入り」項目の名前
*/
#define CMXFavoritesDirectoryName	NSLocalizedString(@"Favorites", @"")

/*!
    @defined    BSUserDebugEnabledKey
    @abstract   ユーザ側でデバッグログ出力の可否を切り替えるための defaults キー
    @discussion ユーザに defaults データベースのこのキーを YES にしてもらうことで、
                デバッグログを取得してもらい、問題発生時の調査・解決に役立てる。
*/
#define BSUserDebugEnabledKey @"BSUserDebugEnabled"

#ifdef __cplusplus
}  /* End of the 'extern "C"' block */
#endif
#endif /* CMREXPORTS_H_INCLUDED */
