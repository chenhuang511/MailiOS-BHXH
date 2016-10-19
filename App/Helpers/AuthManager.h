//
//  AuthManager.h
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import <GContacts/GDataContacts.h>
#import "AuthNavigationViewController.h"
#import "FXKeychain.h"

extern NSString *const HostnameKey;
extern NSString *const SmtpHostnameKey;

@class GDataFeedContact;

@interface AuthManager : NSObject {

  NSInteger accIndex;
  NSString *mtype;
  NSString *imaphost;
  NSString *imapport;
  NSString *smtp;
  NSString *smtpport;
  NSString *username;
  NSString *password;
  NSString *imapemail;
  NSString *imappass;
  NSString *smtpemail;
  NSString *smtppass;
  NSString *keychain;

  BOOL isRefreshOauthSession;
}

@property(nonatomic, strong, readonly) GDataFeedContact *googleContacts;

+ (id)sharedManager;
+ (void)resetImapSession:(BOOL)isReset;

+ (MCOIMAPSession *)getImapSession_;

- (void)refresh_logout;
- (void)refresh_google;
- (void)refreshSession;

- (void)logout;

- (void)setLoginGTMOAuth2Authentication:(GTMOAuth2Authentication *)auth;

- (MCOSMTPSession *)getSmtpSession;
- (MCOIMAPSession *)getImapSession;

- (void)getAccountInfo:(BOOL)isFromMailType;

- (void)requestGoogleContacts:(void (^)(GDataFeedContact *feed,
                                        NSError *error))handler;

@end
