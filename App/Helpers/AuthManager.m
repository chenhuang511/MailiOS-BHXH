//
//  AuthManager.m
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "AuthManager.h"
#import "GmailConstance.h"
#import "Oauth2NewAccountLogin.h"

/***********************************************************************

 You'll need a Gmail Client ID and Secret. Takes about 5 minutes.

 1. Go to the Google API Console:
 code.google.com/apis/console

 2. After logging in, you'll need to create a project.

 If this is your first project, it'll be a central button.
 Otherwise, it'll be the the menu on the left hand side.

 3. Configure it.

 - You won't been to select any services when asked.
 - Select "API Access" on the left hand menu.
 - Create an OAuth 2.0 client ID
 - Fill out the form. You can get the icon from
 ThatInbox/Graphics/AppIcons/icon.png
 - On the next page, you'll select "Installed application"
 - Select iOS. You'll need to specify the bundle id. Use the bundle id, which is
 set to com.inkmobility.thatinbox.
 - The App Store ID ad Deep Linking are optional and you should leave them
 blank.

 4. Copy your Client ID and Client Secret below

 5. Remove the #error line to proceed.

 ************************************************************************/

static MCOIMAPSession *returnImap;

static BOOL isResetImapSession = YES;

@interface AuthManager () <AuthViewControllerDelegate>

@property(nonatomic, strong) MCOIMAPSession *imapSession;
@property(nonatomic, strong) MCOSMTPSession *smtpSession;
@property(nonatomic, strong) GTMOAuth2Authentication *auth;

@property(nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property(nonatomic, strong) NSMutableArray *listAccount;

@end

@implementation AuthManager

#define Oauth2_Error 0

BOOL allow = YES;

+ (void)resetImapSession:(BOOL)isReset {
  isResetImapSession = isReset;
}

+ (id)sharedManager {
  static dispatch_once_t pred = 0;
  __strong static id _sharedObject = nil;
  dispatch_once(&pred, ^{
    _sharedObject = [[self alloc] init];
    [_sharedObject startLogin];
  });

  return _sharedObject;
}

- (void)setLoginGTMOAuth2Authentication:(GTMOAuth2Authentication *)auth {
  self.auth = auth;
}

- (void)refresh_logout {
  isResetImapSession = YES;
  [self startLogin];
}

- (void)refresh_google {
  GTMOAuth2Authentication *auth =
      [AuthViewController authForGoogleFromKeychainForName:keychain
                                                  clientID:CLIENT_ID
                                              clientSecret:CLIENT_SECRET];

  // Authen thất bại; Đăng nhập lại
  if ([auth refreshToken] == nil) {

    [[Oauth2NewAccountLogin shareOauth2NewAccountLogin]
        oauth2NewAccountLogin:NO];

  } else {

    // Authen thành công; Yêu cầu token phía máy chủ Google
    [auth beginTokenFetchWithDelegate:self
                    didFinishSelector:@selector(auth:
                                          finishedRefreshWithFetcher:
                                                               error:)];
  }
}

- (void)auth:(GTMOAuth2Authentication *)auth
    finishedRefreshWithFetcher:(GTMHTTPFetcher *)fetcher
                         error:(NSError *)error {

  /* Lấy token thành công: kết thúc Authen
    Nếu xảy ra lỗi từ chối đăng nhập, mã lỗi như sau:
    Error Domain=com.google.HTTPStatus Code=400 "The operation couldn’t be
    completed. (com.google.HTTPStatus error 400.)" UserInfo=0x1742602c0 {json={
        error = "invalid_grant";
        "error_description" = "Token has been revoked.";
    }
   */
  if (error == nil || error.code != 400) {
    [self finishedAuth:auth];
  } else {

    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Notifi", nil)
                  message:NSLocalizedString(@"FailAndBeginLoginGmail", nil)
                 delegate:self
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil];
    alert.tag = Oauth2_Error;
    [alert show];
  }
}

