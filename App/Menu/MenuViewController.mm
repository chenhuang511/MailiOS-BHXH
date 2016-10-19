//
//  MenuViewController.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "MenuViewController.h"
#import "AuthManager.h"
#import "MenuViewCell.h"

#import "AppDelegate.h"
#import "MsgListViewController.h"
#import "CheckNetWork.h"
#import "MBProgressHUD.h"

#import "DBManager.h"
#import "TokenType.h"
#import "AuthNavigationViewController.h"

#import "HardTokenMethod.h"
#import "SDSelectableCell.h"
#import "SDGroupCell.h"
#import "SDSubCell.h"
#import "SetupTableController.h"
#import "PrivatePolicy.h"

#import "ListAllFolders.h"
#import "FileManager.h"
#import "Constants.h"

#define Logout 1
//HoangTD edit
//#define TokenSetting 0
//#define passwordHT 2

bool firstLoad = true;
NSString *folderName;
NSMutableArray *listAccount;
NSInteger accIndex;
int ranger;
int current;

@interface MenuViewController ()

@property(nonatomic, strong) MCOIMAPSession *imapSession;
@property(nonatomic, strong) NSArray *contents;
@property(nonatomic) bool firstLoad;
@end

@implementation MenuViewController
@synthesize mainItemsAmt, subItemsAmt, groupCell;

//@synthesize delegate;

@synthesize folderNameLookup;

+ (NSString *)sharedFolderName {
  return folderName;
}

- (id)init {
  if (self = [self initWithNibName:@"MenuViewController" bundle:nil]) {
  }
  return self;
}

#pragma mark - To be implemented in sublclasses

- (NSInteger)mainTable:(UITableView *)mainTable
    numberOfItemsInSection:(NSInteger)section {
  return 1;
}

- (NSInteger)mainTable:(UITableView *)mainTable
    numberOfSubItemsforItem:(SDGroupCell *)item
                atIndexPath:(NSIndexPath *)indexPath {
  NSInteger count = (int)listAccount.count / 4;
  return count + 1;
}

- (SDGroupCell *)mainTable:(UITableView *)mainTable
                   setItem:(SDGroupCell *)item
         forRowAtIndexPath:(NSIndexPath *)indexPath {
  [item.contentView setBackgroundColor:[UIColor colorFromHexCode:cellBgColor]];
  [item.contentView
      setFrame:CGRectMake(0, 0, item.contentView.frame.size.width, 60)];
  NSString *mailtype = [listAccount objectAtIndex:accIndex + 3];
  NSString *name = [listAccount objectAtIndex:accIndex];
  NSString *emails = [listAccount objectAtIndex:accIndex + 1];
  if (!name.length || [mailtype isEqualToString:@"2"]) {
    NSRange endRange = [emails rangeOfString:@"@"
                                     options:NSBackwardsSearch
                                       range:NSMakeRange(0, emails.length - 1)];
    if (endRange.length > 0) {
      name = [emails substringToIndex:endRange.location];
    } else {
      name = emails;
    }
  }

  if (emails.length > 0) {
    UIView *accountView = [[UIView alloc] init];
    [accountView setFrame:CGRectMake(0, 0, 180, 60)];

    UIImage *image = [UIImage imageNamed:@"mail_acc.png"];

//    switch ([mailtype integerValue]) {
//    case 2:
//      image = [UIImage imageNamed:@"mail_acc_gmail.png"];
//      break;
//    case 3:
//      image = [UIImage imageNamed:@"mail_acc_yahoo.png"];
//      break;
//    case 4:
//      image = [UIImage imageNamed:@"mail_acc_outlook.png"];
//      break;
//    default:
//      image = [UIImage imageNamed:@"mail_acc_dif.png"];
//      break;
//    }

    UIImageView *mailImageType = [[UIImageView alloc] initWithImage:image];
    [mailImageType setFrame:CGRectMake(15, 5, 30, 40)];
    [accountView addSubview:mailImageType];
    UILabel *displayName = [[UILabel alloc] init];
    displayName.textColor = [UIColor whiteColor];
    displayName.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
    displayName.text = name;
    [displayName setFrame:CGRectMake(60, 4, accountView.frame.size.width, 20)];
    UILabel *email = [[UILabel alloc] init];
    email.textColor = [UIColor grayColor];
    email.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:10];
    email.text = [NSString stringWithFormat:@"%@", emails];
    [email setFrame:CGRectMake(60, 26, accountView.frame.size.width, 20)];

    displayName.backgroundColor = email.backgroundColor =
        [UIColor colorFromHexCode:cellBgColor];

    [accountView addSubview:displayName];
    [accountView addSubview:email];
    [item.contentView addSubview:accountView];
  }
  item.itemText.text = @"";

  return item;
}

