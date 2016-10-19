//
//  Oauth2NewAccountLogin.m
//  iMail
//
//  Created by Macbook Pro on 6/25/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import "Oauth2NewAccountLogin.h"
#import "GmailConstance.h"
#import "AuthManager.h"
#import "MailTypeViewController.h"

static Oauth2NewAccountLogin *shareOauth = nil;

@implementation Oauth2NewAccountLogin

+ (id)shareOauth2NewAccountLogin {
  if (!shareOauth) {
    shareOauth = [[super allocWithZone:NULL] init];
  }
  return shareOauth;
}

- (void)oauth2NewAccountLogin:(BOOL)_isAuthenDone {

  isAuthenDone = _isAuthenDone;

  NSDate *date = [NSDate date];
  NSTimeInterval ti = [date timeIntervalSince1970];
  keychain = [NSString stringWithFormat:@"%f", ti];
  AuthNavigationViewController *authViewController =
      [AuthNavigationViewController
          controllerWithTitle:NSLocalizedString(@"Login", nil)
                        scope:@"https://mail.google.com/ "
                        @"https://www.google.com/m8/feeds"
                     clientID:CLIENT_ID
                 clientSecret:CLIENT_SECRET
             keychainItemName:keychain];
  authViewController.dismissOnSuccess = YES;
  authViewController.dismissOnError = YES;
  authViewController.delegate = self;
  [authViewController presentFromRootAnimated:YES completion:nil];
}

- (void)authViewController:(AuthViewController *)controller
          didRetrievedAuth:(GTMOAuth2Authentication *)retrievedAuth {
  if ([retrievedAuth accessToken]) {
    [[AuthManager sharedManager] setLoginGTMOAuth2Authentication:retrievedAuth];
    [self finishedAuth:retrievedAuth];
    [MailTypeViewController setAuthenIsDone:isAuthenDone];
  }
}

- (void)finishedAuth:(GTMOAuth2Authentication *)auth {
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  NSInteger accIndex;
  BOOL usedAcc = NO;

  if (listAccount.count == 0) {
    listAccount = [[NSMutableArray alloc] init];
    accIndex = 0;
  } else {
    listAccount =
        [[NSMutableArray alloc] initWithArray:listAccount copyItems:YES];
    accIndex = [listAccount count];

    NSString *email = [auth userEmail];
    for (int i = 0; i < listAccount.count; i = i + 4) {
      NSString *em = [listAccount objectAtIndex:i + 1];
      if ([email isEqualToString:em]) {
        accIndex = i;
        usedAcc = YES;
      }
    }
  }
  if (!usedAcc) {
    [listAccount addObject:keychain];           // keychain
    [listAccount addObject:[auth userEmail]];   // username
    [listAccount addObject:[auth accessToken]]; // accesstoken
    [listAccount addObject:@"2"];               // gmail
    [[NSUserDefaults standardUserDefaults] setObject:[listAccount copy]
                                              forKey:@"listAccount"];
  }
  [[NSUserDefaults standardUserDefaults]
      setObject:[NSString stringWithFormat:@"%ld", (long)accIndex]
         forKey:@"accIndex"];

  [[NSUserDefaults standardUserDefaults] setObject:@"2" forKey:@"mailtype"];

  [AuthManager resetImapSession:YES];
  [[AuthManager sharedManager] getAccountInfo:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu"
                                                      object:nil];
}

@end
