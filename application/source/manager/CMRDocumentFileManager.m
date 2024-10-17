//
//  CMRDocumentFileManager.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/03/17.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRDocumentFileManager.h"
#import "CocoMonar_Prefix.h"
#import "BSModalStatusWindowController.h"
#import "AppDefaults.h"

@implementation CMRDocumentFileManager
APP_SINGLETON_FACTORY_METHOD_IMPLEMENTATION(defaultManager);

- (NSString *)threadDocumentFileExtention
{
	return @"thread";
//	return [[NSDocumentController sharedDocumentController] firstFileExtensionFromType:CMRThreadDocumentType];
}

- (NSString *)datIdentifierWithLogPath:(NSString *)filepath
{
	return [[filepath lastPathComponent] stringByDeletingPathExtension];
}

- (NSString *)boardNameWithLogPath:(NSString *)filepath
{
	NSString		*boardName_;
	CFMutableStringRef			normalized;
	
	if (!filepath) return nil;
    
	
	boardName_ = [filepath stringByDeletingLastPathComponent];
    // 例えば「ほげ/はげ」のような掲示板名の場合、Finder では「ほげ/はげ」というフォルダができているように見えるが、
    // ファイルシステム上（filepath 中）では「ほげ:はげ」に置き換わっていたりする。
    // filepath から元の掲示板名を復元するには、単に lastPathComponent を見るのではなく
    // Finder 上で見えている文字列が欲しい。そこで -displayNameAtPath: を使ってみる。
    NSString *hoge = [[NSFileManager defaultManager] displayNameAtPath:boardName_];
	
    // Normalization 対策も上の -displayNameAtPath: で大丈夫だと思う
    // →だめ。必要。
	normalized = (CFMutableStringRef)[[hoge mutableCopy] autorelease];
	CFStringNormalize(normalized, kCFStringNormalizationFormC);
	
	return (NSString *)normalized;
}

- (NSString *)threadPathWithBoardName:(NSString *)boardName datIdentifier:(NSString *)datIdentifier
{
	NSString		*filepath_;
	
	if (!boardName || !datIdentifier) return nil;

	filepath_ = [self directoryWithBoardName:boardName];
	filepath_ = [filepath_ stringByAppendingPathComponent:datIdentifier];
	filepath_ = [filepath_ stringByDeletingPathExtension];

	return [filepath_ stringByAppendingPathExtension:[self threadDocumentFileExtention]];
}

- (NSString *)logFileURLWithBoardName:(NSString *)boardName datIdentifier:(NSString *)datIdentifier
{
    NSString *path = [self threadPathWithBoardName:boardName datIdentifier:datIdentifier];
    if (!path) {
        return nil;
    }
    return [NSURL fileURLWithPath:path];
}

- (BOOL)isInLogFolder:(NSURL *)absoluteURL
{
	SGFileRef *logFileLoc = [SGFileRef fileRefWithFileURL:absoluteURL];
	SGFileRef *parentParentLoc = [[logFileLoc parentFileReference] parentFileReference];
	if (!parentParentLoc) return NO;

	SGFileRef *logFolderLoc = [[CMRFileManager defaultManager] dataRootDirectory];

	return ([parentParentLoc isEqual:logFolderLoc]);
}

- (BOOL)forceCopyLogFile:(NSURL *)absoluteURL boardName:(NSString *)boardName datIdentifier:(NSString *)datIdentifier destination:(NSURL **)outURL
{
	char	*target;
	OSStatus err;

	err = FSPathCopyObjectSync(
			[[absoluteURL path] fileSystemRepresentation],
			[[self directoryWithBoardName:boardName] fileSystemRepresentation],
			(CFStringRef)[datIdentifier stringByAppendingPathExtension:[self threadDocumentFileExtention]],
			&target,
			(kFSFileOperationDefaultOptions|kFSFileOperationOverwrite)
		  );

	if (err != noErr) return NO;

	if (outURL != NULL) {
		*outURL = [NSURL fileURLWithPath:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:target length:strlen(target)]];
	}
	return YES;
}

- (SGFileRef *)ensureDirectoryExistsWithBoardName:(NSString *)boardName createIfNeeded:(BOOL)flag
{
	SGFileRef	*f;
	
	if (!boardName || [boardName isEmpty]) return nil;
	
	f = [[CMRFileManager defaultManager] dataRootDirectory];
	f = [f fileRefWithChildName:boardName createDirectory:flag];
	
	return f;
}

- (SGFileRef *)ensureDirectoryExistsWithBoardName:(NSString *)boardName
{
    return [self ensureDirectoryExistsWithBoardName:boardName createIfNeeded:YES];
}

- (NSString *)directoryWithBoardName:(NSString *)boardName createIfNeeded:(BOOL)flag
{
	SGFileRef *f = [self ensureDirectoryExistsWithBoardName:boardName createIfNeeded:flag];
    if (f) {
        return [f filepath];
    }
    return nil;
}

- (NSString *)directoryWithBoardName:(NSString *)boardName
{
    return [self directoryWithBoardName:boardName createIfNeeded:YES];
}

