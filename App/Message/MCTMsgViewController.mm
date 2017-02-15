//
//  MCTMsgViewController.m
//  testUI
//
//  Created by DINH Viêt Hoà on 1/20/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCTMsgViewController.h"
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

#import <MobileCoreServices/MobileCoreServices.h>

#import "ComposerViewController.h"
#import "AuthManager.h"
#import "ActionPickerViewController.h"
#import "UIPopoverController+FlatUI.h"
#import "UIColor+FlatUI.h"

#import "MBProgressHUD.h"
#import "DelayedAttachment.h"
#import "UTIFunctions.h"

//HoangTD edit
//#import "SoftToken_SignEnvelope.h"
//#import "HardToken_Envelope.h"
//#import "Base64.h"
//#import "WebService.h"
//#import "HardTokenMethod.h"
//#import "SoftTokenSign.h"
#import "DBManager.h"
#import "TokenType.h"
#import "AuthNavigationViewController.h"
#import "MsgListViewController.h"

#import "CheckNetWork.h"


static NSString *fromEmail;

@interface MCTMsgViewController () <
    UIGestureRecognizerDelegate, UIPopoverControllerDelegate,
    UIActionSheetDelegate, AuthViewControllerDelegate> {

  UIPopoverController *_actionPickerPopover;
  ActionPickerViewController *_actionPicker;
}
@end

@implementation MCTMsgViewController
NSString *fullMSN1 = nil;
NSMutableArray *delayed = nil;
int uid;
MCOIMAPPart *cachePart;

@synthesize folder = _folder;
@synthesize session = _session;

+ (NSString *)shareFromEmail {
  return fromEmail;
}

- (void)awakeFromNib {
  _storage = [[NSMutableDictionary alloc] init];
  _ops = [[NSMutableArray alloc] init];
  _pending = [[NSMutableSet alloc] init];
  _callbacks = [[NSMutableDictionary alloc] init];
}

- (id)init {
  self = [super init];
  if (self) {
    [self awakeFromNib];
    _session = [[AuthManager sharedManager] getImapSession];
  }
  return self;
}

