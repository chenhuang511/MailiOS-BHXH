//
//  SINavigationMenuView.m
//  NavigationMenu
//
//  Created by Ivan Sapozhnik on 2/19/13.
//  Copyright (c) 2013 Ivan Sapozhnik. All rights reserved.
//

#import "SINavigationMenuView.h"
#import "SIMenuButton.h"
#import "QuartzCore/QuartzCore.h"
#import "SIMenuConfiguration.h"
#import "TokenType.h"

@interface SINavigationMenuView ()
@property(nonatomic, strong) SIMenuButton *menuButton;
@property(nonatomic, strong) SIMenuTable *table;
@property(nonatomic, strong) UIView *menuContainer;

@end

@implementation SINavigationMenuView

bool buttonIndex0;
bool buttonIndex1;

- (id)initWithFrame:(CGRect)frame title:(NSString *)title {
  buttonIndex0 = false;
  buttonIndex1 = false;
  self = [super initWithFrame:frame];
  if (self) {
    frame.origin.y += 1.0;
    self.menuButton = [[SIMenuButton alloc] initWithFrame:frame];
    self.menuButton.alpha = 0.4;

    self.menuButton.title.text = title;
    [self.menuButton addTarget:self
                        action:@selector(onHandleMenuTap:)
              forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.menuButton];
  }
  return self;
}

- (void)displayMenuInView:(UIView *)view {
  self.menuContainer = view;
}

- (void)itemChecked {
  self.menuButton.alpha = 1;
  buttonIndex0 = true;
}

- (void)itemUnchecked {
  self.menuButton.alpha = 0.4;
  buttonIndex0 = false;
}

#pragma mark -
#pragma mark Actions
- (void)onHandleMenuTap:(id)sender {
  if (self.menuButton.isActive) {
    // NSLog(@"On show");
    [self onShowMenu];
  } else {
    // NSLog(@"On hide");
    [self onHideMenu];
  }
}

- (void)onShowMenu {
  if (!self.table) {
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    CGRect frame = mainWindow.frame;
    // Vị trí khởi tạo menu
    if (IDIOM == IPAD) {
      frame.origin.y = self.frame.size.height;
    } else {
      frame.origin.y +=
          self.frame.size.height +
          [[UIApplication sharedApplication] statusBarFrame].size.height;
    }

    frame.size.width = _SIWidth;

    self.table = [[SIMenuTable alloc] initWithFrame:frame items:self.items];
    self.table.menuDelegate = self;
  }
  [self.menuContainer addSubview:self.table];
  [self rotateArrow:M_PI];
  [self.table show];
}

- (void)onHideMenu {
  [self rotateArrow:0];
  [self.table hide];
}

- (void)rotateArrow:(float)degrees {
  [UIView animateWithDuration:[SIMenuConfiguration animationDuration]
                        delay:0
                      options:UIViewAnimationOptionAllowUserInteraction
                   animations:^{
                     self.menuButton.arrow.layer.transform =
                         CATransform3DMakeRotation(degrees, 0, 0, 1);
                   }
                   completion:NULL];
}

#pragma mark -
#pragma mark Delegate methods
- (void)didSelectItemAtIndex:(NSUInteger)index {
  self.menuButton.isActive = !self.menuButton.isActive;
  [self onHandleMenuTap:nil];
  [self.delegate didSelectItemAtIndex:index];
  if (index == 0) {
    buttonIndex0 = !buttonIndex0;
  }
  if (index == 1) {
    buttonIndex1 = !buttonIndex1;
  }

  if ((!buttonIndex0) && (!buttonIndex1)) {
    self.menuButton.alpha = 0.4;
  } else {
    self.menuButton.alpha = 1;
  }
}

- (void)didBackgroundTap {
  self.menuButton.isActive = !self.menuButton.isActive;
  [self onHandleMenuTap:nil];
}

#pragma mark -
#pragma mark Memory management
- (void)dealloc {
  self.items = nil;
  self.menuButton = nil;
  self.menuContainer = nil;
}

@end
