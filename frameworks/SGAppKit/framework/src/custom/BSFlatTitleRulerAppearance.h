//
//  BSFlatTitileRulerAppearance.h
//  SGAppKit
//
//  Created by Tsutomu Sawada on 2014/11/15.
//
//

#import <Cocoa/Cocoa.h>

@interface BSFlatTitleRulerAppearance : NSObject<NSCoding> {
    @private
    NSColor *m_titleBackgroundColor;
    NSColor *m_inactiveTitleBackgroundColor;
    NSColor *m_infoBackgroundColor;
    
    NSColor *m_titleTextColor;
    NSColor *m_inactiveTitleTextColor;
    NSColor *m_infoTextColor;
    
    NSColor *m_bottomBorderColor;
}

@property(readwrite, retain) NSColor *titleBackgroundColor;
@property(readwrite, retain) NSColor *inactiveTitleBackgroundColor;
@property(readwrite, retain) NSColor *infoBackgroundColor;

@property(readwrite, retain) NSColor *titleTextColor;
@property(readwrite, retain) NSColor *inactiveTitleTextColor;
@property(readwrite, retain) NSColor *infoTextColor;

@property(readwrite, retain) NSColor *bottomBorderColor;

@end
