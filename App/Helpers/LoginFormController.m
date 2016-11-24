
//  FormTableController.m
//  TableWithTextField
//
//  Created by Andrew Lim on 4/15/11.
//

#import "LoginFormController.h"
#import "FlatUIKit.h"
#import "MailTypeViewController.h"
#import <GContacts/GDataContacts.h>
#import <MailCore/MailCore.h>
#import "FXKeychain.h"

#import "MsgListViewController.h"
#import "AuthManager.h"

#import "CheckNetWork.h"
#import "AuthNavigationViewController.h"
#import "Constants.h"

@implementation LoginFormController

NSInteger mailtype;
NSInteger accIndex;
UIInterfaceOrientation orientation;
NSMutableArray *listAccount;
NSMutableArray *smtpportArr;

@synthesize name = name_;
@synthesize password = password_;
@synthesize displayname = displayname_;

// imap
@synthesize imap = imap_;
@synthesize imapport = imapport_;
@synthesize imapEmail = imapEmail_;
@synthesize imapPass = imapPass_;

// smtp
@synthesize smtp = smtp_;
@synthesize smtpport = smtpport_;
@synthesize smtpEmail = smtpEmail_;
@synthesize smtpPass = smtpPass_;

- (void)viewDidLoad {

  [super viewDidLoad];

  self.name = @"";
  self.password = @"";
  smtpportArr = [[NSMutableArray alloc] init];
  [smtpportArr addObject:@"25"];
  [smtpportArr addObject:@"465"];
  [smtpportArr addObject:@"587"];

  listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  mailtype = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"mailtype"] integerValue];

  switch (mailtype) {
  case 2:
    self.imap = @"imap.gmail.com";
    self.imapport = @"993";
    self.smtp = @"smtp.gmail.com";
    self.smtpport = @"465";
    break;
  case 3:
    self.imap = @"imap.mail.yahoo.com";
    self.imapport = @"993";
    self.smtp = @"smtp.mail.yahoo.com";
    self.smtpport = @"465";
    break;
  case 4:
    self.imap = @"imap-mail.outlook.com";
    self.imapport = @"993";
    self.smtp = @"smtp-mail.outlook.com";
    self.smtpport = @"587";
    break;
  default:
    self.imap = @"";
    self.imapport = @"993";
    self.smtp = @"";
    self.smtpport = @"25";
    break;
  }
  
  name_Field.delegate = self;
  displayname_Field.delegate = self;
  imap_Field.delegate = self;
  imapport_Field.delegate = self;
  smtp_Field.delegate = self;
  smtpport_Field.delegate = self;

  orientation = [[UIApplication sharedApplication] statusBarOrientation];

  if (orientation == UIInterfaceOrientationPortrait ||
      orientation == UIInterfaceOrientationPortraitUpsideDown) {
    _tableView = [[UITableView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                 self.view.bounds.size.height)
                style:UITableViewStyleGrouped];
  } else {
    _tableView = [[UITableView alloc]
        initWithFrame:CGRectMake(0, 0, self.view.frame.size.height,
                                 self.view.bounds.size.width)
                style:UITableViewStyleGrouped];
  }
  _tableView.delegate = self;
  _tableView.dataSource = self;

  self.navigationController.navigationBarHidden = NO;
  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor colorFromHexCode:barColor]];
  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];
    
  UIButton *continuebtn = [UIButton buttonWithType:UIButtonTypeCustom];
  [continuebtn setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [continuebtn addTarget:self
                  action:@selector(startLogin:)
        forControlEvents:UIControlEventTouchUpInside];
  UIImage *sendImage = [UIImage imageNamed:@"send.png"];
  [continuebtn setImage:sendImage forState:UIControlStateNormal];

  UIBarButtonItem *continueButton =
      [[UIBarButtonItem alloc] initWithCustomView:continuebtn];
  self.navigationItem.rightBarButtonItem = continueButton;
  self.navigationItem.title = NSLocalizedString(@"Login", nil);
  _tableView.backgroundView = nil;
  _tableView.backgroundColor = [UIColor whiteColor];
  self.view.backgroundColor = [UIColor whiteColor];
  [_tableView setFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                  self.view.frame.size.height)];
  UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:self.view.frame];