- (UIImage *)getImageWithTintedColor:(UIImage *)image
                            withTint:(UIColor *)color
                       withIntensity:(float)alpha {
  CGSize size = image.size;

  UIGraphicsBeginImageContextWithOptions(size, FALSE, 2);
  CGContextRef context = UIGraphicsGetCurrentContext();

  [image drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:1.0];

  CGContextSetFillColorWithColor(context, color.CGColor);
  CGContextSetBlendMode(context, kCGBlendModeOverlay);
  CGContextSetAlpha(context, alpha);

  CGContextFillRect(UIGraphicsGetCurrentContext(),
                    CGRectMake(CGPointZero.x, CGPointZero.y, image.size.width,
                               image.size.height));

  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return tintedImage;
}

- (void)accountAdd:(id)sender {
  [self accountAdd];
}

- (SDSubCell *)item:(SDGroupCell *)item
           setSubItem:(SDSubCell *)subItem
    forRowAtIndexPath:(NSIndexPath *)indexPath {

  [subItem.contentView setBackgroundColor:[UIColor colorFromHexCode:cellBgColor]];
  NSInteger row = indexPath.row;

  if (row < listAccount.count / 4) {
    NSInteger currIndex = row * 4;
    NSString *name = [listAccount objectAtIndex:currIndex];
    NSString *mailtype = [listAccount objectAtIndex:currIndex + 3];
    NSString *emails = [listAccount objectAtIndex:currIndex + 1];
    if (!name.length || [mailtype isEqualToString:@"2"]) {
      NSRange endRange =
          [emails rangeOfString:@"@"
                        options:NSBackwardsSearch
                          range:NSMakeRange(0, emails.length - 1)];
      if (endRange.length > 0) {
        name = [emails substringToIndex:endRange.location];
      } else {
        name = emails;
      }
    }

    if (emails.length > 0) {
      UIView *accountView = [[UIView alloc] init];
      [accountView setFrame:CGRectMake(0, 0, 180, 50)];

      UILabel *displayName = [[UILabel alloc] init];
      displayName.textColor = [UIColor whiteColor];
      displayName.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
      displayName.text = name;
      [displayName
          setFrame:CGRectMake(20, 5, accountView.frame.size.width, 20)];

      UILabel *email = [[UILabel alloc] init];
      email.textColor = [UIColor grayColor];
      email.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:10];
      email.text = [NSString stringWithFormat:@"%@", emails];
      [email setFrame:CGRectMake(20, 26, accountView.frame.size.width, 20)];

      displayName.backgroundColor = email.backgroundColor =
          [UIColor colorFromHexCode:cellBgColor];

      UIButton *config = [[UIButton alloc] init];
      config = [UIButton buttonWithType:UIButtonTypeCustom];
      [config setFrame:CGRectMake(235, 10, 30, 30)];
      [config addTarget:self
                    action:@selector(accountConfig:)
          forControlEvents:UIControlEventTouchUpInside];
      [config setImage:[UIImage imageNamed:@"icon_setting.png"]
              forState:UIControlStateNormal];

      UIButton *signout = [[UIButton alloc] init];
      signout = [UIButton buttonWithType:UIButtonTypeCustom];
      [signout setFrame:CGRectMake(200, 10, 30, 30)];
      [signout addTarget:self
                    action:@selector(accountAdd:)
          forControlEvents:UIControlEventTouchUpInside];
      [signout setImage:[UIImage imageNamed:@"icon_sign_out.png"]
               forState:UIControlStateNormal];

      if (currIndex == accIndex) {
        displayName.backgroundColor = email.backgroundColor =
            [UIColor colorFromHexCode:@"black"];

        [subItem.contentView
            setBackgroundColor:[UIColor colorFromHexCode:@"black"]];
      }
      [accountView addSubview:displayName];
      [accountView addSubview:email];
      [subItem.contentView addSubview:accountView];
    }
  } else {
    // addmail
    UIView *accountView = [[UIView alloc] init];
    [accountView setFrame:CGRectMake(0, 0, 280, 50)];
    UIButton *addAccount = [[UIButton alloc] init];
    addAccount = [UIButton buttonWithType:UIButtonTypeCustom];
    [addAccount setFrame:CGRectMake(0, 0, 33, 20)];
    addAccount.center = CGPointMake(accountView.frame.size.width / 2,
                                    accountView.frame.size.height / 2);
    [addAccount addTarget:self
                   action:@selector(accountAdd:)
         forControlEvents:UIControlEventTouchUpInside];
    [addAccount setImage:[UIImage imageNamed:@"email_plus_account.png"]
                forState:UIControlStateNormal];
    addAccount.alpha = 0.5;
    [accountView addSubview:addAccount];
    [subItem.contentView addSubview:accountView];
  }
  if (indexPath.row > 0) {
    UIView *separator = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0.5, subItem.contentView.frame.size.width,
                                 1)];
    UIView *separator2 = [[UIView alloc]
        initWithFrame:CGRectMake(0, 1.0, subItem.contentView.frame.size.width,
                                 1)];
    separator.backgroundColor = [UIColor blackColor];
    separator2.backgroundColor = [UIColor darkGrayColor];
    [subItem.contentView addSubview:separator];
    [subItem.contentView addSubview:separator2];
  }
  return subItem;
}

