//
//  MoveToMailboxes.m
//  iMail
//
//  Created by Tran Ha on 12/30/14.
//  Copyright (c) 2014 com.vdcca. All rights reserved.
//

#import "MoveToMailboxes.h"
#import "AuthManager.h"
#import "FlatUIKit.h"
#import "ListAllFolders.h"
#import "Constants.h"

#import <CoreImage/CoreImage.h>

@interface MoveToMailboxes ()

@end

@implementation MoveToMailboxes
@synthesize message, content, fromFolder;

- (void)viewDidLoad {
  [super viewDidLoad];

  // Navigation bar
  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];
  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor
                                              colorFromHexCode:barColor]];

  // Back button
  UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
  [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [back setImage:[UIImage imageNamed:@"bt_back.png"]
        forState:UIControlStateNormal];
  [back addTarget:self
                action:@selector(dismissMoveMailBoxes:)
      forControlEvents:UIControlEventTouchUpInside];
  UIBarButtonItem *backButton =
      [[UIBarButtonItem alloc] initWithCustomView:back];
  self.navigationItem.leftBarButtonItem = backButton;

  // Folder list
  folderlist = [[NSMutableArray alloc]
      initWithObjects:NSLocalizedString(@"Inbox", nil),
                      NSLocalizedString(@"Sent", nil),
                      NSLocalizedString(@"Spam", nil),
                      NSLocalizedString(@"Trash", nil), nil];
  [self initView];
}

- (void)initView {
  if (_tableView) {
    [_tableView removeFromSuperview];
  }
  _tableView = [[UITableView alloc]
      initWithFrame:CGRectMake(0, 0, self.view.frame.size.height,
                               self.view.bounds.size.width)
              style:UITableViewStyleGrouped];
  _tableView.backgroundView = nil;
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [_tableView setFrame:CGRectMake(0, 0, self.view.frame.size.width,
                                  self.view.frame.size.height)];
  [self.view addSubview:_tableView];
}

- (void)dismissMoveMailBoxes:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
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
  return [folderlist count];
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {
  return 35.0f;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 50.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  UITableViewCell *myCellView = nil;
  UILabel *mainLabel;
  UIImageView *icon, *icon_;
  NSArray *c = [NSArray arrayWithObjects:@"Inbox.png", @"Sent.png", @"Spam.png",
                                         @"Trash.png", nil];

  NSLog(@"%@", fromFolder);

  if ([tableView isEqual:_tableView]) {

    static NSString *TableViewCellIdentifier = @"Cell";
    myCellView =
        [tableView dequeueReusableCellWithIdentifier:TableViewCellIdentifier];
    if (myCellView == nil) {
      myCellView =
          [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:TableViewCellIdentifier];

      // Icon view
      CGRect myFrame = CGRectMake(20, 50 / 2 - 15, 30, 30);
      icon = [[UIImageView alloc] initWithFrame:myFrame];
      NSString *icon_name;
      icon_name = [c objectAtIndex:indexPath.row];
      UIImage *image;

      // Next view
      myFrame = CGRectMake(self.view.frame.size.width - 20, 50 / 2 - 6, 12, 12);
      icon_ = [[UIImageView alloc] initWithFrame:myFrame];
      [icon_ setImage:[UIImage imageNamed:@"icon_next.png"]];

      // Header view
      myFrame =
          CGRectMake(60, 50 / 2 - 10, self.view.frame.size.width - 30, 20);
      mainLabel = [[UILabel alloc] initWithFrame:myFrame];
      mainLabel.numberOfLines = 1;
      mainLabel.font = [UIFont systemFontOfSize:15];
      mainLabel.backgroundColor = [UIColor clearColor];

      // Disable click for existing from folder
      if ([[folderlist objectAtIndex:indexPath.row]
              isEqualToString:fromFolder]) {
        myCellView.userInteractionEnabled = NO;
        mainLabel.textColor = [UIColor grayColor];
        image = [MoveToMailboxes changeColorImage:[UIImage imageNamed:icon_name]
                                        withColor:[UIColor blackColor]];
        [icon setImage:image];
        icon.alpha = 0.5f;
        icon_.alpha = 0.5f;
      } else {
        mainLabel.textColor = [UIColor colorFromHexCode:@"#1846a0"];
        image = [MoveToMailboxes
            changeColorImage:[UIImage imageNamed:icon_name]
                   withColor:[UIColor colorFromHexCode:@"#1846a0"]];
        [icon setImage:image];
        icon.alpha = 1.0f;
        icon_.alpha = 1.0f;
      }

      [myCellView.contentView addSubview:icon];
      [myCellView.contentView addSubview:mainLabel];
      [myCellView.contentView addSubview:icon_];
    }
    mainLabel.text = [folderlist objectAtIndex:indexPath.row];
  }
  return myCellView;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  //[tableView deselectRowAtIndexPath:indexPath animated:YES];
  NSDictionary *listFolderName = [ListAllFolders shareFolderNames];
  // Pass data back
  NSString *fileName = [folderlist objectAtIndex:indexPath.row];
  NSString *folderName;

  if ([fileName isEqualToString:NSLocalizedString(@"Inbox", nil)]) {
    folderName = [listFolderName objectForKey:@"Inbox"];
  } else if ([fileName isEqualToString:NSLocalizedString(@"Sent", nil)]) {
    folderName = [listFolderName objectForKey:@"Sent"];
  } else if ([fileName isEqualToString:NSLocalizedString(@"Spam", nil)]) {
    folderName = [listFolderName objectForKey:@"Spam"];
  } else if ([fileName isEqualToString:NSLocalizedString(@"Trash", nil)]) {
    folderName = [listFolderName objectForKey:@"Trash"];
  }
    if (self.indexPaths != nil && self.indexPaths.count > 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(moveMultipleMail:didFinishEnteringItem:message:)]) {
            [self.delegate moveMultipleMail:self didFinishEnteringItem:folderName message:self.indexPaths];
        }
    } else {
        if (message) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(passDestFolderName:didFinishEnteringItem:message:)]) {
                [self.delegate passDestFolderName:self
                            didFinishEnteringItem:folderName
                                          message:message];
            }
        }
    }
  [self dismissViewControllerAnimated:YES completion:nil];
}

+ (UIImage *)changeColorImage:(UIImage *)image withColor:(UIColor *)color {
  UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [color setFill];
  CGContextTranslateCTM(context, 0, image.size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextClipToMask(context,
                      CGRectMake(0, 0, image.size.width, image.size.height),
                      [image CGImage]);
  CGContextFillRect(context,
                    CGRectMake(0, 0, image.size.width, image.size.height));

  UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();
  return coloredImg;
}

- (void)willAnimateRotationToInterfaceOrientation:
            (UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
  [self initView];
}

@end
