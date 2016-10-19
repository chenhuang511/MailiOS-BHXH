//
//  MsgListViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import <QuartzCore/QuartzCore.h>

#import "CheckNetWork.h"
#import "Reachability.h"

#import "UINavigationBar+FlatUI.h"
#import "FixedNavigationController.h"
#import "FFCircularProgressView.h"
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "FPPopoverController.h"
#import "MNMBottomPullToRefreshManager.h"

#import "MessageListDelegate.h"
#import "MenuViewController.h"
#import "MoveToMailboxes.h"
#import "MessageDetailViewController.h"
#import "MessageDetailViewController_iPhone.h"

#import "CheckValidSession.h"

#import "ARCMacros.h"

typedef void (^MailActionCallback)(BOOL cancelled, BOOL deleted,
                                   NSInteger actionIndex);

@interface MsgListViewController
    : UITableViewController <
          MessageListDelegate, MenuViewDelegate, FPPopoverControllerDelegate,
          MoveToMailboxesDelegate, UITextFieldDelegate,
          MGSwipeTableCellDelegate, UIActionSheetDelegate,
          MCOHTMLRendererIMAPDelegate, UISearchBarDelegate,
          UISearchControllerDelegate, MNMBottomPullToRefreshManagerClient> {

  FPPopoverController *popover;
  UILabel *label;
  uint64_t msgUID_t;
  NSString *selectedAccName;
  NSString *username;
  MailActionCallback actionCallback;
  BOOL isSearching;
  NSMutableArray *filterResult;
  NSMutableArray *sourceSearchArray;

  MNMBottomPullToRefreshManager *pullToRefreshManager_;

  // set bar
  UILabel *currentMailbox;
  UILabel *currentUserEmail;
}

@property(strong, nonatomic) MessageDetailViewController *detailViewController;
@property(strong, nonatomic)
    MessageDetailViewController_iPhone *detailViewController_iPhone;

@property(strong, nonatomic)
    IBOutlet UISearchDisplayController *searchBarDisplay;
@property(weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property(strong) NSString *folder;
@property(strong) NSString *folderParent;

@property(weak, nonatomic) IBOutlet UIBarButtonItem *leftMenu;

- (IBAction)showLeftView:(id)sender;
- (IBAction)composeEmail:(id)sender;
- (void)listCertHard;
- (void)loadFolderIntoCache:(NSString *)imapPath;

+ (BOOL)shareFlagSeen;
+ (MCOIMAPMessage *)shareOrgMsg;
+ (void)setUnlockMail:(BOOL)status;

@end
