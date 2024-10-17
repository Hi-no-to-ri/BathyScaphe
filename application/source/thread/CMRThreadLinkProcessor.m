//
//  CMRThreadLinkProcessor.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 12/08/14.
//  Copyright 2005-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "CMRThreadLinkProcessor.h"

#import "CMRMessageAttributesStyling.h"
#import "BoardManager.h"
#import "CMRDocumentFileManager.h"
#import "CMRHostHandler.h"
#import "NSCharacterSet+CMXAdditions.h"
#import "CMRThreadSignature.h"
#import "BSInnerLinkValueRep.h"

// for debugging only
#define UTIL_DEBUGGING				0
#import "UTILDebugging.h"


@implementation CMRThreadLinkProcessor
+ (BOOL)parseBoardLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL
{
	NSURL *link_;
	NSString *boardName_ = nil;
	BOOL result_ = NO;

	link_ = [NSURL URLWithLink:aLink];
	UTILRequireCondition(link_, ReturnResult);

	// 最低限の救済措置として、末尾に「index.html」などがくっついていた場合は除去を試みる
	{
		CFStringRef lastPathExt = CFURLCopyPathExtension((CFURLRef)link_);
		if (lastPathExt != NULL) {
			CFURLRef anotherLink_ = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, (CFURLRef)link_);
			link_ = [[(NSURL *)anotherLink_ copy] autorelease];
			CFRelease(anotherLink_);
			CFRelease(lastPathExt);
		}
	}

	boardName_ = [[BoardManager defaultManager] boardNameForURL:link_];

	UTILRequireCondition(boardName_, ReturnResult);
	result_ = YES;

ReturnResult:
	if (pBoardName != NULL) *pBoardName = boardName_;
	if (pBoardURL  != NULL) *pBoardURL = link_;

	return result_;
}

+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL filepath:(NSString **)pFilepath
{
    return [self parseThreadLink:aLink boardName:pBoardName boardURL:pBoardURL filepath:pFilepath parsedHost:NULL];
}

+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName boardURL:(NSURL **)pBoardURL filepath:(NSString **)pFilepath parsedHost:(NSString **)pH
{
	NSURL			*link_;
	CMRHostHandler	*handler_;
	
	NSString	*bbs_;
	NSString	*key_;
	
	NSURL		*boardURL_  = nil;
    NSURL       *currentBoardURL_ = nil;
	NSString	*boardName_ = nil;
	NSString	*filepath_  = nil;
	
	BOOL		result_ = NO;
	
	
	link_ = [NSURL URLWithLink:aLink];
	UTILRequireCondition(link_, ReturnResult);
	handler_ = [CMRHostHandler hostHandlerForURL:link_];
	UTILRequireCondition(handler_, ReturnResult);
	
	if (![handler_ parseParametersWithReadURL:link_ bbs:&bbs_ key:&key_ start:NULL to:NULL showFirst:NULL]) {
		goto ReturnResult;
	}

	boardURL_ = [handler_ boardURLWithURL:link_ bbs:bbs_];
	UTILRequireCondition(boardURL_, ReturnResult);

	boardName_ = [[BoardManager defaultManager] boardNameForURL:boardURL_];
	UTILRequireCondition(boardName_, ReturnResult);

    currentBoardURL_ = [[BoardManager defaultManager] URLForBoardName:boardName_];
    UTILRequireCondition(currentBoardURL_, ReturnResult);

	filepath_ = [[CMRDocumentFileManager defaultManager] threadPathWithBoardName:boardName_ datIdentifier:key_];
	result_ = YES;

ReturnResult:
	if (pBoardName != NULL) {
        *pBoardName = boardName_;
    }
	if (pBoardURL != NULL) {
        *pBoardURL = currentBoardURL_;
    }
	if (pFilepath != NULL) {
        *pFilepath = filepath_;
	}
    if (pH != NULL) {
        *pH = [boardURL_ host];
    }
	return result_;
}

+ (BOOL)parseThreadLink:(id)aLink boardName:(NSString **)pBoardName threadSignature:(CMRThreadSignature **)pSignature
{
	NSURL			*link_;
	CMRHostHandler	*handler_;
	
	NSString	*bbs_;
	NSString	*key_;
	
	NSURL		*boardURL_  = nil;
	NSString	*boardName_ = nil;
	CMRThreadSignature	*signature_  = nil;
	
	BOOL		result_ = NO;
	
	
	link_ = [NSURL URLWithLink:aLink];
	UTILRequireCondition(link_, ReturnResult);
	handler_ = [CMRHostHandler hostHandlerForURL:link_];
	UTILRequireCondition(handler_, ReturnResult);
	
	if (![handler_ parseParametersWithReadURL:link_ bbs:&bbs_ key:&key_ start:NULL to:NULL showFirst:NULL]) {
		goto ReturnResult;
	}
    
	boardURL_ = [handler_ boardURLWithURL:link_ bbs:bbs_];
	UTILRequireCondition(boardURL_, ReturnResult);
    
	boardName_ = [[BoardManager defaultManager] boardNameForURL:boardURL_];
	UTILRequireCondition(boardName_, ReturnResult);
    
    signature_ = [CMRThreadSignature threadSignatureWithIdentifier:key_ boardName:boardName_];
	result_ = YES;
    
ReturnResult:
	if (pBoardName != NULL) {
        *pBoardName = boardName_;
    }
	if (pSignature != NULL) {
        *pSignature = signature_;
	}

	return result_;
}

+ (BOOL)isMessageLinkUsingLocalScheme:(id)aLink messageIndexes:(NSIndexSet **)indexSetPtr localAbonePreviewLink:(BOOL *)boolPtr
{
    if (![aLink isKindOfClass:[BSInnerLinkValueRep class]]) {
        return NO;
    }

    NSIndexSet *indexes = [(BSInnerLinkValueRep *)aLink indexes];
    if (!indexes || ([indexes count] == 0)) {
        return NO;
    }
    
    if (indexSetPtr != NULL) {
        *indexSetPtr = indexes;
    }
    if (boolPtr != NULL) {
        *boolPtr = [(BSInnerLinkValueRep *)aLink isLocalAbonedPreviewLink];
    }
    return YES;
}

+ (BOOL)isBeProfileLinkUsingLocalScheme:(id)aLink linkParam:(NSString **)aParam
{
	NSString *str_ = nil;
	BOOL ret = NO;

	UTILRequireCondition(aLink, RetMessageLink);

	str_ = [aLink stringValue];
	str_ = [str_ stringByDeletingURLScheme:CMRAttributesBeProfileLinkScheme];

	if (str_) {
        ret = YES;
	}
RetMessageLink:
	if (aParam != NULL) {
        *aParam = str_;
    }
	return ret;
}
@end
