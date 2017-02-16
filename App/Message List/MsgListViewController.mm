//
//  MsgListViewController.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "MsgListViewController.h"

#import "MenuViewController.h"
#import "ListAllFolders.h"
#import "MCTMsgViewController.h"
#import "ComposerViewController.h"
#import "Composer_iPhoneViewController.h"

#import "AuthManager.h"
#import "DelayedAttachment.h"

#import "AppDelegate.h"
#import "MessageCell.h"

#import "NSData+Base64.h"

//HoangTD edit
#import "TokenType.h"

#import "MyCache.h"
#import "DBManager.h"
#import "Constants.h"

#define checkInternet 0
#define checkFistAuth 5
#define protectMail 3
#define deleteMail 4
#define selectCertDefault 6

int numberMSM = 30;
NSInteger mailtype = 0;
int handel = 0;

static MCOIMAPMessage *orgMsg = nil;
static BOOL unlockMail;
static BOOL flagUnSeen;

@interface MsgListViewController ()

@property(nonatomic, strong) NSMutableDictionary *cache;
@property(nonatomic, strong) NSArray *messages;

@property(nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property(nonatomic, strong) MCOIMAPFetchMessagesOperation *imapMessagesFetchOp;

@end

@implementation MsgListViewController
@synthesize searchBar;
@synthesize searchBarDisplay;

+ (void)setUnlockMail:(BOOL)status {
  if (status) {
    unlockMail = YES;
  } else {
    unlockMail = NO;
  }
}

+ (BOOL)shareFlagSeen {
  return flagUnSeen;
}

- (void)viewDidLoad {
  [super viewDidLoad];

    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.moreToolBarButton setTitle:NSLocalizedString(@"More All", nil)];
    [self.deleteToolbarButton setTitle:NSLocalizedString(@"Delete All", nil)];
    
  filterResult = [[NSMutableArray alloc] init];
  if (!self.folder) {
    self.folder = @"INBOX";
    self.title = NSLocalizedString(@"Inbox", nil);
  }

  // set bar
  UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 44)];
  currentMailbox = [[UILabel alloc]
      initWithFrame:CGRectMake(0, 0, titleView.frame.size.width,
                               titleView.frame.size.height / 2)];
  currentMailbox.text = self.title;
  currentMailbox.font = [UIFont fontWithName:@"Helvetica-Bold" size:16];
  currentMailbox.textColor = [UIColor whiteColor];
  currentMailbox.textAlignment = NSTextAlignmentCenter;
  [titleView addSubview:currentMailbox];

  currentUserEmail = [[UILabel alloc]
      initWithFrame:CGRectMake(0, currentMailbox.frame.size.height,
                               titleView.frame.size.width,
                               titleView.frame.size.height / 3)];
  currentUserEmail.text = username;
  currentUserEmail.font = [UIFont systemFontOfSize:12];
  currentUserEmail.textColor = [UIColor whiteColor];
  currentUserEmail.textAlignment = NSTextAlignmentCenter;
  [titleView addSubview:currentUserEmail];
  self.navigationItem.titleView = titleView;

  self.cache = [[NSMutableDictionary alloc] init];

  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor
                                              colorFromHexCode:barColor]];

  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];
  self.navigationController.navigationBar.translucent = NO;

    [self setLeftMenuBarButton];

  UIButton *composeEmail = [UIButton buttonWithType:UIButtonTypeCustom];
  [composeEmail setFrame:CGRectMake(0.0f, 0.0f, 30, 30)];
  [composeEmail addTarget:self
                   action:@selector(composeEmail:)
         forControlEvents:UIControlEventTouchUpInside];
  UIImage *composeEmailImage = [UIImage imageNamed:@"bt_compose.png"];
  [composeEmail setImage:composeEmailImage forState:UIControlStateNormal];
  UIBarButtonItem *composeEmailButtonBar =
      [[UIBarButtonItem alloc] initWithCustomView:composeEmail];
  self.navigationItem.rightBarButtonItem = composeEmailButtonBar;

  self.detailViewController = (MessageDetailViewController *)
      [[self.splitViewController.viewControllers lastObject] topViewController];

  // Kéo xuống: refresh hòm thư
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  refreshControl.backgroundColor = [UIColor whiteColor];
  [refreshControl addTarget:self
                     action:@selector(loadEmails:)
           forControlEvents:UIControlEventValueChanged];
  self.refreshControl = refreshControl;

  /*
   Luồng tải email trong các hòm thư:
   * Khi bắt đầu chương trình: nếu không có tài khoản sẵn: thoát ra màn hình
   đăng nhập, nếu có: load email từ NSUserDefault với key = INBOX+tên tài khoản.
   - Nếu NSUserDefault trả về kết quả không nil: hiển thị kết quả từ
   NSUserdefault và kích hoạt chức năng tìm kiếm, ẩn chức năng refresh hòm thư
   trước; thực hiện fetch email ngầm sau.
   - Nếu NSUserDefault trả về kết quả nil: ẩn chức năng tìm kiếm, kích hoạt
   chức năng refresh hòm thư. Fetch email thực hiện trên main thread.
   - Khi fetch email xong: cập nhật NSUserDefault, reload table và hiển thị lại.
   * Đối với các hòm thư khác trừ Attachments cũng thực hiện tương tự: nếu có
   NSUserDefault thì ưu tiên hiển thị trước, fetch sau. Nếu không có
   NSUserDefault thì thực hiện fetch hòm thư như mặc định.
   * Khi tải thêm email (loadmoremail): mỗi lần tải thêm 10 email; Tải xong cập
   nhật lại NSUserDefault và numberMSM.
   */

  NSString *accIndex =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"];
  if (accIndex != nil) {
    NSMutableArray *listAccount =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    mailtype = [[[NSUserDefaults standardUserDefaults]
        objectForKey:@"mailtype"] integerValue];
    selectedAccName = [listAccount objectAtIndex:([accIndex intValue] + 1)];
  }

  if (selectedAccName) {
    NSString *key = [self.folder stringByAppendingString:selectedAccName];
    NSArray *cachedMes = [self loadCustomObjectWithKey:key];
    if (cachedMes) {
      self.messages = cachedMes;
    }
  }

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(finishedAuth)
                                               name:@"Finished_OAuth"
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(reloadMessage)
                                               name:@"reloadMessage"
                                             object:nil];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(selectedTableRow)
                                               name:@"closePopOver"
                                             object:nil];


  CGRect frame = self.view.frame;
  if (self.splitViewController) {
    frame = [[
        [self.splitViewController.viewControllers objectAtIndex:0] view] frame];
  }
  pullToRefreshManager_ = [[MNMBottomPullToRefreshManager alloc]
      initWithPullToRefreshViewHeight:
                                60.0f:frame.size.width
                            tableView:self.tableView
                           withClient:self];

  [AuthManager sharedManager];

  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

  [searchBar setTranslucent:NO];

  // Ẩn search bar khi messagelist rỗng, tạm thời che search bar khi messagelist
  // load xong dữ liệu
  sourceSearchArray = [NSMutableArray new];
  isSearching = NO;
  if (![self.messages count]) {
    self.searchBar.alpha = 0;
  } else {
    // Walk around to wait tableview end loading data
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    });
  }

  // Status mạng
  if (IDIOM == IPAD) {
    UINavigationController *leftNavigationController =
        [self.splitViewController.viewControllers objectAtIndex:0];
    label = [[UILabel alloc]
        initWithFrame:CGRectMake(0, self.navigationController.navigationBar
                                        .frame.size.height,
                                 leftNavigationController.view.frame.size.width,
                                 44)];
  } else {
    label = [[UILabel alloc]
        initWithFrame:CGRectMake(0, self.navigationController.navigationBar
                                        .frame.size.height,
                                 self.view.frame.size.width, 44)];
  }

  label.backgroundColor = [UIColor clearColor];
  label.textColor = [UIColor whiteColor];
  label.textAlignment = NSTextAlignmentCenter;
  [label setFont:[UIFont systemFontOfSize:15]];
  [label setAlpha:0.0];
  [self.navigationController.navigationBar addSubview:label];
}

- (void)setLeftMenuBarButton {
    UIButton *leftMenu = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftMenu setFrame:CGRectMake(0.0f, 0.0f, 30, 30)];
    [leftMenu addTarget:self
                 action:@selector(showLeftView:)
       forControlEvents:UIControlEventTouchUpInside];
    UIImage *leftMenuImage = [UIImage imageNamed:@"bt_drawer.png"];
    [leftMenu setImage:leftMenuImage forState:UIControlStateNormal];
    UIBarButtonItem *leftMenuButtonBar =
    [[UIBarButtonItem alloc] initWithCustomView:leftMenu];
    self.navigationItem.leftBarButtonItem = leftMenuButtonBar;
}

- (void)setLeftCancelBarButton {
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:CGRectMake(0.0f, 0.0f, 60, 30)];
    [cancelButton addTarget:self
                 action:@selector(cancelBarButtonClicked:)
       forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    UIBarButtonItem *leftMenuButtonBar =
    [[UIBarButtonItem alloc] initWithCustomView:cancelButton];
    self.navigationItem.leftBarButtonItem = leftMenuButtonBar;
}

- (void)cancelBarButtonClicked:(id) sender {
    [self showEdittingMode:NO];
}

- (void)viewWillAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(handleNetworkChange:)
             name:kReachabilityChangedNotification
           object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:kReachabilityChangedNotification
              object:nil];
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [pullToRefreshManager_ relocatePullToRefreshView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  [pullToRefreshManager_ tableViewScrolled];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
  [pullToRefreshManager_ tableViewReleased];
}

- (void)bottomPullToRefreshTriggered:(MNMBottomPullToRefreshManager *)manager {
  [self performSelector:@selector(loadTable) withObject:nil afterDelay:1.0f];
}

- (void)loadTable {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self updateEmailsWithCache:NO moreMail:10];
  });
}

/* IDLE is used to keep a connection open with the server so that new messages
 * can be pushed to the client */
- (void)getNewMail {

  NSLog(@"Get newmail is running");

  // LastKnownUID
  uint64_t lastmsg = 0;
  if ([self.messages count]) {
    MCOIMAPMessage *msgImap = [self.messages objectAtIndex:0];
    lastmsg = [msgImap uid];
  }
  // See RFC2177
  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"firstImap"];
  MCOIMAPIdleOperation *idleOp = [[[AuthManager sharedManager] getImapSession]
      idleOperationWithFolder:@"INBOX"
                 lastKnownUID:lastmsg];
  [idleOp start:^(NSError *error) {
    [self performSelector:@selector(getNewMail) withObject:nil afterDelay:10];
    [self loadEmailsWithCache:NO];
  }];
}

