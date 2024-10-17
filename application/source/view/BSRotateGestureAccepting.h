//
//  BSRotateGestureAccepting.h
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 2012/11/03.
//
//

#import <AppKit/AppKit.h>

@protocol BSRotateGestureAccepting <NSObject>
@optional
- (void)view:(NSView *)aView rotateEnough:(CGFloat)rotatedDegree;
- (void)view:(NSView *)aView didFinishRotating:(CGFloat)rotatedDegree;
@end