//  scroll.contentSize =
//      CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 300);
    scroll.contentSize =
    CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
  [scroll addSubview:_tableView];
  [self.view addSubview:scroll];
  
  if (mailtype == 0) {
    [self fillDefaultAccountConfig];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if (mailtype != 0) {
    [displayname_Field becomeFirstResponder];
  }
}

- (void)willAnimateRotationToInterfaceOrientation:
            (UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
  _tableView = [[UITableView alloc]
      initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,
                               self.view.frame.size.height)
              style:UITableViewStyleGrouped];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [self.view addSubview:_tableView];
}

- (void)addBackButton {
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self
             action:@selector(backtoType:)
   forControlEvents:UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    //Đổ màu lam (mặc đinh) cho Image
    // backImage = [backImage
    // imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton =
    [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)fillDefaultAccountConfig {
//  remove fill default account config
    
//  self.displayname = @"Tuanpt";
//  self.name = @"tuanpt@hanoi.vssic.gov.vn";
//  self.password = @"1234567a@";
  
  self.imap = @"email.vssic.gov.vn";
//  self.imapEmail = @"tuanpt@hanoi.vssic.gov.vn";
//  self.imapPass = @"1234567a@";
  
  self.smtp = @"email.vssic.gov.vn";
//  self.smtpEmail = @"tuanpt@hanoi.vssic.gov.vn";
//  self.smtpPass = @"1234567a@";
  
    displayname_Field = [self makeTextField:displayname_Field text:self.displayname placeholder:@""];
    
    imap_Field = [self makeTextField:imap_Field text:self.imap placeholder:@""];
    imap_Field.text = self.imap;
    
    imapEmail_Field = [self makeTextField:imapEmail_Field text:self.imapEmail placeholder:@""];
    imapPass_Field = [self makeTextField:imapPass_Field text:self.imapPass placeholder:@""];
    
    smtp_Field = [self makeTextField:smtp_Field text:self.smtp placeholder:@""];
    smtp_Field.text = self.smtp;
    
    smtpEmail_Field = [self makeTextField:smtpEmail_Field text:self.smtpEmail placeholder:@""];
    smtpPass_Field = [self makeTextField:smtpPass_Field text:self.smtpPass placeholder:@""];
    
  [_tableView reloadData];
}

- (void)beginChecking {

  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  hud.labelText = NSLocalizedString(@"PleaseWait", nil);
  [self.view endEditing:YES];
  self.imapSession = [[MCOIMAPSession alloc] init];
  [self.imapSession setCheckCertificateEnabled:NO];
  self.imapSession.hostname = imap_;
  self.imapSession.port = (unsigned int)[imapport_ integerValue];
  self.imapSession.username = name_Field.text;
  if (mailtype == 4) {
    if ([name_Field.text rangeOfString:@"@outlook.com"].location ==
        NSNotFound) {
      self.imapSession.username =
          [NSString stringWithFormat:@"%@@outlook.com", name_Field.text];
    }
  }
  self.imapSession.password = password_Field.text;
  self.imapSession.connectionType = MCOConnectionTypeTLS;
  LoginFormController *__weak weakSelf = self;
  self.imapSession.connectionLogger = ^(void *connectionID,
                                        MCOConnectionLogType type,
                                        NSData *data) {
    @synchronized(weakSelf) {
      NSString *errStr =
          [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      if ([errStr isEqualToString:@"2 NO [AUTHENTICATIONFAILED] Invalid "
                  @"credentials (Failure)"]) {
      }

      NSLog(@"Error Type : %lu  = Error Login : %@", (long)type, errStr);
      if (type != MCOConnectionLogTypeSentPrivate) {
        NSLog(
            @"event logged:%p %li withData: %@", connectionID, (long)type,
            [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
      }
    }
  };

  self.imapCheckOp = [self.imapSession checkAccountOperation];
  [self.imapCheckOp start:^(NSError *error) {
    NSLog(@"finished checking account.");
    if (error == nil) {
      if (mailtype == 0) { // Nếu tự cấu hình = tài khoản gmail
        NSLog(@"%@", name_Field.text);
        if (!([name_Field.text rangeOfString:@"@gmail.com"].location ==
              NSNotFound)) {
          mailtype = 2;
          [self saveCustomerInfo];
        } else if (!([name_Field.text rangeOfString:@"@yahoo.com"].location ==
                     NSNotFound)) {
          mailtype = 3;
          [self saveCustomerInfo];
        } else if (!([name_Field.text rangeOfString:@"@outlook.com"].location ==
                     NSNotFound)) {
          mailtype = 4;
          [self saveCustomerInfo];
        } else {
          [self startChecKSMTP:0];
        }
      } else {
        [self saveCustomerInfo];
      }

    } else {
      NSString *errStr;
      if (error.code == 40) {
        errStr = NSLocalizedString(@"2StepAuthenError", nil);
      } else {
        errStr = NSLocalizedString(@"LoginErrorMsg", nil);
      }
      UIAlertView *alertView = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"LoginError", nil)
                    message:errStr
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
          otherButtonTitles:nil];
      alertView.tag = 1;
      [alertView show];
      [hud hide:YES];
      NSLog(@"error loading account formtableview: %@", error);
    }
  }];

  [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"fistauth"];
  //[[NSUserDefaults standardUserDefaults]setObject:@"" forKey:@"firstImap"];
  [AuthManager resetImapSession:YES];
}

- (NSString *)usernameMail:(NSString *)username {
  NSString *mailtype =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"];
  if ([mailtype isEqual:@"2"]) {
    if ([username rangeOfString:@"gmail.com"].location == NSNotFound) {
      username = [NSString stringWithFormat:@"%@@gmail.com", username];
    }
  }
  if ([mailtype isEqual:@"3"]) {
    if ([username rangeOfString:@"yahoo.com"].location == NSNotFound) {
      username = [NSString stringWithFormat:@"%@@yahoo.com", username];
    }
  }

  if ([mailtype isEqual:@"4"]) {
    if ([username rangeOfString:@"outlook.com"].location == NSNotFound) {
      username = [NSString stringWithFormat:@"%@@outlook.com", username];
    }
  }
  return username;
}

- (void)startChecKSMTP:(int)index {
  // Kiểm tra port
  if (index == smtpportArr.count) {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    UIAlertView *alertView = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Error", nil)
                  message:NSLocalizedString(@"ConnectSMTP", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil];

    [alertView show];
    return;
  }
  MCOSMTPSession *smtp = [[MCOSMTPSession alloc] init];
  [smtp setCheckCertificateEnabled:NO];
  [smtp setHostname:self.smtp];
  [smtp setPort:(unsigned int)[[smtpportArr objectAtIndex:index] integerValue]];
  [smtp setUsername:smtpEmail_Field.text];
  [smtp setPassword:smtpPass_Field.text];

  // TLS CONNECTION
  // MCOConnectionTypeTLS :      Port 465
  // MCOConnectionTypeStartTLS : Port 587
  // MCOConnectionTypeClear :    Port 25
  
  switch (index) {
  case 0:
    [smtp setConnectionType:MCOConnectionTypeClear];
    break;
  case 1:
    [smtp setConnectionType:MCOConnectionTypeTLS];
    break;
  case 2:
    [smtp setConnectionType:MCOConnectionTypeStartTLS];
    break;
  }
  MCOSMTPOperation *op =
      [smtp checkAccountOperationWithFrom:
                [MCOAddress addressWithMailbox:smtpEmail_Field.text]];
  [op start:^(NSError *error) {
    if (error == nil) {
      self.smtpport = [smtpportArr objectAtIndex:index];
      [self saveCustomerInfo];
    } else {
      [self startChecKSMTP:index + 1];
    }
  }];
}

- (void)startLogin:(id)sender {
  CheckNetWork *init = [[CheckNetWork alloc] init];
  if (![init checkNetworkAvailable]) {
    UIAlertView *alertView = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Notifi", nil)
                  message:NSLocalizedString(@"CheckInternet", nil)
                 delegate:self
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil];
    alertView.tag = 1;
    [alertView show];

  } else {
    if ((![imap_Field.text isEqualToString:@""] &&
         ![imapport_Field.text isEqualToString:@""] &&
         ![name_Field.text isEqualToString:@""]) &&
        ![password_Field.text isEqualToString:@""] &&
        ![smtp_Field.text isEqualToString:@""] &&
        ![smtpport_Field.text isEqualToString:@""]) {
      NSLog(@"Begin checking account");
      if (mailtype == 0) {
        if ([self checkvalidEmail:name_Field.text]) {
          [self beginChecking];
        } else {
          // Email không hợp lệ
          UIAlertView *alertView = [[UIAlertView alloc]
                  initWithTitle:NSLocalizedString(@"Error", nil)
                        message:NSLocalizedString(@"InvalidEmail_", nil)
                       delegate:self
              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
              otherButtonTitles:nil];
          alertView.tag = 1;
          [alertView show];
        }

      } else {
        [self beginChecking];
      }

    } else {
      UIAlertView *alertView =
          [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                     message:NSLocalizedString(@"EnterAll", nil)
                                    delegate:self
                           cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                           otherButtonTitles:nil];
      alertView.tag = 1;
      [alertView show];
    }
  }
}

- (void)backtoType:(id)sender {
  [self dismissViewControllerAnimated:true completion:nil];
}

- (void)saveCustomerInfo {


  BOOL usedAcc = NO;
  NSString *account = name_Field.text;
  switch (mailtype) {
  case 2:
    if ([account rangeOfString:@"@gmail.com"].location == NSNotFound) {
      account = [NSString stringWithFormat:@"%@@gmail.com", account];
    }
    break;
  case 3:
    if ([account rangeOfString:@"@"].location == NSNotFound) {
      account = [NSString stringWithFormat:@"%@@yahoo.com", account];
    } else {
      NSRange endRange =
          [account rangeOfString:@"@"
                         options:NSBackwardsSearch
                           range:NSMakeRange(0, account.length - 1)];
      account = [account substringToIndex:endRange.location];
      account = [NSString stringWithFormat:@"%@@yahoo.com", account];
    }
    break;
  case 4:
    if ([account rangeOfString:@"@outlook.com"].location == NSNotFound) {
      account = [NSString stringWithFormat:@"%@@outlook.com", account];
    }
    break;
  default:
    break;
  }
  accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  if (listAccount.count == 0) {
    listAccount = [[NSMutableArray alloc] init];
    accIndex = 0;
  } else {
    listAccount =
        [[NSMutableArray alloc] initWithArray:listAccount copyItems:YES];
    for (int i = 0; i < listAccount.count; i = i + 4) {
      NSString *em = [listAccount objectAtIndex:i + 1];
      if ([em isEqualToString:account]) {
        accIndex = i;
        usedAcc = YES;
      }
    }
  }
  if (usedAcc == NO) {
    accIndex = listAccount.count;
    [listAccount addObject:displayname_Field.text];
    [listAccount addObject:account];
    [listAccount addObject:password_Field.text];
    if (mailtype <= 4 && mailtype != 0) {
      [listAccount
          addObject:[NSString stringWithFormat:@"%ld", (long)mailtype]];
    } else {
      NSString *custom =
          [[NSUserDefaults standardUserDefaults] objectForKey:@"customIndex"];
      if (custom == nil) {
        custom = @"8";
      }
      NSInteger num = [custom integerValue] + 1;
      custom = [NSString stringWithFormat:@"%ld", (long)num];
      NSMutableArray *customInfo = [[NSMutableArray alloc] init];
      NSArray *copy =
          [[NSUserDefaults standardUserDefaults] objectForKey:@"customInfo"];
      customInfo = [copy mutableCopy];
      if (customInfo.count == 0) {
        customInfo = [[NSMutableArray alloc] init];
      }
      [listAccount addObject:[NSString stringWithFormat:@"%ld", (long)num]];
      [customInfo addObject:[NSString stringWithFormat:@"%ld", (long)num]];
      [customInfo addObject:imap_Field.text];
      [customInfo addObject:self.imapport];
      [customInfo addObject:imapEmail_Field.text];
      [customInfo addObject:imapPass_Field.text];
      [customInfo addObject:smtp_Field.text];
      [customInfo addObject:self.smtpport];
      [customInfo addObject:smtpEmail_Field.text];
      [customInfo addObject:smtpPass_Field.text];
      [[NSUserDefaults standardUserDefaults]
          setObject:[NSString stringWithFormat:@"%ld", (long)num]
             forKey:@"customIndex"];
      [[NSUserDefaults standardUserDefaults] setObject:customInfo
                                                forKey:@"customInfo"];
    }
  }

  [[NSUserDefaults standardUserDefaults] setObject:[listAccount copy]
                                            forKey:@"listAccount"];
  [[NSUserDefaults standardUserDefaults]
      setObject:[NSString stringWithFormat:@"%ld", (long)accIndex]
         forKey:@"accIndex"];

  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"Finished_FirstOAuth"
                    object:nil];
  [[AuthManager sharedManager] getAccountInfo:NO];

  [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMessage"
                                                      object:nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu"
                                                      object:nil];
  [MBProgressHUD hideHUDForView:self.view animated:YES];
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
//  return 3;
    return 2;
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"]
//         isEqual:@"0"]) {
//        return 3;
//    } else {
        return 1;
//    }
}