- (void)expandingItem:(SDGroupCell *)item
        withIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"expandingItem");
}

- (void)collapsingItem:(SDGroupCell *)item
         withIndexPath:(NSIndexPath *)indexPath {
  NSLog(@"collapsingItem");
}

// Optional method to implement. Will be called when creating a new main cell to
// return the nib name you want to use

- (NSString *)nibNameForMainCell {
  return @"SDGroupCell";
}

#pragma mark - Delegate methods

- (void)mainTable:(UITableView *)mainTable itemDidChange:(SDGroupCell *)item {
  NSLog(@"maindid change");
}

- (void)item:(SDGroupCell *)item subItemDidChange:(SDSelectableCell *)subItem {
  NSLog(@"subItemDidChange change");
}

- (void)mainItemDidChange:(SDGroupCell *)item forTap:(BOOL)tapped {
  if (self.delegate != nil &&
      [self.delegate respondsToSelector:@selector(mainTable:itemDidChange:)]) {
    [self.delegate performSelector:@selector(mainTable:itemDidChange:)
                        withObject:self.tableView
                        withObject:item];
  }
}

- (void)mainItem:(SDGroupCell *)item
    subItemDidChange:(SDSelectableCell *)subItem
              forTap:(BOOL)tapped {
  if (self.delegate != nil &&
      [self.delegate respondsToSelector:@selector(item:subItemDidChange:)]) {
    [self.delegate performSelector:@selector(item:subItemDidChange:)
                        withObject:item
                        withObject:subItem];
  }
}

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))

  {
    // self.delegate = self;
  }

  return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self) {
    NSString *type =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"];
    if ([type isEqual:@"1"]) {
      folderNameLookup = @{
        @"Inbox" : @"INBOX",
        @"Sent" : @"Th&AbA- &AREA4w- g&Hu0-i",
        @"All Mail" : @"INBOX",
        @"Starred" : @"Notes",
        @"Trash" : @"Trash"
      };
    } else if ([type isEqual:@"2"]) {
      folderNameLookup = @{
        @"Inbox" : @"INBOX",
        @"Sent" : @"[Gmail]/Sent Mail",
        @"All Mail" : @"[Gmail]/All Mail",
        @"Starred" : @"[Gmail]/Starred",
        @"Trash" : @"[Gmail]/Bin"
      };
    }

    else if ([type isEqual:@"3"]) {
      folderNameLookup = @{
        @"Inbox" : @"INBOX",
        @"Sent" : @"Sent",
        @"All Mail" : @"INBOX",
        @"Starred" : @"INBOX",
        @"Trash" : @"Trash"
      };
    } else if ([type isEqual:@"4"]) {
      folderNameLookup = @{
        @"Inbox" : @"INBOX",
        @"Sent" : @"Sent",
        @"All Mail" : @"INBOX",
        @"Starred" : @"INBOX",
        @"Trash" : @"Trash"
      };
    }
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:YES];
  listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadMenu)
                                               name:@"reloadMenu"
                                             object:nil];
  self.clearsSelectionOnViewWillAppear = NO;
  self.tableView.separatorColor = [UIColor clearColor];
  [self setTableContents];
  [self.tableView setBackgroundView:nil];
  self.tableView.backgroundColor = [UIColor colorFromHexCode:cellBgColor];
  float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
  if (sysVer > 7.0) {
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, 0)];
  }
  subItemsAmt = [[NSMutableDictionary alloc] initWithDictionary:nil];
  expandedIndexes = [[NSMutableDictionary alloc] init];
  selectableCellsState = [[NSMutableDictionary alloc] init];
  selectableSubCellsState = [[NSMutableDictionary alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
  // refresh the view
  [self.tableView reloadData];
  if (firstLoad) {
    folderNameLookup = nil;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath
                                animated:YES
                          scrollPosition:UITableViewScrollPositionBottom];

    // Nếu không kịp lấy folder path: lấy path từ NSUserdefault
    NSString *accIndex =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"];
    NSMutableArray *listAccount =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    if (accIndex != nil) {
      NSString *username =
          [listAccount objectAtIndex:([accIndex intValue] + 1)];
      username = [NSString stringWithFormat:@"%@_MailPath", username];
      folderNameLookup =
          [[NSUserDefaults standardUserDefaults] dictionaryForKey:username];
    }
    if (folderNameLookup == NULL) {
      folderNameLookup = [ListAllFolders shareFolderNames];
    }
    NSLog(@"Menu new dictionary: %@", folderNameLookup);

    for (NSString *HRName in self.contents) {
      if ([HRName isEqualToString:@"Attachments"]) {
        [[self delegate] loadFolderIntoCache:HRName];
      } else {
        if (![HRName isEqualToString:@"Setting"] &&
            ![HRName isEqualToString:@"Logout"] &&
            ![HRName isEqualToString:@"Account"] &&
            ![HRName isEqualToString:@"Privacy policy"]) {
          //[[self delegate] loadFolderIntoCache:[self pathFromName:HRName]];
        }
      }
    }
    firstLoad = NO;
  }
}

