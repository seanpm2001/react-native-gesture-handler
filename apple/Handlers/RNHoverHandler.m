//
//  RNHoverHandler.m
//  RNGestureHandler
//
//  Created by Jakub Piasecki on 31/03/2023.
//

#import "RNHoverHandler.h"

#import <React/RCTConvert.h>

#if !TARGET_OS_OSX
#import <UIKit/UIGestureRecognizerSubclass.h>
#endif

typedef NS_ENUM(NSInteger, RNGestureHandlerHoverEffect) {
  RNGestureHandlerHoverEffectNone = 0,
  RNGestureHandlerHoverEffectLift,
  RNGestureHandlerHoverEffectHightlight,
};

#if !TARGET_OS_OSX && defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && defined(__IPHONE_13_4) && \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4

API_AVAILABLE(ios(13.4))
@interface RNBetterHoverGestureRecognizer : UIHoverGestureRecognizer <UIPointerInteractionDelegate>

- (id)initWithGestureHandler:(RNGestureHandler *)gestureHandler;

@property (nonatomic) RNGestureHandlerHoverEffect hoverEffect;

@end

@implementation RNBetterHoverGestureRecognizer {
  __weak RNGestureHandler *_gestureHandler;
}

- (id)initWithGestureHandler:(RNGestureHandler *)gestureHandler
{
  if ((self = [super initWithTarget:gestureHandler action:@selector(handleGesture:)])) {
    _gestureHandler = gestureHandler;
    _hoverEffect = RNGestureHandlerHoverEffectNone;
  }
  return self;
}

- (void)triggerAction
{
  [_gestureHandler handleGesture:self];
}

- (void)cancel
{
  self.enabled = NO;
}

- (UIPointerStyle *)pointerInteraction:(UIPointerInteraction *)interaction styleForRegion:(UIPointerRegion *)region
{
  if (interaction.view != nil && _hoverEffect != RNGestureHandlerHoverEffectNone) {
    UITargetedPreview *preview = [[UITargetedPreview alloc] initWithView:interaction.view];
    UIPointerEffect *effect = nil;

    if (_hoverEffect == RNGestureHandlerHoverEffectLift) {
      effect = [UIPointerLiftEffect effectWithPreview:preview];
    } else if (_hoverEffect == RNGestureHandlerHoverEffectHightlight) {
      effect = [UIPointerHoverEffect effectWithPreview:preview];
    }

    return [UIPointerStyle styleWithEffect:effect shape:nil];
  }

  return nil;
}

@end

#endif

@implementation RNHoverGestureHandler {
#if !TARGET_OS_OSX && defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && defined(__IPHONE_13_4) && \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4
  UIPointerInteraction *_pointerInteraction;
#endif
}

- (instancetype)initWithTag:(NSNumber *)tag
{
  if ((self = [super initWithTag:tag])) {
#if !TARGET_OS_OSX && defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && defined(__IPHONE_13_4) && \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4
    if (@available(iOS 13.4, *)) {
      _recognizer = [[RNBetterHoverGestureRecognizer alloc] initWithGestureHandler:self];
      _pointerInteraction =
          [[UIPointerInteraction alloc] initWithDelegate:(id<UIPointerInteractionDelegate>)_recognizer];
    }
#endif
  }
  return self;
}

#if !TARGET_OS_OSX && defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && defined(__IPHONE_13_4) && \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_4
- (void)bindToView:(UIView *)view
{
  if (@available(iOS 13.4, *)) {
    [super bindToView:view];
    [view addInteraction:_pointerInteraction];
  }
}

- (void)unbindFromView
{
  if (@available(iOS 13.4, *)) {
    [super unbindFromView];
    [self.recognizer.view removeInteraction:_pointerInteraction];
  }
}

- (void)resetConfig
{
  [super resetConfig];

  if (@available(iOS 13.4, *)) {
    RNBetterHoverGestureRecognizer *recognizer = (RNBetterHoverGestureRecognizer *)_recognizer;
    recognizer.hoverEffect = RNGestureHandlerHoverEffectNone;
  }
}

- (void)configure:(NSDictionary *)config
{
  [super configure:config];

  if (@available(iOS 13.4, *)) {
    RNBetterHoverGestureRecognizer *recognizer = (RNBetterHoverGestureRecognizer *)_recognizer;
    APPLY_INT_PROP(hoverEffect);
  }
}

- (RNGestureHandlerEventExtraData *)eventExtraData:(UIGestureRecognizer *)recognizer
{
  return [RNGestureHandlerEventExtraData forPosition:[recognizer locationInView:recognizer.view]
                                withAbsolutePosition:[recognizer locationInView:recognizer.view.window]];
}
#endif

@end
