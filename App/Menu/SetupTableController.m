//
//  SetupTableController.m
//  iMail
//
//  Created by Thanh on 8/12/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "SetupTableController.h"
#import "MsgListViewController.h"
#import "AppDelegate.h"
#import "DBManager.h"
#import "TokenType.h"
#import "HardTokenMethod.h"
#import "PrivatePolicy.h"
#import "DBManager.h"

#import "Composer_iPhoneViewController.h"
#import "ComposerViewController.h"
#import "FixedNavigationController.h"

#import "Constants.h"

#define TokenSetting 0
#define SetSign 1
#define APP_ID 915231260

@interface SetupTableController ()

@end

@implementation SetupTableController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
  [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [back addTarget:self
                action:@selector(dismissSetting:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
  [back setImage:backImage forState:UIControlStateNormal];
  UIBarButtonItem *backButton =
      [[UIBarButtonItem alloc] initWithCustomView:back];
  self.navigationItem.leftBarButtonItem = backButton;
// HoangTD edit
//  [[NSNotificationCenter defaultCenter] addObserver:self
//                                           selector:@selector(selectedTableRow)
//                                               name:@"closePopOver"
//                                             object:nil];
  iosVer = [[[UIDevice currentDevice] systemVersion] floatValue];
  if (!expandedSections) {
    expandedSections = [[NSMutableIndexSet alloc] init];
  }
  if (!expandedSectionSign) {
    expandedSectionSign = [[NSMutableIndexSet alloc] init];
  }
  if (!expandedSectionLang) {
    expandedSectionLang = [[NSMutableIndexSet alloc] init];
  }
}

- (void)viewDidAppear:(BOOL)animated {

  // Unlock
  username = [[NSString alloc] init];
  [MsgListViewController setUnlockMail:YES];
  NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count > 0 && accIndex < listAccount.count) {
    username = [listAccount objectAtIndex:accIndex + 1];
  }

// HoangTD edit
//  NSArray *protect = [[DBManager getSharedInstance] findProtected:username];
//  int tokenType = [[protect objectAtIndex:0] intValue];
//
//  if (tokenType == SOFTTOKEN || tokenType == HARDTOKEN) {
//    if (tokenType == SOFTTOKEN) {
//      status = @"Bật";
//      device = @"Soft Token";
//      serial = @"SID";
//    } else if (tokenType == HARDTOKEN) {
//      status = @"Bật";
//      device = @"Hard Token";
//      serial = [protect objectAtIndex:2];
//    }
//    [switchProtect setOn:YES animated:NO];
//    if (iosVer >= 7.0) {
//      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
//      NSInteger section = indexPath.section;
//      BOOL currentlyExpanded = [expandedSections containsIndex:section];
//      if (!currentlyExpanded) {
//        NSInteger rows;
//
//        NSMutableArray *tmpArray = [NSMutableArray array];
//
//        if (currentlyExpanded) {
//          rows = [self tableView:self.tableView numberOfRowsInSection:section];
//          [expandedSections removeIndex:section];
//        } else {
//          [expandedSections addIndex:section];
//          rows = [self tableView:self.tableView numberOfRowsInSection:section];
//        }
//        for (int i = 2; i < rows; i++) {
//          NSIndexPath *tmpIndexPath =
//              [NSIndexPath indexPathForRow:i inSection:section];
//          [tmpArray addObject:tmpIndexPath];
//        }
//        if (currentlyExpanded) {
//          [self.tableView deleteRowsAtIndexPaths:tmpArray
//                                withRowAnimation:UITableViewRowAnimationTop];
//        } else {
//          [self.tableView insertRowsAtIndexPaths:tmpArray
//                                withRowAnimation:UITableViewRowAnimationTop];
//        }
//      }
//    }
//  }
  if (iosVer >= 7.0) {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"signature"]) {
      [switchSignature setOn:YES animated:YES];
//    HoangTD edit
      NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
      NSInteger section = indexPath.section;
      BOOL currentlyExpanded = [expandedSectionSign containsIndex:section];
      if (!currentlyExpanded) {
        NSInteger rows;

        NSMutableArray *tmpArray = [NSMutableArray array];

        if (currentlyExpanded) {
          rows = [self tableView:self.tableView numberOfRowsInSection:section];
          [expandedSectionSign removeIndex:section];
        } else {
          [expandedSectionSign addIndex:section];
          rows = [self tableView:self.tableView numberOfRowsInSection:section];
        }
        for (int i = 2; i < rows; i++) {
          NSIndexPath *tmpIndexPath =
              [NSIndexPath indexPathForRow:i inSection:section];
          [tmpArray addObject:tmpIndexPath];
        }
        if (currentlyExpanded) {
          signature_text.text =
              [[NSUserDefaults standardUserDefaults] objectForKey:@"signature"];
          [self.tableView deleteRowsAtIndexPaths:tmpArray
                                withRowAnimation:UITableViewRowAnimationTop];
        } else {
          signature_text.text = @"";
          [self.tableView insertRowsAtIndexPaths:tmpArray
                                withRowAnimation:UITableViewRowAnimationTop];
        }
      }

    } else {
      [switchSignature setOn:NO animated:YES];
    }
  }
  BOOL luonKy = [[NSUserDefaults standardUserDefaults] boolForKey:@"luonky"];
  [switchLuonKy setOn:luonKy animated:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (BOOL)tableView:(UITableView *)tableView
    canCollapseSection:(NSInteger)section {
  return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //HoangTD edit
    return 2;
//  return 3;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  switch (section) {
//  HoangTD edit
//  case 0:
//    return NSLocalizedString(@"Security_Settings", nil);
//    break;
  case 0:
    return NSLocalizedString(@"MoreOptions", nil);
    break;
  case 1:
    return NSLocalizedString(@"About", nil);
    break;
  default:
    return nil;
    break;
  }
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  switch (section) {
//  HoangTD edit
//  case 0:
//    if ([self tableView:tableView canCollapseSection:section]) {
//      if ([expandedSections containsIndex:section]) {
//        return 4;
//      }
//      return 2;
//    } else {
//      return 4;
//    }
//    return 0;
//    break;
  case 0:
    if (iosVer >= 7.0) {
      if ([self tableView:tableView canCollapseSection:section]) {
        if ([expandedSectionSign containsIndex:section]) {
            return 3;
// HoangTD edit
//          return 4;
        }
         return 2;
      }
// HoangTD edit
//      return 3;
        return 2;
    } else {
      return 2;
    }
    break;
  case 1:
    return 4;
  default:
    return 1;
    break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return 30;
  }
  return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";

  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:CellIdentifier];
  }
  NSString *stringForCell;
  UILabel *subHeader = [[UILabel alloc] init];
  subHeader.font = [UIFont systemFontOfSize:17];
  subHeader.clipsToBounds = YES;
  subHeader.textColor = [UIColor colorFromHexCode:subHeaderColor];
  switch (indexPath.section) {
// HoangTD edit
//  case 0:
//    switch (indexPath.row) {
//    case 0:
//      stringForCell = NSLocalizedString(@"ConfigToken", nil);
//      ;
//      break;
//    case 1:
//      stringForCell = NSLocalizedString(@"EmailSecurity", nil);
//      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//      switchProtect = [[UISwitch alloc] initWithFrame:CGRectZero];
//      cell.accessoryView = switchProtect;
//      [switchProtect addTarget:self
//                        action:@selector(switchChanged:)
//              forControlEvents:UIControlEventValueChanged];
//      [switchProtect setTag:1];
//      break;
//    case 2:
//      stringForCell = NSLocalizedString(@"DeviceSecurity", nil);
//      subHeader.text = device;
//      [subHeader sizeToFit];
//      [subHeader setFrame:CGRectMake(cell.frame.size.width - 10 -
//                                         subHeader.frame.size.width,
//                                     0, subHeader.frame.size.width,
//                                     cell.frame.size.height)];
//      cell.accessoryView = subHeader;
//      break;
//    case 3: {
//      stringForCell = NSLocalizedString(@"DeviceSerial", nil);
//      subHeader.text = serial;
//      [subHeader sizeToFit];
//      [subHeader setFrame:CGRectMake(cell.frame.size.width - 10 -
//                                         subHeader.frame.size.width,
//                                     0, subHeader.frame.size.width,
//                                     cell.frame.size.height)];
//      cell.accessoryView = subHeader;
//    } break;
//    default:
//      break;
//    }
//    break;
//  HoangTD edit
//case 1:
  case 0:
    switch (indexPath.row) {
// HoangTD edit
//    case 0: {
//      stringForCell = NSLocalizedString(@"AlwaysSign", nil);
//      switchLuonKy = [[UISwitch alloc] initWithFrame:CGRectZero];
//      cell.accessoryView = switchLuonKy;
//      [switchLuonKy addTarget:self
//                       action:@selector(switchChanged:)
//             forControlEvents:UIControlEventValueChanged];
//      [switchLuonKy setTag:0];
//    } break;
    case 0: {
      stringForCell = NSLocalizedString(@"Language", nil);
      break;
    } break;
    case 1: {
      stringForCell = NSLocalizedString(@"Signature", nil);
      switchSignature = [[UISwitch alloc] initWithFrame:CGRectZero];
      cell.accessoryView = switchSignature;
      [switchSignature addTarget:self
                          action:@selector(switchChanged:)
                forControlEvents:UIControlEventValueChanged];
      [switchSignature setTag:2];
    } break;
    case 2: {
      signature_text = [[UITextField alloc]
          initWithFrame:CGRectMake(20, 0, cell.frame.size.width - 20,
                                   cell.frame.size.height)];

      NSString *sig =
          [[NSUserDefaults standardUserDefaults] objectForKey:@"signature"];
      if (!sig.length) {
        signature_text.text = NSLocalizedString(@"Signature_default", nil);
      } else {
        signature_text.text = sig;
      }

      signature_text.textColor = [UIColor colorFromHexCode:subHeaderColor];
      cell.accessoryView = signature_text;

      [cell.accessoryView
          setFrame:CGRectMake(20, 0, self.view.frame.size.width - 40,
                              cell.accessoryView.frame.size.height)];
    } break;
    default:
      break;
    }
    break;
//HoangTD edit
//case 2:
  case 1:
    switch (indexPath.row) {
    case 0: {
      appver = [[NSBundle mainBundle]
          objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
      stringForCell = [NSString
          stringWithFormat:@"%@ %@", NSLocalizedString(@"VersionApp", nil),
                           appver];
    } break;
    case 1:
      stringForCell = NSLocalizedString(@"RateApp", nil);
      break;
    case 2:
      stringForCell = NSLocalizedString(@"SendFeedback", nil);
      break;
    case 3:
      stringForCell = NSLocalizedString(@"Privacy_policy", nil);
      break;
    default:
      break;
    }
    break;
  default:
    break;
  }
  // cell.selectionStyle = UITableViewCellSelectionStyleNone;
  cell.textLabel.text = stringForCell;

  UIView *bgColorView = [[UIView alloc] init];
  bgColorView.backgroundColor = [UIColor peterRiverColor];
  bgColorView.layer.masksToBounds = YES;
  [cell setSelectedBackgroundView:bgColorView];

  return cell;
}

