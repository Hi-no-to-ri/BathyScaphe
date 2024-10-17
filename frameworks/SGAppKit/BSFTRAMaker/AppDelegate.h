//
//  AppDelegate.h
//  BSFTRAMaker
//
//  Created by Tsutomu Sawada on 2014/11/23.
//
//

#import <Cocoa/Cocoa.h>
#import "BSFlatTitleRulerAppearance.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    BSFlatTitleRulerAppearance *appearance;
}

@property(readwrite, strong) BSFlatTitleRulerAppearance *appearance;

- (IBAction)createFile:(id)sender;
- (IBAction)readFromFile:(id)sender;
@end

