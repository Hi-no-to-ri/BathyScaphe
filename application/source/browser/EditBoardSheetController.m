//
//  EditBoardSheetController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 06/09/04.
//  Copyright 2006-2014 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "EditBoardSheetController.h"
#import "CocoMonar_Prefix.h"
#import "BoardManager.h"
#import "BoardListItem.h"

#import "CMRDocumentFileManager.h"
#import "CMRReplyDocumentFileManager.h"
#import "CMRDocumentController.h"
#import "BSBoardInfoInspector.h"
#import "BSModalStatusWindowController.h"
#import "AppDefaults.h"

static NSString *const kEditBoardSheetNibName       = @"EditBoardSheet";
static NSString *const kEditBoardSheetStringsName   = @"BoardListEditor";

static NSString *const kEditBoardSheetHelpAnchorEditBoard = @"Edit Board HelpAnchor";
static NSString *const kEditBoardSheetHelpAnchorEditCategory = @"Edit Category HelpAnchor";
static NSString *const kEditBoardSheetHelpAnchorAddCategory = @"Add Category HelpAnchor";

static NSString *const kEditDrawerItemMsgForAdditionKey = @"Add Category Msg";
static NSString *const kEditDrawerItemMsgForBoardKey = @"Edit Board Msg";
static NSString *const kEditDrawerItemMsgForCategoryKey = @"Edit Category Msg";

@implementation EditBoardSheetController
@synthesize editingBoardNameString;
@synthesize editingURLString;
@synthesize targetItem;
@synthesize delegate;
@synthesize helpAnchor;

- (id)initWithDelegate:(id<EditBoardSheetControllerDelegate>)aDelegate targetItem:(BoardListItem *)anItem
{
    if (self = [super initWithWindowNibName:kEditBoardSheetNibName]) {
        [self window];
        self.delegate = aDelegate;
        self.targetItem = anItem;
    }
    return self;
}

- (id)initWithDelegate:(id<EditBoardSheetControllerDelegate>)aDelegate
{
    return [self initWithDelegate:aDelegate targetItem:nil];
}

- (id)init
{
    return [self initWithDelegate:nil targetItem:nil];
}

- (void)dealloc
{
    [targetItem release];
    [editingBoardNameString release];
    [editingURLString release];
    [helpAnchor release];
    [super dealloc];
}

#pragma mark Accessors
- (NSTextField *)messageField
{
    return m_messageField;
}

- (NSTextField *)warningField
{
    return m_warningField;
}

- (NSButton *)OKButton
{
    return m_OKButton;
}

#pragma mark Actions
- (IBAction)pressOK:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
}

- (IBAction)pressCancel:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
}

- (IBAction)pressHelp:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:self.helpAnchor
                                               inBook:[NSBundle applicationHelpBookName]];
}