- (void)viewDidLoad {
  if (!self.message) {
    return;
  }
  uid = self.message.uid;

  NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  NSString *username = nil;
  if (listAccount.count > 0 && accIndex < listAccount.count) {
    username = [listAccount objectAtIndex:accIndex + 1];
  }

  NSDictionary *folderNames = [ListAllFolders shareFolderNames];

  tokenType = [[[[DBManager getSharedInstance] findTokenTypeByEmail:username]
      objectAtIndex:0] intValue];

  // Remove all the underlying subviews;
  [[self.view subviews]
      makeObjectsPerformSelector:@selector(removeFromSuperview)];
  _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  _scrollView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _scrollView.scrollEnabled = YES;
  _scrollView.directionalLockEnabled = YES;

  delayed = [[NSMutableArray alloc] init];
  for (MCOIMAPPart *a in [self.message attachments]) {
    DelayedAttachment *da = [[DelayedAttachment alloc] initWithMCOIMAPPart:a];
    da.fetchData = ^(void) {
      __block NSData *data = [self MCOMessageView:_messageView
                          dataForPartWithUniqueID:[a uniqueID]];
      if (data) {
        return data;
      } else {
        __block NSConditionLock *fetchLock;
        fetchLock = [[NSConditionLock alloc] initWithCondition:1];
        [self MCOMessageView:_messageView
            fetchDataForPartWithUniqueID:[a uniqueID]
                      downloadedFinished:^(NSError *error) {
                        data = [self MCOMessageView:_messageView
                            dataForPartWithUniqueID:[a uniqueID]];
                        [fetchLock lock];
                        [fetchLock unlockWithCondition:0];
                      }];

        [fetchLock lockWhenCondition:0];
        [fetchLock unlock];
        return data;
      }
    };
    [delayed addObject:da];
    if (![da.filename isEqualToString:@"smime.p7s"]) {
      self.delayedAttachment = [delayed copy];
    }
  };
//  HoangTD edit
//  /* Thư mã hoá */
//  NSString *mcoMessage = [NSString stringWithFormat:@"%@", self.message];
//  if ([mcoMessage rangeOfString:@"filename: smime.p7m"].location !=
//      NSNotFound) {
//
//    // Chỉ giải mã trên hòm Inbox và All mail, còn lại sẽ hiển thị thư gốc
//    if ([_folder isEqualToString:@"INBOX"] ||
//        [_folder isEqualToString:[folderNames objectForKey:@"All Mail"]]) {
//      HardTokenMethod *initProgress = [[HardTokenMethod alloc] init];
//      if (_message) {
//        [initProgress
//            showGlobalProgressHUDWithTitle:NSLocalizedString(
//                                               @"DownloadEncryptFile", nil)];
//      }
//
//      //        MCOIMAPSession *session1 = [[AuthManager sharedManager]
//      //        getImapSession];
//      //        MCOIMAPFetchContentOperation *operation = [session1
//      //        fetchMessageByUIDOperationWithFolder:@"INBOX" uid:_message.uid];
//      //        [operation start:^(NSError *error, NSData *rfc822Data) {
//      //            fullMSN1 = [[NSString alloc] initWithData:rfc822Data
//      //            encoding:NSUTF8StringEncoding];
//      //        }];
//
//      MCOIMAPSession *session = [[AuthManager sharedManager] getImapSession];
//      MCOIMAPPart *part = [self.message.attachments objectAtIndex:0];
//      NSLog(@"Encode File size %i", part.decodedSize);
//      MCOIMAPFetchContentOperation *mcop = [session
//          fetchMessageAttachmentByUIDOperationWithFolder:_folder
//                                                     uid:self.message.uid
//                                                  partID:part.partID
//                                                encoding:part.encoding];
//      [mcop start:^(NSError *error, NSData *data) {
//
//        if (error) {
//
//          UIWindow *window =
//              [[UIApplication sharedApplication] delegate].window;
//          MBProgressHUD *hud =
//              [MBProgressHUD showHUDAddedTo:window animated:YES];
//          hud.labelText = NSLocalizedString(@"FetchEmailError", nil);
//          hud.labelFont = [UIFont boldSystemFontOfSize:13];
//          hud.mode = MBProgressHUDModeCustomView;
//          hud.margin = 12.0f;
//          hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
//          hud.removeFromSuperViewOnHide = YES;
//          [hud hide:YES afterDelay:2.0];
//
//          if (error.code == 5) {
//            [CheckValidSession
//                checkValidSession:[[AuthManager sharedManager] getImapSession]];
//          }
//          return;
//        }
//
//        NSString *p7m = [data base64EncodedStringWithWrapWidth:64];
//        [initProgress dismissGlobalHUD];
//        if (!p7m) {
//          UIAlertView *alertPin = [[UIAlertView alloc]
//                  initWithTitle:NSLocalizedString(@"Error", nil)
//                        message:NSLocalizedString(@"CheckInternet", nil)
//                       delegate:nil
//              cancelButtonTitle:NSLocalizedString(@"Back", nil)
//              otherButtonTitles:nil];
//          [alertPin show];
//        } else {
//          [[NSUserDefaults standardUserDefaults] setObject:p7m forKey:@"p7m"];
//          [[NSUserDefaults standardUserDefaults] synchronize];
//
//          if (tokenType == NOTOKEN) {
//            [self displayOrgMail];
//          }
//
//          if (tokenType == SOFTTOKEN) {
//            NSString *passwrd =
//                [[NSUserDefaults standardUserDefaults] stringForKey:@"passwrd"];
//
//            if (!passwrd) {
//              FUIAlertView *alertPin = [[FUIAlertView alloc]
//                      initWithTitle:NSLocalizedString(@"TokenPass", nil)
//                            message:nil
//                           delegate:self
//                  cancelButtonTitle:NSLocalizedString(@"Out", nil)
//                  otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
//              [alertPin setAlertViewStyle:FUIAlertViewStyleSecureTextInput];
//              if (IDIOM == IPAD) {
//                alertPin.titleLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//                alertPin.messageLabel.textColor = [UIColor asbestosColor];
//                alertPin.messageLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//                alertPin.defaultButtonFont =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//              } else {
//                alertPin.titleLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//                alertPin.messageLabel.textColor = [UIColor asbestosColor];
//                alertPin.messageLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
//                alertPin.defaultButtonFont =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
//              }
//              alertPin.backgroundOverlay.backgroundColor =
//                  [[UIColor blackColor] colorWithAlphaComponent:0.8];
//              alertPin.alertContainer.backgroundColor = [UIColor cloudsColor];
//              alertPin.defaultButtonColor = [UIColor cloudsColor];
//              alertPin.defaultButtonShadowColor = [UIColor cloudsColor];
//              alertPin.defaultButtonTitleColor = [UIColor belizeHoleColor];
//              alertPin.tag = passwordST;
//              [alertPin show];
//            } else {
//              [self showSpinnerWithText:NSLocalizedString(@"Decode", nil)];
//              [self decryptCall_];
//            }
//          }
//          if (tokenType == HARDTOKEN) {
//            NSString *passHardToken = [[NSUserDefaults standardUserDefaults]
//                stringForKey:@"HardPasswrd"];
//            if (!passHardToken) {
//              FUIAlertView *alertPin = [[FUIAlertView alloc]
//                      initWithTitle:NSLocalizedString(@"TokenPass", nil)
//                            message:nil
//                           delegate:self
//                  cancelButtonTitle:NSLocalizedString(@"Out", nil)
//                  otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
//              [alertPin setAlertViewStyle:FUIAlertViewStyleSecureTextInput];
//              if (IDIOM == IPAD) {
//                alertPin.titleLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//                alertPin.messageLabel.textColor = [UIColor asbestosColor];
//                alertPin.messageLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//                alertPin.defaultButtonFont =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//              } else {
//                alertPin.titleLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//                alertPin.messageLabel.textColor = [UIColor asbestosColor];
//                alertPin.messageLabel.font =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
//                alertPin.defaultButtonFont =
//                    [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
//              }
//              alertPin.backgroundOverlay.backgroundColor =
//                  [[UIColor blackColor] colorWithAlphaComponent:0.8];
//              alertPin.alertContainer.backgroundColor = [UIColor cloudsColor];
//              alertPin.defaultButtonColor = [UIColor cloudsColor];
//              alertPin.defaultButtonShadowColor = [UIColor cloudsColor];
//              alertPin.defaultButtonTitleColor = [UIColor belizeHoleColor];
//              alertPin.tag = passwordHT;
//              [alertPin show];
//            } else {
//              HardTokenMethod *initMethod = [[HardTokenMethod alloc] init];
//              if ([initMethod connect]) {
//                [self showSpinnerWithText:NSLocalizedString(@"Decode", nil)];
//                [self decryptCall_];
//              }
//            }
//          }
//        }
//      }];
//    } else {
//      [self displayOrgMail];
//      if (_message) {
//        [self showSpinner];
//      }
//    }
//  }
//
//  else if ([mcoMessage rangeOfString:@"filename: smime.p7s"].location !=
//           NSNotFound) {
//    /* Thư đã ký */
//    if (_message) {
//      [self showSpinnerWithText:NSLocalizedString(@"Download", nil)];
//    }
//
//    // Load nội dung mail, chưa xác thực
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VERIFY"];
//    [self displayOrgMail];
//
//    // Xác thực
//    MCOIMAPSession *session = [[AuthManager sharedManager] getImapSession];
//    MCOIMAPFetchContentOperation *operation =
//        [session fetchMessageByUIDOperationWithFolder:_folder uid:_message.uid];
//    [operation start:^(NSError *error, NSData *rfc822Data) {
//
//      if (error) {
//
//        UIWindow *window = [[UIApplication sharedApplication] delegate].window;
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
//        hud.labelText = NSLocalizedString(@"FetchEmailError", nil);
//        hud.labelFont = [UIFont boldSystemFontOfSize:13];
//        hud.mode = MBProgressHUDModeCustomView;
//        hud.margin = 12.0f;
//        hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
//        hud.removeFromSuperViewOnHide = YES;
//        [hud hide:YES afterDelay:2.0];
//
//        if (error.code == 5) {
//          [CheckValidSession
//              checkValidSession:[[AuthManager sharedManager] getImapSession]];
//        }
//        return;
//      }
//
//      // Lấy trường người gửi (from) để xác thực và cập nhật webservice
//      MCOMessageHeader *header = [_message header];
//      NSString *r_mail = [[header from] mailbox];
//      fromEmail = r_mail;
//      /*
//       || result 0: sign err
//       || result 1: good
//       || result 2: revoke
//       || result 3: expired
//       || result 4: email err
//       || result 5: unknown error
//       */
//      totalSize = [rfc822Data length] / 1024.0f / 1024.0f;
//      if (totalSize > 5.0f) {
//        totalSize = 0;
//        UIWindow *window = [[UIApplication sharedApplication] delegate].window;
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
//        hud.labelText = NSLocalizedString(@"HUDCantVerify", nil);
//        hud.labelFont = [UIFont boldSystemFontOfSize:13];
//        hud.mode = MBProgressHUDModeCustomView;
//        hud.margin = 12.0f;
//        hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
//        hud.removeFromSuperViewOnHide = YES;
//        [hud hide:YES afterDelay:2.0];
//        [[NSUserDefaults standardUserDefaults] setObject:@"YES"
//                                                  forKey:@"CantVerify"];
//      } else {
//        SoftToken_SignEnvelope *signVerify =
//            [[SoftToken_SignEnvelope alloc] init];
//        int result = [signVerify signVerify:rfc822Data];
//        switch (result) {
//        case 0: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"NO"
//                                                    forKey:@"VERIFY"];
//        } break;
//        case 1: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"YES"
//                                                    forKey:@"VERIFY"];
//          [[NSUserDefaults standardUserDefaults] setObject:rfc822Data
//                                                    forKey:@"FullMSN"];
//        } break;
//        case 2: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"REVOKE"
//                                                    forKey:@"VERIFY"];
//        } break;
//        case 3: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"EXPIRED"
//                                                    forKey:@"VERIFY"];
//          [[NSUserDefaults standardUserDefaults] setObject:rfc822Data
//                                                    forKey:@"FullMSN"];
//        } break;
//        case 4: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"IVALIDEMAIL"
//                                                    forKey:@"VERIFY"];
//          [[NSUserDefaults standardUserDefaults] setObject:rfc822Data
//                                                    forKey:@"FullMSN"];
//        } break;
//        case 5: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"UNKNOWN"
//                                                    forKey:@"VERIFY"];
//        } break;
//        default:
//          break;
//        }
//        if (result == 1) {
//          /* Webservice */
//          NSString *base64 = [self getBase64];
//          WebService *saveMail = [[WebService alloc] init];
//          NSString *sucess = [saveMail SaveMail:r_mail cert:base64];
//          NSLog(@"Webservice update = %@", sucess);
//          /* Database */
//          NSArray *checkExist =
//              [[DBManager getSharedInstance] findByEmail:r_mail];
//          // Kiểm tra người gửi tồn tại trong DB
//          if (!checkExist) {
//            int _id = [[DBManager getSharedInstance] getLastObjectID];
//            BOOL sucess = [[DBManager getSharedInstance] saveData:(_id + 1)
//                                                           r_mail:r_mail
//                                                         certdata:base64];
//            NSLog(@"Chèn dữ liệu database = %d", sucess);
//          } else {
//            NSString *certdata = [checkExist objectAtIndex:1];
//            NSString *_id = [checkExist objectAtIndex:0];
//            if (![certdata isEqualToString:base64]) {
//              NSLog(@"Updating database...");
//              BOOL sucess =
//                  [[DBManager getSharedInstance] updateData:[_id intValue]
//                                                     r_mail:r_mail
//                                                   certdata:base64];
//              NSLog(@"Update dữ liệu database = %d", sucess);
//            }
//          }
//        }
//      }
//      // Sau khi Verify xong, thực hiện refresh header
//      _headerView = [[HeaderView alloc] initWithFrame:self.view.bounds
//                                              message:_message
//                                   delayedAttachments:delayed];
//      _headerView.delegate = self;
//      [_scrollView addSubview:_headerView];
//      [UIView transitionWithView:self.view
//                        duration:0.4
//                         options:UIViewAnimationOptionTransitionCrossDissolve
//                      animations:^{
//                        [self.view addSubview:_scrollView];
//                      }
//                      completion:nil];
//    }];
//  }
//
//  else {
//    /* Thư không ký, ko mã hoá */
//    [self displayOrgMail];
//    if (_message) {
//      [self showSpinner];
//    }
//  }

  [self displayOrgMail];
  if (_message) {
    [self showSpinner];
  }
  UILongPressGestureRecognizer *longPress =
      [[UILongPressGestureRecognizer alloc]
          initWithTarget:self
                  action:@selector(didLongPressOnMessageContentsView:)];
  [longPress setDelegate:self];
  [longPress setMinimumPressDuration:0.8f];
  [_messageContentsView addGestureRecognizer:longPress];
}

