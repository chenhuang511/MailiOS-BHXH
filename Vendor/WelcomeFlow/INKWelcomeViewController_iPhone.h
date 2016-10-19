//
//  INKWelcomeViewController_iPhone.h
//  ThatInbox
//
//  Created by Tran Ha on 27/03/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagedScrollView.h"
@interface INKWelcomeViewController_iPhone : UIViewController
@property IBOutlet PagedScrollView *PageView;

@property UIViewController *nextViewController_iPhone;

+ (BOOL) shouldRunWelcomeFlow_iPhone;
+ (void) setShouldRunWelcomeFlow_iPhone:(BOOL)should;


@end