+ (id)sharedManager {
  static dispatch_once_t pred = 0;
  __strong static id _sharedObject = nil;
  dispatch_once(&pred, ^{
    _sharedObject = [[self alloc] init];

  });
  return _sharedObject;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)setTableContents {

  // TODO: HACK: NOTE: So Gmail allows you to turn on if folders show up or not
  // in imap, so
  // some of these folders might not actually exist...
  self.contents = @[
    @"Account",
    @"Inbox",
    @"Attachments",
    @"Sent",
    @"All Mail",
    @"Spam",
    @"Trash",
    @"Logout",
    @"File Manager",
    @"Setting"
  ];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return [self.contents count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  if (indexPath.row == 0) {
    SDGroupCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"GroupCell"];
    [[NSBundle mainBundle] loadNibNamed:[self nibNameForMainCell]
                                  owner:self
                                options:nil];
    cell = groupCell;
    [cell setParentTable:self];
    [cell setCellIndexPath:indexPath];
    cell = [self mainTable:tableView setItem:cell forRowAtIndexPath:indexPath];
    NSNumber *amt =
        [NSNumber numberWithInt:(int)[self mainTable:tableView
                                    numberOfSubItemsforItem:cell
                                                atIndexPath:indexPath]];
    [subItemsAmt setObject:amt forKey:indexPath];
    //[self initWithStyle:self.tableView];
    [cell setSubCellsAmt:[[subItemsAmt objectForKey:indexPath] intValue]];
    BOOL isExpanded = [[expandedIndexes objectForKey:indexPath] boolValue];
    cell.isExpanded = isExpanded;
    if (cell.isExpanded) {
      [cell rotateExpandBtnToExpanded];
    } else {
      [cell rotateExpandBtnToCollapsed];
    }
    [cell.subTable reloadData];

    return cell;
  } else {

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell =
        [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
      cell = [[MenuViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                 reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.backgroundColor = [UIColor blackColor];
    UIView *separator = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0.5, cell.contentView.frame.size.width, 1)];
    UIView *separator2 = [[UIView alloc]
        initWithFrame:CGRectMake(0, 1.0, cell.contentView.frame.size.width, 1)];
    separator.backgroundColor = [UIColor blackColor];
    separator2.backgroundColor = [UIColor darkGrayColor];
    UIView *selectedColor = [[UIView alloc] init];
    selectedColor.backgroundColor = [UIColor colorFromHexCode:menuBackgroundColor];
    cell.selectedBackgroundView = selectedColor;

    if (indexPath.section == 0) {
      NSInteger idx = indexPath.row;
      if (idx > 1) {
        [cell.contentView addSubview:separator];
        [cell.contentView addSubview:separator2];
      }
      NSString *name = [self.contents objectAtIndex:idx];
      cell.imageView.image =
          [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", name]];
      switch (idx) {
        break;
      case 1:
        cell.textLabel.text = NSLocalizedString(@"Inbox", nil);
        break;
      case 2:
        cell.textLabel.text = NSLocalizedString(@"Attachments", nil);
        break;
      case 3:
        cell.textLabel.text = NSLocalizedString(@"Sent", nil);
        break;
      case 4:
        cell.textLabel.text = NSLocalizedString(@"AllMail", nil);
        break;
      case 5:
        cell.textLabel.text = NSLocalizedString(@"Spam", nil);
        break;
      case 6:
        cell.textLabel.text = NSLocalizedString(@"Trash", nil);
        break;
      case 7: {
        cell.textLabel.text = NSLocalizedString(@"Logout", nil);
        cell.imageView.image = [UIImage imageNamed:@"icon_sign_out.png"];
        cell.textLabel.highlightedTextColor = [UIColor peterRiverColor];
      } break;
      case 8: {
        cell.textLabel.text = NSLocalizedString(@"FileManager", nil);
        cell.imageView.image = [UIImage imageNamed:@"file_manager.png"];
        cell.textLabel.highlightedTextColor = [UIColor peterRiverColor];
      } break;
      case 9: {
        [cell.contentView addSubview:separator];
        [cell.contentView addSubview:separator2];
        cell.textLabel.text = NSLocalizedString(@"Config", nil);
        cell.imageView.image = [UIImage imageNamed:@"icon_setting.png"];
        cell.textLabel.highlightedTextColor = [UIColor peterRiverColor];
        break;
      }
      default:
        break;
        return cell;
      }
    }
    return cell;
  }
}

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView
    viewForHeaderInSection:(NSInteger)section {
  UIView *headerView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 30)];
  if (section == 0) {
    [headerView setBackgroundColor:[UIColor clearColor]];
    return headerView;
  } else {
    [headerView setBackgroundColor:[UIColor colorWithRed:224 / 255.0
                                                   green:224 / 255.0
                                                    blue:224 / 255.0
                                                   alpha:1.0]];
    return headerView;
  }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForHeaderInSection:(NSInteger)section {
  if (IDIOM == IPAD) {
    if (section == 0) {
      return 50;
    } else {
      return 1;
    }
  } else {
    if (section == 0) {
      return 30;
    } else {
      return 1;
    }
  }
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.row > 0) {
    if (IDIOM == IPAD) {
      return 60;
    } else {
      return 50;
    }
  } else {
    int amt = (int)(listAccount.count / 4 + 1);
    // NSLog(@"Number SubView %d",amt);
    BOOL isExpanded = [[expandedIndexes objectForKey:indexPath] boolValue];

    if (isExpanded) {
      return [SDGroupCell getHeight] + [SDGroupCell getsubCellHeight] * amt;
    }
    return [SDGroupCell getHeight];
  }

  return 50;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.delegate) {
    if (indexPath.row == 0) {
      [self collapsableButtonTapped:nil withEvent:nil];
    }

    if (IDIOM == IPHONE && indexPath.row != 0) {
      [self hideLeftViewoClick];
    }

    NSInteger idx = indexPath.row;
    if (idx != 0 && idx != 7 && idx != 8 && idx != 9) {
      NSString *HRName = [self.contents objectAtIndex:idx];
      folderName = HRName;
      [self.delegate loadMailFolder:[self pathFromName:HRName] withHR:HRName];
    }
  }

  switch (indexPath.row) {
  case 7: {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    FUIAlertView *alertView = [[FUIAlertView alloc]
            initWithTitle:NSLocalizedString(@"iMailLogout", nil)
                  message:NSLocalizedString(@"Confirm", nil)
                 delegate:self
        cancelButtonTitle:NSLocalizedString(@"Back", nil)
        otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    alertView.tag = Logout;
    if (IDIOM == IPAD) {
      alertView.titleLabel.font =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
      alertView.messageLabel.textColor = [UIColor asbestosColor];
      alertView.messageLabel.font =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
      alertView.backgroundOverlay.backgroundColor =
          [[UIColor blackColor] colorWithAlphaComponent:0.8];
      alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
      alertView.defaultButtonColor = [UIColor cloudsColor];
      alertView.defaultButtonShadowColor = [UIColor cloudsColor];
      alertView.defaultButtonFont =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
      alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
    } else {
      alertView.titleLabel.font =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
      alertView.messageLabel.textColor = [UIColor asbestosColor];
      alertView.messageLabel.font =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
      alertView.backgroundOverlay.backgroundColor =
          [[UIColor blackColor] colorWithAlphaComponent:0.8];
      alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
      alertView.defaultButtonColor = [UIColor cloudsColor];
      alertView.defaultButtonShadowColor = [UIColor cloudsColor];
      alertView.defaultButtonFont =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
      alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
    }
    [alertView show];
  } break;

  case 8: {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideLeftView:nil];
    FileManager *stc = [[FileManager alloc] init];
    UINavigationController *nc =
        [[UINavigationController alloc] initWithRootViewController:stc];
    nc.navigationBar.titleTextAttributes =
        @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    nc.navigationBar.topItem.title = NSLocalizedString(@"FileManager", nil);
    [nc.navigationBar
        configureFlatNavigationBarWithColor:[UIColor
                                                colorFromHexCode:barColor]];
    [self presentViewController:nc animated:YES completion:nil];

  } break;

  case 9: {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideLeftView:nil];
    SetupTableController *stc =
        [[SetupTableController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc =
        [[UINavigationController alloc] initWithRootViewController:stc];
    nc.navigationBar.titleTextAttributes =
        @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    nc.navigationBar.topItem.title = NSLocalizedString(@"Config", nil);
    [nc.navigationBar
        configureFlatNavigationBarWithColor:[UIColor
                                                colorFromHexCode:barColor]];
    [self presentViewController:nc animated:YES completion:nil];

  } break;
  default:
    break;
  }
}