// Network change notification; scan folder when have Internet
- (void)handleNetworkChange:(NSNotification *)notice {
  Reachability *reachability = (Reachability *)[notice object];
  NetworkStatus remoteHostStatus = [reachability currentReachabilityStatus];
  if (remoteHostStatus == NotReachable) {
    NSLog(@"No Internet");
    [self Internet_warning];
  } else {
    NSLog(@"Have Internet");
    [self HaveInternet];
    ListAllFolders *method = [[ListAllFolders alloc] init];
    [method findFolderName:^(BOOL success){
    }];
  }
}

- (void)scrolltoEnd {
  if (self.tableView.contentSize.height > self.tableView.frame.size.height) {
    CGPoint offset = CGPointMake(0, self.tableView.contentSize.height -
                                        self.tableView.frame.size.height);
    [UIView animateWithDuration:0.5
                     animations:^{
                       self.tableView.contentOffset = offset;
                     }];
  }
}

- (void)finishedAuth {

  [self.tableView setContentOffset:CGPointMake(0, -60) animated:YES];
  if (!self.refreshControl.isRefreshing) {
    [self.refreshControl beginRefreshing];
  }
  /* Tìm thư mục; không được đặt [loadAccount] ngoài tiến trình async do hàm
   * 'sharedManager' ở phía AuthManager phải được kết thúc càng sớm càng tốt */

  ListAllFolders *method = [[ListAllFolders alloc] init];
  [method findFolderName:^(BOOL success) {
    // Load hòm thư
    [self loadAccount];
  }];
}

- (void)loadAccount {
  [self loadEmailsWithCache:NO];
}

- (void)Internet_warning {

  [UIView animateWithDuration:0.5
      delay:0
      options:UIViewAnimationOptionTransitionCurlUp
      animations:^(void) {
        [label setText:NSLocalizedString(@"CheckInternet", nil)];
        [label setBackgroundColor:[UIColor redColor]];
        [label setAlpha:1.0];
      }
      completion:^(BOOL finished) {
        [self performSelector:@selector(HaveInternet)
                   withObject:self
                   afterDelay:4.0];
      }];
}

- (void)HaveInternet {
  [UIView animateWithDuration:0.5
      delay:0
      options:UIViewAnimationOptionTransitionCurlDown
      animations:^(void) {
        [label setAlpha:0.0];
      }
      completion:^(BOOL finished) {
        [label setText:@""];
        [label setBackgroundColor:[UIColor clearColor]];
      }];
}

// Save message for offline reading
- (void)saveCustomObject:(NSArray *)object key:(NSString *)key {
  NSString *accIndex =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (accIndex != nil) {
    NSString *usrname = [listAccount objectAtIndex:([accIndex intValue] + 1)];
    if (usrname) {
      key = [key stringByAppendingString:usrname];
      NSData *encodedObject =
          [NSKeyedArchiver archivedDataWithRootObject:object];
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      [defaults setObject:encodedObject forKey:key];
      [defaults synchronize];
    }
  }
}

- (NSArray *)loadCustomObjectWithKey:(NSString *)key {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSData *encodedObject = [defaults objectForKey:key];
  if (encodedObject == NULL) {
    return nil;
  }
  NSArray *object = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
  return object;
}

/* YES = load from cache
 NO  = load from server */
- (void)loadEmailsWithCache:(BOOL)allowed {

  NSString *folderName = self.folder;
  if ([self checkNetworkAvaiable]) {
    if (!self.refreshControl.isRefreshing) {
      if (![self.messages count]) {
        [self.tableView setContentOffset:CGPointMake(0, -60) animated:YES];
        [self.refreshControl beginRefreshing];
      }
    }
    if (allowed) {
      NSArray *lookup = [self.cache objectForKey:folderName];
      if (lookup) {
        NSLog(@"CACHE HIT %@", folderName);
        self.messages = lookup;
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
        return;
      }
      NSLog(@"CACHE MISS %@", folderName);
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    void (^completionWithLoad)(NSError *, NSArray *, MCOIndexSet *) =
        ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {

          if (error.code == 5) {
            [CheckValidSession
                checkValidSession:[[AuthManager sharedManager] getImapSession]];
          }

          [UIApplication sharedApplication].networkActivityIndicatorVisible =
              NO;

          if (!error) {
            self.messages = messages;
            [self.cache setValue:messages forKey:folderName];
            [self saveCustomObject:messages key:folderName];
          }

          [self.tableView reloadData];
          [self.refreshControl endRefreshing];

          // Hide Search Bar
          NSArray *cellArray = [self.tableView visibleCells];
          self.searchBar.alpha = 1.0f;
          if (self.searchBar.frame.size.height == 0) {
            [self.searchBar setFrame:CGRectMake(0, 0, 320, 44)];
          }
          if ([cellArray count] > 0) {
            UITableViewCell *cell = [cellArray objectAtIndex:0];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if (indexPath.row == 0) {
              [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
            }
          }
          if (!messages) {
            [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
          }
        };
    [self loadEmailsFromFolder:folderName WithCompletion:completionWithLoad];
  } else {
    // Load from cache
    NSString *key = [folderName stringByAppendingString:selectedAccName];
    NSArray *cachedMes = [self loadCustomObjectWithKey:key];
    self.messages = cachedMes;
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    return;
  }
}

// Load more mail
- (void)updateEmailsWithCache:(BOOL)allowed moreMail:(int)moreMail {

  NSString *folderName = self.folder;
  if (allowed) {
    NSArray *lookup = [self.cache objectForKey:folderName];
    if (lookup) {
      NSLog(@"CACHE HIT %@", folderName);
      self.messages = lookup;
      [self.tableView reloadData];
      // [self.refreshControl endRefreshing];
      return;
    }
    NSLog(@"CACHE MISS %@", folderName);
  }

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  void (^completionWithLoad)(NSError *, NSArray *,
                             MCOIndexSet *) = ^(NSError *error,
                                                NSArray *messages,
                                                MCOIndexSet *vanishedMessages) {

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (error) {
      [pullToRefreshManager_ tableViewReloadFinished];
      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }
      return;
    }

    if (messages.count - self.messages.count < 1) {
      [pullToRefreshManager_ tableViewReloadFinished];
      self.messages = messages;
      return;
    }

    NSMutableArray *paths = [NSMutableArray
        arrayWithCapacity:(messages.count - self.messages.count)];
    for (int i = 0; i < (messages.count - self.messages.count); i++) {
      NSIndexPath *path =
          [NSIndexPath indexPathForRow:self.messages.count + i inSection:0];
      [paths addObject:path];
    }
    self.messages = messages;
    if (paths.count > 0) {
      [self.tableView insertRowsAtIndexPaths:paths
                            withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    // save for offline
    [self.cache setValue:messages forKey:folderName];
    [self saveCustomObject:messages key:folderName];
    [pullToRefreshManager_ tableViewReloadFinished];
  };
  [self refreshEmailsFromFolder:
                     folderName:moreMail
                 WithCompletion:completionWithLoad];
}

- (void)loadEmails:(id)sender {
  [self loadEmailsWithCache:NO];
}

- (void)loadEmailsFromFolder:(NSString *)folderName
              WithCompletion:(void (^)(NSError *error, NSArray *messages,
                                       MCOIndexSet *vanishedMessages))block {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  if ([folderName isEqualToString:@"ATTACHMENTS"]) {
    return [self loadEmailsWithAttachmentsWithCompletion:block];
  }

  MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)(
      MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
      MCOIMAPMessagesRequestKindInternalDate |
      MCOIMAPMessagesRequestKindHeaderSubject |
      MCOIMAPMessagesRequestKindFlags);

  // Get inbox information. Then grab the most recent mails.
  MCOIMAPFolderInfoOperation *folderInfo =
      [[[AuthManager sharedManager] getImapSession]
          folderInfoOperation:folderName];
  [folderInfo start:^(NSError *error, MCOIMAPFolderInfo *info) {

    if ([self.messages count]) {
      numberMSM = [self.messages count];
    }
    int messageCount = [info messageCount];
    int numberOfMessages = numberMSM; // Hạ thêm
    if (messageCount <= numberOfMessages) {
      numberOfMessages = messageCount - 1;
    }
    MCOIndexSet *numbers = [MCOIndexSet
        indexSetWithRange:MCORangeMake(messageCount - numberOfMessages,
                                       numberOfMessages)];

    self.imapMessagesFetchOp = [[[AuthManager sharedManager] getImapSession]
        fetchMessagesByNumberOperationWithFolder:folderName
                                     requestKind:requestKind
                                         numbers:numbers];

    [self.imapMessagesFetchOp start:^(NSError *error, NSArray *messages,
                                      MCOIndexSet *vanishedMessages) {
      NSSortDescriptor *sort =
          [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
      block(error, [messages sortedArrayUsingDescriptors:@[ sort ]],
            vanishedMessages);

      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }
    }];
  }];
}

- (void)refreshEmailsFromFolder:(NSString *)
                     folderName:(int)mailPlus
                 WithCompletion:(void (^)(NSError *error, NSArray *messages,
                                          MCOIndexSet *vanishedMessages))block {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  if ([folderName isEqualToString:@"ATTACHMENTS"]) {
    return [self loadEmailsWithAttachmentsWithCompletion:block];
  }

  MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)(
      MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
      MCOIMAPMessagesRequestKindInternalDate |
      MCOIMAPMessagesRequestKindHeaderSubject |
      MCOIMAPMessagesRequestKindFlags);

  // Get inbox information. Then grab the 50 most recent mails.
  MCOIMAPFolderInfoOperation *folderInfo =
      [[[AuthManager sharedManager] getImapSession]
          folderInfoOperation:self.folder];

  [folderInfo start:^(NSError *error, MCOIMAPFolderInfo *info) {

    if (error.code == 5) {
      [CheckValidSession
          checkValidSession:[[AuthManager sharedManager] getImapSession]];
    }

    int messageCount = [info messageCount];

    numberMSM = numberMSM + mailPlus;
    if (messageCount <= numberMSM) {
      numberMSM = messageCount - 1;
    }
    MCOIndexSet *numbers = [MCOIndexSet
        indexSetWithRange:MCORangeMake(messageCount - numberMSM, numberMSM)];

    self.imapMessagesFetchOp = [[[AuthManager sharedManager] getImapSession]
        fetchMessagesByNumberOperationWithFolder:folderName
                                     requestKind:requestKind
                                         numbers:numbers];

    [self.imapMessagesFetchOp start:^(NSError *error, NSArray *messages,
                                      MCOIndexSet *vanishedMessages) {

      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }

      NSSortDescriptor *sort =
          [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
      block(error, [messages sortedArrayUsingDescriptors:@[ sort ]],
            vanishedMessages);
      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
  }];

  //[self.tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
}

- (void)loadEmailsWithAttachmentsWithCompletion:
    (void (^)(NSError *error, NSArray *messages,
              MCOIndexSet *vanishedMessages))block {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  NSString *folderParent = self.folderParent;
  if (!folderParent) {
    folderParent = @"[Gmail]/All Mail";
  }

  MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)(
      MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
      MCOIMAPMessagesRequestKindInternalDate |
      MCOIMAPMessagesRequestKindHeaderSubject |
      MCOIMAPMessagesRequestKindFlags);

  MCOIMAPFolderInfoOperation *folderInfo =
      [[[AuthManager sharedManager] getImapSession]
          folderInfoOperation:folderParent];

  [folderInfo start:^(NSError *error, MCOIMAPFolderInfo *info) {

    if (error.code == 5) {
      [CheckValidSession
          checkValidSession:[[AuthManager sharedManager] getImapSession]];
    }

    int messageCount = [info messageCount];
    int numberOfMessages = 200;
    if (messageCount <= numberOfMessages) {
      numberOfMessages = messageCount - 1;
    }
    MCOIndexSet *numbers = [MCOIndexSet
        indexSetWithRange:MCORangeMake(messageCount - numberOfMessages,
                                       numberOfMessages)];

    self.imapMessagesFetchOp = [[[AuthManager sharedManager] getImapSession]
        fetchMessagesByNumberOperationWithFolder:folderParent
                                     requestKind:requestKind
                                         numbers:numbers];
    [self.imapMessagesFetchOp start:^(NSError *error, NSArray *messages,
                                      MCOIndexSet *vanishedMessages) {
      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }

      NSPredicate *predicate =
          [NSPredicate predicateWithFormat:@"attachments.@count > 0"];
      NSArray *filteredMessages =
          [messages filteredArrayUsingPredicate:predicate];

      NSSortDescriptor *sort =
          [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
      block(error, [filteredMessages sortedArrayUsingDescriptors:@[ sort ]],
            vanishedMessages);
      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
  }];
}

- (void)deleteFromTrash:(uint64_t)msgUID rowIndexPath:(NSIndexPath *)indexpath {

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  MCOIMAPOperation *op = [[[AuthManager sharedManager] getImapSession]
      storeFlagsOperationWithFolder:self.folder
                               uids:[MCOIndexSet indexSetWithIndex:msgUID]
                               kind:MCOIMAPStoreFlagsRequestKindSet
                              flags:MCOMessageFlagDeleted];
  [op start:^(NSError *error) {
    if (!error) {
      NSLog(@"Updated flags!");
    } else {
      NSLog(@"Error updating flags:%@", error);
      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }
    }
    MCOIMAPOperation *deleteOp = [[[AuthManager sharedManager] getImapSession]
        expungeOperation:self.folder];
    [deleteOp start:^(NSError *error) {

      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

      if (error) {
        NSLog(@"Error expunging folder:%@", error);
        if (error.code == 5) {
          [CheckValidSession
              checkValidSession:[[AuthManager sharedManager] getImapSession]];
        }
      } else {
        NSLog(@"Successfully expunged folder");
      }
    }];
  }];

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC),
      dispatch_get_main_queue(), ^{
        // update UI
        NSMutableArray *msg = [NSMutableArray arrayWithArray:self.messages];
        [msg removeObjectAtIndex:indexpath.row];
        self.messages = [NSArray arrayWithArray:msg];
        [self.tableView
            deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexpath]
                  withRowAnimation:UITableViewRowAnimationLeft];

        // delete & update NSUserDefault and Cache
        NSString *s_uid = [NSString stringWithFormat:@"%d", (NSUInteger)msgUID];
        NSString *key =
            [NSString stringWithFormat:@"%@%@%@", username, _folder, s_uid];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        [self.cache setValue:msg forKey:self.folder];
        [self saveCustomObject:msg key:self.folder];

        if (IDIOM == IPAD && index != 0) {
          [self selectRowAtIndexPath:indexpath.row];
        }
      });
}

- (void)deleteFromTrash:(MCOIndexSet *)mcoIndexSet indexSet:(NSIndexSet *)indexSet indexPaths:(NSArray *)indexPaths selectedMessages:(NSArray *)selectedMessages {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    MCOIMAPOperation *op = [[[AuthManager sharedManager] getImapSession]
                            storeFlagsOperationWithFolder:self.folder
                            uids:mcoIndexSet
                            kind:MCOIMAPStoreFlagsRequestKindSet
                            flags:MCOMessageFlagDeleted];
    [op start:^(NSError *error) {
        if (!error) {
            NSLog(@"Updated flags!");
        } else {
            NSLog(@"Error updating flags:%@", error);
            if (error.code == 5) {
                [CheckValidSession
                 checkValidSession:[[AuthManager sharedManager] getImapSession]];
            }
        }
        MCOIMAPOperation *deleteOp = [[[AuthManager sharedManager] getImapSession]
                                      expungeOperation:self.folder];
        [deleteOp start:^(NSError *error) {
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            if (error) {
                NSLog(@"Error expunging folder:%@", error);
                if (error.code == 5) {
                    [CheckValidSession
                     checkValidSession:[[AuthManager sharedManager] getImapSession]];
                }
            } else {
                NSLog(@"Successfully expunged folder");
            }
        }];
    }];
    
    dispatch_after(
                   dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
                       // update UI
                       NSMutableArray *msg = [NSMutableArray arrayWithArray:self.messages];
                       [msg removeObjectsAtIndexes:indexSet];
                       self.messages = [NSArray arrayWithArray:msg];
                       [self.tableView
                        deleteRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationLeft];
                       
                       // delete & update NSUserDefault and Cache
                       [self deleteMailData:selectedMessages];
                       
                       [self.cache setValue:msg forKey:self.folder];
                       [self saveCustomObject:msg key:self.folder];
                       
//                       if (IDIOM == IPAD && index != 0) {
//                           [self selectRowAtIndexPath:indexpath.row];
//                       }
                   });
}