- (BOOL)copyAllLogFilesFrom:(NSString *)oldBoardName to:(NSString *)newBoardName modalStatus:(BSModalStatusWindowController *)controller session:(NSModalSession)session error:(NSError **)errorPtr
{
    if ([oldBoardName isEqualToString:newBoardName]) {
        // Nothing to do
        return YES;
    }

    NSString *fromFolderPath = [self directoryWithBoardName:oldBoardName createIfNeeded:NO];
    if (!fromFolderPath) {
        return YES;
    }
    
    NSString *toFolderPath = [self directoryWithBoardName:newBoardName createIfNeeded:YES];
    if (!toFolderPath) {
        // コピー先フォルダを作成できなかった場合
        if (errorPtr != NULL) {
            *errorPtr = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSDocumentWriteCannotMakeLogSubDirError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"CreateNewBoardNameFolderDescription", @"BoardListEditor", nil), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTable(@"StopErrorSuggestion", @"BoardListEditor", nil), NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedStringFromTable(@"ErrorRecoveryStopOption", @"BoardListEditor", nil)]}];
        }
        return NO;
    }
    
    NSError *underlyingError = nil;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:fromFolderPath] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&underlyingError];
    if (!files) {
        // ログフォルダ内のファイルリストを取得できなかった場合
        if (errorPtr != NULL) {
            NSDictionary *userInfo = @{NSUnderlyingErrorKey: underlyingError, NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"UnderlyingErrorDescription", @"BoardListEditor", nil), NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedStringFromTable(@"ErrorRecoveryStopOption", @"BoardListEditor", nil)]};
            *errorPtr = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSDocumentReadCannotScanLogSubDirError userInfo:userInfo];
        }
        return NO;
    }
    
    [[controller progressIndicator] setIndeterminate:NO];
    [[controller progressIndicator] setMaxValue:[files count]];
    [[controller progressIndicator] setDoubleValue:0];
    [[controller messageTextField] setStringValue:NSLocalizedStringFromTable(@"Converting Log File(s)...", @"BoardListEditor", nil)];
    
    // session の start は本メソッドの呼び出し側で行うこと
    
    NSMutableArray *failedFileURLs = [NSMutableArray array];
    NSUInteger threadFileCount = 0;
    
    for (NSURL *fileURL in files) {
        [NSApp runModalSession:session];
        [[controller infoTextField] setStringValue:[fileURL lastPathComponent]];
        [[controller progressIndicator] incrementBy:1];
        if ([[fileURL pathExtension] isEqualToString:@"thread"]) {
            threadFileCount++;
            NSMutableDictionary *fileContents = [NSMutableDictionary dictionaryWithContentsOfURL:fileURL];
            if ([[fileContents objectForKey:@"BoardName"] isEqualToString:oldBoardName]) {
                NSURL  *newFileURL = [NSURL fileURLWithPath:[toFolderPath stringByAppendingPathComponent:[fileURL lastPathComponent]]];
                [fileContents setObject:newBoardName forKey:@"BoardName"];
                
                if ([CMRPref saveThreadDocAsBinaryPlist])  {
                    // バイナリ形式で新しいファイルを作成
                    NSData *data_ = [NSPropertyListSerialization dataWithPropertyList:fileContents format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
                        
                    if (!data_ || ![data_ writeToURL:newFileURL options:NSDataWritingAtomic error:NULL]) {
                        // 失敗時
                        [failedFileURLs addObject:fileURL]; // リストに追加するのは「コピー元のファイルのURL」
                    }

                } else {
                    // xml plist形式で新しいファイルを作成
                    if (![fileContents writeToURL:newFileURL atomically:YES]) {
                        // 失敗時
                        [failedFileURLs addObject:fileURL];
                    }
                }
            } else {
                // ファイルに記録されている掲示板名がログフォルダの名前と一致しないか、掲示板名自体が記録されていない？
                [failedFileURLs addObject:fileURL];
            }
        }
    }
    
    // TODO あるファイルのコピーに失敗した時、どうするのか…？
    // 貯めて、ファイル名をエラーで渡して。
    // Partially 成功なら YES だけど errorPtr にエラー引き渡す。
    // 全項目失敗なら NO で errorPtr にエラー引き渡す。
    // (reply の場合は全項目失敗でも YES で errorPtr にして続行しようか
    NSUInteger failedCount = [failedFileURLs count];
    if (failedCount > 0) {
        // 1つ以上失敗したファイルがある
        if (failedCount == threadFileCount) {
            // すべてのファイルが失敗している
            // TODO エラー処理
            // *errorPtr = ...
            if (errorPtr != NULL) {
                *errorPtr = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSDocumentReadCannotCopyAllLogFilesError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"AllLogCopyErrorDescription", @"BoardListEditor", nil), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTable(@"StopErrorSuggestion", @"BoardListEditor", nil), NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedStringFromTable(@"ErrorRecoveryStopOption", @"BoardListEditor", nil)]}];
            }
            return NO;
        }
        
        // TOOD エラー処理
        // *errorPtr = ...
        if (errorPtr != NULL) {
            *errorPtr = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSDocumentReadCannotCopyLogFileError userInfo:@{NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"LogCopyErrorDescription", @"BoardListEditor", nil), NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTable(@"CopyErrorSuggestion", @"BoardListEditor", nil), NSLocalizedRecoveryOptionsErrorKey: @[NSLocalizedStringFromTable(@"ErrorRecoveryProceedOption", @"BoardListEditor", nil), NSLocalizedStringFromTable(@"ErrorRecoveryStopOption", @"BoardListEditor", nil)]}];
        }
    }
    
    // session の end は本メソッドの呼び出し側で行うこと
    
    return YES;
}

- (BOOL)deleteLogFolderOfBoardName:(NSString *)boardName error:(NSError **)errorPtr
{
    NSString *folderPath = [self directoryWithBoardName:boardName createIfNeeded:NO];
    if (!folderPath) {
        return YES;
    }
    return [[NSFileManager defaultManager] removeItemAtPath:folderPath error:errorPtr];
}
@end