- (void)authViewController:(AuthViewController *)controller
          didRetrievedAuth:(GTMOAuth2Authentication *)retrievedAuth {
  if ([retrievedAuth accessToken]) {
    [self finishedAuth:retrievedAuth];
    [self finishedFirstAuth:retrievedAuth];
  }
}

- (void)authViewController:(AuthViewController *)controller
        didFailedWithError:(NSError *)error {
  NSLog(@"error occurred: %@", error.localizedDescription);
}

- (void)finishedFirstAuth:(GTMOAuth2Authentication *)auth {

  self.auth = auth;
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"Finished_FirstOAuth"
                    object:nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"Finished_OAuth"
                                                      object:nil];
}

- (void)finishedAuth:(GTMOAuth2Authentication *)auth {

  self.auth = auth;
  [self requestGoogleContacts:nil];
  if (isRefreshOauthSession == NO) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Finished_OAuth"
                                                        object:nil];
  } else {
    isRefreshOauthSession = NO;
  }
}

- (void)getAccountInfo:(BOOL)isFromMailType {

  self.listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];

  if (accIndex < self.listAccount.count) {
    username = [self.listAccount objectAtIndex:accIndex + 1];
    password = [self.listAccount objectAtIndex:accIndex + 2];
    mtype = [self.listAccount objectAtIndex:accIndex + 3];
    switch ([mtype integerValue]) {
    case 2:
      imaphost = @"imap.gmail.com";
      imapport = @"993";
      smtp = @"smtp.gmail.com";
      smtpport = @"465";
      break;
    case 3:
      imaphost = @"imap.mail.yahoo.com";
      imapport = @"993";
      smtp = @"smtp.mail.yahoo.com";
      smtpport = @"465";
      break;
    case 4:
      imaphost = @"imap-mail.outlook.com";
      imapport = @"993";
      smtp = @"smtp-mail.outlook.com";
      smtpport = @"587";
      break;
    default: {
      NSMutableArray *customInfo = [[NSMutableArray alloc] init];
      NSArray *copy =
          [[NSUserDefaults standardUserDefaults] objectForKey:@"customInfo"];
      customInfo = [copy mutableCopy];
      if (customInfo.count > 0) {
        for (int i = 0; i < customInfo.count; i = i + 9) {
          if ([[customInfo objectAtIndex:i] isEqualToString:mtype]) {
            imaphost = [customInfo objectAtIndex:i + 1];
            imapport = [customInfo objectAtIndex:i + 2];
            imapemail = [customInfo objectAtIndex:i + 3];
            imappass = [customInfo objectAtIndex:i + 4];
            smtp = [customInfo objectAtIndex:i + 5];
            smtpport = [customInfo objectAtIndex:i + 6];
            smtpemail = [customInfo objectAtIndex:i + 7];
            smtppass = [customInfo objectAtIndex:i + 8];
            break;
          }
        }
      }

    } break;
    }
    self.imapSession = [[MCOIMAPSession alloc] init];
    self.imapSession.port = [imapport intValue];
    self.imapSession.username = username;
    self.imapSession.hostname = imaphost;
    self.imapSession.connectionType = MCOConnectionTypeTLS;

    /* Với gmail: nếu đăng nhập mới (isFromMailType = YES) thì sử dụng
      accessToken lưu trong Userdefault từ bước đăng nhập trước
      nếu đăng nhập từ trạng thái đã có sẵn tài khoản trong ListAccount thì get
      lại self.auth */

    if ([mtype isEqualToString:@"2"]) {
      if (!isFromMailType) {
        keychain = [self.listAccount objectAtIndex:accIndex];
        [self refresh_google];
      } else {
        self.imapSession.OAuth2Token = password;
        self.imapSession.authType = MCOAuthTypeXOAuth2;
        [self finishedFirstAuth:self.auth];
      }
    } else {
      // Các loại mail khác
      self.imapSession.password = password;
      [self.imapSession setCheckCertificateEnabled:NO];
      returnImap = self.imapSession;
      [self finishedAuth:nil];
    }

    // save custom session date
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:@"sessionDate"];
    [userDefaults synchronize];

  } else {
    if ([self.listAccount count] > 0) {
      accIndex = 0;
      [[NSUserDefaults standardUserDefaults]
          setObject:[NSString stringWithFormat:@"%d", (int)accIndex]
             forKey:@"accIndex"];
      [self getAccountInfo:NO];
    } else {
      [self startLogin];
    }
  }
}