- (void)removeMessage:(uint64_t)msgUID {
  NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
  NSPredicate *predicate =
      [NSPredicate predicateWithFormat:@"uid != %d", msgUID];
  self.messages = [self.messages filteredArrayUsingPredicate:predicate];
  // Last row issue.
  if (indexPath.row >= [self.messages count]) {
    indexPath = [NSIndexPath indexPathForItem:[self.messages count] - 1
                                    inSection:indexPath.section];
  }
  [self selectRowAtIndexPath:indexPath.row];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)composeEmail:(id)sender {

  // Test only
  /*
UIApplication *yourApplication = [UIApplication sharedApplication];
  NSString *dataToSign = @"123";
NSString *urlActive =
    [NSString stringWithFormat:@"mcatoken://bac?data=%@?sessionID=%@?scheme=%@",
                               dataToSign, @"1123", @"vnpt"];
NSURL *mcaLogonURL = [NSURL URLWithString:urlActive];
if (![yourApplication canOpenURL:mcaLogonURL]) {
  UIAlertView *alertView = [[UIAlertView alloc]
          initWithTitle:@"Lỗi"
                message:@"Ứng dụng mCA Logon chưa cài đặt"
               delegate:nil
      cancelButtonTitle:@"Đồng ý"
      otherButtonTitles:nil];
  [alertView show];
} else {
  [yourApplication openURL:mcaLogonURL];
}
  */
  // End of Test only

  if (IDIOM == IPAD) {
    ComposerViewController *vc = [[ComposerViewController alloc] initWithTo:@[
    ] CC:@[] BCC:@[] subject:@"" message:[[NSUserDefaults standardUserDefaults]
                                              objectForKey:@"signature"]
                                                                attachments:@[]
                                                         delayedAttachments:@[
                                                         ]];
    UINavigationController *nc =
        [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nc animated:YES completion:nil];
  } else {
    Composer_iPhoneViewController *vc = [[Composer_iPhoneViewController alloc]
                initWithTo:@[]
                        CC:@[]
                       BCC:@[]
                   subject:@""
                   message:[[NSUserDefaults standardUserDefaults]
                               objectForKey:@"signature"]
               attachments:@[]
        delayedAttachments:@[]];
    FixedNavigationController *nc =
        [[FixedNavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nc animated:YES completion:nil];
  }
}

#pragma mark - PKRevealController
- (void)showLeftView:(id)sender {
  AppDelegate *appDelegate =
      (AppDelegate *)[[UIApplication sharedApplication] delegate];
  if (appDelegate.revealController.focusedController ==
      appDelegate.revealController.leftViewController) {
    [appDelegate.revealController
        showViewController:appDelegate.revealController.frontViewController];
  } else {
    [appDelegate.revealController
        showViewController:appDelegate.revealController.leftViewController];
  }
}

- (void)hideLeftView:(id)sender {
  AppDelegate *appDelegate =
      (AppDelegate *)[[UIApplication sharedApplication] delegate];
  if (appDelegate.revealController.focusedController ==
      appDelegate.revealController.leftViewController) {
    [appDelegate.revealController
        showViewController:appDelegate.revealController.frontViewController];
  }
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  if (isSearching) {
    return filterResult.count;
  } else {
    return self.messages.count;
  }
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

  /* Các thao tác trên message hoạt động theo luồng sau:
   - Kiểm tra mạng: nếu ko có mạng thì không thực hiện (return), nếu có mạng thì
   thực hiện Operation (delete, move, flag...) đồng thời với việc update status
   mạng
   - Operation thực hiện xong: đóng status mạng. Nếu kết quả trả về lỗi thì kết
   thúc hàm; nếu thành công thì reload table, update bộ Cache, update
   NSUserdefault */

  [self.view endEditing:YES];

  if (![self checkNetworkAvaiable]) {
    return nil;
  }

  NSIndexPath *cellIndexPath;
  if (!isSearching) {
    cellIndexPath = [self.tableView indexPathForCell:cell];
  } else {
    cellIndexPath = [self.searchDisplayController.searchResultsTableView
        indexPathForCell:cell];
  }
  NSInteger row = [cellIndexPath row];
  MCOIMAPMessage *msgImap;
  if (isSearching) {
    msgImap = self.messages[[filterResult[row] integerValue]];
  } else {
    msgImap = self.messages[row];
  }
  uint64_t msgUID = msgImap.uid;

  swipeSettings.transition = MGSwipeTransitionBorder;
  expansionSettings.buttonIndex = 0;

  __weak MsgListViewController *me = self;

  // Read <-> Unread
  if (direction == MGSwipeDirectionLeftToRight) {

    expansionSettings.fillOnTrigger = YES;
    expansionSettings.threshold = 1.0;
    CGFloat padding = 5;

    BOOL text;
    MCOMessageFlag flags = msgImap.flags;
    if (flags & MCOMessageFlagSeen) {
      text = YES;
    } else {
      text = NO;
    }

    // Set flag
    MGSwipeButton *flag = [MGSwipeButton
        buttonWithTitle:NSLocalizedString(@"Flag", nil)
        backgroundColor:
            [UIColor colorWithRed:1.0 green:149 / 255.0 blue:0.05 alpha:1.0]
                padding:padding
               callback:^BOOL(MGSwipeTableCell *sender) {
                 [UIApplication sharedApplication]
                     .networkActivityIndicatorVisible = YES;

                 // set flag MCO Operation
                 MCOMessageFlag flags = msgImap.flags;
                 MCOIMAPStoreFlagsRequestKind request;
                 if (!(flags & MCOMessageFlagFlagged)) {
                   request = MCOIMAPStoreFlagsRequestKindAdd;
                   flags |= MCOMessageFlagFlagged;
                 } else {
                   request = MCOIMAPStoreFlagsRequestKindRemove;
                   flags &= ~MCOMessageFlagFlagged;
                 }
                 // Update flag MCO Operation
                 MCOIMAPOperation *msgOperation = [
                     [[AuthManager sharedManager] getImapSession]
                     storeFlagsOperationWithFolder:self.folder
                                              uids:[MCOIndexSet
                                                       indexSetWithIndex:msgUID]
                                              kind:request
                                             flags:MCOMessageFlagFlagged];
                 [msgOperation start:^(NSError *error) {
                   if (!error) {
                     NSLog(@"Update Flags done!");
                   } else {
                     NSLog(@"Update Flags failed!, %@", error.description);
                     if (error.code == 5) {
                       [CheckValidSession
                           checkValidSession:
                               [[AuthManager sharedManager] getImapSession]];
                     }
                   }
                   [UIApplication sharedApplication]
                       .networkActivityIndicatorVisible = NO;
                 }];

                 // delay 0.3s, chống lag table khi reload dữ liệu
                 dispatch_after(
                     dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC),
                     dispatch_get_main_queue(), ^{
                       if (isSearching) {
                         [self.messages[[filterResult[row] integerValue]]
                             setFlags:flags];
                       } else {
                         [self.messages[row] setFlags:flags];
                       }
                       [self.cache setValue:self.messages forKey:self.folder];
                       [self saveCustomObject:self.messages key:self.folder];
                       if (!isSearching) {
                         [self.tableView beginUpdates];
                         [self.tableView reloadRowsAtIndexPaths:@[
                           cellIndexPath
                         ] withRowAnimation:UITableViewRowAnimationFade];
                         [self.tableView endUpdates];
                       } else {
                         [self.searchDisplayController
                                 .searchResultsTableView beginUpdates];
                         [self.searchDisplayController.searchResultsTableView
                             reloadRowsAtIndexPaths:@[
                               cellIndexPath
                             ] withRowAnimation:UITableViewRowAnimationFade];
                         [self.searchDisplayController
                                 .searchResultsTableView endUpdates];
                       }
                     });
                 return YES;
               }];

    MGSwipeButton *readUnread = [MGSwipeButton
        buttonWithTitle:[self readButtonText:text]
        backgroundColor:
            [UIColor colorWithRed:0 green:122 / 255.0 blue:1.0 alpha:1.0]
                padding:padding
               callback:^BOOL(MGSwipeTableCell *sender) {
                 [UIApplication sharedApplication]
                     .networkActivityIndicatorVisible = YES;

                 MCOMessageFlag flags = msgImap.flags;
                 MCOIMAPStoreFlagsRequestKind request;
                 if (flags & MCOMessageFlagSeen) {
                   request = MCOIMAPStoreFlagsRequestKindRemove;
                   flags &= ~MCOMessageFlagSeen;
                 } else {
                   request = MCOIMAPStoreFlagsRequestKindAdd;
                   flags |= MCOMessageFlagSeen;
                 }

                 MCOIMAPOperation *msgOperation = [
                     [[AuthManager sharedManager] getImapSession]
                     storeFlagsOperationWithFolder:self.folder
                                              uids:[MCOIndexSet
                                                       indexSetWithIndex:msgUID]
                                              kind:request
                                             flags:MCOMessageFlagSeen];
                 [msgOperation start:^(NSError *error) {
                   [UIApplication sharedApplication]
                       .networkActivityIndicatorVisible = NO;
                   if (!error) {
                     NSLog(@"Flags read/unread done!");
                   } else {
                     NSLog(@"Flags read/unread error!");
                     if (error.code == 5) {
                       [CheckValidSession
                           checkValidSession:
                               [[AuthManager sharedManager] getImapSession]];
                     }
                   }
                 }];
                 // chống lag table khi update dữ liệu mới
                 dispatch_after(
                     dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC),
                     dispatch_get_main_queue(), ^{
                       if (isSearching) {
                         [self.messages[[filterResult[row] integerValue]]
                             setFlags:flags];
                       } else {
                         [self.messages[row] setFlags:flags];
                       }
                       [self.cache setValue:self.messages forKey:self.folder];
                       [self saveCustomObject:self.messages key:self.folder];

                       if (isSearching) {
                         [self.searchDisplayController
                                 .searchResultsTableView beginUpdates];
                         [self.searchDisplayController.searchResultsTableView
                             reloadRowsAtIndexPaths:@[
                               cellIndexPath
                             ] withRowAnimation:UITableViewRowAnimationFade];
                         [self.searchDisplayController
                                 .searchResultsTableView endUpdates];
                       } else {
                         [self.tableView beginUpdates];
                         [self.tableView reloadRowsAtIndexPaths:@[
                           cellIndexPath
                         ] withRowAnimation:UITableViewRowAnimationFade];
                         [self.tableView endUpdates];
                       }
                     });
                 return YES;
               }];

    return @[ readUnread, flag ];
  }
  if (direction == MGSwipeDirectionRightToLeft) {

    expansionSettings.fillOnTrigger = YES;
    expansionSettings.threshold = 1.0;
    CGFloat padding = 5;

    // More button
    MGSwipeButton *more = [MGSwipeButton
        buttonWithTitle:NSLocalizedString(@"More", nil)
        backgroundColor:[UIColor colorWithRed:200 / 255.0
                                        green:200 / 255.0
                                         blue:205 / 255.0
                                        alpha:1.0]
                padding:padding
               callback:^BOOL(MGSwipeTableCell *sender) {
                 [me showMailActions:^(BOOL cancelled, BOOL deleted,
                                       NSInteger actionIndex) {
                   [self dismissWithClickedButtonIndex:0 animated:YES];
                   [cell hideSwipeAnimated:YES];
                   if (cancelled) {
                     return;
                   } else if (actionIndex == 0) {
                     NSLog(@"Reply - Action Index = 0");
                     [me moreAction:0 indexPath:cellIndexPath];
                   } else if (actionIndex == 1) {
                     [me moreAction:1 indexPath:cellIndexPath];
                     NSLog(@"Forward");
                   } else if (actionIndex == 2) {
                     NSLog(@"Current folder %@", self.folder);
                     NSLog(@"Move to Junk");
                     NSString *spamFolder = [[ListAllFolders shareFolderNames]
                         objectForKey:@"Spam"];
                     [self moveMessageWithUID:cellIndexPath
                                     toFolder:spamFolder];
                   } else if (actionIndex == 3) {

                     NSLog(@"Move to ...");
                     MCOIMAPMessage *mes;
                     if (!isSearching) {
                       mes = self.messages[cellIndexPath.row];
                     } else {
                       mes = self.messages[
                           [filterResult[cellIndexPath.row] integerValue]];
                     }
                     MoveToMailboxes *move = [[MoveToMailboxes alloc] init];
                     move.delegate = self;
                     move.fromFolder = self.title;
                     move.message = cellIndexPath;
                     NSString *from = mes.header.from.displayName
                                          ? mes.header.from.displayName
                                          : mes.header.from.mailbox;
                     NSString *subject =
                         mes.header.subject
                             ? mes.header.subject
                             : NSLocalizedString(@"NoSubject", nil);
                     move.title = NSLocalizedString(@"MoveToFolders", nil);
                     move.content =
                         [NSString stringWithFormat:@"%@\n%@", from, subject];
                     FixedNavigationController *nav =
                         [[FixedNavigationController alloc]
                             initWithRootViewController:move];
                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                       [self presentViewController:nav
                                          animated:YES
                                        completion:nil];
                     }];
                   } else if (actionIndex == 4) {
                       [self showEdittingMode:YES];
                   }

                 }];
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
                   [UIApplication sharedApplication]
                   .networkActivityIndicatorVisible = YES;
                   
                   /* delete MCO operation */
                   if ([[MenuViewController sharedFolderName]
                        isEqualToString:@"Trash"]) {
                       
                       /* From trash */
                       [self deleteFromTrash:msgUID rowIndexPath:cellIndexPath];
                       
                   } else {
                       /* From other mailboxes */
                       
                       // delete MCO Operation
                       NSString *trash = [[ListAllFolders shareFolderNames]
                                          objectForKey:@"Trash"];
                       MCOIMAPCopyMessagesOperation *opC =
                       [[[AuthManager sharedManager] getImapSession]
                        copyMessagesOperationWithFolder:
                        self.folder uids:[MCOIndexSet
                                          indexSetWithIndex:msgUID]
                        destFolder:trash];
                       [opC start:^(NSError *error, NSDictionary *uidMapping) {
                           NSLog(@"Yahoo & Outlook... Trash with UID mapping %@",
                                 uidMapping);
                           if (error) {
                               NSLog(@"error delete: %@", error.description);
                               if (error.code == 5) {
                                   [CheckValidSession
                                    checkValidSession:
                                    [[AuthManager sharedManager] getImapSession]];
                               }
                           }
                           
                       }];
                       MCOIMAPOperation *op = [
                                               [[AuthManager sharedManager] getImapSession]
                                               storeFlagsOperationWithFolder:
                                               self.folder uids:[MCOIndexSet
                                                                 indexSetWithIndex:msgUID]
                                               kind:
                                               MCOIMAPStoreFlagsRequestKindSet
                                               flags:MCOMessageFlagDeleted];
                       [op start:^(NSError *error) {
                           if (error) {
                               NSLog(@"Error updating flags:%@", error);
                               if (error.code == 5) {
                                   [CheckValidSession
                                    checkValidSession:
                                    [[AuthManager sharedManager] getImapSession]];
                               }
                               
                               [UIApplication sharedApplication]
                               .networkActivityIndicatorVisible = NO;
                               
                               return;
                           }
                           MCOIMAPOperation *deleteOp =
                           [[[AuthManager sharedManager] getImapSession]
                            expungeOperation:self.folder];
                           [deleteOp start:^(NSError *error) {
                               [UIApplication sharedApplication]
                               .networkActivityIndicatorVisible = NO;
                               if (!error) {
                                   if (IDIOM == IPAD && row != 0) {
                                       [self selectRowAtIndexPath:row];
                                   }
                                   NSLog(@"Email has been deleted");
                               } else {
                                   NSLog(@"Error expunging folder:%@", error);
                                   if (error.code == 5) {
                                       [CheckValidSession
                                        checkValidSession:
                                        [[AuthManager
                                          sharedManager] getImapSession]];
                                   }
                               }
                           }];
                       }];
                       
                       // update UI
                       dispatch_after(
                                      dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC),
                                      dispatch_get_main_queue(), ^{
                                          NSMutableArray *msg =
                                          [NSMutableArray arrayWithArray:self.messages];
                                          if (row < msg.count) {
                                              if (isSearching) {
                                                  [msg removeObjectAtIndex:
                                                   [filterResult[row] integerValue]];
                                                  [filterResult removeObjectAtIndex:row];
                                              } else {
                                                  [msg removeObjectAtIndex:row];
                                              }
                                          }
                                          self.messages = [NSArray arrayWithArray:msg];
                                          if (!isSearching) {
                                              [self.tableView
                                               deleteRowsAtIndexPaths:
                                               [NSArray arrayWithObject:cellIndexPath]
                                               withRowAnimation:
                                               UITableViewRowAnimationLeft];
                                          } else {
                                              [self.searchDisplayController.searchResultsTableView
                                               deleteRowsAtIndexPaths:
                                               [NSArray arrayWithObject:cellIndexPath]
                                               withRowAnimation:
                                               UITableViewRowAnimationLeft];
                                          }
                                          // delete & update NSUserDefault and Cache
                                          NSString *s_uid = [NSString
                                                             stringWithFormat:@"%d", (NSUInteger)msgUID];
                                          NSString *key =
                                          [NSString stringWithFormat:@"%@%@%@", username,
                                           _folder, s_uid];
                                          [[NSUserDefaults standardUserDefaults]
                                           removeObjectForKey:key];
                                          [self.cache setValue:msg forKey:self.folder];
                                          [self saveCustomObject:msg key:self.folder];
                                      });
                   }
                 return YES;
               }];

    return @[ trash, more ];
  }
  return nil;
}