- (void)beginEditBoardSheetForWindow:(NSWindow *)targetWindow
{
    NSString *name_ = [[self targetItem] representName];
    NSString *URLStr_ = [[[self targetItem] url] absoluteString];

    NSString *messageTemplate = [self localizedString:kEditDrawerItemMsgForBoardKey];

    [m_URLLabelField setHidden:NO];
    [m_URLField setHidden:NO];
    
    [[self warningField] setStringValue:@""];
    [[self OKButton] setEnabled:YES];

// #warning 64BIT: Check formatting arguments
// 2010-09-06 tsawada2 検証済
    [[self messageField] setStringValue:[NSString localizedStringWithFormat:messageTemplate, name_]];
    [self setEditingBoardNameString:name_];
    [self setEditingURLString:URLStr_];

    self.helpAnchor = [self localizedString:kEditBoardSheetHelpAnchorEditBoard];

    [NSApp beginSheet:[self window]
       modalForWindow:targetWindow
        modalDelegate:self
       didEndSelector:@selector(editBoardSheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)beginEditCategorySheetForWindow:(NSWindow *)targetWindow
{
    NSString *name_ = [[self targetItem] representName];

    NSString *messageTemplate = [self localizedString:kEditDrawerItemMsgForCategoryKey];

    [m_URLLabelField setHidden:YES];
    [m_URLField setHidden:YES];
    
    [m_boardNameField setEnabled:YES];
    
    [[self warningField] setStringValue:@""];
    [[self OKButton] setEnabled:YES];

// #warning 64BIT: Check formatting arguments
// 2010-09-06 tsawada2 検証済
    [[self messageField] setStringValue:[NSString localizedStringWithFormat:messageTemplate, name_]];
    [self setEditingBoardNameString:name_];
    [self setEditingURLString:nil];

    self.helpAnchor = [self localizedString:kEditBoardSheetHelpAnchorEditCategory];

    [NSApp beginSheet:[self window]
       modalForWindow:targetWindow
        modalDelegate:self
       didEndSelector:@selector(editCategorySheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)beginAddCategorySheetForWindow:(NSWindow *)targetWindow
{
    [m_URLLabelField setHidden:YES];
    [m_URLField setHidden:YES];
    
    [m_boardNameField setEnabled:YES];
    
    [[self messageField] setStringValue:[self localizedString:kEditDrawerItemMsgForAdditionKey]];
    [self setEditingBoardNameString:nil];
    [self setEditingURLString:nil];

    self.helpAnchor = [self localizedString:kEditBoardSheetHelpAnchorAddCategory];
    
    [[self warningField] setStringValue:[self localizedString:@"Validation Error 3"]];
    [[self OKButton] setEnabled:NO];

    [NSApp beginSheet:[self window]
       modalForWindow:targetWindow
        modalDelegate:self
       didEndSelector:@selector(addCategorySheetDidEnd:returnCode:delegateInfo:)
          contextInfo:nil];
}

#pragma mark Utilities
+ (NSString *)localizableStringsTableName
{
    return kEditBoardSheetStringsName;
}

- (BOOL)shouldValidateURLString
{
    return ![m_URLField isHidden];
}

- (void)finishSheet:(NSInteger)returnCode
{
    id<EditBoardSheetControllerDelegate> theDelegate = self.delegate;
    if (theDelegate && [theDelegate respondsToSelector:@selector(controller:didEndSheetWithReturnCode:)]) {
        [theDelegate controller:self didEndSheetWithReturnCode:returnCode];
    }
    self.targetItem = nil;
}

#pragma mark Sheet Delegates
- (void)addCategorySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode delegateInfo:(id)aDelegate
{
    if (NSOKButton == returnCode) {
        [[BoardManager defaultManager] addCategoryOfName:[self editingBoardNameString]];
    }

    [sheet close];
    [self finishSheet:returnCode];
}

- (void)editCategorySheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(id)contextInfo
{
    if (NSOKButton == returnCode) {
        [[BoardManager defaultManager] editCategoryItem:[self targetItem] newName:[self editingBoardNameString]];
    }

    [sheet close];
    [self finishSheet:returnCode];
}

- (BOOL)showBeforeYouBeginAlert
{
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert setMessageText:[self localizedString:@"BeforeYouBeginMessage"]];
    [alert setInformativeText:[self localizedString:@"BeforeYouBeginDescription"]];
    [alert addButtonWithTitle:[self localizedString:@"BeforeYouBeginOK"]];
    [[alert addButtonWithTitle:[self localizedString:@"BeforeYouBeginCancel"]] setKeyEquivalent:@"\e"];
    
    NSBeep();
    return ([alert runModal] == NSAlertFirstButtonReturn);
}

- (void)editBoardSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(id)contextInfo
{
    BOOL urlChanged = NO;

    if (NSOKButton == returnCode) {
        NSString *oldBoardURLString = [[[self targetItem] url] absoluteString];
        if (![oldBoardURLString isEqualToString:[self editingURLString]]) {
            // URL に変化あり
            urlChanged = YES;
            if (![[BoardManager defaultManager] editBoardItem:[self targetItem] newURLString:[self editingURLString]]) {
                // URL 変更に失敗したら、以降の処理は行わない
                [sheet close];
                [self finishSheet:NSCancelButton];
                return;
            }
        }

        NSString *oldBoardName = [NSString stringWithString:[[self targetItem] representName]];
        if (![oldBoardName isEqualToString:[self editingBoardNameString]]) {
            // 掲示板名に変化あり
            if (![self showBeforeYouBeginAlert]) {
                [sheet close];
                // URL変更していた場合、そちらはロールバックされないので
                [self finishSheet:(urlChanged ? NSOKButton : NSCancelButton)];
                return;
            }
            
            // 名称変更対象の掲示板に所属するスレッドやその下書きが開いていないか確認する
            NSArray *array = [[CMRDocumentController sharedDocumentController] documentsForBoardName:oldBoardName];
            
            if (array) {
                // 所属するスレッドや下書きが開いていた場合
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                NSString *messageText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"PrepareAlertMessage", @"BoardListEditor", nil), oldBoardName];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:messageText];
                [alert setInformativeText:NSLocalizedStringFromTable(@"PrepareAlertDescription", @"BoardListEditor", nil)];
                [alert addButtonWithTitle:NSLocalizedStringFromTable(@"PrepareAlertContinue", @"BoardListEditor", nil)];
                [alert addButtonWithTitle:NSLocalizedStringFromTable(@"PrepareAlertStop", @"BoardListEditor", nil)];
                
                if ([alert runModal] == NSAlertFirstButtonReturn) {
                    // 「閉じて続ける」
                    [[CMRDocumentController sharedDocumentController] safelyCloseAllDocumentsForBoardName:oldBoardName];
                } else {
                    [sheet close];
                    [self finishSheet:NSCancelButton];
                    return;
                }
            }

            BOOL shouldRestoreBoardInfoInspector = ([[BSBoardInfoInspector sharedInstance] isWindowLoaded] && [[[BSBoardInfoInspector sharedInstance] window] isVisible]);
            NSString *boardInfoInspectorTargetBoardName = nil;
            BOOL useNewBoardNameForRestore = NO;
            
            // 「掲示板オプション」が開いている場合はいったん閉じる
            if (shouldRestoreBoardInfoInspector) {
                boardInfoInspectorTargetBoardName = [NSString stringWithString:[[BSBoardInfoInspector sharedInstance] currentTargetBoardName]];
                if ([boardInfoInspectorTargetBoardName isEqualToString:oldBoardName]) {
                    useNewBoardNameForRestore = YES;
                }
                [[[BSBoardInfoInspector sharedInstance] window] performClose:self];
            }
            
            NSError *error = nil;

            BSModalStatusWindowController *winController;
            winController = [[BSModalStatusWindowController alloc] init];
            
            NSModalSession session = [NSApp beginModalSessionForWindow:[winController window]];
            
            // ログファイルを新しい名前の掲示板サブフォルダにコピー
            BOOL logCopySuccess = [[CMRDocumentFileManager defaultManager] copyAllLogFilesFrom:oldBoardName to:[self editingBoardNameString] modalStatus:winController session:session error:&error];
            if (error) {
                NSModalResponse response = [[NSAlert alertWithError:error] runModal];
                if (!logCopySuccess || (response == NSAlertSecondButtonReturn)) { // ErrorRecoveryStopOption を選択した場合
                    [NSApp endModalSession:session];
                    [winController close];
                    [winController release];
                    
                    [sheet close];
                    [self finishSheet:NSCancelButton];
                    return;
                }
                
                // 続ける可能性もある
            }
            
            // 下書きファイルを新しい名前の掲示板サブフォルダにコピー
            BOOL replyCopySuccess = [[CMRReplyDocumentFileManager defaultManager] copyAllReplyDocumentsFrom:oldBoardName to:[self editingBoardNameString] modalStatus:winController session:session error:&error];
            if (error)  {
                NSModalResponse response = [[NSAlert alertWithError:error] runModal];
                if (!replyCopySuccess || (response == NSAlertSecondButtonReturn)) { // ErrorRecoveryStopOption を選択した場合
                    [NSApp endModalSession:session];
                    [winController close];
                    [winController release];

                    [sheet close];
                    [self finishSheet:NSCancelButton];
                    return;
                }
                
                // 続ける可能性もある
            }
            
            [[winController progressIndicator] setIndeterminate:YES];
            [[winController progressIndicator] startAnimation:nil];
            [[winController infoTextField] setStringValue:@""];
            
            [NSApp runModalSession:session];

            [[winController messageTextField] setStringValue:NSLocalizedStringFromTable(@"Passing Board Properties...", @"BoardListEditor", nil)];
            
            [NSApp runModalSession:session];
            
            // 掲示板の迷惑レス設定ファイルを新しい名前の掲示板サブフォルダにコピー
            NSError *underlyingError = nil;
            if (![[BoardManager defaultManager] copySpamCorpusFileFrom:oldBoardName to:[self editingBoardNameString] error:&underlyingError]) {
                // コピーに失敗した場合はエラーを表示するが、処理は続行
                if (underlyingError) {
                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                    [alert setAlertStyle:NSCriticalAlertStyle];
                    [alert setMessageText:NSLocalizedStringFromTable(@"SpamSamplesCopyErrorDescription", @"BoardListEditor", nil)];
                    [alert setInformativeText:[NSString stringWithFormat:@"%@ (%@ %ld)", [underlyingError localizedDescription], [underlyingError domain], (long)[underlyingError code]]];
                    [alert runModal];
                }
            }

            [NSApp runModalSession:session];
            
            // 掲示板オプションの内部辞書で、掲示板名を付け替え（ファイルのコピーはしない）
            [[BoardManager defaultManager] passPropertiesOfBoardName:oldBoardName toBoardName:[self editingBoardNameString]];
            
            [[winController messageTextField] setStringValue:NSLocalizedStringFromTable(@"Editing Board List Item...", @"BoardListEditor", nil)];
            
            [NSApp runModalSession:session];
            [[BoardManager defaultManager] editBoardItem:[self targetItem] newBoardName:[self editingBoardNameString]];
            
            // 最後に、古い名前の掲示板サブフォルダを削除
            [[winController messageTextField] setStringValue:NSLocalizedStringFromTable(@"Removing Old Folder...", @"BoardListEditor", nil)];
            [NSApp runModalSession:session];
            
            NSError *deletionError = nil;
            if (![[CMRDocumentFileManager defaultManager] deleteLogFolderOfBoardName:oldBoardName error:&deletionError]) {
                // 削除に失敗した場合はエラーを表示するが、処理は続行
                if (deletionError) {
                    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                    [alert setAlertStyle:NSCriticalAlertStyle];
                    [alert setMessageText:NSLocalizedStringFromTable(@"OldFolderDeletionErrorDescription", @"BoardListEditor", nil)];
                    [alert setInformativeText:[NSString stringWithFormat:@"%@ (%@ %ld)", [deletionError localizedDescription], [deletionError domain], (long)[deletionError code]]];
                    [alert runModal];
                }
            }

            [NSApp endModalSession:session];
            [winController close];
            [winController release];
            
            // 最後に開いていた掲示板の情報を、必要なら更新
            if ([[CMRPref browserLastBoard] isEqualToString:oldBoardName]) {
                [CMRPref setBrowserLastBoard:[self editingBoardNameString]];
            }
            
            // 「掲示板オプション」必要があれば復帰
            if (shouldRestoreBoardInfoInspector) {
                [[BSBoardInfoInspector sharedInstance] showInspectorForTargetBoard:(useNewBoardNameForRestore ? [self editingBoardNameString] : boardInfoInspectorTargetBoardName)];
            }
        }
    }

    [sheet close];
    [self finishSheet:returnCode];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    // 簡単な入力文字列チェックを行う
    if (!self.editingBoardNameString || [self.editingBoardNameString isEqualToString:@""]) {
        [[self warningField] setStringValue:[self localizedString:@"Validation Error 3"]];
        [[self OKButton] setEnabled:NO];
        return;
    } else if ([self shouldValidateURLString] && (!self.editingURLString || [self.editingURLString isEqualToString:@""])) {
        [[self warningField] setStringValue:[self localizedString:@"Validation Error 4"]];
        [[self OKButton] setEnabled:NO];
        return;
    } else if ([self shouldValidateURLString] && ![self.editingURLString hasPrefix:@"http://"]) {
        [[self warningField] setStringValue:[self localizedString:@"Validation Error 1"]];
        [[self OKButton] setEnabled:NO];
        return;
    } else if ([self shouldValidateURLString] && ![self.editingURLString hasSuffix:@"/"]) {
        [[self warningField] setStringValue:[self localizedString:@"Validation Error 2"]];
        [[self OKButton] setEnabled:NO];
        return;
    }		
    [m_warningField setStringValue:@""];
    [[self OKButton] setEnabled:YES];
}
@end
