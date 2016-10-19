//
//  FileManager.m
//  iMail
//
//  Created by MACBOOK PRO on 2/2/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import "ComposerViewController.h"
#import "Composer_iPhoneViewController.h"
#import "FPMimetype.h"
#import "FileManager.h"
#import "FixedNavigationController.h"
#import "FlatUIKit.h"
#import "TokenType.h"
#import <MailCore/MailCore.h>
@interface FileManager ()

@end

@implementation FileManager

- (void)viewDidLoad {
  [super viewDidLoad];

  // Back button
  UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
  [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [back setImage:[UIImage imageNamed:@"bt_back.png"]
        forState:UIControlStateNormal];
  [back addTarget:self
                action:@selector(dismissDocument:)
      forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *backButton =
      [[UIBarButtonItem alloc] initWithCustomView:back];
  self.navigationItem.leftBarButtonItem = backButton;

  self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated {
  [self initView];
}

- (NSMutableArray *)listFileAtPath:(NSString *)path {
  NSMutableArray *directoryContent = [[NSMutableArray alloc]
      initWithArray:[[NSFileManager defaultManager]
                        contentsOfDirectoryAtPath:path
                                            error:NULL]];
  NSMutableArray *temp = directoryContent;
  for (int i = 0; i < (int)[temp count]; i++) {
    if ([[temp objectAtIndex:i] isEqualToString:@"Inbox"]) {
      [directoryContent removeObjectAtIndex:i];
    }
  }
  return directoryContent;
}

- (void)dismissDocument:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initView {
  if (_tableView) {
    [_tableView removeFromSuperview];
  }

  // Find file
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  listFile = [self listFileAtPath:documentsDirectory];

  // Find date
  NSMutableArray *dateCreat = [[NSMutableArray alloc] init];
  for (int count = 0; count < (int)[listFile count]; count++) {
    NSString *filepath =
        [NSString stringWithFormat:@"%@/%@", documentsDirectory,
                                   [listFile objectAtIndex:count]];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *attrs = [fm attributesOfItemAtPath:filepath error:nil];
    if (attrs != nil) {
      NSDate *date = (NSDate *)[attrs objectForKey:NSFileCreationDate];
      NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"HH:mm:ss dd-MM-yyyy"];
      NSString *dateString = [dateFormatter stringFromDate:date];
      [dateCreat addObject:dateString];
    }
  }
  listCreate = [NSArray arrayWithArray:dateCreat];

  if (label) {
    [label removeFromSuperview];
  }

  _tableView = [[UITableView alloc]
      initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 0)
              style:UITableViewStylePlain];
  _tableView.backgroundView = nil;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [_tableView setFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                  60 * [listFile count])];
  _tableView.backgroundColor = [UIColor whiteColor];

  [UIView transitionWithView:self.view
                    duration:0.2
                     options:UIViewAnimationOptionTransitionCrossDissolve
                  animations:^{
                    [self.view addSubview:_tableView];
                  }
                  completion:nil];

  label = [[UILabel alloc]
      initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame
                                      .size.height,
                               self.view.frame.size.width, 30)];

  label.backgroundColor = [UIColor violetUnderBarColor];
  label.textColor = [UIColor whiteColor];
  label.textAlignment = NSTextAlignmentCenter;
  [label setFont:[UIFont systemFontOfSize:14]];
  [self.navigationController.navigationBar addSubview:label];
  [label setAlpha:0.0];

  if ([listFile count] == 0) {
    [UIView animateWithDuration:1.5
        delay:0
        options:UIViewAnimationOptionCurveLinear |
                UIViewAnimationOptionAllowUserInteraction
        animations:^(void) {
          [label setText:NSLocalizedString(@"NoFile", nil)];
          [label setAlpha:1.0];
        }
        completion:^(BOOL finished){
        }];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return [listFile count];
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 50.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  MGSwipeTableCell *myCellView = nil;
  UILabel *mainLabel, *notice;
  UIImageView *icon;
  static NSString *TableViewCellIdentifier = @"Cell";
  myCellView = (MGSwipeTableCell *)[tableView
      dequeueReusableCellWithIdentifier:TableViewCellIdentifier];

  if (myCellView == nil) {
    myCellView =
        [[MGSwipeTableCell alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:TableViewCellIdentifier];
    myCellView.textLabel.font = [UIFont systemFontOfSize:16];
    myCellView.accessoryType = UITableViewCellAccessoryNone;
    myCellView.delegate = self;
    myCellView.rightSwipeSettings.transition = MGSwipeTransitionDrag;
    myCellView.rightExpansion.buttonIndex = 0;
    myCellView.rightExpansion.fillOnTrigger = YES;

    // Icon view
    CGRect myFrame = CGRectMake(15, 12.5, 25, 25);
    icon = [[UIImageView alloc] initWithFrame:myFrame];
    NSString *icon_name =
        [FPMimetype iconPathForFilename:[listFile objectAtIndex:indexPath.row]];

    [icon setImage:[UIImage imageNamed:icon_name]];
    [myCellView.contentView addSubview:icon];

    // Header view
    myFrame = CGRectMake(50, 5, self.view.frame.size.width - 30, 20);
    mainLabel = [[UILabel alloc] initWithFrame:myFrame];
    mainLabel.numberOfLines = 0;
    if (IDIOM == IPHONE) {
      mainLabel.font = [UIFont systemFontOfSize:13];
    } else {
      mainLabel.font = [UIFont systemFontOfSize:15];
    }
    mainLabel.backgroundColor = [UIColor clearColor];
    [myCellView.contentView addSubview:mainLabel];

    // Subtitle view
    myFrame = CGRectMake(50, 25, self.view.frame.size.width - 30, 20);
    notice = [[UILabel alloc] initWithFrame:myFrame];
    notice.numberOfLines = 0;
    if (IDIOM == IPHONE) {
      notice.font = [UIFont systemFontOfSize:11];
    } else {
      notice.font = [UIFont systemFontOfSize:11];
    }
    notice.alpha = 0.5;
    notice.backgroundColor = [UIColor clearColor];
    [myCellView.contentView addSubview:notice];

    mainLabel.text = [listFile objectAtIndex:indexPath.row];
    NSString *datetime = NSLocalizedString(@"CreateDate", nil);
    notice.text =
        [NSString stringWithFormat:@"%@ %@", datetime,
                                   [listCreate objectAtIndex:indexPath.row]];
  }
  return myCellView;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  // Pass data back
  NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  dataURL = [documentsPath
      stringByAppendingPathComponent:[listFile objectAtIndex:indexPath.row]];
  QLPreviewController *previewController = [[QLPreviewController alloc] init];
  previewController.delegate = self;
  previewController.dataSource = self;
  [previewController.navigationItem setRightBarButtonItem:nil];
  [[self navigationController] pushViewController:previewController
                                         animated:YES];
}

- (void)willAnimateRotationToInterfaceOrientation:
            (UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
  [self initView];
}

- (void)swipeTableCell:(MGSwipeTableCell *)cell
   didChangeSwipeState:(MGSwipeState)state
       gestureIsActive:(BOOL)gestureIsActive {
  NSString *str;
  switch (state) {
  case MGSwipeStateNone:
    str = @"None";
    break;
  case MGSwipeStateSwippingLeftToRight:
    str = @"SwippingLeftToRight";
    break;
  case MGSwipeStateSwippingRightToLeft:
    str = @"SwippingRightToLeft";
    break;
  case MGSwipeStateExpandingLeftToRight:
    str = @"ExpandingLeftToRight";
    break;
  case MGSwipeStateExpandingRightToLeft:
    str = @"ExpandingRightToLeft";
    break;
  }
}

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell
              canSwipe:(MGSwipeDirection)direction {
  return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell
   swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings
          expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
  swipeSettings.transition = MGSwipeTransitionBorder;
  expansionSettings.buttonIndex = 0;
  if (direction == MGSwipeDirectionRightToLeft) {
    expansionSettings.fillOnTrigger = YES;
    expansionSettings.threshold = 1.2;
    CGFloat padding = 12;

    // Open Composer View
    MGSwipeButton *mail = [MGSwipeButton
        buttonWithTitle:NSLocalizedString(@"Mail", nil)
        backgroundColor:[UIColor peterRiverColor]
                padding:padding
               callback:^BOOL(MGSwipeTableCell *sender) {
                 indexPath_ = [_tableView indexPathForCell:sender];
                 NSString *fileName = [listFile objectAtIndex:indexPath_.row];
                 NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(
                     NSDocumentDirectory, NSUserDomainMask, YES)
                     objectAtIndex:0];
                 NSString *filePath =
                     [documentsPath stringByAppendingPathComponent:fileName];
                 MCOAttachment *attachment =
                     [MCOAttachment attachmentWithContentsOfFile:filePath];
                 NSMutableArray *delayedAttachments =
                     [[NSMutableArray alloc] init];
                 [delayedAttachments addObject:attachment];

                 if (IDIOM == IPAD) {
                   ComposerViewController *vc = [[ComposerViewController alloc]
                               initWithTo:@[]
                                       CC:@[]
                                      BCC:@[]
                                  subject:@""
                                  message:[[NSUserDefaults standardUserDefaults]
                                              objectForKey:@"signature"]
                              attachments:@[]
                       delayedAttachments:delayedAttachments];
                   UINavigationController *nc = [[UINavigationController alloc]
                       initWithRootViewController:vc];
                   nc.modalPresentationStyle = UIModalPresentationPageSheet;
                   [self presentViewController:nc animated:YES completion:nil];
                 } else {
                   Composer_iPhoneViewController *vc = [
                       [Composer_iPhoneViewController alloc]
                               initWithTo:@[]
                                       CC:@[]
                                      BCC:@[]
                                  subject:@""
                                  message:[[NSUserDefaults standardUserDefaults]
                                              objectForKey:@"signature"]
                              attachments:@[]
                       delayedAttachments:delayedAttachments];
                   FixedNavigationController *nc =
                       [[FixedNavigationController alloc]
                           initWithRootViewController:vc];
                   [self presentViewController:nc animated:YES completion:nil];
                 }

                 return YES;
               }];

    // Delete mail
    MGSwipeButton *trash = [MGSwipeButton
        buttonWithTitle:NSLocalizedString(@"DeleteSwipe", nil)
        backgroundColor:[UIColor colorWithRed:1.0
                                        green:59 / 255.0
                                         blue:50 / 255.0
                                        alpha:1.0]
                padding:padding
               callback:^BOOL(MGSwipeTableCell *sender) {
                 indexPath_ = [_tableView indexPathForCell:sender];
                 FUIAlertView *alertView = [[FUIAlertView alloc]
                         initWithTitle:NSLocalizedString(@"Message", nil)
                               message:NSLocalizedString(@"DeleteFile", nil)
                              delegate:self
                     cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                     otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                 if (IDIOM == IPAD) {
                   alertView.titleLabel.font =
                       [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
                   alertView.messageLabel.textColor = [UIColor asbestosColor];
                   alertView.messageLabel.font =
                       [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
                   alertView.defaultButtonFont =
                       [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
                 } else {
                   alertView.titleLabel.font =
                       [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
                   alertView.messageLabel.textColor = [UIColor asbestosColor];
                   alertView.messageLabel.font =
                       [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
                   alertView.defaultButtonFont =
                       [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
                 }
                 alertView.backgroundOverlay.backgroundColor =
                     [[UIColor blackColor] colorWithAlphaComponent:0.8];
                 alertView.alertContainer.backgroundColor =
                     [UIColor cloudsColor];
                 alertView.defaultButtonColor = [UIColor cloudsColor];
                 alertView.defaultButtonShadowColor = [UIColor cloudsColor];
                 alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];

                 [alertView setTag:0];
                 [alertView show];
                 return YES;
               }];

    return @[ trash, mail ];
  }
  return nil;
}

- (void)alertView:(UIAlertView *)sucess
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (sucess.tag == 0) {
    if (buttonIndex == 1) {
      NSString *text = @"";
      NSString *fileName = [listFile objectAtIndex:indexPath_.row];
      NSFileManager *fileManager = [NSFileManager defaultManager];
      NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(
          NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
      NSString *filePath =
          [documentsPath stringByAppendingPathComponent:fileName];
      NSError *error;
      BOOL success = [fileManager removeItemAtPath:filePath error:&error];
      if (success) {
        [listFile removeObjectAtIndex:indexPath_.row];
        [_tableView deleteRowsAtIndexPaths:@[ indexPath_ ]
                          withRowAnimation:UITableViewRowAnimationLeft];
        [self initView];
        text = NSLocalizedString(@"DeleteFileSuccess", nil);
      } else {
        text = NSLocalizedString(@"DeleteFileFailed", nil);
        NSLog(@"Could not delete file -:%@ ", [error localizedDescription]);
      }
      UIWindow *window = [[UIApplication sharedApplication] delegate].window;
      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
      hud.labelText = text;
      hud.labelFont = [UIFont boldSystemFontOfSize:13];
      hud.mode = MBProgressHUDModeCustomView;
      hud.margin = 12.0f;
      hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
      hud.removeFromSuperViewOnHide = YES;
      [hud hide:YES afterDelay:1.5];
    }
  }
}

- (NSInteger)numberOfPreviewItemsInPreviewController:
    (QLPreviewController *)controller {
  return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller
                    previewItemAtIndex:(NSInteger)index {
  return [NSURL fileURLWithPath:dataURL];
}

@end