- (MCOIMAPSession *)getImapSession {

  // Nếu không tồn tại IMAP Session thì đăng nhập lại
  if (isResetImapSession) {

    self.listAccount =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];

    if (!imaphost.length > 0) {
      if (self.listAccount.count == 0) {
        AuthNavigationViewController *authViewController =
            [AuthNavigationViewController
                controllerWithLogin:NSLocalizedString(@"iMailLogin", nil)];
        authViewController.dismissOnSuccess = YES;
        authViewController.dismissOnError = YES;
        authViewController.delegate = self;
        [authViewController presentFromRootAnimated:YES completion:nil];
        return nil;
      }
      [self getAccountInfo:NO];
    }

    /* đề phòng trong lúc biến "isResetImapSession" reset về YES thì có 1 tiến
     trình getImapSession của tài khoản cũ xen vào */
    if (self.listAccount.count > 0) {
      if ([[self.listAccount objectAtIndex:accIndex + 1]
              isEqualToString:self.imapSession.username]) {
        isResetImapSession = NO;
      } else {
        [self.imapSession setCheckCertificateEnabled:NO];
        return self.imapSession;
      }
    } else {
      return nil;
    }

    MCOIMAPSession *imapSession = [[MCOIMAPSession alloc] init];

    imapSession.hostname = imaphost;
    imapSession.port = [imapport intValue];
    imapSession.username = username;
    imapSession.connectionType = MCOConnectionTypeTLS;

    if ([mtype isEqualToString:@"2"]) {
      // Tai khoan gmail
      if ([self.auth accessToken].length > 0) {
        imapSession.username = [self.auth userEmail];
        imapSession.password = @"";
        imapSession.OAuth2Token = [self.auth accessToken]; // access token
        imapSession.authType = MCOAuthTypeXOAuth2;
      } else {
        return nil;
      }

    } else {
      imapSession.password = password;
    }

    [imapSession setCheckCertificateEnabled:NO];

    self.imapSession = imapSession;

    // save custom session date
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:@"sessionDate"];
    [userDefaults synchronize];
  } else {

    // check current session expired
    if (self.imapSession) {
      NSDate *currentDate = [NSDate date];
      if ([mtype isEqualToString:@"2"]) {
        int overtime =
            (int)[self.auth.expirationDate timeIntervalSinceDate:currentDate] /
            60;
        // Gmail: tạo session mới 15 phút trước khi session cũ hết hạn
        if (overtime < 15) {
          NSLog(@"Prepare refresh session Gmail");
          [self performSelector:@selector(refreshSession)
                     withObject:self
                     afterDelay:3.0];
        }
      } else {
        // Các loại mail khác: tạo session mới 30 phút sau khi session cũ được
        // khởi tạo
        NSDate *sessionDate =
            [[NSUserDefaults standardUserDefaults] objectForKey:@"sessionDate"];
        int intervall =
            (int)[currentDate timeIntervalSinceDate:sessionDate] / 60;
        if (intervall > 30) {
          NSLog(@"Prepare refresh session Other Mail");
          [self performSelector:@selector(refreshSession)
                     withObject:self
                     afterDelay:3.0];
        }
      }
    }
  }

  returnImap = self.imapSession;

  return self.imapSession;
}

+ (MCOIMAPSession *)getImapSession_ {
  return returnImap;
}

