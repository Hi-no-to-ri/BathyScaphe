//
//  CMRReplyDocumentFileManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/22.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class CMRThreadSignature;
@class BSModalStatusWindowController;

@interface CMRReplyDocumentFileManager : NSObject {

}
+ (id)defaultManager;

+ (NSArray *)documentAttributeKeys;

- (BOOL)replyDocumentFileExistsAtPath:(NSString *)path;
- (BOOL)createDocumentFileIfNeededAtPath:(NSString *)filepath contentInfo:(NSDictionary *)contentInfo;

- (BOOL)replyDocumentFileExistsAtURL:(NSURL *)absoluteURL;
- (BOOL)createReplyDocumentFileAtURL:(NSURL *)absoluteURL documentAttributes:(NSDictionary *)attributesDict;

- (NSString *)replyDocumentFileExtention;
- (NSString *)replyDocumentDirectoryWithBoardName:(NSString *)boardName createIfNeeded:(BOOL)flag;
- (NSString *)replyDocumentFilepathWithLogPath:(NSString *)filepath createIfNeeded:(BOOL)flag;

- (NSURL *)replyDocumentFileURLWithLogURL:(NSURL *)logFileURL createIfNeeded:(BOOL)flag;

- (NSArray *)replyDocumentFilesArrayWithLogsArray:(NSArray *)logfiles;
- (NSArray *)replyDocumentFileURLsWithLogURLs:(NSArray *)logFileURLs;

// 古い掲示板名のフォルダから、新しい掲示板名のフォルダに下書きファイルをすべてコピーする。その際、下書きファイル内の BoardName キーの値を書き換えながらコピーする。
- (BOOL)copyAllReplyDocumentsFrom:(NSString *)oldBoardName to:(NSString *)newBoardName modalStatus:(BSModalStatusWindowController *)controller session:(NSModalSession)session error:(NSError **)errorPtr;
@end
