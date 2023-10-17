//
//  RNRootViewGestureRecognizer.m
//  RNGestureHandler
//
//  Created by Krzysztof Magiera on 12/10/2017.
//  Copyright © 2017 Software Mansion. All rights reserved.
//

#import "RNRootViewGestureRecognizer.h"

#if !TARGET_OS_OSX
#import <UIKit/UIGestureRecognizerSubclass.h>
#endif

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTSurfaceTouchHandler.h>
#else
#import <React/RCTTouchHandler.h>
#endif // RCT_NEW_ARCH_ENABLED

@implementation RNRootViewGestureRecognizer {
    BOOL _active;
}

@dynamic delegate;

- (instancetype)init
{
#if !TARGET_OS_OSX
    if (self = [super init]) {
        self.delaysTouchesEnded = NO;
        self.delaysTouchesBegan = NO;
    }
#else
    self = [super init];
#endif
    return self;
}

- (BOOL)shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // This method is used to implement "enabled" feature for gesture handlers. We enforce gesture
    // recognizers that are connected with "disabled" handlers to wait for the root gesture
    // recognizer to fail and this way we block them from acting.
    RNGestureHandler *otherHandler = [RNGestureHandler findGestureHandlerByRecognizer:otherGestureRecognizer];
    if (otherHandler != nil && otherHandler.enabled == NO) {
        return YES;
    }
    return NO;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    return ![preventedGestureRecognizer isKindOfClass:[
#ifdef RCT_NEW_ARCH_ENABLED
        RCTSurfaceTouchHandler
#else
        RCTTouchHandler
#endif
        class]];
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    // When this method is called it means that one of handlers has activated, in this case we want
    // to send an info to JS so that it cancells all JS responders, as long as the preventing
    // recognizer is from Gesture Handler, otherwise we might break some interactions
    RNGestureHandler *handler = [RNGestureHandler findGestureHandlerByRecognizer:preventingGestureRecognizer];
    if (handler != nil) {
        [self.delegate gestureRecognizer:preventingGestureRecognizer didActivateInViewWithTouchHandler:self.view];
    }
    
    return [super canBePreventedByGestureRecognizer:preventingGestureRecognizer];
}

#if !TARGET_OS_OSX
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _active = YES;
    self.state = UIGestureRecognizerStatePossible;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStatePossible;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateEnded;
    } else {
        self.state = UIGestureRecognizerStateFailed;
    }
    [self reset];
    _active = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateCancelled;
    [self reset];
    _active = NO;
}
#else
- (void)mouseDown:(NSEvent *)event {
    _active = YES;
    self.state = UIGestureRecognizerStatePossible;
}

- (void)mouseDragged:(NSEvent *)event {
    self.state = UIGestureRecognizerStatePossible;
}

- (void)mouseUp:(NSEvent *)event {
    if (self.state == UIGestureRecognizerStateBegan || self.state == UIGestureRecognizerStateChanged) {
        self.state = UIGestureRecognizerStateEnded;
    } else {
        self.state = UIGestureRecognizerStateFailed;
    }
    [self reset];
    _active = NO;
}

- (void)touchesCancelledWithEvent:(NSEvent *)event {
    self.state = UIGestureRecognizerStateCancelled;
    [self reset];
    _active = NO;
}
#endif

- (void)blockOtherRecognizers
{
    if (_active) {
        self.state = UIGestureRecognizerStateBegan;
    }
}

@end