- (CGFloat)tableView:(UITableView *)tableView
heightForHeaderInSection:(NSInteger)section {
//    if (section == 0) {
        return 35;
//    }
//    return 15;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
    NSString *sectionName;
    switch (section) {
        case 0:
            sectionName = NSLocalizedString(@"UserInfo", nil);
            break;
//        case 1:
//            sectionName = @"HOST IMAP";
//            break;
//        case 2:
//            sectionName = @"HOST SMTP";
//            break;
        default:
            sectionName = @"";
            break;
    }
//
//    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"]
//         isEqualToString:@"2"]) {
//        if (section == 1) {
//            sectionName = @"Trường hợp không thể đăng nhập";
//        }
//    }
    return sectionName;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.section == 0) {
//        if (indexPath.row == 0) {
//            return 0;
//        } else {
//            return 44.0f;
//        }
//    } else {
//        return 0;
//    }
//}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                             reuseIdentifier:nil];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  UIFont *myFont = [UIFont systemFontOfSize:16.0];
  UITextField *tf;
//  switch (indexPath.section) {
//  case 0:
    switch (indexPath.row) {
    case 0: {
//      cell.textLabel.text = NSLocalizedString(@"DisplayName", nil);
//      cell.textLabel.font = myFont;
//      tf = displayname_Field =
//          [self makeTextField:displayname_Field text:self.displayname placeholder:@""];
//      displayname_Field.autocapitalizationType =
//          UITextAutocapitalizationTypeWords;
//      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
//      tf.placeholder = @"Cherry Blossom";
//
//      [cell addSubview:displayname_Field];
//      break;
//    }
//    case 1: {
      cell.textLabel.text = NSLocalizedString(@"MailBox", nil);
      cell.textLabel.font = myFont;
      tf = name_Field = [self makeTextField:name_Field text:self.name placeholder:@""];
      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
      tf.placeholder = @"mymail@company.com";
      [name_Field addTarget:self
                     action:@selector(emailFieldDidChange:)
           forControlEvents:UIControlEventEditingChanged];
      name_Field.keyboardType = UIKeyboardTypeEmailAddress;
      [cell addSubview:name_Field];
      break;
    }
//    case 2: {
    case 1: {
      cell.textLabel.text = NSLocalizedString(@"Password", nil);
      cell.textLabel.font = myFont;
      tf = password_Field = [self makeTextField:password_Field text:self.password placeholder:@""];
      tf.secureTextEntry = YES;
      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
      tf.placeholder = @"●●●●●●●●";
      [password_Field addTarget:self
                         action:@selector(passFieldDidChange:)
               forControlEvents:UIControlEventEditingChanged];
      [cell addSubview:password_Field];
      break;
    }
    }
//    break;
//  case 1:
//    switch (indexPath.row) {
//    case 0: {
//      cell.textLabel.text = NSLocalizedString(@"Address", nil);
//      cell.textLabel.font = myFont;
//      tf = imap_Field = [self makeTextField:imap_Field text:self.imap placeholder:@""];
//      tf.keyboardType = UIKeyboardTypeEmailAddress;
//      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
//      tf.placeholder = @"imap.company.com";
//      [cell addSubview:imap_Field];
//      break;
//    }
//    case 1: {
//      cell.textLabel.text = NSLocalizedString(@"Username", nil);
//      cell.textLabel.font = myFont;
//      tf = imapEmail_Field =
//      [self makeTextField:imapEmail_Field text:self.imapEmail placeholder:@""];
//      tf.keyboardType = UIKeyboardTypeEmailAddress;
//      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
//      tf.placeholder = NSLocalizedString(@"Required", nil);
//      [cell addSubview:imapEmail_Field];
//      break;
//    }
//    case 2: {
//      cell.textLabel.text = NSLocalizedString(@"Password", nil);
//      cell.textLabel.font = myFont;
//      tf = imapPass_Field = [self makeTextField:imapPass_Field text:self.imapPass placeholder:@""];
//      tf.secureTextEntry = YES;
//      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
//      tf.placeholder = @"●●●●●●●●";
//      [cell addSubview:imapPass_Field];
//      break;
//    }
//    }
//    break;
//  case 2:
//    switch (indexPath.row) {
//    case 0: {
//      cell.textLabel.text = NSLocalizedString(@"Address", nil);
//      cell.textLabel.font = myFont;
//      tf = smtp_Field = [self makeTextField:smtp_Field text:self.smtp placeholder:@""];
//      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
//      tf.keyboardType = UIKeyboardTypeEmailAddress;
//      tf.placeholder = @"smtp.company.com";
//      [cell addSubview:smtp_Field];
//      break;
//    }
//    case 1: {
//      cell.textLabel.text = NSLocalizedString(@"Username", nil);
//      cell.textLabel.font = myFont;
//      tf = smtpEmail_Field =
//      [self makeTextField:smtpEmail_Field text:self.smtpEmail placeholder:@""];
//      tf.keyboardType = UIKeyboardTypeEmailAddress;
//      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
//      tf.placeholder = NSLocalizedString(@"Optional", nil);
//      [cell addSubview:smtpEmail_Field];
//      break;
//    }
//    case 2: {
//      cell.textLabel.text = NSLocalizedString(@"Password", nil);
//      cell.textLabel.font = myFont;
//      tf = smtpPass_Field = [self makeTextField:smtpPass_Field text:self.smtpPass placeholder:@""];
//      tf.secureTextEntry = YES;
//      tf.frame = CGRectMake(120, 7, self.view.frame.size.width - 130, 30);
//      tf.placeholder = @"●●●●●●●●";
//      [cell addSubview:smtpPass_Field];
//      break;
//    }
//    }
//    break;
//  default:
//    break;
//  }

  // Workaround to dismiss keyboard when Done/Return is tapped
  [tf addTarget:self
                action:@selector(textFieldFinished:)
      forControlEvents:UIControlEventEditingDidEndOnExit];
  tf.delegate = self;

    cell.clipsToBounds = YES;
    
  return cell;
}

