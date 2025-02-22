//
//  SGFileRef.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/12/15.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <ApplicationServices/ApplicationServices.h>
#import <SGFoundation/SGFoundationBase.h>

@class SGFileLocation;

/*!
 * @class       SGFileRef
 * @abstract    File System Reference Wrapper class
 * @discussion  File System Reference Wrapper class
 */

@interface SGFileRef : NSObject<NSCopying>
{
    @private
    FSRef m_fsRef;
}

+ (id)fileRefWithFileURL:(NSURL *)anURL;
- (id)initWithFileURL:(NSURL *)anURL;

+ (id)fileRefWithFSRef:(FSRef *)fsRef;
- (id)initWithFSRef:(FSRef *)fsRef;

+ (id)fileRefWithPath:(NSString *)filepath;
- (id)initWithPath:(NSString *)filepath;


- (FSRef *)getFSRef;
- (SGFileLocation *)fileLocation;
- (NSString *)filepath;
- (NSString *)filename;
- (NSString *)pathExtension;

- (NSURL *)fileURL;
- (NSDate *)modifiedDate;

- (BOOL)isDirectory;
- (BOOL)isPackage;
@end


@interface SGFileRef(AllocateOtherRef)
// Find Folders
+ (id)searchDirectoryInDomain:(FSVolumeRefNum)vRefNum
				   folderType:(OSType)folderType
				   willCreate:(BOOL)willCreate;
+ (id)homeDirectory;

// Available in SGFoundation 1.6.2 and later.
+ (id)desktopFolder;
+ (id)downloadsFolder; // On Mac OS X v10.4 and earlier, returns Desktop folder.
+ (id)logsFolder;

- (id)parentFileReference;
- (id)fileRefOfResolvedAliasFile;

- (id)fileRefWithChildName:(NSString *)aName;
- (id)fileRefWithChildName:(NSString *)aName createDirectory:(BOOL)flag;
@end


@interface SGFileRef(AliasManagerSupport)
- (BOOL)isAliasFile;
- (BOOL)isSymbolicLink;
- (NSString *)pathContentResolvingLinkIfNeeded;
- (id)fileRefResolvingLinkIfNeeded;
@end


@interface SGFileRef(LaunchServicesSupport)
- (NSString *)displayName;
- (NSString *)kindString;

- (OSStatus)copyItemInfo:(LSRequestedInfo)inWhichInfo itemInfo:(LSItemInfoRecord *)outItemInfo;
- (LSItemInfoFlags)itemInfoFlags;
- (BOOL)fileHFSCreatorCode:(OSTypePtr)creator fileType:(OSTypePtr)type;
- (OSType)fileHFSCreatorCode;
- (OSType)fileHFSTypeCode;
@end


@interface SGFileRef(SGApplicationSupport)
// ~/Library/Application Support
+ (SGFileRef *)applicationSupportFolderRef;
// ~/Library/Application Support/(ExecutableName)
+ (SGFileRef *)applicationSpecificFolderRef;
@end
