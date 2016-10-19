//
//  MailTypeViewController.h
//  VNPTCA Mail
//
//  Created by HungNP on 4/25/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MailTypeViewController : UIViewController {
  UITableView *_tableView;
  UIImageView *backgroundView;
  float iosVer;

  NSString *keychain;
}

+ (void)setAuthenIsDone: (BOOL)isDone;

@end