- (void)alertView:(FUIAlertView *)alertView
    didDismissWithButtonIndex:(NSInteger)buttonIndex {

//  if (alertView.tag == passwordHT) {
//    if (buttonIndex == 1) {
//      [alertView dismissWithClickedButtonIndex:0 animated:YES];
//      NSString *passwrd = [[alertView textFieldAtIndex:0] text];
//      // Tránh gọi lại alertView thêm 1 lần nữa
//      alertView.tag = 11;
//      HardTokenMethod *initMethod = [[HardTokenMethod alloc] init];
//      if ([initMethod connect]) {
//        long ckrv = 1;
//        ckrv = [initMethod
//            VerifyPIN:[passwrd cStringUsingEncoding:NSASCIIStringEncoding]];
//        if (ckrv) {
//          UIAlertView *alertPin = [[UIAlertView alloc]
//                  initWithTitle:NSLocalizedString(@"Error", nil)
//                        message:NSLocalizedString(@"TokenPassWrong", nil)
//                       delegate:nil
//              cancelButtonTitle:NSLocalizedString(@"Out", nil)
//              otherButtonTitles:nil];
//          [alertPin show];
//          [self displayOrgMail];
//        } else {
//          // Kiểm tra chứng thư
//          HardTokenMethod *hud = [[HardTokenMethod alloc] init];
//          [hud showGlobalProgressHUDWithTitle:NSLocalizedString(@"VerifyCert",
//                                                                nil)];
//          dispatch_async(
//              dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//                dispatch_async(dispatch_get_main_queue(), ^{
//                  if (![VerifyMethod selfverifyCertificate]) {
//                    [[NSUserDefaults standardUserDefaults]
//                        setObject:passwrd
//                           forKey:@"HardPasswrd"];
//                    [[NSUserDefaults standardUserDefaults] synchronize];
//                    [self
//                        showSpinnerWithText:NSLocalizedString(@"Decode", nil)];
//                    [self decryptCall_];
//                  } else {
//                    [self displayOrgMail];
//                  }
//                });
//                dispatch_async(dispatch_get_main_queue(), ^{
//                  [hud dismissGlobalHUD];
//                });
//              });
//        }
//      } else {
//        [self displayOrgMail];
//      }
//    } else {
//      [self displayOrgMail];
//    }
//  }
//
//  if (alertView.tag == passwordST) {
//    if (buttonIndex == 1) {
//      [alertView dismissWithClickedButtonIndex:0 animated:YES];
//      NSString *passwrd = [[alertView textFieldAtIndex:0] text];
//      // Tránh gọi lại alertView thêm 1 lần nữa
//      alertView.tag = 11;
//      SoftTokenSign *initMethod = [[SoftTokenSign alloc] init];
//      if (![initMethod connectSoftToken:passwrd]) {
//        [self displayOrgMail];
//      } else {
//        // Kiểm tra chứng thư
//        HardTokenMethod *hud = [[HardTokenMethod alloc] init];
//        [hud showGlobalProgressHUDWithTitle:NSLocalizedString(@"VerifyCert",
//                                                              nil)];
//        dispatch_async(
//            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//              dispatch_async(dispatch_get_main_queue(), ^{
//                if (![VerifyMethod selfverifyCertificate]) {
//                  [[NSUserDefaults standardUserDefaults] setObject:passwrd
//                                                            forKey:@"passwrd"];
//                  [[NSUserDefaults standardUserDefaults] synchronize];
//                  [self showSpinnerWithText:NSLocalizedString(@"Decode", nil)];
//                  [self decryptCall_];
//                } else {
//                  [self displayOrgMail];
//                }
//                [hud dismissGlobalHUD];
//              });
//
//              dispatch_async(dispatch_get_main_queue(), ^{
//                [MBProgressHUD hideHUDForView:self.view animated:YES];
//              });
//            });
//      }
//    } else {
//      [self displayOrgMail];
//    }
//  }
}