- (void)moveMessageWithUID:(NSIndexPath *)index toFolder:(NSString *)dest {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  // find message
  MCOIMAPMessage *message;
  if (!isSearching) {
    message = self.messages[index.row];
  } else {
    message = self.messages[[filterResult[index.row] integerValue]];
  }

  // update UI
  NSMutableArray *msg = [NSMutableArray arrayWithArray:self.messages];
  [msg removeObjectAtIndex:index.row];
  self.messages = [NSArray arrayWithArray:msg];

  if (!isSearching) {
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:index]
                          withRowAnimation:UITableViewRowAnimationLeft];
  } else {
    [filterResult removeObjectAtIndex:index.row];
    [self.searchDisplayController.searchResultsTableView
        deleteRowsAtIndexPaths:[NSArray arrayWithObject:index]
              withRowAnimation:UITableViewRowAnimationLeft];
  }

  // delete & update NSUserDefault and Cache
  [self.cache setValue:msg forKey:self.folder];
  [self saveCustomObject:msg key:self.folder];

  MCOIMAPCopyMessagesOperation *op =
      [[[AuthManager sharedManager] getImapSession]
          copyMessagesOperationWithFolder:self.folder
                                     uids:[MCOIndexSet
                                              indexSetWithIndex:message.uid]
                               destFolder:dest];
  [op start:^(NSError *error, NSDictionary *uidMapping) {

    if (!error) {
      MCOMessageFlag newflags = [message flags];
      newflags |= MCOMessageFlagDeleted;

      MCOIMAPOperation *changeFlags =
          [[[AuthManager sharedManager] getImapSession]
              storeFlagsOperationWithFolder:self.folder
                                       uids:[MCOIndexSet
                                                indexSetWithIndex:message.uid]
                                       kind:MCOIMAPStoreFlagsRequestKindSet
                                      flags:newflags];

      [changeFlags start:^(NSError *error) {
        if (!error) {
          NSLog(@"Flag has been changed");
          MCOIMAPOperation *expungeOp =
              [[[AuthManager sharedManager] getImapSession]
                  expungeOperation:self.folder];
          [expungeOp start:^(NSError *error) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible =
                NO;
            if (error) {
              NSLog(@"Expunge Failed, %@", error.description);
              if (error.code == 5) {
                [CheckValidSession
                    checkValidSession:
                        [[AuthManager sharedManager] getImapSession]];
              }
            } else {
              NSLog(@"Folder Expunged");
              /*
            // update UI
            NSMutableArray *msg =
                [NSMutableArray arrayWithArray:self.messages];
            [msg removeObjectAtIndex:index.row];
            self.messages = [NSArray arrayWithArray:msg];

            if (!isSearching) {
              [self.tableView
                  deleteRowsAtIndexPaths:[NSArray arrayWithObject:index]
                        withRowAnimation:UITableViewRowAnimationLeft];
            } else {
              [filterResult removeObjectAtIndex:index.row];
              [self.searchDisplayController.searchResultsTableView
                  deleteRowsAtIndexPaths:[NSArray arrayWithObject:index]
                        withRowAnimation:UITableViewRowAnimationLeft];
            }

            // delete & update NSUserDefault and Cache
            [self.cache setValue:msg forKey:self.folder];
            [self saveCustomObject:msg key:self.folder];
               */
            }
          }];
        } else {
          NSLog(@"Error with flag changing");
          [UIApplication sharedApplication].networkActivityIndicatorVisible =
              NO;
          if (error.code == 5) {
            [CheckValidSession
                checkValidSession:[[AuthManager sharedManager] getImapSession]];
          }
        }
      }];
    } else {
      NSLog(@"Message can not Copy");
      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }
    }
  }];
}

