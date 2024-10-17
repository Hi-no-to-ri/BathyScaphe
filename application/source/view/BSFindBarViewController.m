//
//  BSFindBarViewController.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/11/04.
//
//

#import "BSFindBarViewController.h"
#import "BSSearchOptions.h"

@interface BSFindBarViewController ()
- (void)updateSearchOptionButton;
- (void)updateSearchTargetButton;
@end

@implementation BSFindBarViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    if (representedObject && [representedObject isKindOfClass:[BSSearchOptions class]]) {
        [self updateSearchOptionButton];
        [self updateSearchTargetButton];
    }
}

- (void)loadView
{
    [super loadView];
    [self updateSearchOptionButton];
    [self updateSearchTargetButton];
}

- (void)setStatusText:(NSString *)msg status:(BOOL)isSearching
{
    if (isSearching) {
        [progressIndicator startAnimation:self];
    } else {
        [progressIndicator stopAnimation:self];
    }

    if (msg) {
        [statusField setStringValue:msg];
    } else {
        [statusField setStringValue:@""];
    }
}

- (void)updateSearchOptionButton
{
    BSSearchOptions *searchOption = (BSSearchOptions *)[self representedObject];
    
    [[searchOptionButton itemAtIndex:1] setState:([searchOption isCaseInsensitive] ? NSOnState : NSOffState)];
    [[searchOptionButton itemAtIndex:2] setState:([searchOption usesRegularExpression] ? NSOnState : NSOffState)];
}

- (void)updateSearchTargetButton
{
    BSSearchOptions *searchOption = (BSSearchOptions *)[self representedObject];

    for (NSMenuItem *item in [searchTargetButton itemArray]) {
        if ([item tag] < 0 || [item tag] > 16) {
            continue;
        }
        [item setState:(([searchOption targetsMask] & [item tag]) ? NSOnState : NSOffState)];
    }
}

- (IBAction)chooseSearchOption:(id)sender
{
    if (![sender isKindOfClass:[NSPopUpButton class]]) {
        return;
    }
    
    NSPopUpButton *popUpButton = (NSPopUpButton *)sender;
    NSInteger selected = [popUpButton indexOfSelectedItem];
    if (selected == 1) { // case insensitive
        [(BSSearchOptions *)[self representedObject] setIsCaseInsensitive:([[popUpButton itemAtIndex:selected] state] == NSOffState)];
    } else if (selected == 2) { // regular expression
        [(BSSearchOptions *)[self representedObject] setUsesRegularExpression:([[popUpButton itemAtIndex:selected] state] == NSOffState)];
    }
    [self updateSearchOptionButton];
}

- (IBAction)chooseSearchTarget:(id)sender
{
    NSPopUpButton *popUpButton = (NSPopUpButton *)sender;
    NSInteger selectedTag = [[popUpButton selectedItem] tag];
    if (selectedTag < 0 || selectedTag > 16) {
        return;
    }
    [(BSSearchOptions *)[self representedObject] setTarget:([[popUpButton selectedItem] state] == NSOffState) forMask:selectedTag];
    [self updateSearchTargetButton];
}
@end