- (void)saveMessageData:(NSData *)data key:(NSString *)key {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:data forKey:key];
  [defaults synchronize];
}

- (NSData *)getMessageDataOffline:(NSString *)key {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSData *data = [defaults objectForKey:key];
  return data;
}

- (void)downloadMessage {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  MCOIMAPFetchContentOperation *op =
      [_session fetchMessageByUIDOperationWithFolder:_folder
                                                 uid:[_message uid]];
  [_ops addObject:op];
  [op start:^(NSError *error, NSData *data) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if ([error code] != MCOErrorNone) {
      return;
    }
    if (data == nil) {
      return;
    }
    NSString *s_uid = [NSString stringWithFormat:@"%d", (int)[_message uid]];
    NSString *key = @"";
    NSString *username = nil;
    NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
        objectForKey:@"accIndex"] integerValue];
    NSMutableArray *listAccount =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    if (listAccount.count > 0 && accIndex < listAccount.count) {
      username = [listAccount objectAtIndex:accIndex + 1];
    }
    if (username && _folder && s_uid) {
      @try {
        key = [NSString stringWithFormat:@"%@%@%@", username, _folder, s_uid];
      } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
      }
      [self saveMessageData:data key:key];
    }
  }];
}

- (void)displayOrgMail {
  _headerView = [[HeaderView alloc] initWithFrame:self.view.bounds
                                          message:_message
                               delayedAttachments:delayed];
  _headerView.delegate = self;
  [_scrollView addSubview:_headerView];

  _messageContentsView = [[UIView alloc]
      initWithFrame:CGRectMake(0, _headerView.frame.size.height,
                               self.view.bounds.size.width,
                               self.view.bounds.size.height -
                                   _headerView.frame.size.height)];
  _messageContentsView.backgroundColor = [UIColor whiteColor];
  [_scrollView addSubview:_messageContentsView];

  _messageView = [[MCOMessageView alloc]
      initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
  [_messageView setDelegate:self];
  [_messageView setFolder:_folder];

  NSString *s_uid = [NSString stringWithFormat:@"%d", (int)[_message uid]];
  NSString *key = @"";
  NSString *username = nil;
  NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count > 0 && accIndex < listAccount.count) {
    username = [listAccount objectAtIndex:accIndex + 1];
  }
  key = [key stringByAppendingString:username];
  key = [key stringByAppendingString:_folder];
  key = [key stringByAppendingString:s_uid];
  NSData *cachedMes = [self getMessageDataOffline:key];
  if (cachedMes == nil) {
    [self loadEmailWithInternet];
  } else {
    MCOMessageParser *msg = [MCOMessageParser messageParserWithData:cachedMes];
    [_messageView setMessage:NULL];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
                     [_messageView setMessage:msg];
                     [self loadEmailWithInternet];
                   });
  }

  [UIView transitionWithView:self.view
                    duration:0.3
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^{
                    [self.view addSubview:_scrollView];
                  }
                  completion:nil];
}