- (void)moveMessageWithIndexPaths:(NSArray *)indexPaths toFolder:(NSString *)dest {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    NSMutableArray *messageArray = [[NSMutableArray alloc] init];
    MCOIndexSet *mcoIndexSet = [[MCOIndexSet alloc] init];
    
    MCOIMAPMessage *message;
    
    for (NSIndexPath *indexPath in indexPaths) {
        [indexSet addIndex:indexPath.row];
        if (!isSearching) {
            message = self.messages[indexPath.row];
        } else {
            message = self.messages[[filterResult[indexPath.row] integerValue]];
        }
        [messageArray addObject:message];
        [mcoIndexSet addIndex:message.uid];
    }
    
    // update UI
    NSMutableArray *msg = [NSMutableArray arrayWithArray:self.messages];
    [msg removeObjectsAtIndexes:indexSet];
    self.messages = [NSArray arrayWithArray:msg];
    
    if (!isSearching) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationLeft];
    } else {
        [filterResult removeObjectsAtIndexes:indexSet];
        [self.searchBarDisplay.searchResultsTableView deleteRowsAtIndexPaths:indexPaths
                                                            withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    // delete & update NSUserDefault and Cache
    [self.cache setValue:msg forKey:self.folder];
    [self saveCustomObject:msg key:self.folder];
    
    MCOIMAPCopyMessagesOperation *op =
    [[[AuthManager sharedManager] getImapSession]
     copyMessagesOperationWithFolder:self.folder
     uids:mcoIndexSet
     destFolder:dest];
    [op start:^(NSError *error, NSDictionary *uidMapping) {
        
        if (!error) {
            MCOMessageFlag newflags = [message flags];
            newflags |= MCOMessageFlagDeleted;
            
            MCOIMAPOperation *changeFlags =
            [[[AuthManager sharedManager] getImapSession]
             storeFlagsOperationWithFolder:self.folder
             uids:mcoIndexSet
             kind:MCOIMAPStoreFlagsRequestKindSet
             flags:newflags];
            
            [changeFlags start:^(NSError *error) {
                if (!error) {
                    NSLog(@"Flag has been changed");
                    MCOIMAPOperation *expungeOp =
                    [[[AuthManager sharedManager] getImapSession]
                     expungeOperation:self.folder];
                    [expungeOp start:^(NSError *error) {
                        [UIApplication sharedApplication].networkActivityIndicatorVisible =
                        NO;
                        if (error) {
                            NSLog(@"Expunge Failed, %@", error.description);
                            if (error.code == 5) {
                                [CheckValidSession
                                 checkValidSession:
                                 [[AuthManager sharedManager] getImapSession]];
                            }
                        } else {
                            NSLog(@"Folder Expunged");
                            /*
                             // update UI
                             NSMutableArray *msg =
                             [NSMutableArray arrayWithArray:self.messages];
                             [msg removeObjectAtIndex:index.row];
                             self.messages = [NSArray arrayWithArray:msg];
                             
                             if (!isSearching) {
                             [self.tableView
                             deleteRowsAtIndexPaths:[NSArray arrayWithObject:index]
                             withRowAnimation:UITableViewRowAnimationLeft];
                             } else {
                             [filterResult removeObjectAtIndex:index.row];
                             [self.searchDisplayController.searchResultsTableView
                             deleteRowsAtIndexPaths:[NSArray arrayWithObject:index]
                             withRowAnimation:UITableViewRowAnimationLeft];
                             }
                             
                             // delete & update NSUserDefault and Cache
                             [self.cache setValue:msg forKey:self.folder];
                             [self saveCustomObject:msg key:self.folder];
                             */
                        }
                    }];
                } else {
                    NSLog(@"Error with flag changing");
                    [UIApplication sharedApplication].networkActivityIndicatorVisible =
                    NO;
                    if (error.code == 5) {
                        [CheckValidSession
                         checkValidSession:[[AuthManager sharedManager] getImapSession]];
                    }
                }
            }];
        } else {
            NSLog(@"Message can not Copy");
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if (error.code == 5) {
                [CheckValidSession
                 checkValidSession:[[AuthManager sharedManager] getImapSession]];
            }
        }
    }];
}

- (void)showMailActions:(MailActionCallback)callback {
  NSLog(@"CURRENT FOLDER %@", self.folder);
  NSLog(@"CURRENT TITLE FOLDER %@", self.title);

  actionCallback = callback;
  UIActionSheet *morePopup;

  if ([[self.folder uppercaseString] isEqualToString:@"ATTACHMENTS"]) {
    morePopup = [[UIActionSheet alloc]
                 initWithTitle:nil
                      delegate:self
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
        destructiveButtonTitle:nil
             otherButtonTitles:NSLocalizedString(@"Reply", nil),
                               NSLocalizedString(@"Forward", nil), nil];
  } else {
    morePopup = [[UIActionSheet alloc]
                 initWithTitle:nil
                      delegate:self
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
        destructiveButtonTitle:nil
             otherButtonTitles:NSLocalizedString(@"Reply", nil),
                               NSLocalizedString(@"Forward", nil),
                               NSLocalizedString(@"Junk", nil),
                               NSLocalizedString(@"MoveTo", nil),
                               NSLocalizedString(@"Edit", nil), nil];
  }
  [morePopup showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  actionCallback(buttonIndex == actionSheet.cancelButtonIndex,
                 buttonIndex == actionSheet.destructiveButtonIndex,
                 buttonIndex);
  actionCallback = nil;
}

- (NSString *)readButtonText:(BOOL)read {
  NSString *unseen =
      [NSString stringWithFormat:@"%@", NSLocalizedString(@"Unseen", nil)];
  NSString *seen =
      [NSString stringWithFormat:@"%@", NSLocalizedString(@"Seen", nil)];
  return read ? unseen : seen;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 85.0f;
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
  SEL selector = NSSelectorFromString(@"_alertController");
  if ([actionSheet respondsToSelector:selector]) {
    UIAlertController *alertController =
        [actionSheet valueForKey:@"_alertController"];
    if ([alertController isKindOfClass:[UIAlertController class]]) {
      NSArray *t = alertController.actions;
      UIAlertAction *spam = [t objectAtIndex:2];
      // alertController.view.tintColor = [UIColor blackColor];
    }
  } else { // iOS 7
    for (UIView *subview in actionSheet.subviews) {
      if ([subview isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)subview;
        [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
      }
    }
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

  MessageCell *cell = (MessageCell *)
      [self.tableView dequeueReusableCellWithIdentifier:@"MsgCell"];
  MCOIMAPMessage *message_atRow;
  if (isSearching) {
    if (indexPath.row < filterResult.count) {
      message_atRow = self.messages[[filterResult[indexPath.row] integerValue]];
      [cell setMessage:message_atRow];
    }
  } else {
    message_atRow = self.messages[indexPath.row];
    [cell setMessage:message_atRow];
  }

  // Turn off autolayout Storyboard
  CGFloat cellHeight = 85.0f;
  CGRect dateTextFrame =
      CGRectMake(self.view.frame.size.width - 150 - 10, 3, 150, 20);
  [cell.dateTextField setFrame:dateTextFrame];
  CGRect fromTextFrame = CGRectMake(
      75, 3, self.view.frame.size.width - dateTextFrame.size.width - 5, 20);
  [cell.fromTextField setFrame:fromTextFrame];

  if (cell.signIcon.alpha == 1) {
CGRect subjectTextFrame = CGRectMake(75, cellHeight / 2 - 20,
                                         self.view.frame.size.width - 45, 40);
    [cell.subjectTextField setFrame:subjectTextFrame];
    CGRect signIconFrame =
        CGRectMake(self.view.frame.size.width - 20 - 5, 23, 20, 20);
    [cell.signIcon setFrame:signIconFrame];
  } else {
    CGRect subjectTextFrame = CGRectMake(
        75, cellHeight / 2 - 20, self.view.frame.size.width - 20 - 10, 40);
    [cell.subjectTextField setFrame:subjectTextFrame];
    CGRect signIconFrame = CGRectMake(0, 0, 0, 0);
    [cell.signIcon setFrame:signIconFrame];
  }
  CGRect attachmentFrame = CGRectMake(75, cellHeight - 13 - 6, 12, 12);
  [cell.attachementIcon setFrame:attachmentFrame];
  CGRect attachmentTitle = CGRectMake(
      95, cellHeight - 13 - 10, self.view.frame.size.width - 20 - 20 - 10, 20);
  [cell.attachmentTextField setFrame:attachmentTitle];

  // READ, UNREAD, FLAG View
  UIImageView *indicatorView =
      [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  indicatorView.center =
      CGPointMake(10, cell.fromTextField.frame.origin.y + 20 / 2);
  indicatorView.backgroundColor = [UIColor whiteColor];

  // Update data
  if (IDIOM == IPHONE) {
    if (!(message_atRow.flags & MCOMessageFlagSeen) &&
        (message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView =
          [self updateCellIndicactor:UNREAD_FLAG cell:indicatorView];
      [cell.fromTextField setFont:[UIFont boldSystemFontOfSize:12.0f]];
      [cell.dateTextField setFont:[UIFont boldSystemFontOfSize:12.0f]];
      [cell.subjectTextField setFont:[UIFont boldSystemFontOfSize:15.0f]];
    } else if ((message_atRow.flags & MCOMessageFlagSeen) &&
               (message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView = [self updateCellIndicactor:FLAG cell:indicatorView];
      [cell.fromTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f]];
      [cell.dateTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f]];
      [cell.subjectTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
    } else if ((message_atRow.flags & MCOMessageFlagSeen) &&
               !(message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView = [self updateCellIndicactor:READ cell:indicatorView];
      [cell.fromTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f]];
      [cell.dateTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0f]];
      [cell.subjectTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
    } else if (!(message_atRow.flags & MCOMessageFlagSeen) &&
               !(message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView = [self updateCellIndicactor:UNREAD cell:indicatorView];
      [cell.fromTextField setFont:[UIFont boldSystemFontOfSize:12.0f]];
      [cell.dateTextField setFont:[UIFont boldSystemFontOfSize:12.0f]];
      [cell.subjectTextField setFont:[UIFont boldSystemFontOfSize:15.0f]];
    }
  } else {
    if (!(message_atRow.flags & MCOMessageFlagSeen) &&
        (message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView =
          [self updateCellIndicactor:UNREAD_FLAG cell:indicatorView];
      [cell.fromTextField setFont:[UIFont boldSystemFontOfSize:13.0f]];
      [cell.dateTextField setFont:[UIFont boldSystemFontOfSize:13.0f]];
      [cell.subjectTextField setFont:[UIFont boldSystemFontOfSize:14.0f]];
    } else if ((message_atRow.flags & MCOMessageFlagSeen) &&
               (message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView = [self updateCellIndicactor:FLAG cell:indicatorView];
      [cell.fromTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
      [cell.dateTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
      [cell.subjectTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f]];
    } else if ((message_atRow.flags & MCOMessageFlagSeen) &&
               !(message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView = [self updateCellIndicactor:READ cell:indicatorView];
      [cell.fromTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
      [cell.dateTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
      [cell.subjectTextField
          setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f]];
    } else if (!(message_atRow.flags & MCOMessageFlagSeen) &&
               !(message_atRow.flags & MCOMessageFlagFlagged)) {
      indicatorView = [self updateCellIndicactor:UNREAD cell:indicatorView];
      [cell.fromTextField setFont:[UIFont boldSystemFontOfSize:13.0f]];
      [cell.dateTextField setFont:[UIFont boldSystemFontOfSize:13.0f]];
      [cell.subjectTextField setFont:[UIFont boldSystemFontOfSize:14.0f]];
    }
  }
  cell.delegate = self;
  cell.dateTextField.textAlignment = NSTextAlignmentRight;
  [cell.contentView addSubview:indicatorView];
  return cell;
}

- (UIImageView *)updateCellIndicactor:(int)type cell:(UIImageView *)indicator {
  if (type == UNREAD_FLAG) {
    indicator.image = [UIImage imageNamed:@"mix_dot_unread_flag.png"];
  } else if (type == FLAG) {
    indicator.image = [UIImage imageNamed:@"yellow_dot_flag.png"];
  } else if (type == READ) {
    indicator.image = [UIImage imageNamed:@"blank"];
  } else {
    indicator.image = [UIImage imageNamed:@"blue_dot_unread.png"];
  }
  return indicator;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        if (!self.moreToolBarButton.isEnabled) {
            self.moreToolBarButton.enabled = YES;
        }
        if (!self.deleteToolbarButton.isEnabled) {
            self.deleteToolbarButton.enabled = YES;
        }
    } else {
        [self selectRowAtIndexPath:indexPath.row];
        
        if (IDIOM == IPHONE && isSearching) {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        } else {
            [self.view endEditing:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.isEditing) {
        NSArray *selectedRows = tableView.indexPathsForSelectedRows;
        if (selectedRows.count == 0) {
            self.moreToolBarButton.enabled = NO;
            self.deleteToolbarButton.enabled = NO;
        }
    }
}

- (void)selectRowAtIndexPath:(NSInteger)index {
  [self hideLeftView:nil];

  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];

  /* Refresh lại table để deselect row đối với trường hợp:
   - Nhấn vào thư khi ở trong form tìm kiếm
   - Nhấn vào thư khi ở trong form danh sách thư và thiết bị là iPhone
   */

  if (IDIOM == IPHONE && isSearching) {
    [self.searchDisplayController.searchResultsTableView
        deselectRowAtIndexPath:indexPath
                      animated:YES];
  } else if (IDIOM == IPHONE && !isSearching) {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  }

  NSString *folder = self.folder;
  if ([self.folder isEqualToString:@"ATTACHMENTS"]) {
    folder = self.folderParent;
  }
  MCOIMAPMessage *msg;
  if (isSearching) {
    msg = self.messages[[filterResult[index] integerValue]];
  } else {
    msg = self.messages[index];
  }

  // Unread -> read; Kiểm tra thư chưa đọc để kích hoạt tự động
  MCOMessageFlag newFlags = msg.flags;
  if (!(newFlags & MCOMessageFlagSeen)) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    flagUnSeen = YES;
    MCOIMAPOperation *msgOperation = [
        [[AuthManager sharedManager] getImapSession]
        storeFlagsOperationWithFolder:self.folder
                                 uids:[MCOIndexSet indexSetWithIndex:msg.uid]
                                 kind:MCOIMAPStoreFlagsRequestKindAdd
                                flags:MCOMessageFlagSeen];
    if (!isSearching) {
      [self.messages[index] setFlags:MCOMessageFlagSeen];
    } else {
      [self.messages[[filterResult[index] integerValue]]
          setFlags:MCOMessageFlagSeen];
    }
    [msgOperation start:^(NSError *error) {
      NSLog(@"Update flag done!");
      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }
    }];
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 0.7 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
          if (!isSearching) {
            [self.tableView reloadData];
            // Thiết bị là Ipad thì select lại row vừa nhấn vào
            if (IDIOM == IPAD) {
              [self.tableView
                  selectRowAtIndexPath:indexPath
                              animated:NO
                        scrollPosition:UITableViewScrollPositionNone];
            }
          } else {
            [self.searchDisplayController.searchResultsTableView reloadData];
          }

        });
  } else {
    flagUnSeen = NO;
  }

  // Open new view; parse orgMsg to activation code
  orgMsg = msg;
  if (IDIOM == IPAD) {
    self.detailViewController.folder = folder;
    self.detailViewController.message = msg;
    self.detailViewController.session =
        [[AuthManager sharedManager] getImapSession];
    self.detailViewController.delegate = self;
    [self.detailViewController viewDidLoad];
  } else {
    UINavigationController *navigationController = [self.storyboard
        instantiateViewControllerWithIdentifier:@"details_navi"];
    MessageDetailViewController_iPhone *home =
        navigationController.viewControllers[0];
    home.folder = folder;
    home.message = msg;
    home.session = [[AuthManager sharedManager] getImapSession];
    home.delegate = self;
    [self presentViewController:navigationController
                       animated:YES
                     completion:nil];
  }
}

+ (MCOIMAPMessage *)shareOrgMsg {
  return orgMsg;
}

#pragma mark MenuViewDelegate
- (void)loadMailFolder:(NSString *)folderPath withHR:(NSString *)name {

  // Tải email trước từ NSUserDefault
  NSString *key = [folderPath stringByAppendingString:selectedAccName];
  NSArray *cachedMes = [self loadCustomObjectWithKey:key];
  if (cachedMes && ![name isEqualToString:@"Attachments"]) {
    self.messages = cachedMes;
    [self.tableView reloadData];
  } else {
    [self.tableView
        setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height -
                                            self.searchBar.frame.size.height)
                animated:YES];
    [self.searchBar setFrame:CGRectMake(0, 0, 320, 44)];
    if (!self.refreshControl.isRefreshing) {
      [self.refreshControl beginRefreshing];
    }
  }

  if ([name isEqualToString:@"Inbox"]) {
    currentMailbox.text = self.title = NSLocalizedString(@"Inbox", nil);
  }
  if ([name isEqualToString:@"Attachments"]) {
    currentMailbox.text = self.title = NSLocalizedString(@"Attachments", nil);
  }
  if ([name isEqualToString:@"Sent"]) {
    currentMailbox.text = self.title = NSLocalizedString(@"Sent", nil);
  }
  if ([name isEqualToString:@"All Mail"]) {
    currentMailbox.text = self.title = NSLocalizedString(@"AllMail", nil);
  }
  if ([name isEqualToString:@"Spam"]) {
    currentMailbox.text = self.title = NSLocalizedString(@"Spam", nil);
  }
  if ([name isEqualToString:@"Trash"]) {
    currentMailbox.text = self.title = NSLocalizedString(@"Trash", nil);
  }
  if ([name isEqualToString:@"Attachments"]) {
    self.folder = @"ATTACHMENTS";
    self.folderParent = folderPath;
  } else {
    self.folder = folderPath;
  }
  if (numberMSM <= 30) {
    numberMSM = 30;
  }
  [self loadEmailsWithCache:NO];
}

- (void)loadFolderIntoCache:(NSString *)imapPath {

  if (![[AuthManager sharedManager] getImapSession]) {
    return;
  }

  NSString *folderName = imapPath;
  if ([folderName isEqualToString:@"Attachments"]) {
    folderName = @"ATTACHMENTS";
  }
  NSLog(@"Loading Folder: %@", folderName);

  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

  NSArray *lookup = [self.cache objectForKey:folderName];
  if (lookup) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    return;
  }

  void (^completionNoLoad)(NSError *, NSArray *, MCOIndexSet *) =
      ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {

        if (!error) {
          NSLog(@"CACHE WARM: %@", folderName);
          [self.cache setValue:messages forKey:folderName];
          [self saveCustomObject:messages key:folderName];
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        if (error.code == 5) {
          [CheckValidSession
              checkValidSession:[[AuthManager sharedManager] getImapSession]];
        }
      };
  [self loadEmailsFromFolder:folderName WithCompletion:completionNoLoad];
}

- (void)viewDidAppear:(BOOL)animated {

  if (!isSearching) {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  }

  CheckNetWork *initCheck = [[CheckNetWork alloc] init];
  if ([initCheck checkNetworkAvailable]) {
    [self HaveInternet];
  } else {
    [self Internet_warning];
  }

// HoangTD edit
//  [self checkProtected];
}

// HoangTD edit
//- (void)checkProtected {
//  // Kiểm tra mật khẩu bảo vệ Mail
//  NSString *accIndex =
//      [[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"];
//  NSMutableArray *listAccount =
//      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
//  if (accIndex != nil && !isSearching) {
//    mailtype = [[[NSUserDefaults standardUserDefaults]
//        objectForKey:@"mailtype"] integerValue];
//    username = [listAccount objectAtIndex:([accIndex intValue] + 1)];
//    selectedAccName = username;
//
//    currentUserEmail.text = selectedAccName;
//
//    NSArray *protectInfo =
//        [[DBManager getSharedInstance] findProtected:username];
//    if (protectInfo) {
//      NSString *protectType =
//          [[[DBManager getSharedInstance] findProtected:username]
//              objectAtIndex:0];
//      if ([protectType isEqualToString:@"0"] || unlockMail || !protectType) {
//        NSLog(@"Load Emails with Cache");
//        //[self loadEmailsWithCache:NO];
//      } else if ([protectType isEqualToString:@"1"] && !unlockMail) {
//        [self showProtectAlertView:1 message:0];
//      } else if ([protectType isEqualToString:@"2"] && !unlockMail) {
//        [self showProtectAlertView:2 message:0];
//      }
//      unlockMail = NO;
//    } else {
//      // Ha
//      //[self loadEmailsWithCache:NO];
//    }
//  }
//}

- (void)clearMessages {
  self.detailViewController.folder = self.folder;
  self.detailViewController.message = nil;
  self.detailViewController.session =
      [[AuthManager sharedManager] getImapSession];
  self.detailViewController.delegate = self;
  [self.detailViewController viewDidLoad];
  self.messages = @[];
  [self.cache removeAllObjects];
  [self.tableView reloadData];
  self.folder = @"INBOX";
}

- (void)reloadMessage {
  if (numberMSM <= 30) {
    numberMSM = 30;
  }

  [self.searchBar setFrame:CGRectMake(0, 0, 320, 44)];

  // Xoá dữ liệu gốc từ tài khoản cũ
  self.messages = @[];
  self.folder = @"INBOX";
  [self.cache removeAllObjects];
  currentMailbox.text = self.title = NSLocalizedString(@"Inbox", nil);

  // Reload lại bảng để kéo searchBar và refreshControl về đầu
  [self.tableView reloadData];

//  HoangTD edit
//  // Kiểm tra bảo vệ mật khẩu
//  [self checkProtected];

  if (IDIOM == IPAD) {
    self.detailViewController.folder = nil;
    self.detailViewController.message = nil;
    self.detailViewController.session =
        [[AuthManager sharedManager] getImapSession];
    self.detailViewController.delegate = self;
    [self.detailViewController viewDidLoad];
  }

  [self.tableView reloadData];
}

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {

  if (alertView.tag == checkInternet) {
    CheckNetWork *init = [[CheckNetWork alloc] init];
    if (![init checkNetworkAvailable]) {
      if (buttonIndex == alertView.cancelButtonIndex) {
        UIAlertView *alertView = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"Error", nil)
                      message:NSLocalizedString(@"CheckInternet", nil)
                     delegate:self
            cancelButtonTitle:NSLocalizedString(@"Ok", nil)
            otherButtonTitles:nil];
        [alertView show];
      }
    } else {
      [[AuthManager sharedManager] logout];
      [[AuthManager sharedManager] refresh_logout];
    }
  }
}

- (void)passDestFolderName:(MoveToMailboxes *)controller
     didFinishEnteringItem:(NSString *)destFolder
                   message:(NSIndexPath *)index {
  if (index && destFolder) {
    NSLog(@"Selected %@", destFolder);
    [self moveMessageWithUID:index toFolder:destFolder];
  }
}

- (void)moveMultipleMail:(MoveToMailboxes *)controller
     didFinishEnteringItem:(NSString *)destFolder
                   message:(NSArray *)indexPaths {
    if (indexPaths != nil && indexPaths.count > 0 && destFolder) {
        [self moveMessageWithIndexPaths:indexPaths toFolder:destFolder];
    }
}

- (void)didRotateFromInterfaceOrientation:
    (UIInterfaceOrientation)fromInterfaceOrientation {
  [label setFrame:CGRectMake(0, self.navigationController.navigationBar.frame
                                    .size.height,
                             self.view.frame.size.width, 20)];

  CGRect frame = self.view.frame;
  if (self.splitViewController) {
    frame = [[
        [self.splitViewController.viewControllers objectAtIndex:0] view] frame];
  }

  if (pullToRefreshManager_)
    pullToRefreshManager_ = NULL;

  pullToRefreshManager_ = [[MNMBottomPullToRefreshManager alloc]
      initWithPullToRefreshViewHeight:
                                60.0f:frame.size.width
                            tableView:self.tableView
                           withClient:self];
}

- (void)willAnimateRotationToInterfaceOrientation:
            (UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
  if (!isSearching) {
    [self.tableView reloadData];
  } else {
    [self.searchDisplayController.searchResultsTableView reloadData];
  }
}

- (void)moreAction:(int)actionIndex indexPath:(NSIndexPath *)indexPath {

  // hud
  MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
  hud.labelText = NSLocalizedString(@"PleaseWait", nil);
  NSString *type;
  MCOIMAPMessage *msg = self.messages[indexPath.row];

  // reply, forward
  if (actionIndex == 0) {
    type = @"Trả lời";
  } else if (actionIndex == 1) {
    type = @"Chuyển tiếp";
  }
  MCOIMAPFetchContentOperation *op =
      [[[AuthManager sharedManager] getImapSession]
          fetchMessageByUIDOperationWithFolder:self.folder
                                           uid:[msg uid]];
  [op start:^(NSError *error, NSData *data) {
    if (error || !data) {
      NSLog(@"Error:%@ %@", error, data);
      if (error.code == 5) {
        [CheckValidSession
            checkValidSession:[[AuthManager sharedManager] getImapSession]];
      }
      return;
    }
    MCOMessageParser *parser = [[MCOMessageParser alloc] initWithData:data];

    NSString *strBody = [parser htmlRenderingWithDelegate:self];

    strBody = [[strBody mco_flattenHTML]
        stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSMutableArray *delayedAttachments;

    if (actionIndex == 1) {
      delayedAttachments =
          [[NSMutableArray alloc] initWithArray:[parser attachments]];
      NSMutableArray *discardedItems = [NSMutableArray array];
      for (int i = 0; i < delayedAttachments.count; i++) {
        MCOAttachment *attachment = [delayedAttachments objectAtIndex:i];
        if ([[attachment filename] isEqualToString:@"smime.p7s"] ||
            [[attachment filename] isEqualToString:@"smime.p7m"]) {
          [discardedItems addObject:attachment];
        }
        [delayedAttachments removeObjectsInArray:discardedItems];
      }

    } else {
      delayedAttachments = [[NSMutableArray alloc] init];
    }
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    if (IDIOM == IPAD) {
      ComposerViewController *vc =
          [[ComposerViewController alloc] initWithMessage:msg
                                                   ofType:type
                                                  content:strBody
                                              attachments:@[]
                                       delayedAttachments:delayedAttachments];
      UINavigationController *nc =
          [[UINavigationController alloc] initWithRootViewController:vc];
      nc.modalPresentationStyle = UIModalPresentationPageSheet;
      [self presentViewController:nc animated:YES completion:nil];
    } else {
      Composer_iPhoneViewController *vc = [[Composer_iPhoneViewController alloc]
             initWithMessage:msg
                      ofType:type
                     content:strBody
                 attachments:@[]
          delayedAttachments:delayedAttachments];
      UINavigationController *nc =
          [[UINavigationController alloc] initWithRootViewController:vc];
      nc.modalPresentationStyle = UIModalPresentationPageSheet;
      [self presentViewController:nc animated:YES completion:nil];
    }
  }];
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex
                             animated:(BOOL)animated {
}

- (void)searchTableList {
  NSString *searchString = self.searchBar.text;
  for (int i = 0; i < sourceSearchArray.count; i++) {
    NSRange foundRange = [[sourceSearchArray objectAtIndex:i]
        rangeOfString:searchString
              options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
                range:NSMakeRange(
                          0, [[sourceSearchArray objectAtIndex:i] length] - 1)];
    if (foundRange.length > 0) {
      [filterResult addObject:[NSString stringWithFormat:@"%d", i]];
    }
  }
}

#pragma mark - Search Implementation

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  if (IDIOM == IPHONE) {
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  }
  isSearching = NO;
}

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText {
  // Remove all objects first.
  [filterResult removeAllObjects];
  if ([searchText length] != 0) {
    isSearching = YES;
    [self searchTableList];
  } else {
    isSearching = NO;
  }
}

- (void)loadValueToSearchArray:(NSArray *)messageArray {
  [sourceSearchArray removeAllObjects];
  for (MCOIMAPMessage *tempMessage in messageArray) {

    NSArray *atts = tempMessage.attachments;
    NSString *attachmentsName = @"";
    if (atts.count > 0) {
      for (MCOAbstractPart *attpart in atts) {
        attachmentsName = [NSString
            stringWithFormat:@"%@,%@,", attachmentsName, attpart.filename];
      }
    }
    NSDate *date = tempMessage.header.date;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd"];
    NSString *stringday = [dateFormatter stringFromDate:date];
    [dateFormatter setDateFormat:@"MM"];
    NSString *stringmonth = [dateFormatter stringFromDate:date];
    [dateFormatter setDateFormat:@"yyyy"];
    NSString *stringyear = [dateFormatter stringFromDate:date];
    [sourceSearchArray
        addObject:[NSString
                      stringWithFormat:@"%@,%@,%@,%@/%@/%@,%@",
                                       tempMessage.header.from.displayName,
                                       tempMessage.header.subject,
                                       tempMessage.header.sender.mailbox,
                                       stringday, stringmonth, stringyear,
                                       attachmentsName]];
  }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
  isSearching = NO;
  dispatch_async(dispatch_get_main_queue(), ^{
    [UIView transitionWithView:self.view
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      label.alpha = 0;
                    }
                    completion:nil];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    [self.tableView reloadData];
  });
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  [self searchTableList];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.view endEditing:YES];
    [UIView transitionWithView:self.view
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      label.alpha = 0;
                    }
                    completion:nil];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  });
}

// Bắt đầu tìm kiếm, load dữ liệu vào mảng tìm kiếm
- (void)searchDisplayControllerWillBeginSearch:
    (UISearchDisplayController *)controller {
  self.navigationController.navigationBar.translucent = YES;
  [self loadValueToSearchArray:self.messages];
}

// Kết thúc tìm kiếm, giải phóng dữ liệu khỏi mảng tìm kiếm
- (void)searchDisplayControllerDidEndSearch:
    (UISearchDisplayController *)controller {
  self.navigationController.navigationBar.translucent = NO;
  [sourceSearchArray removeAllObjects];
}

- (BOOL)checkNetworkAvaiable {
  CheckNetWork *init = [[CheckNetWork alloc] init];
  if ([init checkNetworkAvailable]) {
    return YES;
  } else {
    return NO;
  }
}

- (void)showEdittingMode:(BOOL)editting {
    if (editting) {
        [self setLeftCancelBarButton];
    } else {
        [self setLeftMenuBarButton];
    }
    [self.tableView setEditing:editting animated:YES];
    [self.navigationController setToolbarHidden:!editting animated:YES];
}

- (IBAction)deleteToolbarButtonClicked:(id)sender {
    NSArray *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
    if (selectedIndexPaths != nil && selectedIndexPaths.count > 0) {
        [self deleteMessageAtIndexPaths:selectedIndexPaths];
    }
}

- (IBAction)moreToolbarButtonClicked:(id)sender {
    [self showMoreActions:^(BOOL cancelled, BOOL deleted, NSInteger actionIndex) {
        if (cancelled) {
            return;
        } else if (actionIndex == 0) {
            NSString *spamFolder = [[ListAllFolders shareFolderNames]
                                    objectForKey:@"Spam"];
            NSArray *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
            if (selectedIndexPaths != nil && selectedIndexPaths.count > 0) {
                [self moveMessageWithIndexPaths:selectedIndexPaths toFolder:spamFolder];
            }
        } else if (actionIndex == 1) {
            NSLog(@"Move to ...");
            NSArray *selectedIndexPaths = self.tableView.indexPathsForSelectedRows;
            
            if (selectedIndexPaths != nil && selectedIndexPaths.count > 0) {
            
                MCOIMAPMessage *message;
                if (!isSearching) {
                    message = self.messages[0];
                } else {
                    message = self.messages[[filterResult[0] integerValue]];
                }
                
                MoveToMailboxes *move = [[MoveToMailboxes alloc] init];
                move.delegate = self;
                move.fromFolder = self.title;
                move.indexPaths = selectedIndexPaths;
                NSString *from = message.header.from.displayName
                ? message.header.from.displayName
                : message.header.from.mailbox;
                NSString *subject =
                message.header.subject
                ? message.header.subject
                : NSLocalizedString(@"NoSubject", nil);
                move.title = NSLocalizedString(@"MoveToFolders", nil);
                move.content =
                [NSString stringWithFormat:@"%@\n%@", from, subject];
                FixedNavigationController *nav =
                [[FixedNavigationController alloc]
                 initWithRootViewController:move];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self presentViewController:nav
                                       animated:YES
                                     completion:nil];
                }];
            }
        }
        [self showEdittingMode:NO];
    }];
}

