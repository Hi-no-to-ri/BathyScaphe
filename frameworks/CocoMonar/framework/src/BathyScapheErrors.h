//
//  BathyScapheErrors.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/03/07.
//  Copyright 2008-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>


enum {
    // File Read/Write Errors
    BSDocumentReadRequiredAttrNotFoundError = 201, // 書類の内容で必須な部分が欠落
    BSDocumentReadNoDataError = 202, // 書類の内容がまったく無い
    BSDocumentReadTooOldLogFormatError = 203, // ログファイルのフォーマットが古すぎる
    BSDocumentReadCannotCopyLogFileError = 211, // ログファイルを適切な場所にコピーできない
    BSDocumentReadCannotCopyAllLogFilesError = 212, // 特定の掲示板のログファイルがすべて、適切な場所にコピーできない Available in BathyScaphe 2.4.3 and later.
    
    BSDocumentReadCannotScanLogSubDirError = 251, // ログフォルダ内の掲示板名のサブフォルダのリストを取得できない Available in BathyScaphe 2.4.3 and later.
    BSDocumentReadCannotScanReplyDirError = 252, // Reply フォルダのファイルリストを取得できない Available in BathyScaphe 2.4.3 and later.

    BSDocumentWriteRequiredAttrNotFoundError = 501, // 書類に書き込むべき必須な内容が欠落
    BSDocumentWriteNoDataError = 502, // 書類に書き込むべき内容がまったく無い
    
    BSDocumentWriteCannotMakeLogSubDirError = 551, // ログフォルダ内に掲示板名のサブフォルダを作成できない Available in BathyScaphe 2.4.3 and later.
    BSDocumentWriteCannotMakeReplyDirError = 552, // Reply フォルダを作成できない Availabe in BathyScaphe 2.4.3 and later.

    // Downloader Errors
    BSDATDownloaderThreadNotFoundError = 404, // そんな板orスレッドないです（DAT 落ち？）
    BSThreadHTMLDownloaderThreadNotFoundError = 2404, // したらばで そんな板orスレッドないです
    BSOfflaw2DownloaderThreadNotFoundError = 1302, // offlaw2.so が 200 以外のステータスを返した場合
    BSLoggedInDATDownloaderThreadNotFoundError = 1404, // ●ログインして "-ERR そんな板orスレッドないです。"
    BSThreadTextDownloaderInvalidPartialContentsError = 416, // ダウンロードしたデータが不完全
    CMRDownloaderConnectionDidFailError = 1401, // （NSURLConnection レベルの）ダウンロードエラー Available in BathyScaphe 2.0 "Final Moratorium" and later.

    // BSSettingTxtDetector Errors: Available in BathyScaphe 1.6.3 "Hinagiku" and later.
    BSSettingTxtDetectorCannotStartDownloadingError = 1001, // SETTINT.TXT のダウンロード開始失敗（ダウンロード場所確保失敗）
    
    // BoardManager Errors: Available in BathyScaphe 2.1.1 "D-FORMATION" and later.
    BoardManagerMovedBoardDetectConnectionDidFailError = 1101, // （NSURLConnection レベルの）エラーで板移転検知処理を実行できなかった
    BoardManagerMovedBoardDetectBBONSuspectionError = 1102, // スレッド一覧更新時にバーボン・ボボン規制ページに飛ばされた
    BoardManagerMovedBoardDetectGeneralError = 1103, // 何らかの理由で板移転検知がうまくできなかった
    
    // Threads List Errors: Available in BathyScaphe 2.3 "Bright Stream" and later.
    BSSmartBoardUpdateTaskNetworkError = 1201, // スマート掲示板のスレッドに含まれるいくつかの掲示板で subject.txt 取得時にネットワークエラー
    BSThreadsListOPTaskCloudFlareStatusError = 1202, // ２ちゃんねるの subject.txt 取得時に CloudFlare がエラーステータスを返した。 Available in BathyScaphe 2.4.3 "Matatabi-Step" and later.

    // BSRelatedKeywordsCollector Errors: Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
    // Removed in BathyScaphe 2.0.
//    BSRelatedKeywordsCollectorInvalidResponseError = 1501, // 不正な http レスポンス（200 以外）
//    BSRelatedKeywordsCollectorDidFailParsingError = 1502, // キーワードの抽出失敗
    
    // BSTGrepSoulGem Errors: Available in BathyScaphe 2.1.1 "D-FORMATION" and later.
    BSFind2chSoulGemServerCapacityError = 1601, // ２ちゃんねる検索側の高負荷のため、検索結果が 0 件だった場合

    // BSNGExpression Errors: Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
    BSNGExpressionInvalidAsRegexError = 1701, // 文字列を正規表現として評価できない
    BSNGExpressionNilExpressionError = 1702, // 文字列を空に設定しようとしている Available in BathyScaphe 2.0 and later.
    BSNGExpressionWhitespaceExpressionError = 1703, //文字列が空白のみで構成されている Available in BathyScaphe 2.4 and later.

    // CMRFavoritesManager Errors: Available in BathyScaphe 2.0 "Final Moratorium" and later.
    CMRFavoritesManagerHEADCheckUnavailableError = 1801, // 更新チェックの利用不可
    
    // CMRKeychainManager Errors: Available in BathyScaphe 2.4 "Kazusa-Ushiku" and later.
    CMRKeychainManagerKeychainServiceError = 2501, // Keychain Services のエラー
    CMRKeychainManagerNoAccountError = 2599, // アカウント（ユーザーID／メールアドレス等）が与えられていない場合
    CMRKeychainManagerKeychainItemNotExistError = 2628, // キーチェーン項目が存在しない場合
};

extern NSString *const BSBathyScapheErrorDomain;