- (void)loadEmailWithInternet {

  CheckNetWork *init = [[CheckNetWork alloc] init];
  if ([init checkNetworkAvailable]) {
    [_messageView setMessage:_message];
    [self downloadMessage];
  }
}

- (void)didLongPressOnMessageContentsView:
    (UILongPressGestureRecognizer *)recognizer {
  if (recognizer && recognizer.state == UIGestureRecognizerStateRecognized) {
    CGPoint point = [recognizer locationInView:_messageContentsView];
    [_messageView handleTapAtpoint:point];
  }
}

- (void)willRotateToInterfaceOrientation:
            (UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
  // Update the underlying webview with the new bounds
  // We don't know it yet for sure, but we can predict it
  if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
    _messageView.frame = CGRectMake(0, 0, 703, 724);
  } else {
    // You don't want to do this as it will flash the underlying content. Just
    // wait it out.
    //_messageView.frame = CGRectMake(0, 0, 447, 980);
  }
}

- (void)didRotateFromInterfaceOrientation:
    (UIInterfaceOrientation)fromInterfaceOrientation {
  // Update the underlying webview with the new bounds;
  _messageView.frame = self.view.bounds;
  [_headerView render];
}

- (void)showSpinner {
  [MBProgressHUD showHUDAddedTo:[self view] animated:YES];
}

- (void)showSpinnerWithText:(NSString *)text {
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[self view] animated:YES];
  hud.labelText = text;
}

- (void)hideSpinner {
  [MBProgressHUD hideAllHUDsForView:[self view] animated:NO];
}

- (void)setMessage:(MCOIMAPMessage *)message {
  for (MCOOperation *op in _ops) {
    [op cancel];
  }
  [_ops removeAllObjects];
  [_callbacks removeAllObjects];
  [_pending removeAllObjects];
  [_storage removeAllObjects];
  _message = message;
}

