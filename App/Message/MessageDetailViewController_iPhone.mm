//
//  MessageDetailViewController.m
//  ThatInbox
//
//  Created by Liyan David Chang on 7/9/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "MessageDetailViewController_iPhone.h"
#import "MsgListViewController.h"

#import "UINavigationBar+FlatUI.h"
#import "Composer_iPhoneViewController.h"
#import "UIColor+FlatUI.h"

#import "DelayedAttachment.h"
#import "FPPopoverController.h"
#import "MenuViewController.h"
#import "Constants.h"

#define deleteMail 0

@interface MessageDetailViewController_iPhone ()
@property(strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation MessageDetailViewController_iPhone
#define archiveButton_TAG 0
#define replyButton_TAG 1
#define replyAllButton_TAG 2
#define forwardButton_TAG 3

- (void)viewDidLoad {
  [super viewDidLoad];

  // UNLOCK
  [MsgListViewController setUnlockMail:YES];

  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone;

  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor
                                              colorFromHexCode:barColor]];
  self.navigationController.navigationBar.translucent = NO;

  UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
  [close setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [close addTarget:self
                action:@selector(closeWindow_:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *closeImage = [UIImage imageNamed:@"bt_back.png"];
  [close setImage:closeImage forState:UIControlStateNormal];
  UIBarButtonItem *closeButton =
      [[UIBarButtonItem alloc] initWithCustomView:close];

  UIButton *reply = [UIButton buttonWithType:UIButtonTypeCustom];
  [reply setFrame:CGRectMake(0.0f, 0.0f, 40.0f, 22.0f)];
  [reply addTarget:self
                action:@selector(replyWindow_iPhone:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *replyImage = [UIImage imageNamed:@"bt_reply.png"];
  [reply setImage:replyImage forState:UIControlStateNormal];
  UIBarButtonItem *replyButton =
      [[UIBarButtonItem alloc] initWithCustomView:reply];
  reply.tag = replyButton_TAG;

  UIButton *replyAll = [UIButton buttonWithType:UIButtonTypeCustom];
  [replyAll setFrame:CGRectMake(0.0f, 0.0f, 40.0, 22.0f)];
  [replyAll addTarget:self
                action:@selector(replyWindow_iPhone:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *replyAllImage = [UIImage imageNamed:@"bt_reply_all.png"];
  [replyAll setImage:replyAllImage forState:UIControlStateNormal];
  UIBarButtonItem *replyAllButton =
      [[UIBarButtonItem alloc] initWithCustomView:replyAll];
  replyAll.tag = replyAllButton_TAG;

  UIButton *forward = [UIButton buttonWithType:UIButtonTypeCustom];
  [forward setFrame:CGRectMake(0.0f, 0.0f, 40.0f, 22.0f)];
  [forward addTarget:self
                action:@selector(replyWindow_iPhone:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *forwardImage = [UIImage imageNamed:@"bt_forward.png"];
  [forward setImage:forwardImage forState:UIControlStateNormal];
  UIBarButtonItem *forwardButton =
      [[UIBarButtonItem alloc] initWithCustomView:forward];
  forward.tag = forwardButton_TAG;

  self.navigationItem.leftBarButtonItems = @[ closeButton ];

  MCOMessageHeader *header = [self.message header];
  if ([header to].count == 1) {
    self.navigationItem.rightBarButtonItems = @[ forwardButton, replyButton ];
  } else {
    self.navigationItem.rightBarButtonItems =
        @[ forwardButton, replyAllButton, replyButton ];
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)closeWindow_:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)replyWindow_iPhone:(id)sender {
  NSString *type = nil;

  UIButton *clicked = (UIButton *)sender;
  if (clicked.tag == replyButton_TAG) {
    type = @"Trả lời";
  }
  if (clicked.tag == replyAllButton_TAG) {
    type = @"Trả lời tất cả";
  }
  if (clicked.tag == forwardButton_TAG) {
    type = @"Chuyển tiếp";
  }

  NSMutableArray *delayedAttachments = [[NSMutableArray alloc] init];

  if ([type isEqualToString:@"Chuyển tiếp"]) {
      
    // Hưng thêm
    // Comment đoạn trên : Các file attachtment đã được lưu lại nên không cần
    // load lại dữ liệu
    NSMutableArray *discardedItems = [NSMutableArray array];
    delayedAttachments = [self.delayedAttachment mutableCopy];
    // HoangTD - Không chuyển tiếp file chữ ký hoặc file mã hoá
    for (int i = 0; i < delayedAttachments.count; i++) {
      MCOAttachment *attachment = [delayedAttachments objectAtIndex:i];
        if ([[attachment filename] isEqualToString:@"smime.p7s"] || [[attachment filename] isEqualToString:@"smime.p7m"]) {
            [discardedItems addObject:attachment];
        }
    }
    [delayedAttachments removeObjectsInArray:discardedItems];

  }

  Composer_iPhoneViewController *vc = [[Composer_iPhoneViewController alloc]
         initWithMessage:[self message]
                  ofType:type
                 content:[self msgContent]
             attachments:@[]
      delayedAttachments:delayedAttachments];
 self.delayedAttachment = nil;
  UINavigationController *nc =
      [[UINavigationController alloc] initWithRootViewController:vc];
  nc.modalPresentationStyle = UIModalPresentationPageSheet;
  [self presentViewController:nc animated:YES completion:nil];
}

- (IBAction)archiveMessage:(id)sender {
  if ([[MenuViewController sharedFolderName] isEqualToString:@"Trash"]) {
    UIAlertView *alertPin =
        [[UIAlertView alloc] initWithTitle:@"Thông báo"
                                   message:@"Bạn muốn xoá hoàn toàn Email này?"
                                  delegate:self
                         cancelButtonTitle:@"Thoát"
                         otherButtonTitles:@"Đồng ý", nil];
    alertPin.tag = deleteMail;
    [alertPin show];
  } else {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSelector:@selector(removeMail) withObject:nil afterDelay:0.1];
  }
}

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView.tag == deleteMail) {
    if (buttonIndex == 1) {
      [self dismissViewControllerAnimated:YES completion:nil];
      [self performSelector:@selector(removeMail)
                 withObject:nil
                 afterDelay:0.1];
    }
  }
}

- (void)removeMail {
  [[self delegate] archiveMessage:[[self message] uid]];
}

#pragma mark - Split view

- (void)splitViewController:(UINavigationController *)splitController
     willHideViewController:(UIViewController *)viewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)popoverController {
  // NOTE: This isn't used given that we no longer hide. See comment in
  // splitViewController:shouldHideViewController:...
  /*
   barButtonItem.title = @"Messages";

   [barButtonItem setTitleTextAttributes:[NSDictionary
   dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue"
   size:16.0], UITextAttributeFont, [UIColor peterRiverColor],
   UITextAttributeTextColor, [UIColor clearColor],
   UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
   [barButtonItem setTitleTextAttributes:[NSDictionary
   dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue"
   size:16.0], UITextAttributeFont, [UIColor belizeHoleColor],
   UITextAttributeTextColor, nil] forState:UIControlStateHighlighted];

   [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
   self.masterPopoverController = popoverController;
   */
}

- (void)splitViewController:(UINavigationController *)splitController
       willShowViewController:(UIViewController *)viewController
    invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
  // Called when the view is shown again in the split view, invalidating the
  // button and popover controller.
  [self.navigationItem setLeftBarButtonItem:nil animated:YES];
  self.masterPopoverController = nil;
}

- (BOOL)splitViewController:(UINavigationController *)svc
    shouldHideViewController:(UIViewController *)vc
               inOrientation:(UIInterfaceOrientation)orientation {
  // NOTE: You'll want this. Otherwise, if you hide the controller, then you get
  // into two problems:
  // 1. The slide gestures collide.
  // 2. The popoverController will be fixed to the left side, just like your
  // menu, and in fact will hide the menu.
  // Therefore, we are going with the reasonable approach of just not hiding
  // ever, and just making the email side smaller.
  return NO;
}

@end