- (void)switchChanged:(id)sender {
  UISwitch *switchControl = sender;
  switch (switchControl.tag) {
// HoangTD edit
//  case 0: {
//    if (switchControl.on) {
//      NSLog(@"Sign ON");
//      if (![[DBManager getSharedInstance] findTokenTypeByEmail:username]) {
//        MBProgressHUD *hud =
//            [MBProgressHUD showHUDAddedTo:self.navigationController.view
//                                 animated:YES];
//        hud.mode = MBProgressHUDModeCustomView;
//        hud.labelText = NSLocalizedString(@"NoToken", nil);
//        hud.labelFont = [UIFont boldSystemFontOfSize:13];
//        hud.margin = 12.0f;
//        hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
//        hud.removeFromSuperViewOnHide = YES;
//        [hud hide:YES afterDelay:1.5];
//        [switchControl setOn:NO animated:YES];
//      }
//    } else {
//      NSLog(@"Sign OFF");
//    }
//
//    [[NSUserDefaults standardUserDefaults] setBool:switchControl.on
//                                            forKey:@"luonky"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//  } break;
//  case 1: {
//    NSArray *protect =
//        [[DBManager getSharedInstance] findTokenTypeByEmail:username];
//    NSString *tokenType = [protect objectAtIndex:0];
//    if ([tokenType isEqualToString:@"0"] || !tokenType) {
//      status = NSLocalizedString(@"TurnOff", nil);
//      device = NSLocalizedString(@"No", nil);
//      serial = NSLocalizedString(@"No", nil);
//      [switchProtect setOn:NO animated:YES];
//      MBProgressHUD *hud =
//          [MBProgressHUD showHUDAddedTo:self.navigationController.view
//                               animated:YES];
//      hud.mode = MBProgressHUDModeCustomView;
//      hud.labelText = NSLocalizedString(@"NoToken", nil);
//      hud.labelFont = [UIFont boldSystemFontOfSize:13];
//      hud.margin = 12.0f;
//      hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
//      hud.removeFromSuperViewOnHide = YES;
//      [hud hide:YES afterDelay:1.5];
//      [switchControl setOn:NO animated:YES];
//    } else if ([tokenType isEqualToString:@"1"]) {
//      status = NSLocalizedString(@"TurnOn", nil);
//      device = @"Soft Token";
//      serial = @"SID";
//    } else if ([tokenType isEqualToString:@"2"]) {
//      status = NSLocalizedString(@"TurnOn", nil);
//      device = @"Hard Token";
//      serial = [protect objectAtIndex:3];
//    }
//    if (iosVer >= 7.0) {
//      // Unlock
//      if ([tokenType isEqualToString:@"1"] ||
//          [tokenType isEqualToString:@"2"]) {
//        [MsgListViewController setUnlockMail:YES];
//        CGPoint buttonPosition =
//            [sender convertPoint:CGPointZero toView:self.tableView];
//        NSIndexPath *indexPath =
//            [self.tableView indexPathForRowAtPoint:buttonPosition];
//        UITableViewCell *cell =
//            [self.tableView cellForRowAtIndexPath:indexPath];
//        UITableView *tableView = (UITableView *)cell.superview.superview;
//        NSInteger section = indexPath.section;
//        BOOL currentlyExpanded = [expandedSections containsIndex:section];
//        NSInteger rows;
//        NSMutableArray *tmpArray = [NSMutableArray array];
//        if (currentlyExpanded) {
//          rows = [self tableView:tableView numberOfRowsInSection:section];
//          [expandedSections removeIndex:section];
//        } else {
//          [expandedSections addIndex:section];
//          rows = [self tableView:tableView numberOfRowsInSection:section];
//        }
//        for (int i = 2; i < rows; i++) {
//          NSIndexPath *tmpIndexPath =
//              [NSIndexPath indexPathForRow:i inSection:section];
//          [tmpArray addObject:tmpIndexPath];
//        }
//        if (currentlyExpanded) {
//          [tableView deleteRowsAtIndexPaths:tmpArray
//                           withRowAnimation:UITableViewRowAnimationTop];
//        } else {
//          [tableView insertRowsAtIndexPaths:tmpArray
//                           withRowAnimation:UITableViewRowAnimationTop];
//        }
//      }
//    } else {
//      if ([tokenType isEqualToString:@"1"] ||
//          [tokenType isEqualToString:@"2"]) {
//        [MsgListViewController setUnlockMail:YES];
//      }
//    }
//  } break;
  case 2: {
    CGPoint buttonPosition =
        [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath =
        [self.tableView indexPathForRowAtPoint:buttonPosition];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UITableView *tableView = (UITableView *)cell.superview.superview;
    NSInteger section = indexPath.section;
    BOOL currentlyExpanded = [expandedSectionSign containsIndex:section];
    NSInteger rows;
    NSMutableArray *tmpArray = [NSMutableArray array];
    if (currentlyExpanded) {
      rows = [self tableView:tableView numberOfRowsInSection:section];
      [expandedSectionSign removeIndex:section];
    } else {
      [expandedSectionSign addIndex:section];
      rows = [self tableView:tableView numberOfRowsInSection:section];
    }
    for (int i = 2; i < rows; i++) {
      NSIndexPath *tmpIndexPath =
          [NSIndexPath indexPathForRow:i inSection:section];
      [tmpArray addObject:tmpIndexPath];
    }
    if (currentlyExpanded) {
      NSString *sig =
          [[NSUserDefaults standardUserDefaults] objectForKey:@"signature"];
      if (!sig.length) {
        signature_text.text = NSLocalizedString(@"Signature_default", nil);
      } else {
        signature_text.text = sig;
      }
      [tableView deleteRowsAtIndexPaths:tmpArray
                       withRowAnimation:UITableViewRowAnimationTop];
    } else {
      signature_text.text = @"";
      [tableView insertRowsAtIndexPaths:tmpArray
                       withRowAnimation:UITableViewRowAnimationTop];
    }
  } break;
  default:
    break;
  }
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

  [tableView deselectRowAtIndexPath:indexPath animated:YES];

//  HoangTD edit
//  if (indexPath.section == 0) {
//    switch (indexPath.row) {
//    case 0: {
//      FUIAlertView *alertView = [[FUIAlertView alloc]
//              initWithTitle:NSLocalizedString(@"ConfigToken", nil)
//                    message:NSLocalizedString(@"TokenType", nil)
//                   delegate:self
//          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
//          otherButtonTitles:@"Soft Token", @"Hard Token", nil];
//      if (IDIOM == IPAD) {
//        alertView.titleLabel.font =
//            [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//        alertView.messageLabel.textColor = [UIColor asbestosColor];
//        alertView.messageLabel.font =
//            [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//        alertView.defaultButtonFont =
//            [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//      } else {
//        alertView.titleLabel.font =
//            [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//        alertView.messageLabel.textColor = [UIColor asbestosColor];
//        alertView.messageLabel.font =
//            [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
//        alertView.defaultButtonFont =
//            [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
//      }
//      alertView.backgroundOverlay.backgroundColor =
//          [[UIColor blackColor] colorWithAlphaComponent:0.8];
//      alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
//      alertView.defaultButtonColor = [UIColor cloudsColor];
//      alertView.defaultButtonShadowColor = [UIColor cloudsColor];
//      alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
//
//      [alertView setTag:TokenSetting];
//      [alertView show];
//    } break;
//
//    default:
//      break;
//    }
//  } else
//HoangTD edit
if (indexPath.section == 0) {
    switch (indexPath.row) {
// HoangTD edit
// case 1
    case 0: {
      FUIAlertView *alertViewLang = [[FUIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Language", nil)
                    message:NSLocalizedString(@"LangChangedNoti", nil)
                   delegate:self
          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
          otherButtonTitles:NSLocalizedString(@"Vietnamese", nil),
                            NSLocalizedString(@"English", nil), nil];
      alertViewLang.backgroundOverlay.backgroundColor =
          [[UIColor blackColor] colorWithAlphaComponent:0.8];
      alertViewLang.alertContainer.backgroundColor = [UIColor cloudsColor];
      alertViewLang.defaultButtonColor = [UIColor cloudsColor];
      alertViewLang.defaultButtonShadowColor = [UIColor cloudsColor];
      alertViewLang.defaultButtonTitleColor = [UIColor belizeHoleColor];
      if (IDIOM == IPAD) {
        alertViewLang.titleLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        alertViewLang.messageLabel.textColor = [UIColor asbestosColor];
        alertViewLang.messageLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        alertViewLang.defaultButtonFont =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
      } else {
        alertViewLang.titleLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        alertViewLang.messageLabel.textColor = [UIColor asbestosColor];
        alertViewLang.messageLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
        alertViewLang.defaultButtonFont =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
      }
      alertViewLang.tag = 3;
      [alertViewLang show];
    } break;

    default:
      break;
    }
  }
//HoangTD edit
else if (indexPath.section == 1) {
    switch (indexPath.row) {
//    case 1: {
//      NSString *const iOS7AppStoreURLFormat =
//          @"itms-apps://itunes.apple.com/app/id%d";
//      NSString *const iOSAppStoreURLFormat =
//          @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/"
//          @"viewContentsUserReviews?type=Purple+Software&id=%d";
//      NSURL *openItunes = [NSURL
//          URLWithString:[NSString stringWithFormat:
//                                      ([[UIDevice currentDevice].systemVersion
//                                               floatValue] >= 7.0f)
//                                          ? iOS7AppStoreURLFormat
//                                          : iOSAppStoreURLFormat,
//                                      APP_ID]];
//      [[UIApplication sharedApplication] openURL:openItunes];
//    } break;
    case 2: {
      NSString *header = [NSString
          stringWithFormat:@"Góp ý và báo lỗi cho phiên bản %@", appver];
      if (IDIOM == IPAD) {
        ComposerViewController *vc =
            [[ComposerViewController alloc] initWithTo:@[
              @"tuanpt@hanoi.vssic.gov.vn"
            ] CC:@[] BCC:@[] subject:header message:@""
                                           attachments:@[]
                                    delayedAttachments:@[]];
        UINavigationController *nc =
            [[UINavigationController alloc] initWithRootViewController:vc];
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:nc animated:YES completion:nil];
      } else {
        Composer_iPhoneViewController *vc =
            [[Composer_iPhoneViewController alloc] initWithTo:@[
              @"tuanpt@hanoi.vssic.gov.vn"
            ] CC:@[] BCC:@[] subject:header message:@""
                                                  attachments:@[]
                                           delayedAttachments:@[]];
        FixedNavigationController *nc =
            [[FixedNavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nc animated:YES completion:nil];
      }
    } break;
//    case 3: {
//      PrivatePolicy *stc = [[PrivatePolicy alloc] init];
//      UINavigationController *nc =
//          [[UINavigationController alloc] initWithRootViewController:stc];
//      nc.navigationBar.titleTextAttributes =
//          @{NSForegroundColorAttributeName : [UIColor whiteColor]};
//      nc.navigationBar.topItem.title = NSLocalizedString(@"PrivacyPolicy", nil);
//      [nc.navigationBar
//          configureFlatNavigationBarWithColor:[UIColor
//                                                  colorFromHexCode:barColor]];
//      [self presentViewController:nc animated:YES completion:nil];
//    } break;
    default:
      break;
    }
  }
}

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (alertView.tag) {
// HoangTD edit
//  case TokenSetting: {
//    if (buttonIndex == 1) {
//      NSLog(@"SOFT TOKEN");
//      UIApplication *ourApplication = [UIApplication sharedApplication];
//      NSURL *ourURL = [NSURL URLWithString:@"vnptcatokenmanager://?emailcall"];
//      if ([ourApplication canOpenURL:ourURL]) {
//        [self softTokenCall];
//      } else {
//        UIAlertView *alertView = [[UIAlertView alloc]
//                initWithTitle:NSLocalizedString(@"Error", nil)
//                      message:NSLocalizedString(@"NotSetup", nil)
//                     delegate:nil
//            cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//            otherButtonTitles:nil];
//        [alertView show];
//      }
//    }
//    if (buttonIndex == 2) {
//      NSLog(@"HARD TOKEN");
//      [self hardTokenCall];
//    }
//  } break;
//  case passwordHT: {
//    if (buttonIndex == 1) {
//      NSString *passwrd = [[alertView textFieldAtIndex:0] text];
//      [alertView dismissWithClickedButtonIndex:1 animated:YES];
//      HardTokenMethod *initMethod = [[HardTokenMethod alloc] init];
//      if ([initMethod connect]) {
//        long ckrv = 1;
//        ckrv = [initMethod
//            VerifyPIN:[passwrd cStringUsingEncoding:NSASCIIStringEncoding]];
//        if (!ckrv) {
//          [[NSNotificationCenter defaultCenter]
//              postNotificationName:@"listCertHard"
//                            object:nil];
//        }
//      };
//    }
//  } break;
//  case passwordST: {
//    if (buttonIndex == 1) {
//      NSString *passwrd = [[alertView textFieldAtIndex:0] text];
//      [alertView dismissWithClickedButtonIndex:1 animated:YES];
//      SoftTokenSign *initMethod = [[SoftTokenSign alloc] init];
//      if ([initMethod connectSoftToken:passwrd]) {
//        [[NSNotificationCenter defaultCenter]
//            postNotificationName:@"softTokenCall"
//                          object:nil];
//      }
//    }
//
//  } break;
  case 3: {
    if (buttonIndex == 1 || buttonIndex == 2) {
      MBProgressHUD *hud =
          [MBProgressHUD showHUDAddedTo:self.navigationController.view
                               animated:YES];
      if (buttonIndex == 1) {
        NSLog(@"Vietnamese");
        NSArray *languages = [NSArray arrayWithObjects:@"vi", nil];
        [[NSUserDefaults standardUserDefaults] setObject:languages
                                                  forKey:@"AppleLanguages"];
        hud.labelText = NSLocalizedString(@"Vietnamese", nil);
      }
      if (buttonIndex == 2) {
        NSLog(@"English");
        NSArray *languages = [NSArray arrayWithObjects:@"en", nil];
        [[NSUserDefaults standardUserDefaults] setObject:languages
                                                  forKey:@"AppleLanguages"];
        hud.labelText = NSLocalizedString(@"English", nil);
      }
      hud.mode = MBProgressHUDModeCustomView;
      hud.dimBackground = YES;
      hud.customView = [[UIImageView alloc]
          initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
      hud.margin = 10.0f;
      hud.removeFromSuperViewOnHide = YES;
      [hud hide:YES afterDelay:1.5];
    }
  } break;
  default:
    break;
  }
}

- (void)dismissSetting:(id)sender {
  // save token protect status
// HoangTD edit
//  if (switchProtect.isOn) {
//    NSString *_id = [[[DBManager getSharedInstance] findProtected:username]
//        objectAtIndex:3];
//    if (_id) {
//      if ([device isEqualToString:@"Soft Token"]) {
//        [[DBManager getSharedInstance] updateProtected:[_id intValue]
//                                         protectedType:SOFTTOKEN
//                                            serialHash:@"0"
//                                                serial:@"SID"
//                                                 email:username];
//      } else if ([device isEqualToString:@"Hard Token"]) {
//        [[DBManager getSharedInstance]
//            updateProtected:[_id intValue]
//              protectedType:HARDTOKEN
//                 serialHash:[HardTokenMethod sha1:[HardTokenMethod shareSerial]]
//                     serial:[HardTokenMethod shareSerial]
//                      email:username];
//      }
//
//    } else {
//      int id_int = [[DBManager getSharedInstance] getLastIDProtected];
//      if ([device isEqualToString:@"Soft Token"]) {
//        [[DBManager getSharedInstance] saveProtected:(id_int + 1)
//                                       protectedType:SOFTTOKEN
//                                          serialHash:@"0"
//                                              serial:@"SID"
//                                               email:username];
//      } else if ([device isEqualToString:@"Hard Token"]) {
//        [[DBManager getSharedInstance]
//            saveProtected:(id_int + 1)
//            protectedType:HARDTOKEN
//               serialHash:[HardTokenMethod sha1:[HardTokenMethod shareSerial]]
//                   serial:[HardTokenMethod shareSerial]
//                    email:username];
//      }
//    }
//  } else {
//    [self resetProtectStatus];
//  }
    
// HoangTD edit
  if ([expandedSectionSign containsIndex:0]) {
    [[NSUserDefaults standardUserDefaults] setObject:signature_text.text
                                              forKey:@"signature"];
  } else {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"signature"];
  }
  // dismiss view
  [self dismissViewControllerAnimated:YES completion:nil];
}

// HoangTD edit
//- (void)softTokenCall {
//  FUIAlertView *alertPin =
//      [[FUIAlertView alloc] initWithTitle:NSLocalizedString(@"TokenPass", nil)
//                                  message:nil
//                                 delegate:self
//                        cancelButtonTitle:NSLocalizedString(@"Out", nil)
//                        otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
//  [alertPin setAlertViewStyle:FUIAlertViewStyleSecureTextInput];
//
//  if (IDIOM == IPAD) {
//    alertPin.titleLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//    alertPin.messageLabel.textColor = [UIColor asbestosColor];
//    alertPin.messageLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//    alertPin.defaultButtonFont =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//  } else {
//    alertPin.titleLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//    alertPin.messageLabel.textColor = [UIColor asbestosColor];
//    alertPin.messageLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
//    alertPin.defaultButtonFont =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
//  }
//  alertPin.backgroundOverlay.backgroundColor =
//      [[UIColor blackColor] colorWithAlphaComponent:0.8];
//  alertPin.alertContainer.backgroundColor = [UIColor cloudsColor];
//  alertPin.defaultButtonColor = [UIColor cloudsColor];
//  alertPin.defaultButtonShadowColor = [UIColor cloudsColor];
//  alertPin.defaultButtonTitleColor = [UIColor belizeHoleColor];
//
//  alertPin.tag = passwordST;
//  [alertPin show];
//}
//
//- (void)hardTokenCall {
//  FUIAlertView *alertPin =
//      [[FUIAlertView alloc] initWithTitle:NSLocalizedString(@"TokenPass", nil)
//                                  message:nil
//                                 delegate:self
//                        cancelButtonTitle:NSLocalizedString(@"Out", nil)
//                        otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
//  [alertPin setAlertViewStyle:FUIAlertViewStyleSecureTextInput];
//  if (IDIOM == IPAD) {
//    alertPin.titleLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//    alertPin.messageLabel.textColor = [UIColor asbestosColor];
//    alertPin.messageLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//    alertPin.defaultButtonFont =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
//  } else {
//    alertPin.titleLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//    alertPin.messageLabel.textColor = [UIColor asbestosColor];
//    alertPin.messageLabel.font =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
//    alertPin.defaultButtonFont =
//        [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
//  }
//  alertPin.backgroundOverlay.backgroundColor =
//      [[UIColor blackColor] colorWithAlphaComponent:0.8];
//  alertPin.alertContainer.backgroundColor = [UIColor cloudsColor];
//  alertPin.defaultButtonColor = [UIColor cloudsColor];
//  alertPin.defaultButtonShadowColor = [UIColor cloudsColor];
//  alertPin.defaultButtonTitleColor = [UIColor belizeHoleColor];
//
//  alertPin.tag = passwordHT;
//  [alertPin show];
//}
//
//// Đóng danh sách chứng thư khi chọn một chứng thư bất kỳ
//- (void)selectedTableRow {
//
//  // reset protect status
//  [self resetProtectStatus];
//  if (switchProtect.isOn) {
//    NSInteger rows = 4;
//    NSMutableArray *tmpArray = [NSMutableArray array];
//    [expandedSections removeIndex:3];
//    for (int i = 2; i < rows; i++) {
//      NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
//      [tmpArray addObject:tmpIndexPath];
//    }
//    [self.tableView deleteRowsAtIndexPaths:tmpArray
//                          withRowAnimation:UITableViewRowAnimationTop];
//  }
//  [switchProtect setOn:NO animated:YES];
//
//  // success alert
//  //    MBProgressHUD *hud = [MBProgressHUD
//  //    showHUDAddedTo:self.navigationController.view animated:YES];
//  //    hud.mode = MBProgressHUDModeCustomView;
//  //    hud.dimBackground = YES;
//  //    hud.customView = [[UIImageView alloc] initWithImage:[UIImage
//  //    imageNamed:@"37x-Checkmark.png"]];
//  //    hud.labelText = NSLocalizedString(@"ChooseCertSuccess", nil);
//  //    hud.margin = 10.0f;
//  //    hud.removeFromSuperViewOnHide = YES;
//  //    [hud hide:YES afterDelay:1.5];
//}
//
//- (void)resetProtectStatus {
//  NSString *_id =
//      [[[DBManager getSharedInstance] findProtected:username] objectAtIndex:3];
//  if (_id) {
//    [[DBManager getSharedInstance] updateProtected:[_id intValue]
//                                     protectedType:NOTOKEN
//                                        serialHash:@"0"
//                                            serial:@"0"
//                                             email:username];
//  } else {
//    int id_int = [[DBManager getSharedInstance] getLastIDProtected];
//    [[DBManager getSharedInstance] saveProtected:(id_int + 1)
//                                   protectedType:NOTOKEN
//                                      serialHash:@"0"
//                                          serial:@"0"
//                                           email:username];
//  }
//}

@end
