//
//  p22chAuthenticator.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2013/06/01.
//  Copyright 2013 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import <Foundation/Foundation.h>
#import "AppDefaults.h"
#import "w2chConnect.h"

@interface p22chAuthenticator : NSObject<p22chAuthenticationStatus> {
    @private
    NSString *actualHost; // p2.2ch.net or w2.p2.2ch.net ?
    NSString *cookieHeader;
    NSError *lastError;
}

@property (readwrite, retain) NSString *actualHost;

+ (id)defaultAuthenticator;
+ (void)setPreferencesObject:(AppDefaults *)defaults;
@end
