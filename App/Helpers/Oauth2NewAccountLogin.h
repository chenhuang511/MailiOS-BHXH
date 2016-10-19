//
//  Oauth2NewAccountLogin.h
//  iMail
//
//  Created by Macbook Pro on 6/25/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthNavigationViewController.h"

@interface Oauth2NewAccountLogin : NSObject <AuthViewControllerDelegate> {
  NSString *keychain;
  BOOL isAuthenDone;
}

+ (id)shareOauth2NewAccountLogin;
- (void)oauth2NewAccountLogin: (BOOL)_isAuthenDone;

@end