#pragma mark -
#pragma mark Memory management
- (UITextField *)makeTextField:(UITextField *)textField text:(NSString *)text
                   placeholder:(NSString *)placeholder {
  UITextField *tf = [[UITextField alloc] init];
  tf.placeholder = placeholder;
  tf.text = text;
  tf.autocorrectionType = UITextAutocorrectionTypeNo;
  tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
  tf.adjustsFontSizeToFitWidth = YES;
  tf.clearButtonMode = UITextFieldViewModeWhileEditing;
  if (textField == displayname_Field || textField == name_Field || textField == password_Field) {
    tf.textColor = [UIColor colorWithRed:56.0f / 255.0f
                                   green:84.0f / 255.0f
                                    blue:135.0f / 255.0f
                                   alpha:1.0f];
    
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (sysVer > 7.0) {
      tf.tintColor = [UIColor blueColor];
    }
  } else {
    tf.textColor = [UIColor lightGrayColor];
    tf.tintColor = [UIColor lightGrayColor];
  }
  
  return tf;
}

// Workaround to hide keyboard when Done is tapped
- (IBAction)textFieldFinished:(id)sender {
  // [sender resignFirstResponder];
}

// Textfield value changed, store the new value.

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  if (textField == name_Field || textField == password_Field || textField == displayname_Field) {
    return YES;
  }
  return NO;
}