- (NSString *)msgContent {
  NSString *content = [[[_messageView getMessage] mco_flattenHTML]
      stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if (content) {
    NSLog(@"%@", content);
  }
  return content;
}

- (MCOIMAPMessage *)message {
  return _message;
}

- (int)uid {
  return uid;
}

- (MCOIMAPFetchContentOperation *)
_fetchIMAPPartWithUniqueID:(NSString *)partUniqueID
                    folder:(NSString *)folder {
  MCLog("%s is missing, fetching", partUniqueID.description.UTF8String);

  if ([_pending containsObject:partUniqueID]) {
    return nil;
  }

  MCOIMAPPart *part = (MCOIMAPPart *)[_message partForUniqueID:partUniqueID];
  // NSAssert(part != nil, @"part != nil");

  [_pending addObject:partUniqueID];

  MCOIMAPFetchContentOperation *op =
      [_session fetchMessageAttachmentByUIDOperationWithFolder:folder
                                                           uid:[_message uid]
                                                        partID:[part partID]
                                                      encoding:[part encoding]];
  [_ops addObject:op];
  [op start:^(NSError *error, NSData *data) {
    if ([error code] != MCOErrorNone) {
      [self _callbackForPartUniqueID:partUniqueID error:error];
      return;
    }

    NSAssert(data != NULL, @"data != nil");
    [_ops removeObject:op];
    [_storage setObject:data forKey:partUniqueID];
    [_pending removeObject:partUniqueID];
    MCLog("downloaded %s", partUniqueID.description.UTF8String);

    [self _callbackForPartUniqueID:partUniqueID error:nil];
  }];

  return op;
}

typedef void (^DownloadCallback)(NSError *error);

- (void)_callbackForPartUniqueID:(NSString *)partUniqueID
                           error:(NSError *)error {
  NSArray *blocks;
  blocks = [_callbacks objectForKey:partUniqueID];
  for (DownloadCallback block in blocks) {
    block(error);
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UIGestureRecognizer *)otherGestureRecognizer {
  return _messageView.gestureRecognizerEnabled;
}

#pragma mark - ActionPickerDelegate

- (void)image:(UIImage *)image
    didFinishSavingWithError:(NSError *)error
                 contextInfo:(void *)contextInfo {
  NSLog(@"SAVE IMAGE COMPLETE");
  if (error) {
    NSLog(@"ERROR SAVING:%@", [error localizedDescription]);
  }
}

#pragma mark - MCOMessageViewDelegate

- (NSString *)MCOMessageView_templateForAttachmentSeparator:
    (MCOMessageView *)view {
  return @"";
}

- (NSString *)MCOMessageView_templateForAttachment:(MCOMessageView *)view {
  // No need for attachments to be displayed. Using Native HeaderView instead.
  return @"";
}

- (NSString *)MCOMessageView_templateForMainHeader:(MCOMessageView *)view {
  // No need for main header. Using Native HeaderView instead.
  return @"";
}

- (NSString *)MCOMessageView_templateForImage:(MCOMessageView *)view {
  // Disable inline image attachments. Using Native HeaderView instead.
  return @"";
}

- (NSString *)MCOMessageView_templateForMessage:(MCOMessageView *)view {
  return @"{{BODY}}";
}

- (BOOL)MCOMessageView:(MCOMessageView *)view
        canPreviewPart:(MCOAbstractPart *)part {
  return NO;
}

- (NSData *)MCOMessageView:(MCOMessageView *)view
   dataForPartWithUniqueID:(NSString *)partUniqueID {
  NSData *data = [_storage objectForKey:partUniqueID];
  return data;
}

- (void)MCOMessageView:(MCOMessageView *)view
    fetchDataForPartWithUniqueID:(NSString *)partUniqueID
              downloadedFinished:(void (^)(NSError *error))downloadFinished {
  MCOIMAPFetchContentOperation *op =
      [self _fetchIMAPPartWithUniqueID:partUniqueID folder:_folder];
  [op setProgress:^(unsigned int current, unsigned int maximum){
      //        NSLog(@"progress content: %u/%u", current, maximum);
  }];
  if (op != nil) {
    [_ops addObject:op];
  }
  if (downloadFinished != NULL) {
    NSMutableArray *blocks;
    blocks = [_callbacks objectForKey:partUniqueID];
    if (blocks == nil) {
      blocks = [NSMutableArray array];
      [_callbacks setObject:blocks forKey:partUniqueID];
    }
    [blocks addObject:[downloadFinished copy]];
  }
}

- (void)MCOMessageView:(MCOMessageView *)view
 handleMailtoUrlString:(NSString *)mailtoAddress {
  ComposerViewController *vc = [[ComposerViewController alloc] initWithTo:@[
    mailtoAddress
  ] CC:@[] BCC:@[] subject:@"" message:@"" attachments:@[]
                                                       delayedAttachments:@[]];

  UINavigationController *nc =
      [[UINavigationController alloc] initWithRootViewController:vc];
  nc.modalPresentationStyle = UIModalPresentationPageSheet;
  [self presentViewController:nc animated:YES completion:nil];
}

- (void)MCOMessageView:(MCOMessageView *)view
  didTappedInlineImage:(UIImage *)inlineImage
               atPoint:(CGPoint)point
             imageRect:(CGRect)rect
             imagePath:(NSString *)path
             imageName:(NSString *)imgName
         imageMimeType:(NSString *)mimeType {
  NSLog(@"mimeType : %@", mimeType);
  NSLog(@"Image Name : %@", imgName);
  NSLog(@"Image Path : %@", imgName);
  self.imageMimeType = mimeType;
  self.imageName = imgName;
  self.imagePath = path;
  self.image = inlineImage;
  UIActionSheet *popupQuery = [[UIActionSheet alloc]
               initWithTitle:nil
                    delegate:self
           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
      destructiveButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"Preview", nil),
                             NSLocalizedString(@"DownloadData", nil), nil];
  popupQuery.actionSheetStyle = UIActionSheetStyleDefault;
  [popupQuery showInView:self.view];
}

- (NSData *)MCOMessageView:(MCOMessageView *)view
            previewForData:(NSData *)data
         isHTMLInlineImage:(BOOL)isHTMLInlineImage {
  if (isHTMLInlineImage) {
    return data;
  } else {
    return [self _convertToJPEGData:data];
  }
}

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex {

  switch (buttonIndex) {
  case 0: {
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          NSData *data = UIImagePNGRepresentation(self.image);
          dispatch_async(dispatch_get_main_queue(), ^{
            AuthNavigationViewController *preview =
                [AuthNavigationViewController
                    controllerWithPreview:self.imageName
                                     data:data
                                 mimeType:self.imageMimeType];
            preview.dismissOnSuccess = YES;
            preview.dismissOnError = YES;
            preview.delegate = self;
            [self presentViewController:preview animated:YES completion:nil];
          });
        });

  } break;
  case 1: {
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

          NSData *data = UIImagePNGRepresentation(self.image);
          dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *imageToSave = [UIImage imageWithData:data];
            UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
          });
        });
  } break;
  default:
    break;
  }
}

#define IMAGE_PREVIEW_HEIGHT 300
#define IMAGE_PREVIEW_WIDTH 500
#define IMAGE_PREVIEW_HEIGHT_IP 150
#define IMAGE_PREVIEW_WIDTH_IP 250

