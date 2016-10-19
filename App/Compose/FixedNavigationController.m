//
//  FixedNavigationController.m
//  iMail
//
//  Created by HungNP on 8/25/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "FixedNavigationController.h"
#import "MoveToMailboxes.h"

@interface FixedNavigationController ()

@end

@implementation FixedNavigationController

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end
