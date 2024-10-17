//
//  EditBoardSheetController.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/09/04.
//  Copyright 2006-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>

@class BoardListItem;
@protocol EditBoardSheetControllerDelegate;

@interface EditBoardSheetController : NSWindowController {
    IBOutlet NSTextField *m_messageField;
    IBOutlet NSTextField *m_warningField;
    IBOutlet NSTextField *m_boardNameField;
    IBOutlet NSTextField *m_URLField;
    IBOutlet NSTextField *m_boardNameLabelField;
    IBOutlet NSTextField *m_URLLabelField;
    
    IBOutlet NSButton   *m_OKButton;

    NSString *editingBoardNameString;
    NSString *editingURLString;
    BoardListItem *targetItem;
    id<EditBoardSheetControllerDelegate> delegate;
    NSString *helpAnchor;
}

- (id)initWithDelegate:(id<EditBoardSheetControllerDelegate>)aDelegate targetItem:(BoardListItem *)anItem;
- (id)initWithDelegate:(id<EditBoardSheetControllerDelegate>)aDelegate;

- (NSTextField *)messageField;
- (NSTextField *)warningField;

@property(readwrite, retain) NSString *editingBoardNameString;
@property(readwrite, retain) NSString *editingURLString;
@property(readwrite, retain) BoardListItem *targetItem;
@property(readwrite, assign) id<EditBoardSheetControllerDelegate> delegate;
@property(readwrite, retain) NSString *helpAnchor;

- (IBAction)pressOK:(id)sender;
- (IBAction)pressCancel:(id)sender;
- (IBAction)pressHelp:(id)sender;

- (void)beginEditBoardSheetForWindow:(NSWindow *)targetWindow;
- (void)beginEditCategorySheetForWindow:(NSWindow *)targetWindow;
- (void)beginAddCategorySheetForWindow:(NSWindow *)targetWindow;
@end


@protocol EditBoardSheetControllerDelegate<NSObject>
@optional
- (void)controller:(EditBoardSheetController *)controller didEndSheetWithReturnCode:(NSInteger)code;
@end