- (void)toggleCell:(SDGroupCell *)cell atIndexPath:(NSIndexPath *)pathToToggle {
  [cell tapTransition];
  SelectableCellState cellState = [cell toggleCheck];
  NSNumber *cellStateNumber = [NSNumber numberWithInt:cellState];
  [selectableCellsState setObject:cellStateNumber forKey:pathToToggle];

  [cell subCellsToggleCheck];
  NSLog(@"pathToToggle %@", pathToToggle);
  [self mainItemDidChange:cell forTap:YES];
}

#pragma mark - Nested Tables events

- (void)groupCell:(SDGroupCell *)cell
    didSelectSubCell:(SDSelectableCell *)subCell
       withIndexPath:(NSIndexPath *)indexPath
          andWithTap:(BOOL)tapped {
  if (indexPath.row < listAccount.count / 4) {
    if (indexPath.row * 4 != accIndex) {
      firstLoad = YES;

      // Reset unlock mail
      [MsgListViewController setUnlockMail:NO];

      // AccIndex = 0 , 4 , 8 , 12 ....
      accIndex = indexPath.row * 4;
      [[NSUserDefaults standardUserDefaults]
          setObject:[NSString stringWithFormat:@"%d", (int)accIndex]
             forKey:@"accIndex"];
      [[NSUserDefaults standardUserDefaults]
          setObject:[listAccount objectAtIndex:accIndex + 3]
             forKey:@"mailtype"];

      [[NSNotificationCenter defaultCenter]
          postNotificationName:@"reloadMessage"
                        object:nil];

      [[AuthManager sharedManager] getAccountInfo:NO];
      [AuthManager resetImapSession:YES];

      [self hideLeftViewoClick];
      [self.tableView reloadData];

    } else {
      [self hideLeftViewoClick];
    }
  } else {
    [self accountAdd];
  }
}

