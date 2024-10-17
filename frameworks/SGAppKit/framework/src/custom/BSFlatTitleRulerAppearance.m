//
//  BSFlatTitileRulerAppearance.m
//  SGAppKit
//
//  Created by Tsutomu Sawada on 2014/11/15.
//
//

#import "BSFlatTitleRulerAppearance.h"

@implementation BSFlatTitleRulerAppearance
@synthesize titleBackgroundColor = m_titleBackgroundColor;
@synthesize inactiveTitleBackgroundColor = m_inactiveTitleBackgroundColor;
@synthesize infoBackgroundColor = m_infoBackgroundColor;
@synthesize titleTextColor = m_titleTextColor;
@synthesize inactiveTitleTextColor = m_inactiveTitleTextColor;
@synthesize infoTextColor = m_infoTextColor;
@synthesize bottomBorderColor = m_bottomBorderColor;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        if ([aDecoder allowsKeyedCoding]) {
            self.titleBackgroundColor = [aDecoder decodeObjectForKey:@"title_bg"];
            self.inactiveTitleBackgroundColor = [aDecoder decodeObjectForKey:@"title_bg_inactive"];
            self.infoBackgroundColor = [aDecoder decodeObjectForKey:@"info_bg"];
            self.titleTextColor = [aDecoder decodeObjectForKey:@"title_text"];
            self.inactiveTitleTextColor = [aDecoder decodeObjectForKey:@"title_text_inactive"];
            self.infoTextColor = [aDecoder decodeObjectForKey:@"info_text"];
            self.bottomBorderColor = [aDecoder decodeObjectForKey:@"bottom_border"];
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if ([aCoder allowsKeyedCoding]) {
        [aCoder encodeObject:self.bottomBorderColor forKey:@"bottom_border"];
        [aCoder encodeObject:self.infoTextColor forKey:@"info_text"];
        [aCoder encodeObject:self.inactiveTitleTextColor forKey:@"title_text_inactive"];
        [aCoder encodeObject:self.titleTextColor forKey:@"title_text"];
        [aCoder encodeObject:self.infoBackgroundColor forKey:@"info_bg"];
        [aCoder encodeObject:self.inactiveTitleBackgroundColor forKey:@"title_bg_inactive"];
        [aCoder encodeObject:self.titleBackgroundColor forKey:@"title_bg"];
    }
}
@end