- (void)startLogin {

  self.listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (self.listAccount.count == 0) {
    AuthNavigationViewController *authViewController =
        [AuthNavigationViewController
            controllerWithLogin:NSLocalizedString(@"iMailLogin", nil)];
    authViewController.dismissOnSuccess = YES;
    authViewController.dismissOnError = YES;
    authViewController.delegate = self;
    [authViewController presentFromRootAnimated:YES completion:nil];
    return;
  }
  [self getAccountInfo:NO];
}

- (void)loadAccountWithUsername:(NSString *)username
                       password:(NSString *)password
                       hostname:(NSString *)hostname
                       imapport:(NSString *)imapport
                    oauth2Token:(NSString *)oauth2Token {
  AuthManager *__weak weakSelf = self;
  self.imapSession.connectionLogger =
      ^(void *connectionID, MCOConnectionLogType type, NSData *data) {
        @synchronized(weakSelf) {
          if (type != MCOConnectionLogTypeSentPrivate) {
          }
        }
      };
  self.imapCheckOp = [self.imapSession checkAccountOperation];
  [self.imapCheckOp start:^(NSError *error) {
    AuthManager *strongSelf = weakSelf;
    NSLog(@"finished checking account AuthManager.");
    if (error == nil) {
    } else {
    }
    strongSelf.imapCheckOp = nil;
  }];
}

- (void)requestGoogleContacts:(void (^)(GDataFeedContact *feed,
                                        NSError *error))handler {
  if (!self.googleContacts) {
    if (!self.auth) {
      if (handler) {
        handler(nil, nil);
      }
    }

    GDataServiceGoogleContact *service = [self contactService];
    GDataServiceTicket *ticket;

    NSURL *feedURL = [GDataServiceGoogleContact
        contactFeedURLForUserID:kGDataServiceDefaultUser
                     projection:kGDataGoogleContactFullProjection];

    GDataQueryContact *query =
        [GDataQueryContact contactQueryWithFeedURL:feedURL];
    [query setShouldShowDeleted:NO];
    [query setMaxResults:2000];

    ticket =
        [service fetchFeedWithQuery:query
                  completionHandler:^(GDataServiceTicket *ticket,
                                      GDataFeedBase *feed, NSError *error) {
                    if (!error) {
                      _googleContacts = (GDataFeedContact *)feed;
                    }

                    if (handler) {
                      handler((GDataFeedContact *)feed, error);
                    }
                  }];
  }

  if (handler) {
    handler(self.googleContacts, nil);
  }
}

- (GDataServiceGoogleContact *)contactService {
  static GDataServiceGoogleContact *service = nil;

  if (!service) {
    service = [[GDataServiceGoogleContact alloc] init];

    [service setShouldCacheResponseData:YES];
    [service setServiceShouldFollowNextLinks:YES];
  }

  if ([mtype isEqualToString:@"2"]) {
    [service setAuthorizer:self.auth];
  } else {
    [service setUserCredentialsWithUsername:username password:password];
  }
  return service;
}

- (MCOSMTPSession *)getSmtpSession {

  if (!self.smtpSession || self.smtpSession.username != username) {

    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    smtpSession.hostname = smtp;
    smtpSession.port = [smtpport intValue];
    smtpSession.username = username;
    smtpSession.password = password;
    switch ([mtype integerValue]) {
    case 2:
      smtpSession.connectionType = MCOConnectionTypeTLS;
      smtpSession.authType = MCOAuthTypeXOAuth2;
      smtpSession.password = @"";
      smtpSession.OAuth2Token = [self.auth accessToken];
      break;
    case 3:
      smtpSession.checkCertificateEnabled = NO;
      smtpSession.connectionType = MCOConnectionTypeTLS;
      break;
    case 4:
      smtpSession.checkCertificateEnabled = NO;
      smtpSession.connectionType = MCOConnectionTypeStartTLS;
      break;
    default:
      smtpSession.username = smtpemail;
      smtpSession.password = smtppass;
      switch ([smtpport integerValue]) {
      case 25:
        smtpSession.connectionType = MCOConnectionTypeClear;
        break;
      case 587:
        smtpSession.checkCertificateEnabled = NO;
        smtpSession.connectionType = MCOConnectionTypeStartTLS;
        break;
      case 465:
        smtpSession.checkCertificateEnabled = NO;
        smtpSession.connectionType = MCOConnectionTypeTLS;
        break;
      default:
        break;
      }
      break;
    }
    [smtpSession setCheckCertificateEnabled:NO];
    self.smtpSession = smtpSession;
  }
  return self.smtpSession;
}