- (void)collapsableButtonTapped:(UIControl *)button withEvent:(UIEvent *)event {
  UITableView *tableView = self.tableView;

  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

  if (indexPath == nil)
    return;
  tableView.separatorColor = [UIColor clearColor];
  if ([[expandedIndexes objectForKey:indexPath] boolValue]) {
    [self collapsingItem:(SDGroupCell *)
                             [tableView cellForRowAtIndexPath:indexPath]
           withIndexPath:indexPath];
  } else {
    [self
        expandingItem:(SDGroupCell *)[tableView cellForRowAtIndexPath:indexPath]
        withIndexPath:indexPath];
  }

  BOOL isExpanded = ![[expandedIndexes objectForKey:indexPath] boolValue];
  NSNumber *expandedIndex = [NSNumber numberWithBool:isExpanded];
  [expandedIndexes setObject:expandedIndex forKey:indexPath];

  [self.tableView beginUpdates];
  [self.tableView endUpdates];
}

- (void)accountAdd {

  [self hideLeftViewoClick];

  AuthNavigationViewController *nc = [AuthNavigationViewController
      controllerWithLogin:NSLocalizedString(@"iMailLogin", nil)];
  nc.dismissOnSuccess = YES;
  nc.dismissOnError = YES;
  nc.delegate = self;
  nc.navigationBar.titleTextAttributes =
      @{NSForegroundColorAttributeName : [UIColor whiteColor]};
  [nc.navigationBar
      configureFlatNavigationBarWithColor:[UIColor
                                              colorFromHexCode:barColor]];
  [nc presentFromRootAnimated:YES completion:nil];

  return;
}

