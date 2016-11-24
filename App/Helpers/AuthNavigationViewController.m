//
//  AuthViewController.m
//  ThatInbox
//
//  Created by Andrey Yastrebov on 11.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "AuthNavigationViewController.h"
#import "UIColor+FlatUI.h"
#import "UINavigationBar+FlatUI.h"
#import <QuartzCore/CALayer.h>
#import "Reachability.h"
#import "MailTypeViewController.h"
#import "PreviewViewController.h"
#import "ListFileDocuments.h"

#import "Constants.h"
#import "LoginFormController.h"

@interface AuthNavigationViewController () {
  AuthViewControllerCompletionHandler _completeHandler;
  AuthViewControllerDismissHandler _dismissHandler;
  Reachability *internetReachable;
  UIActivityIndicatorView *_activityIndicator;
}
@end

@implementation AuthNavigationViewController

#pragma mark - Class methods

+ (GTMOAuth2Authentication *)
    authForGoogleFromKeychainForName:(NSString *)keychainItemName
                            clientID:(NSString *)clientID
                        clientSecret:(NSString *)clientSecret {
  return [GTMOAuth2ViewControllerTouch
      authForGoogleFromKeychainForName:keychainItemName
                              clientID:clientID
                          clientSecret:clientSecret];
}

+ (id)controllerWithTitle:(NSString *)title
                    scope:(NSString *)scope
                 clientID:(NSString *)clientID
             clientSecret:(NSString *)clientSecret
         keychainItemName:(NSString *)keychainItemName {
  return [[self alloc] initWithTitle:title
                               scope:scope
                            clientID:clientID
                        clientSecret:clientSecret
                    keychainItemName:keychainItemName];
}

#pragma mark - Init
- (id)initWithTitle:(NSString *)title
               scope:(NSString *)scope
            clientID:(NSString *)clientID
        clientSecret:(NSString *)clientSecret
    keychainItemName:(NSString *)keychainItemName {

  AuthViewController *viewController = [AuthViewController
      controllerWithScope:scope
                 clientID:clientID
             clientSecret:clientSecret
         keychainItemName:keychainItemName
                 delegate:self
         finishedSelector:@selector(viewController:finishedWithAuth:error:)];
  viewController.title = title;

  self = [super initWithRootViewController:viewController];
  if (self) {
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self
                  action:@selector(dismissGoogleView:)
        forControlEvents:UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton =
        [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItem = backButton;

    //        _dismissOnSuccess = NO;
    //        _dismissOnError = NO;
    //
    _activityIndicator = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _activityIndicator.center =
        CGPointMake(self.navigationBar.frame.size.width -
                        _activityIndicator.frame.size.width,
                    self.navigationBar.frame.size.height / 2);
    _activityIndicator.hidden = YES;

    [self.navigationBar addSubview:_activityIndicator];
  }
  return self;
}

- (void)dismissGoogleView:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

// Hung them
+ (id)controllerWithLogin:(NSString *)title {
  return [[self alloc] initWithLogin:title];
}

- (id)initWithLogin:(NSString *)title {
  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor
                                              colorFromHexCode:barColor]];
  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];
    // remove select mail type view
//  MailTypeViewController *viewController =
//      [[MailTypeViewController alloc] init];
//  viewController.title = title;
//
//  self = [super initWithRootViewController:viewController];
    LoginFormController *login = [[LoginFormController alloc] init];
    self = [super initWithRootViewController:login];
    
    [[NSUserDefaults standardUserDefaults] setObject:@"0"
                                              forKey:@"mailtype"];
    // other
    
  if (self) {
    _dismissOnSuccess = NO;
    _dismissOnError = NO;
  }
  return self;
}

- (void)setLogin {
    LoginFormController *login = (LoginFormController *)[self.viewControllers firstObject];
    [login addBackButton];
}

// Preview Image
+ (id)controllerWithPreview:(NSString *)title
                       data:(NSData *)data
                   mimeType:(NSString *)mimeType {
  return [[self alloc] initWithPreview:title data:data mimeType:mimeType];
}

- (id)initWithPreview:(NSString *)title
                 data:(NSData *)data
             mimeType:(NSString *)mimeType {
  PreviewViewController *viewController =
      [[PreviewViewController alloc] initWithPreview:nil
                                              bundle:nil
                                               title:title
                                                data:data
                                            mimeType:mimeType];
  viewController.title = title;
  self = [super initWithRootViewController:viewController];
  if (self) {
    _dismissOnSuccess = NO;
    _dismissOnError = NO;

    // Configure FLATUI NavigationBar
    self.navigationBar.titleTextAttributes =
        @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    [self.navigationBar
        configureFlatNavigationBarWithColor:[UIColor
                                                colorFromHexCode:barColor]];
  }
  return self;
}

#pragma mark - Handler setters
- (void)setCompletionHandler:(AuthViewControllerCompletionHandler)handler {
  _completeHandler = handler;
}

- (void)setDismissHandler:(AuthViewControllerDismissHandler)handler {
  _dismissHandler = handler;
}

#pragma mark - View lifecycle
- (void)viewDidLoad {

  [super viewDidLoad];

  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor colorFromHexCode:barColor]];
  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(startedLoading:)
             name:kGTMOAuth2WebViewStartedLoading
           object:nil];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(stoppedLoading:)
             name:kGTMOAuth2WebViewStoppedLoading
           object:nil];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Presentation

- (void)presentFromRootAnimated:(BOOL)flag
                     completion:(void (^)(void))completion {
  UIViewController *root = [
      [[[UIApplication sharedApplication] delegate] window] rootViewController];

  //[root presentViewController:self animated:flag completion:completion];
  while (root.presentedViewController) {
    root = root.presentedViewController;
  }

  [root presentViewController:self animated:flag completion:completion];
}

#pragma mark - Notifications

- (void)startedLoading:(id)sender {
  if (_activityIndicator) {
    _activityIndicator.hidden = NO;
    [_activityIndicator startAnimating];
  }
}

- (void)stoppedLoading:(id)sender {
  if (_activityIndicator) {
    _activityIndicator.hidden = YES;
    [_activityIndicator stopAnimating];
  }
}

#pragma mark - GTM Oauth Delegate

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
  if (_completeHandler) {
    _completeHandler(self, auth, error);
  }

  if (error) {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(authViewController:
                                                    didFailedWithError:)]) {
      [self.delegate authViewController:self didFailedWithError:error];
    }

    if (self.dismissOnError) {
      [self dismissViewControllerAnimated:NO
                               completion:^{
                                 if (_dismissHandler) {
                                   _dismissHandler(YES);
                                 }
                               }];
    }
  }

  if (auth) {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(authViewController:
                                                      didRetrievedAuth:)]) {
      [self.delegate authViewController:self didRetrievedAuth:auth];
    }

    if (self.dismissOnSuccess) {
      [self dismissViewControllerAnimated:NO
                               completion:^{
                                 if (_dismissHandler) {
                                   _dismissHandler(YES);
                                 }
                               }];
    }
  }
}

@end
