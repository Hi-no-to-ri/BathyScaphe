//
//  CMRDocumentFileManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/17.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class SGFileRef, BSModalStatusWindowController;

@interface CMRDocumentFileManager : NSObject {
}
+ (id)defaultManager;

- (NSString *)threadDocumentFileExtention;

// 注意：これらのメソッドは filepath から dat 番号、板名を取得するためにのみ使用できる
// （ログフォルダ以外の場所にあったり、ファイル名が書き換えられているログファイルでは正しい結果は得られない）
- (NSString *)datIdentifierWithLogPath:(NSString *)filepath;
- (NSString *)boardNameWithLogPath:(NSString *)filepath;

- (NSString *)threadPathWithBoardName:(NSString *)boardName datIdentifier:(NSString *)datIdentifier;
- (NSString *)logFileURLWithBoardName:(NSString *)boardName datIdentifier:(NSString *)datIdentifier;

- (BOOL)isInLogFolder:(NSURL *)absoluteURL; // Available in BathyScaphe 1.6.2 and later.
// 注意：このメソッドは、コピー先に同名ファイルがあった場合、強制的に上書きコピーする
- (BOOL)forceCopyLogFile:(NSURL *)absoluteURL
			   boardName:(NSString *)boardName
		   datIdentifier:(NSString *)datIdentifier
		     destination:(NSURL **)outURL; // Available in BathyScaphe 1.6.2 and later.

// これらのメソッドは、ディレクトリがなければ自動的に作ってくれます
- (SGFileRef *)ensureDirectoryExistsWithBoardName:(NSString *)boardName;
- (NSString *)directoryWithBoardName:(NSString *)boardName;

// 古い掲示板名のフォルダから、新しい掲示板名のフォルダにログファイルをすべてコピーする。その際、ログファイル内の BoardName キーの値を書き換えてコピーする。
- (BOOL)copyAllLogFilesFrom:(NSString *)oldBoardName to:(NSString *)newBoardName modalStatus:(BSModalStatusWindowController *)controller session:(NSModalSession)session error:(NSError **)errorPtr;

// TODO 未実装。不要になったログフォルダの掲示板サブフォルダを削除する。
- (BOOL)deleteLogFolderOfBoardName:(NSString *)boardName error:(NSError **)errorPtr;

@end
