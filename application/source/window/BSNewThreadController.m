//
//  BSNewThreadController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 08/02/09.
//  Copyright 2008-2011 BathyScaphe Project. All rights reserved.
//

#import "BSNewThreadController.h"
#import "CMRReplyControllerTbDelegate.h"

@implementation BSNewThreadController
- (NSTextField *)subjectField
{
	return m_subjectField;
}

- (NSString *)windowNibName
{
	return @"BSNewThreadWindow";
}

- (IBAction)saveAsDefaultFrame:(id)sender
{
	// Not Supported
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action_ = [anItem action];
	if (action_ == @selector(saveAsDefaultFrame:)) {
		return NO;
	}

	return [super validateUserInterfaceItem:anItem];
}

- (void)markUnableToEncodeCharacters:(NSIndexSet *)indexes forKey:(NSString *)formKey
{
    NSText *textView = nil;
    if ([formKey isEqualToString:@"MESSAGE"]) {
        textView = [self textView];
    } else if ([formKey isEqualToString:@"mail"]) {
        if ([[self window] makeFirstResponder:[self mailField]]) {
            textView = [[self mailField] currentEditor];
        }
    } else if ([formKey isEqualToString:@"FROM"]) {
        if ([[self window] makeFirstResponder:[self nameComboBox]]) {
            textView = [[self nameComboBox] currentEditor];
        }
    } else if ([formKey isEqualToString:@"subject"]) {
        if ([[self window] makeFirstResponder:[self subjectField]]) {
            textView = [[self subjectField] currentEditor];
        }
    }
    if (!textView) {
        return;
    }
    [self markUnableToEncodeCharacters:indexes atView:(NSTextView *)textView];
}
@end


@implementation BSNewThreadController(View)
+ (Class)toolbarDelegateImpClass 
{ 
	return [BSNewThreadControllerTbDelegate class];
}

- (void)setupWindowFrameWithMessenger
{
	[self setWindowFrameAutosaveName:@"BathyScaphe:New Thread Window Autosave"];
	[[self window] useOptimizedDrawing:YES];
}

- (void)setupKeyLoops
{
	[[self subjectField] setNextKeyView:[self nameComboBox]];
	[[self nameComboBox] setNextKeyView:[self mailField]];
	[[self mailField] setNextKeyView:[self sageButton]];
	[[self sageButton] setNextKeyView:[self deleteMailButton]];
	[[self deleteMailButton] setNextKeyView:[self textView]];
	[[self textView] setNextKeyView:[self subjectField]];
	[[self window] setInitialFirstResponder:[self subjectField]];
	[[self window] makeFirstResponder:[self subjectField]];
}
@end
