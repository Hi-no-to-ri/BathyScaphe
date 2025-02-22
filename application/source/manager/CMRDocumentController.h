//
//  CMRDocumentController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 08/02/19.
//  Copyright 2005-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import <AppKit/NSDocumentController.h>

@class CMRThreadSignature;

@interface CMRDocumentController : NSDocumentController {
}

// Returns nil if no document for absoluteDocumentURL is open.
- (NSDocument *)documentAlreadyOpenForURL:(NSURL *)absoluteDocumentURL; // Available in SilverGull and later.

// Returns nil if no document of given boardName are open.
- (NSArray *)documentsForBoardName:(NSString *)boardName; // Available in BathyScaphe 2.4.3 "Matatabi-Step" and later.

- (BOOL)safelyCloseAllDocumentsForBoardName:(NSString *)boardName; // Available in BathyScaphe 2.4.3 "Matatabi-Step" and later.

// At least, 'info' must contain boardName and dat-identifier.
- (BOOL)showDocumentWithContentOfFile:(NSURL *)fileURL boardInfo:(NSDictionary *)info; // Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
- (BOOL)showDocumentWithHistoryItem:(CMRThreadSignature *)historyItem; // Available in BathyScaphe 1.6.4 "Stealth Momo" and later.
@end