- (void)showMoreActions:(MailActionCallback)callback {
    actionCallback = callback;
    UIActionSheet *morePopup = [[UIActionSheet alloc]
                                initWithTitle:nil
                                delegate:self
                                cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                destructiveButtonTitle:nil
                                otherButtonTitles:NSLocalizedString(@"Junk", nil),
                                NSLocalizedString(@"MoveTo", nil), nil];
    [morePopup showInView:self.view];
}

- (void)deleteMessageAtIndexPaths:(NSArray *)indexPaths {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    NSMutableArray *selectedMessages = [[NSMutableArray alloc] init];
    MCOIndexSet *mcoIndexSet = [[MCOIndexSet alloc] init];
    
    MCOIMAPMessage *message;
    
    for (NSIndexPath *indexPath in indexPaths) {
        [indexSet addIndex:indexPath.row];
        if (!isSearching) {
            message = self.messages[indexPath.row];
        } else {
            message = self.messages[[filterResult[indexPath.row] integerValue]];
        }
        [selectedMessages addObject:message];
        [mcoIndexSet addIndex:message.uid];
    }
    
    /* delete MCO operation */
    if ([[MenuViewController sharedFolderName]
         isEqualToString:@"Trash"]) {
        
        /* From trash */
//        [self deleteFromTrash:msgUID rowIndexPath:cellIndexPath];
        [self deleteFromTrash:mcoIndexSet indexSet:indexSet indexPaths:indexPaths selectedMessages:selectedMessages];
        
    } else {
        /* From other mailboxes */
        
        // delete MCO Operation
        NSString *trash = [[ListAllFolders shareFolderNames]
                           objectForKey:@"Trash"];
        MCOIMAPCopyMessagesOperation *opC =
        [[[AuthManager sharedManager] getImapSession]
         copyMessagesOperationWithFolder:
         self.folder uids:mcoIndexSet
         destFolder:trash];
        [opC start:^(NSError *error, NSDictionary *uidMapping) {
            NSLog(@"Yahoo & Outlook... Trash with UID mapping %@",
                  uidMapping);
            if (error) {
                NSLog(@"error delete: %@", error.description);
                if (error.code == 5) {
                    [CheckValidSession
                     checkValidSession:
                     [[AuthManager sharedManager] getImapSession]];
                }
            }
            
        }];
        MCOIMAPOperation *op = [
                                [[AuthManager sharedManager] getImapSession]
                                storeFlagsOperationWithFolder:
                                self.folder uids:mcoIndexSet
                                kind:
                                MCOIMAPStoreFlagsRequestKindSet
                                flags:MCOMessageFlagDeleted];
        [op start:^(NSError *error) {
            if (error) {
                NSLog(@"Error updating flags:%@", error);
                if (error.code == 5) {
                    [CheckValidSession
                     checkValidSession:
                     [[AuthManager sharedManager] getImapSession]];
                }
                
                [UIApplication sharedApplication]
                .networkActivityIndicatorVisible = NO;
                
                return;
            }
            MCOIMAPOperation *deleteOp =
            [[[AuthManager sharedManager] getImapSession]
             expungeOperation:self.folder];
            [deleteOp start:^(NSError *error) {
                [UIApplication sharedApplication]
                .networkActivityIndicatorVisible = NO;
                if (!error) {
//                    if (IDIOM == IPAD && row != 0) {
//                        [self selectRowAtIndexPath:row];
//                    }
                    NSLog(@"Email has been deleted");
                } else {
                    NSLog(@"Error expunging folder:%@", error);
                    if (error.code == 5) {
                        [CheckValidSession
                         checkValidSession:
                         [[AuthManager
                           sharedManager] getImapSession]];
                    }
                }
            }];
        }];
        
        // update UI
        dispatch_after(
                       dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC),
                       dispatch_get_main_queue(), ^{
                           NSMutableArray *msg =
                           [NSMutableArray arrayWithArray:self.messages];
                           if (!isSearching) {
                               [msg removeObjectsAtIndexes:indexSet];
                               self.messages = [NSArray arrayWithArray:msg];
                               [self.tableView
                                deleteRowsAtIndexPaths:indexPaths
                                withRowAnimation:
                                UITableViewRowAnimationLeft];
                           } else {
                               [filterResult removeObjectsAtIndexes:indexSet];
                               [self.searchBarDisplay.searchResultsTableView
                                deleteRowsAtIndexPaths:indexPaths
                                withRowAnimation:
                                UITableViewRowAnimationLeft];
                           }
        
                           // delete & update NSUserDefault and Cache
                           [self deleteMailData:[NSArray arrayWithArray:selectedMessages]];
                           [self.cache setValue:msg forKey:self.folder];
                           [self saveCustomObject:msg key:self.folder];
                       });
    }
}

- (void)deleteMailData:(NSArray *)selectedMessages {
    for (MCOIMAPMessage *message in selectedMessages) {
        NSString *s_uid = [NSString
                           stringWithFormat:@"%lu", (unsigned long)message.uid];
        NSString *key =
        [NSString stringWithFormat:@"%@%@%@", username,
         _folder, s_uid];
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey:key];
    }
}

@end
