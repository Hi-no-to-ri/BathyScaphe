//
//  CMRFileManager.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 11/04/09.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>

@class SGFileRef;

@interface CMRFileManager : NSObject {
    @private
    SGFileRef *m_dataRootDirectory;
    NSString *m_dataRootDirectoryPath;
    
    NSFileManager *m_fileManager;
}

+ (id)defaultManager;

// CMRDocumentsDirectory
- (NSString *)dataRootDirectoryPath;
- (NSString *)supportFileUnderDataRootDirectoryPathWithName:(NSString *)name;

// TODO 以下、エイリアス解決対応必要かも
//- (NSURL *)supportDirectoryURL;
//- (NSURL *)userDomainFolderURLForDirectory:(NSSearchPathDirectory)dir;
//- (NSURL *)supportSubDirectoryURLWithName:(NSString *)dirName;
//- (NSURL *)supportFileURLWithName:(NSString *)aFileName;

// ~/Downloads (on Mac OS X 10.5 and later)
- (NSString *)userDomainDownloadsFolderPath;

// ~/Library/Logs
- (NSString *)userDomainLogsFolderPath;
@end

@interface CMRFileManager(BSDeprecated)
- (SGFileRef *)dataRootDirectory;
// ~/Library/Application Support/BathyScaphe
- (SGFileRef *)supportDirectory;
// ~/Library/Application Support/BathyScaphe/<dirName>
- (SGFileRef *)supportDirectoryWithName:(NSString *)dirName;

// ~/Library/Application Support/BathyScaphe/<fileName>
- (NSString *)supportFilepathWithName:(NSString *)aFileName resolvingFileRef:(SGFileRef **)aFileRefPtr;
@end


@interface CMRFileManager(Cache)
- (void)updateDataRootDirectory;
@end
