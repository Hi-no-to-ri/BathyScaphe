//
//  AppDelegate.m
//  BSFTRAMaker
//
//  Created by Tsutomu Sawada on 2014/11/23.
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate
@synthesize appearance;

- (void)awakeFromNib
{
    BSFlatTitleRulerAppearance *blankAppearance = [[BSFlatTitleRulerAppearance alloc] init];
    self.appearance = blankAppearance;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction)createFile:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = @[@"plist"];
    savePanel.canCreateDirectories = YES;
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.appearance];
            [data writeToURL:[savePanel URL] options:NSDataWritingAtomic error:NULL];
        }
    }];
}

- (IBAction)readFromFile:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.canChooseFiles = YES;
    openPanel.resolvesAliases = YES;
    openPanel.allowedFileTypes = @[@"plist"];
    [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSData *data = [NSData dataWithContentsOfURL:[openPanel URL]];
            BSFlatTitleRulerAppearance *readAppearance = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            self.appearance = readAppearance;
        }
    }];
}
@end