- (void)reloadMenu {
  firstLoad = YES;
  listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count != 0) {
    accIndex = [[[NSUserDefaults standardUserDefaults]
        objectForKey:@"accIndex"] integerValue];
    [self.tableView reloadData];
  } else {
    return;
  }
}

//HoangTD edit
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
//  alertPin.tag = passwordHT;
//  [alertPin show];
//}

- (void)logoutPressed {
  CheckNetWork *initCheck = [[CheckNetWork alloc] init];
  if ([initCheck checkNetworkAvailable]) {
    [self.delegate clearMessages];
    [self hideLeftView:nil];
    [[AuthManager sharedManager] logout];
    [[AuthManager sharedManager] refresh_logout];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMessage"
                                                        object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMenu"
                                                        object:nil];
  } else {
    UIAlertView *fail = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Error", nil)
                  message:NSLocalizedString(@"CheckInternet", nil)
                 delegate:self
        cancelButtonTitle:NSLocalizedString(@"Back", nil)
        otherButtonTitles:nil, nil];
    [fail show];
  }
}

#pragma mark Helper Functions
- (NSString *)pathFromName:(NSString *)name {

  // Nếu không kịp lấy folder path: lấy path từ NSUserdefault
  NSString *accIndex =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (accIndex != nil) {
    NSString *username = [listAccount objectAtIndex:([accIndex intValue] + 1)];
    username = [NSString stringWithFormat:@"%@_MailPath", username];
    folderNameLookup =
        [[NSUserDefaults standardUserDefaults] dictionaryForKey:username];
  }
  if (folderNameLookup == NULL) {
    self.folderNameLookup = [ListAllFolders shareFolderNames];
  }

  NSString *imapPath = [self.folderNameLookup objectForKey:name];
  if (!imapPath) {
    if ([name isEqualToString:@"Attachments"]) {
      imapPath = [self.folderNameLookup objectForKey:@"All Mail"];
    } else {
      imapPath = name;
    }
  }

  return imapPath;
}

