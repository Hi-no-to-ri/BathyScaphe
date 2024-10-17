//
//  CMRStatusLineWindowController.h
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 09/02/14.
//  Copyright 2006-2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Cocoa/Cocoa.h>
#import <SGAppKit/SGAppKit.h>
#import "CocoMonar_Prefix.h"
#import "CMRToolbarDelegate.h"

@protocol CMRToolbarDelegate;

@interface CMRStatusLineWindowController: NSWindowController<NSWindowDelegate, NSUserInterfaceValidations>
{
	@private
	id<CMRToolbarDelegate>		m_toolbarDelegateImp;
    IBOutlet NSSegmentedControl *m_indexingNavigator;
    IBOutlet NSTextField        *m_statusMessageField;
    IBOutlet NSObjectController *m_taskObjectController;
    IBOutlet NSTextField        *m_numberOfMessagesField;
    IBOutlet NSProgressIndicator *m_progressIndicator;
}
+ (Class)toolbarDelegateImpClass;
- (id<CMRToolbarDelegate>)toolbarDelegate;

// board / thread signature for historyManager .etc
- (id)threadIdentifier;

- (NSSegmentedControl *)indexingNavigator;
- (NSTextField *)statusMessageField;
- (NSObjectController *)taskObjectController;
- (NSTextField *)numberOfMessagesField;
- (NSProgressIndicator *)progressIndicator;
@end


@interface CMRStatusLineWindowController(Action)
- (IBAction)saveAsDefaultFrame:(id)sender;
- (IBAction)cancelCurrentTask:(id)sender;
- (IBAction)toggleNavigationBarShown:(id)sender;
@end


@interface CMRStatusLineWindowController(ViewInitializer)
- (void)setupNavigationBarComponents:(BOOL)isShown isFirst:(BOOL)isFirst;
- (void)setupUIComponents;
+ (NSUInteger)defaultWindowCollectionBehaviorForLion; // For Lion Full-Screen App Support.

- (void)setNavigationBarControlsHidden:(BOOL)isHidden;
@end

extern NSString *const BSShouldValidateIdxNavNotification;
