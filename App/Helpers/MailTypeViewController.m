//
//  MailTypeViewController.m
//  VNPTCA Mail
//
//  Created by HungNP on 4/25/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "MailTypeViewController.h"
#import "FlatUIKit.h"

#import "LoginFormController.h"
#import "TokenType.h"
#import "MsgListViewController.h"
#import "AuthManager.h"
#import "AuthNavigationViewController.h"

#import "GmailConstance.h"

#import "Oauth2NewAccountLogin.h"

@interface MailTypeViewController () <
    UITableViewDelegate, UITableViewDataSource, AuthViewControllerDelegate>
@end

@implementation MailTypeViewController

static BOOL AuthenIsDone;

UIView *render;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // unlock
  [MsgListViewController setUnlockMail:YES];

  // render bar
  if ([[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"]) {
    self.navigationController.navigationBarHidden = NO;
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self
                  action:@selector(dismissView)
        forControlEvents:UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton =
        [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItem = backButton;
  } else {
    self.navigationController.navigationBarHidden = YES;
  }
  iosVer = [[[UIDevice currentDevice] systemVersion] floatValue];

  // renderView
  [self renderView];
}

+ (void)setAuthenIsDone:(BOOL)isDone {
  AuthenIsDone = isDone;
}
- (void)viewDidAppear:(BOOL)animated {

  [super viewDidAppear:YES];

  if (AuthenIsDone) {
    // sau khi đăng nhập bằng Tk google
    [self dismissView];
    AuthenIsDone = NO;
  }
}

- (void)dismissView {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)renderView {

  UIInterfaceOrientation orientation =
      [UIApplication sharedApplication].statusBarOrientation;
  UIImage *background;
  [backgroundView removeFromSuperview];
  [_tableView removeFromSuperview];
  [render removeFromSuperview];
  backgroundView =
      [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  float bar = self.navigationController.navigationBar.frame.size.height;
  if (IDIOM == IPAD) {
    if (orientation == UIInterfaceOrientationPortrait) {
      background = [UIImage imageNamed:@"bg_login_ipad_portrait.jpg"];
      render = [[UIView alloc]
          initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                                   self.view.bounds.size.height)];
    } else {
      background = [UIImage imageNamed:@"bg_login_ipad_landscape.jpg"];
      render = [[UIView alloc]
          initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height,
                                   self.view.bounds.size.width)];
    }
  } else {
    if (orientation == UIInterfaceOrientationPortrait) {
      background = [UIImage imageNamed:@"bg_login_960@2x.jpg"];
      render = [[UIView alloc]
          initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                                   self.view.bounds.size.height)];

    } else {
      background = nil;
      render = [[UIView alloc]
          initWithFrame:CGRectMake(0, bar, self.view.bounds.size.height,
                                   self.view.bounds.size.width)];
    }
  }

  if (IDIOM == IPAD) {
    if (orientation == UIInterfaceOrientationPortrait) {
      if (iosVer < 7.0) {
        _tableView = [[UITableView alloc]
            initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 50,
                                     self.view.bounds.size.width,
                                     self.view.bounds.size.height)
                    style:UITableViewStyleGrouped];
      } else {
        _tableView = [[UITableView alloc]
            initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 125,
                                     self.view.bounds.size.width,
                                     self.view.bounds.size.height)
                    style:UITableViewStyleGrouped];
      }
    } else {
      _tableView = [[UITableView alloc]
          initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 80,
                                   self.view.bounds.size.width,
                                   self.view.bounds.size.height)
                  style:UITableViewStyleGrouped];
    }
  } else {
    if (orientation == UIInterfaceOrientationPortrait) {

      if (iosVer < 7.0) {
        _tableView = [[UITableView alloc]
            initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 50,
                                     self.view.bounds.size.width, 250)
                    style:UITableViewStyleGrouped];
      } else {
        _tableView = [[UITableView alloc]
            initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 125,
                                     self.view.bounds.size.width, 250)
                    style:UITableViewStyleGrouped];
      }
    } else {
      _tableView = [[UITableView alloc]
          initWithFrame:CGRectMake(0, self.view.bounds.size.height / 2 - 125,
                                   self.view.bounds.size.width, 250)
                  style:UITableViewStyleGrouped];
    }
  }

  _tableView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  _tableView.backgroundColor = [UIColor whiteColor];
  backgroundView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  backgroundView.image = [self imageFromColor:[UIColor whiteColor]];
  backgroundView.contentMode = UIViewContentModeScaleAspectFill;

  [render addSubview:backgroundView];
  [render addSubview:_tableView];
  [self.view addSubview:render];
}

- (void)didRotateFromInterfaceOrientation:
        (UIInterfaceOrientation)fromInterfaceOrientation {
  [self renderView];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *cellidentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:cellidentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellidentifier];
  }

  UIImageView *i = [[UIImageView alloc] init];
  switch (indexPath.row) {
  case 0:
    i.image = [UIImage imageNamed:@"gmail.png"];
    [i setFrame:CGRectMake((self.view.bounds.size.width - 105) / 2, 6, 105,
                           40)];
    [cell addSubview:i];
    break;
  case 1:
    i.image = [UIImage imageNamed:@"yahoo_mail.png"];
    [i setFrame:CGRectMake((self.view.bounds.size.width - 105) / 2, 6, 105,
                           40)];
    [cell addSubview:i];
    break;
  case 2:
    i.image = [UIImage imageNamed:@"outlook_mail.png"];
    [i setFrame:CGRectMake((self.view.bounds.size.width - 105) / 2, 6, 105,
                           40)];
    [cell addSubview:i];
    break;
  case 3:
    i.image = [UIImage imageNamed:@"cauhinhthucong.png"];
    [i setFrame:CGRectMake((self.view.bounds.size.width - 143) / 2, 0, 143,
                           50)];
    [cell addSubview:i];
    break;
  default:
    break;
  };
  return cell;
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath {
  switch (indexPath.row) {
  case 0:
    break;

  default:
    break;
  }
}

- (void)willAnimateRotationToInterfaceOrientation:
            (UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
  _tableView = [[UITableView alloc]
      initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                               self.view.bounds.size.height)
              style:UITableViewStyleGrouped];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [self.view addSubview:_tableView];
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return 4;
}

- (CGFloat)tableView:(UITableView *)tabelView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 50;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
  if (indexPath.section == 0) {
    if (indexPath.row != 0) {
      LoginFormController *login = [[LoginFormController alloc] init];
      [self.navigationController pushViewController:login animated:YES];

      switch (indexPath.row) {
      case 1:
        [[NSUserDefaults standardUserDefaults] setObject:@"3"
                                                  forKey:@"mailtype"];
        // yahoo mail
        break;
      case 2:
        [[NSUserDefaults standardUserDefaults] setObject:@"4"
                                                  forKey:@"mailtype"];
        // outlook mail
        break;
      default:
        [[NSUserDefaults standardUserDefaults] setObject:@"0"
                                                  forKey:@"mailtype"];
        // other
        break;
      }
    } else {

      [[Oauth2NewAccountLogin
        shareOauth2NewAccountLogin] oauth2NewAccountLogin:YES];
    }
  }
}

@end
