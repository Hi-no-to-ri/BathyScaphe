//
//  AccountController.m
//  BathyScaphe
//
//  Updated by Tsutomu Sawada on 07/11/21.
//  Copyright 2005-2015 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "AccountController.h"

#import "AppDefaults.h"
#import "PreferencePanes_Prefix.h"
#import "BSAccountViewController.h"

@implementation AccountController
- (id)initWithPreferences:(AppDefaults *)pref
{
    if (self = [super initWithPreferences:pref]) {
        _topLevelItems = [@[@"h_2ch", @"h_2ch_sc"] retain];
        _childrenDict = [@{@"h_2ch": @[@"i_ronin", @"i_be2ch"], @"h_2ch_sc" : @[@"i_p22ch_sc"]} retain];
    }
    return self;
}

- (void)dealloc
{
    [_currentViewController release];
    [_childrenDict release];
    [_topLevelItems release];
    [super dealloc];
}

- (NSString *)mainNibName
{
	return @"AccountPreferences";
}

- (void)swapAccountSettingView:(NSString *)name
{
    if (_currentViewController) {
        [_currentViewController commitEditing]; // 今はあまり価値が無いが一応
        [[_currentViewController view] removeFromSuperview];
        [_currentViewController release];
    }
    NSString *nibName;
    BSKeychainAccountType type;
    if ([name isEqualToString:@"i_ronin"]) {
        nibName = @"AccountSettingRonin";
        type = BSKeychainAccountX2chAuth;
    } else if ([name isEqualToString:@"i_be2ch"]) {
        nibName = @"AccountSettingBe2chNet";
        type = BSKeychainAccountBe2chAuth;
    } else if ([name isEqualToString:@"i_p22ch_sc"]) {
        nibName = @"AccountSettingP22chSc";
        type = BSKeychainAccountP22chNetAuth;
    } else {
        return;
    }

    _currentViewController = [[BSAccountViewController alloc] initWithNibName:nibName bundle:[NSBundle bundleForClass:[self class]]]; // Retained
    _currentViewController.parentPrefController = self;
    _currentViewController.accountType = type;
    NSView *view = [_currentViewController view];
    
    // 手抜き。スワップする view の幅は常に box の幅と同じで、box の高さを超えない前提
    // スワップする view を auto layout 無効にしないと key view loop がオカシクナル
    NSRect tmpframe = [view frame];
    tmpframe.origin.y += (_boxView.bounds.size.height - tmpframe.size.height);
    // auto layout 有効ならこれで済んだんだけど…
//    view.frame = _boxView.bounds;
//    [view setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];
    view.frame = tmpframe;
    [_boxView addSubview:view];
    
    [[self window] recalculateKeyViewLoop];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    if ([_sidebar selectedRow] != -1) {
        NSString *item = [_sidebar itemAtRow:[_sidebar selectedRow]];
        if ([_sidebar parentForItem:item]) {
            // Only change things for non-root items (root items can be selected, but are ignored)
            [self swapAccountSettingView:item];
        }
    }
}

- (void)setupUIComponents
{
    if (!_contentView) {
        return;
    }
    // The basic recipe for a sidebar. Note that the selectionHighlightStyle is set to NSTableViewSelectionHighlightStyleSourceList in the nib
    [_sidebar sizeLastColumnToFit];
    [_sidebar reloadData];
    [_sidebar setFloatsGroupRows:NO];
    
    // Expand all the root items; disable the expansion animation that normally happens
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0];
    [_sidebar expandItem:nil expandChildren:YES];
    [NSAnimationContext endGrouping];
    
    [_sidebar selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];

    [self updateUIComponents];
}

- (NSArray *)_childrenForItem:(id)item
{
    NSArray *children;
    if (!item) {
        children = _topLevelItems;
    } else {
        children = [_childrenDict objectForKey:item];
    }
    return children;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    return [[self _childrenForItem:item] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if (![outlineView parentForItem:item]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return [[self _childrenForItem:item] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return [_topLevelItems containsObject:item];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    // Group Item の脇にマウスオーバー表示される「表示／隠す」ボタンの表示・動作を抑制
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return ![_topLevelItems containsObject:item];
}

- (NSImage *)imageForSidebarIcon:(NSString *)imageName
{
    return [[NSBundle bundleForClass:[self class]] imageForResource:imageName];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    // For the groups, we just return a regular text view.
    if ([_topLevelItems containsObject:item]) {
        NSTableCellView *result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        // Uppercase the string value, but don't set anything else. NSOutlineView automatically applies attributes as necessary
        result.textField.stringValue = [PPLocalizedString(item) uppercaseString];
        return result;
    } else  {
        // The cell is setup in IB. The textField and imageView outlets are properly setup.
        // Special attributes are automatically applied by NSTableView/NSOutlineView for the source list
        NSTableCellView *result = [outlineView makeViewWithIdentifier:@"MainCell" owner:self];
        result.textField.stringValue = PPLocalizedString(item);
        // Setup the icon based on our section
        if ([item isEqualToString:@"i_ronin"]) {
                result.imageView.image = [self imageForSidebarIcon:@"AccountRonin"];
        } else if ([item isEqualToString:@"i_be2ch"]) {
                result.imageView.image = [self imageForSidebarIcon:@"AccountBe2chNet"];
        } else if ([item isEqualToString:@"i_p22ch_sc"]) {
                result.imageView.image = [self imageForSidebarIcon:@"AccountP22chSc"];
        }
        return result;
    }
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    if ([_topLevelItems containsObject:item]) {
        return 17.0;
    } else {
        return 34.0;
    }
}
@end


@implementation AccountController(Toolbar)
- (NSString *)identifier
{
	return PPAccountSettingsIdentifier;
}

- (NSString *)helpKeyword
{
	return PPLocalizedString(@"Help_Account");
}

- (NSString *)label
{
	return PPLocalizedString(@"Account Label");
}

- (NSString *)paletteLabel
{
	return PPLocalizedString(@"Account Label");
}

- (NSString *)toolTip
{
	return PPLocalizedString(@"Account ToolTip");
}

- (NSString *)imageName
{
	return @"AccountsPreferences";
}
@end