//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//  if (textField == name_Field) {
////    imapEmail_Field.text = name_Field.text;
////    smtpEmail_Field.text = name_Field.text;
//      self.imapEmail = name_Field.text;
//      self.smtpEmail = name_Field.text;
//  } else if (textField == password_Field) {
////    imapPass_Field.text = password_Field.text;
////    smtpPass_Field.text = password_Field.text;
//      self.imapPass = password_Field.text;
//      self.smtpPass = password_Field.text;
//  }
//  return YES;
//}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  if (textField == name_Field) {
    self.name = textField.text;
    self.imapEmail = textField.text;
    self.smtpEmail = textField.text;
      imapEmail_Field.text = textField.text;
      smtpEmail_Field.text = textField.text;
  } else if (textField == displayname_Field) {
    self.displayname = textField.text;
  } else if (textField == password_Field) {
    self.password = textField.text;
    self.imapPass = textField.text;
    self.smtpPass = textField.text;
      imapPass_Field.text = textField.text;
      smtpPass_Field.text = textField.text;
  }
//  else if (textField == imap_Field) {
//    self.imap = textField.text;
//  } else if (textField == imapport_Field) {
//    self.imapport = textField.text;
//  } else if (textField == smtp_Field) {
//    self.smtp = textField.text;
//  } else if (textField == smtpport_Field) {
//    self.smtpport = textField.text;
//  } else if (textField == smtpPass_Field) {
//    self.smtpPass = textField.text;
//  } else if (textField == smtpEmail_Field) {
//    self.smtpEmail = textField.text;
//  } else if (textField == imapEmail_Field) {
//    self.imapEmail = textField.text;
//  } else if (textField == imapPass_Field) {
//    self.imapPass = textField.text;
//  }
}

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView.tag == 2) {
    CheckNetWork *init = [[CheckNetWork alloc] init];
    if (![init checkNetworkAvailable]) {
      if (buttonIndex == alertView.cancelButtonIndex) {
        UIAlertView *alertView = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"Notifi", nil)
                      message:NSLocalizedString(@"CheckInternet", nil)
                     delegate:self
            cancelButtonTitle:NSLocalizedString(@"Ok", nil)
            otherButtonTitles:nil];
        [alertView show];
      }
    } else {
      [self beginChecking];
    }
  }
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)emailFieldDidChange:(UITextField *)textfield {
  imapEmail_Field.text = textfield.text;
  smtpEmail_Field.text = textfield.text;
}

- (void)passFieldDidChange:(UITextField *)textfield {
  imapPass_Field.text = textfield.text;
  smtpPass_Field.text = textfield.text;
}

- (BOOL)checkvalidEmail:(NSString *)checkString {
  BOOL stricterFilter = YES;
  NSString *stricterFilterString =
      @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
  NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
  NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
  NSPredicate *emailTest =
      [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [emailTest evaluateWithObject:checkString];
}

- (NSString *)getNameFromEmail:(NSString *)email {
    if (email == nil || email.length == 0) {
        return @"";
    }
    NSArray *subStrings = [email componentsSeparatedByString:@"@"];
    if (subStrings.count > 0) {
        return subStrings.firstObject;
    }
    return  @"";
}

@end
