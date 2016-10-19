//
//  SAMenuButton.m
//  NavigationMenu
//
//  Created by Ivan Sapozhnik on 2/19/13.
//  Copyright (c) 2013 Ivan Sapozhnik. All rights reserved.
//

#import "SIMenuButton.h"
#import "SIMenuConfiguration.h"

@implementation SIMenuButton

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    if ([self defaultGradient]) {

    } else {
      [self setSpotlightCenter:CGPointMake(frame.size.width / 2,
                                           frame.size.height * (-1) + 10)];
      [self setBackgroundColor:[UIColor clearColor]];
      [self setSpotlightStartRadius:0];
      [self setSpotlightEndRadius:frame.size.width];
    }

    frame.origin.y -= 2.0;

    self.title = [[UILabel alloc] initWithFrame:frame];
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.backgroundColor = [UIColor clearColor];
    NSDictionary *currentStyle =
        [[UINavigationBar appearance] titleTextAttributes];
    self.title.textColor = [UIColor whiteColor];
    self.title.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    self.title.shadowColor = currentStyle[UITextAttributeTextShadowColor];
    NSValue *shadowOffset = currentStyle[UITextAttributeTextShadowOffset];
    self.title.shadowOffset = shadowOffset.CGSizeValue;
    [self addSubview:self.title];

    UIImage *userImg = [UIImage imageNamed:@"icon_arrow_down.png"];
    self.arrow = [[UIImageView alloc] initWithImage:userImg];
    [self addSubview:self.arrow];
  }
  return self;
}

- (UIImageView *)defaultGradient {
  return nil;
}

- (void)layoutSubviews {
  self.title.frame = CGRectMake(0, 0, self.frame.size.width, 20);
  self.title.center = CGPointMake(self.frame.size.width / 2,
                                  (self.frame.size.height - 12.0) / 2);

  self.arrow.frame = CGRectMake(self.frame.size.width / 2 - 5,
                                CGRectGetMaxY(self.title.frame) + 2, 10, 6);
}

#pragma mark -
#pragma mark Handle taps
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  self.isActive = !self.isActive;
  // Gradient quanh Button
  // CGGradientRef defaultGradientRef = [[self class] newSpotlightGradient];
  //[self setSpotlightGradientRef:defaultGradientRef];
  // CGGradientRelease(defaultGradientRef);
  return YES;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  return YES;
}
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
  // self.spotlightGradientRef = nil;
}
- (void)cancelTrackingWithEvent:(UIEvent *)event {
  // self.spotlightGradientRef = nil;
}

#pragma mark - Drawing Override
- (void)drawRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGGradientRef gradient = self.spotlightGradientRef;
  float radius = self.spotlightEndRadius;
  float startRadius = self.spotlightStartRadius;
  CGContextDrawRadialGradient(context, gradient, self.spotlightCenter,
                              startRadius, self.spotlightCenter, radius,
                              kCGGradientDrawsAfterEndLocation);
}

#pragma mark - Factory Method

+ (CGGradientRef)newSpotlightGradient {
  size_t locationsCount = 2;
  CGFloat locations[2] = {
      1.0f, 0.0f,
  };
  CGFloat colors[12] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.55f};
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColorComponents(
      colorSpace, colors, locations, locationsCount);
  CGColorSpaceRelease(colorSpace);

  return gradient;
}

- (void)setSpotlightGradientRef:(CGGradientRef)newSpotlightGradientRef {
  CGGradientRelease(_spotlightGradientRef);
  _spotlightGradientRef = nil;

  _spotlightGradientRef = newSpotlightGradientRef;
  CGGradientRetain(_spotlightGradientRef);

  [self setNeedsDisplay];
}

#pragma mark - Deallocation

- (void)dealloc {
  [self setSpotlightGradientRef:nil];
}

@end