#pragma mark PKReveal Functions
- (void)hideLeftView:(id)sender {
  AppDelegate *appDelegate =
      (AppDelegate *)[[UIApplication sharedApplication] delegate];

  if (appDelegate.revealController.focusedController ==
      appDelegate.revealController.leftViewController) {
    [appDelegate.revealController
        showViewController:appDelegate.revealController.frontViewController];
  }
}

- (void)hideLeftViewoClick {
  AppDelegate *appDelegate =
      (AppDelegate *)[[UIApplication sharedApplication] delegate];

  if (appDelegate.revealController.focusedController ==
      appDelegate.revealController.leftViewController) {
    [appDelegate.revealController
        showViewController:appDelegate.revealController.frontViewController];
  }
}

#pragma mark Functions
- (void)alertView:(FUIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {

//  HoangTD edit
//  if (alertView.tag == passwordHT) {
//    if (buttonIndex == 1) {
//      [alertView dismissWithClickedButtonIndex:1 animated:YES];
//      NSString *passwrd = [[alertView textFieldAtIndex:0] text];
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
//  }

  if (alertView.tag == Logout) {
    if (buttonIndex == 1) {
      [self logoutPressed];
    }
  }

//  HoangTD edit
//  if (alertView.tag == TokenSetting) {
//    if (buttonIndex == 1) {
//      NSLog(@"SOFT TOKEN");
//      UIApplication *ourApplication = [UIApplication sharedApplication];
//      NSURL *ourURL = [NSURL URLWithString:@"vnptcatokenmanager://?emailcall"];
//      if ([ourApplication canOpenURL:ourURL]) {
//        [ourApplication openURL:ourURL];
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
//  }
}

@end