- (void)logout {

  self.listAccount = [[NSUserDefaults standardUserDefaults]
      mutableArrayValueForKey:@"listAccount"];
  isResetImapSession = YES;
  NSString *accname = [self.listAccount objectAtIndex:accIndex + 1];
  NSString *mailtype = [self.listAccount objectAtIndex:accIndex + 3];

  // Kiểm tra có phải tài khoản tự cấu hình hay không .
  if ([mailtype integerValue] > 4) {
    NSMutableArray *customInfo = [[NSMutableArray alloc] init];
    NSArray *copy =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"customInfo"];
    customInfo = [copy mutableCopy];
    if (customInfo.count > 0) {
      for (int i = 0; i < customInfo.count; i = i + 9) {
        // lấy thông tin của tài khoản tự cấu hình
        if ([[customInfo objectAtIndex:i] isEqualToString:mailtype]) {
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
          [customInfo removeObjectAtIndex:i];
        }
      }
      [[NSUserDefaults standardUserDefaults] setObject:customInfo
                                                forKey:@"customInfo"];
    }
  } else if ([mailtype integerValue] == 2) {
    [GTMOAuth2ViewControllerTouch
        removeAuthFromKeychainForName:[self.listAccount
                                          objectAtIndex:accIndex]];
    [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.auth];
  }

  [self.listAccount removeObjectAtIndex:accIndex];
  [self.listAccount removeObjectAtIndex:accIndex];
  [self.listAccount removeObjectAtIndex:accIndex];
  [self.listAccount removeObjectAtIndex:accIndex];

  /* Nếu có nhiều hơn 1 tài khoản thi khi logout sẽ tự chuyển về tài khoản đầu
   tiên */
  if (self.listAccount.count >= 4) {
    accIndex = 0;
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSString stringWithFormat:@"%d", (int)accIndex]
           forKey:@"accIndex"];
    [[NSUserDefaults standardUserDefaults]
        setObject:[self.listAccount objectAtIndex:(accIndex + 3)]
           forKey:@"mailtype"];
  } else {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"accIndex"];
  }
  [[NSUserDefaults standardUserDefaults] setObject:[self.listAccount copy]
                                            forKey:@"listAccount"];
  self.imapSession = nil;
  self.smtpSession = nil;
  returnImap = nil;

  // delete NSUserdefault
  if (accname) {
    NSArray *keys = [[[NSUserDefaults
            standardUserDefaults] dictionaryRepresentation] allKeys];
    for (NSString *key in keys) {
      if ([key rangeOfString:accname].location != NSNotFound) {
        NSLog(@"Key = %@", key);
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
      }
    }
  }
}

- (void)refreshSession {

  NSLog(@"Begin refresh session");

  self.listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];

  if (accIndex < self.listAccount.count) {

    if ([mtype isEqualToString:@"2"]) {
      keychain = [self.listAccount objectAtIndex:accIndex];
      [self refresh_google];
      isRefreshOauthSession = YES;
    }

    isResetImapSession = YES;
  }
}

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {

  if (alertView.tag == Oauth2_Error) {

    if (buttonIndex == [alertView cancelButtonIndex]) {

      // Đăng thoát khỏi tài khoản bị lỗi
      [self logout];
      [self refresh_logout];
      [[NSNotificationCenter defaultCenter]
          postNotificationName:@"reloadMessage"
                        object:nil];
      [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu"
                                                          object:nil];

      // Khởi tạo form đăng nhập lại
      [[Oauth2NewAccountLogin shareOauth2NewAccountLogin]
          oauth2NewAccountLogin:NO];
    }
  }
}

@end