- (NSData *)_convertToJPEGData:(NSData *)data {
  CGImageSourceRef imageSource;
  CGImageRef thumbnail;
  NSMutableDictionary *info;
  int width;
  int height;
  float quality;

  if (IDIOM == IPHONE) {
    width = IMAGE_PREVIEW_WIDTH_IP;
    height = IMAGE_PREVIEW_HEIGHT_IP;
  } else {
    width = IMAGE_PREVIEW_WIDTH;
    height = IMAGE_PREVIEW_HEIGHT;
  }

  quality = 1.0;

  imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
  if (imageSource == NULL)
    return nil;

  info = [[NSMutableDictionary alloc] init];
  [info setObject:(id)kCFBooleanTrue
           forKey:(id)kCGImageSourceCreateThumbnailWithTransform];
  [info setObject:(id)kCFBooleanTrue
           forKey:(id)kCGImageSourceCreateThumbnailFromImageAlways];
  [info setObject:(id)[NSNumber numberWithFloat:(float)IMAGE_PREVIEW_WIDTH]
           forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
  thumbnail = CGImageSourceCreateThumbnailAtIndex(
      imageSource, 0, (__bridge CFDictionaryRef)info);

  CGImageDestinationRef destination;
  NSMutableData *destData = [NSMutableData data];

  destination =
      CGImageDestinationCreateWithData((__bridge CFMutableDataRef)destData,
                                       (CFStringRef) @"public.jpeg", 1, NULL);

  CGImageDestinationAddImage(destination, thumbnail, NULL);
  CGImageDestinationFinalize(destination);

  CFRelease(destination);

  CFRelease(thumbnail);
  CFRelease(imageSource);

  return destData;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

  [self hideSpinner];

  CGFloat contentHeight = webView.scrollView.contentSize.height;
  CGFloat contentWidth = webView.scrollView.contentSize.width;

  contentHeight =
      contentHeight >
              (self.view.bounds.size.height - _headerView.bounds.size.height)
          ? contentHeight
          : (self.view.bounds.size.height - _headerView.bounds.size.height);

  _messageContentsView.frame = CGRectMake(_messageContentsView.frame.origin.x,
                                          _messageContentsView.frame.origin.y,
                                          contentWidth, contentHeight);

  for (UIView *v in webView.scrollView.subviews) {
    [_messageContentsView addSubview:v];
  }

  _scrollView.contentSize =
      CGSizeMake(_messageContentsView.bounds.size.width,
                 _headerView.bounds.size.height +
                     _messageContentsView.bounds.size.height + 100);
}

//HoangTD edit
//- (void)decryptCall_ {
//    /* Gọi hàm giải mã */
//  NSString *decrypMSN = nil;
//  NSString *rfc822Info = nil;
//
//  // Lấy mail gốc (đã mã hoá) để đọc các trường: from, to, subject
//  messageTemp = [MsgListViewController shareOrgMsg];
//  NSString *from = [[[messageTemp header] from] displayName]
//                       ? [[[messageTemp header] from] displayName]
//                       : [[[messageTemp header] from] mailbox];
//
//  NSString *to = [[[[messageTemp header] to] objectAtIndex:0] mailbox];
//  NSString *subject = [[messageTemp header] subject];
//  NSDate *date = [[messageTemp header] date];
//  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//  dateFormatter.dateFormat = @"EEE, dd MMM YYYY HH:mm:ss ZZZ";
//  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
//  [dateFormatter setLocale:locale];
//  NSString *sendTime = [dateFormatter stringFromDate:date];
//  rfc822Info = [NSString
//      stringWithFormat:@"From: %@\r\nTo: %@\r\nDate: %@\r\nSubject: %@\r\n",
//                       from, to, sendTime, subject];
//
//  NSString *fullMsnPath = [NSTemporaryDirectory()
//      stringByAppendingPathComponent:@"fullMsnPath.txt"];
//  NSString *p7m = [[NSUserDefaults standardUserDefaults] stringForKey:@"p7m"];
//  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"p7m"];
//  p7m = [self p7mInform:p7m];
//  [p7m writeToFile:fullMsnPath
//        atomically:YES
//          encoding:NSUTF8StringEncoding
//             error:nil];
//  if (tokenType == SOFTTOKEN) {
//    SoftToken_SignEnvelope *decrypt = [[SoftToken_SignEnvelope alloc] init];
//    decrypMSN = [decrypt deCryptMail];
//  }
//  if (tokenType == HARDTOKEN) {
//    HardToken_Envelope *decrypt = [[HardToken_Envelope alloc] init];
//    decrypMSN = [decrypt deCryptMailHT];
//  }
//  if (!decrypMSN) {
//    [self displayOrgMail];
//    UIAlertView *alertView =
//        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
//                                   message:NSLocalizedString(@"CantDecode", nil)
//                                  delegate:nil
//                         cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//                         otherButtonTitles:nil];
//    [alertView show];
//    /* Vẫn hiển thị giao diện mail nhưng ko có nội dung giải mã */
//  } else {
//    /* Giải mã thành công, hiển thị lên giao diện */
//    decrypMSN = [NSString stringWithFormat:@"%@%@", rfc822Info, decrypMSN];
//    NSData *data2 = [decrypMSN dataUsingEncoding:NSUTF8StringEncoding];
//    MCOMessageParser *msg = [MCOMessageParser messageParserWithData:data2];
//    // Kiểm tra thư được ký
//    NSData *rfc822Data = [decrypMSN dataUsingEncoding:NSUTF8StringEncoding];
//    NSString *mcoMessage = [NSString stringWithFormat:@"%@", msg];
//    if ([mcoMessage rangeOfString:@"filename: smime.p7s"].location !=
//        NSNotFound) {
//
//      [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"VERIFY"];
//      // Lấy trường email người gửi (from) để xác thực và cập nhật webservice
//      MCOMessageHeader *header = [_message header];
//      NSString *r_mail = [[header from] mailbox];
//      fromEmail = r_mail;
//      totalSize = [rfc822Data length] / 1024.0f / 1024.0f;
//      if (totalSize > 5) {
//        totalSize = 0;
//        UIWindow *window = [[UIApplication sharedApplication] delegate].window;
//        [MBProgressHUD hideHUDForView:window animated:YES];
//        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
//        hud.labelText = NSLocalizedString(@"HUDCantVerify", nil);
//        hud.labelFont = [UIFont boldSystemFontOfSize:13];
//        hud.mode = MBProgressHUDModeCustomView;
//        hud.margin = 12.0f;
//        hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
//        hud.removeFromSuperViewOnHide = YES;
//        [hud hide:YES afterDelay:2.0];
//        [[NSUserDefaults standardUserDefaults] setObject:@"YES"
//                                                  forKey:@"CantVerify"];
//      } else {
//        SoftToken_SignEnvelope *signVerify =
//            [[SoftToken_SignEnvelope alloc] init];
//        int result = [signVerify signVerify:rfc822Data];
//        switch (result) {
//        case 0: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"NO"
//                                                    forKey:@"VERIFY"];
//        } break;
//        case 1: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"YES"
//                                                    forKey:@"VERIFY"];
//          [[NSUserDefaults standardUserDefaults] setObject:rfc822Data
//                                                    forKey:@"FullMSN"];
//        } break;
//        case 2: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"REVOKE"
//                                                    forKey:@"VERIFY"];
//        } break;
//        case 3: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"EXPIRED"
//                                                    forKey:@"VERIFY"];
//          [[NSUserDefaults standardUserDefaults] setObject:rfc822Data
//                                                    forKey:@"FullMSN"];
//        } break;
//        case 4: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"IVALIDEMAIL"
//                                                    forKey:@"VERIFY"];
//          [[NSUserDefaults standardUserDefaults] setObject:rfc822Data
//                                                    forKey:@"FullMSN"];
//        } break;
//        case 5: {
//          [[NSUserDefaults standardUserDefaults] setObject:@"UNKNOWN"
//                                                    forKey:@"VERIFY"];
//        } break;
//        default:
//          break;
//        }
//
//        if (result == 1) {
//          NSString *fullMsnPath = [NSTemporaryDirectory()
//              stringByAppendingPathComponent:@"fullMsnPath.txt"];
//          [decrypMSN writeToFile:fullMsnPath
//                      atomically:YES
//                        encoding:NSUTF8StringEncoding
//                           error:nil];
//          NSString *base64 = [self getBase64];
//          /* Webservice */
//          WebService *saveMail = [[WebService alloc] init];
//          NSString *sucess = [saveMail SaveMail:r_mail cert:base64];
//          NSLog(@"Webservice update = %@", sucess);
//          /* Database */
//          NSArray *checkExist =
//              [[DBManager getSharedInstance] findByEmail:r_mail];
//          // Kiểm tra người gửi tồn tại trong DB
//          if (!checkExist) {
//            int _id = [[DBManager getSharedInstance] getLastObjectID];
//            BOOL sucess = [[DBManager getSharedInstance] saveData:(_id + 1)
//                                                           r_mail:r_mail
//                                                         certdata:base64];
//            NSLog(@"Chèn dữ liệu database = %d", sucess);
//          } else {
//            NSString *certdata = [checkExist objectAtIndex:1];
//            NSString *_id = [checkExist objectAtIndex:0];
//            if (![certdata isEqualToString:base64]) {
//              NSLog(@"Updating database...");
//              BOOL sucess =
//                  [[DBManager getSharedInstance] updateData:[_id intValue]
//                                                     r_mail:r_mail
//                                                   certdata:base64];
//              NSLog(@"Update dữ liệu database = %d", sucess);
//            }
//          }
//        }
//      }
//    }
//
//    NSMutableArray *delayed = [[NSMutableArray alloc] init];
//
//    if ([msg.attachments count] > 0) {
//      for (int k = 0; k < [msg.attachments count]; k++) {
//        MCOIMAPPart *a = [msg.attachments objectAtIndex:k];
//        DelayedAttachment *da =
//            [[DelayedAttachment alloc] initWithMCOIMAPPart:a];
//        MCOAttachment *attachment = [msg.attachments objectAtIndex:k];
//        da.fetchData = ^(void) {
//          __block NSData *data = attachment.data;
//          return data;
//        };
//
//        // Hưng thêm
//        // Lưu các file đính kèm sau khi giải mã (Trường hợp forward có đính
//        // kèm)
//        [delayed addObject:da];
//        NSLog(@"Attach file After decrypt %d = %@ ", k, da.filename);
//        self.delayedAttachment = [delayed copy];
//      }
//    }
//
//    _headerView = [[HeaderView alloc] initWithFrame:self.view.bounds
//                                            message:msg
//                                 delayedAttachments:delayed];
//    _headerView.delegate = self;
//    [_scrollView addSubview:_headerView];
//
//    _messageContentsView = [[UIView alloc]
//        initWithFrame:CGRectMake(0, _headerView.frame.size.height,
//                                 self.view.bounds.size.width,
//                                 self.view.bounds.size.height -
//                                     _headerView.frame.size.height)];
//    _messageContentsView.backgroundColor = [UIColor whiteColor];
//    [_scrollView addSubview:_messageContentsView];
//
//    _messageView = [[MCOMessageView alloc]
//        initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
//    [_messageView setDelegate:self];
//    [_messageView setFolder:nil];
//    [_messageView setMessage:NULL];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC),
//                   dispatch_get_main_queue(), ^{
//                     [_messageView setMessage:msg];
//                   });
//
//    [UIView transitionWithView:self.view
//                      duration:0.5
//                       options:UIViewAnimationOptionTransitionCrossDissolve
//                    animations:^{
//                      [self.view addSubview:_scrollView];
//                    }
//                    completion:nil];
//
//    // self.message = (MCOIMAPMessage *)msg;
//    //      self.message.uid = 100;
//  }
//}
//
//- (NSString *)getBase64 {
//  NSString *certPath =
//      [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];
//  NSString *base64 = [NSString stringWithContentsOfFile:certPath
//                                               encoding:NSUTF8StringEncoding
//                                                  error:NULL];
//  base64 = [base64
//      stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----\n"
//                                withString:@""];
//  base64 = [base64
//      stringByReplacingOccurrencesOfString:@"\n-----END CERTIFICATE-----\n"
//                                withString:@""];
//  if ([base64 rangeOfString:@"\n"].location != NSNotFound) {
//    base64 = [base64 stringByReplacingOccurrencesOfString:@"\n" withString:@""];
//  }
//  // remove temp file
//  NSFileManager *fileManager = [NSFileManager defaultManager];
//  NSError *error;
//  [fileManager removeItemAtPath:certPath error:&error];
//  return base64;
//}
//
//- (NSString *)p7mInform:(NSString *)p7m {
//  NSString *inform = @"Content-Disposition: attachment; "
//      @"filename=\"smime.p7m\"\r\nContent-Type: "
//      @"application/pkcs7-mime; smime-type=enveloped-data; "
//      @"name=\"smime.p7m\"\r\nContent-Transfer-Encoding: " @"base64\r\n\r\n";
//  p7m = [NSString stringWithFormat:@"%@%@\r\n\r\n", inform, p7m];
//  return p7m;
//}

@end
