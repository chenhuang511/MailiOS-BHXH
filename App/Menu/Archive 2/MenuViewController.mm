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
#import "ATConnect.h"
#import "AppDelegate.h"
#import "MsgListViewController.h"
#import "CheckNetWork.h"
#import "MBProgressHUD.h"

#import "DBManager.h"
#import "TokenType.h"

#import "HardTokenMethod.h"
#import "MsgListViewController.h"

#define TokenSetting 0
#define Logout 1
#define passwordHT 2
bool firstLoad = YES;
NSString *folderName;

NSMutableArray *listAccount;
NSInteger accIndex;

@interface MenuViewController ()

@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) NSArray* contents;
@property (nonatomic) bool firstLoad;
@end

@implementation MenuViewController
@synthesize folderNameLookup;
@synthesize mainItemsAmt, subItemsAmt, groupCell;
@synthesize delegate;

+ (NSString*)sharedFolderName {
    return folderName;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        NSString *type= [[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"];
        if ([type isEqual:@"1"]) {
            folderNameLookup = @{@"Inbox": @"INBOX",
                                 @"Sent": @"Th&AbA- &AREA4w- g&Hu0-i",
                                 @"All Mail": @"INBOX",
                                 @"Starred": @"Notes",
                                 @"Trash": @"Trash"
                                 };
        }
        else if([type isEqual:@"2"]){
            folderNameLookup = @{@"Inbox": @"INBOX",
                                 @"Sent": @"[Gmail]/Sent Mail",
                                 @"All Mail": @"[Gmail]/All Mail",
                                 @"Starred": @"[Gmail]/Starred",
                                 @"Trash": @"[Gmail]/Bin"
                                 };}
        
        else if([type isEqual:@"3"]){
            folderNameLookup = @{@"Inbox": @"INBOX",
                                 @"Sent": @"Sent",
                                 @"All Mail": @"INBOX",
                                 @"Starred": @"INBOX",
                                 @"Trash": @"Trash"
                                 };}
        else if([type isEqual:@"4"]){
            folderNameLookup = @{@"Inbox": @"INBOX",
                                 @"Sent": @"Sent",
                                 @"All Mail": @"INBOX",
                                 @"Starred": @"INBOX",
                                 @"Trash": @"Trash"
                                 };}
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.separatorColor = [UIColor clearColor];
    
    [self setTableContents];
    [self.tableView setBackgroundView:nil];
    self.tableView.backgroundColor = [UIColor colorFromHexCode:@"363636"];
    
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (sysVer > 7.0) {
        [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, 0)];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadMenu) name:@"reloadMenu" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    
    if (firstLoad) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
        
        MCOIMAPFetchFoldersOperation *fetchFolders = [[[AuthManager sharedManager] getImapSession]  fetchAllFoldersOperation];
        [fetchFolders start:^(NSError *error, NSArray *folders) {
            
            if (error){
                firstLoad = YES;
            }
            
            NSInteger type = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"] integerValue] ;
            switch (type) {
                case 1:
                    folderNameLookup = @{@"Inbox": @"INBOX",
                                         @"Sent": @"Th&AbA- &AREA4w- g&Hu0-i",
                                         @"All Mail": @"INBOX",
                                         @"Starred": @"Notes",
                                         @"Trash": @"Th&APk-ng r&AOE-c"
                                         };
                    break;
                case 2:
                {
                    NSMutableDictionary *updatedFolderNames = [[NSMutableDictionary alloc] initWithDictionary:folderNameLookup];
                    for (MCOIMAPFolder *f in folders) {
                        if (f.flags == MCOIMAPFolderFlagAll) {
                            [updatedFolderNames setObject:f.path forKey:@"All Mail"];
                            [self.delegate setFolderParent:f.path];
                        } else if (f.flags& MCOIMAPFolderFlagInbox){
                            [updatedFolderNames setObject:f.path forKey:@"Inbox"];
                        } else if (f.flags& MCOIMAPFolderFlagSentMail){
                            [updatedFolderNames setObject:f.path forKey:@"Sent"];
                        } else if (f.flags & MCOIMAPFolderFlagStarred){
                            [updatedFolderNames setObject:f.path forKey:@"Starred"];
                        } else if (f.flags & MCOIMAPFolderFlagTrash) {
                            [updatedFolderNames setObject:f.path forKey:@"Trash"];
                        }
                    }
                    folderNameLookup = [NSDictionary dictionaryWithDictionary:updatedFolderNames];
                    NSLog(@"New dictionary: %@", updatedFolderNames);
                }
                    break;
                case 3:
                    folderNameLookup = @{@"Inbox": @"INBOX",
                                         @"Sent": @"Sent",
                                         @"All Mail": @"INBOX",
                                         @"Starred": @"INBOX",
                                         @"Trash": @"Trash"
                                         };
                    break;
                case 4:
                    folderNameLookup = @{@"Inbox": @"INBOX",
                                         @"Sent": @"Sent",
                                         @"All Mail": @"INBOX",
                                         @"Starred": @"INBOX",
                                         @"Trash": @"Trash"
                                         };
                    break;
                    
                default:
                    break;
            }
            
            for (NSString* HRName in self.contents){
                if ([HRName isEqualToString:@"Attachments"]){
                    [[self delegate] loadFolderIntoCache:HRName];
                } else {
                    if (![HRName isEqualToString:@"Setting"] && ![HRName isEqualToString:@"Logout"]) {
                        [[self delegate] loadFolderIntoCache:[self pathFromName:HRName]];
                    }
                }
            }
            
        }];
        firstLoad = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    listAccount =  [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    accIndex =  [[[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"] integerValue];
}

- (void) loadFolderIntoCacheMenu {
    if (firstLoad) {
        
        NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
        
        MCOIMAPFetchFoldersOperation *fetchFolders = [[[AuthManager sharedManager] getImapSession]  fetchAllFoldersOperation];
        [fetchFolders start:^(NSError *error, NSArray *folders) {
            
            if (error){
                firstLoad = YES;
            }
            
            NSInteger type = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"] integerValue] ;
            switch (type) {
                case 1:
                    folderNameLookup = @{@"Inbox": @"INBOX",
                                         @"Sent": @"Th&AbA- &AREA4w- g&Hu0-i",
                                         @"All Mail": @"INBOX",
                                         @"Starred": @"Notes"
                                         };
                    break;
                case 2:
                {
                    NSMutableDictionary *updatedFolderNames = [[NSMutableDictionary alloc] initWithDictionary:folderNameLookup];
                    for (MCOIMAPFolder *f in folders){
                        NSLog(@"Path : %@",f.path);
                        NSLog(@"Flag : %u",f.flags);
                        if (f.flags == MCOIMAPFolderFlagAll){
                            [updatedFolderNames setObject:f.path forKey:@"All Mail"];
                            [self.delegate setFolderParent:f.path];
                        } else if (f.flags& MCOIMAPFolderFlagInbox){
                            [updatedFolderNames setObject:f.path forKey:@"Inbox"];
                        } else if (f.flags& MCOIMAPFolderFlagSentMail){
                            [updatedFolderNames setObject:f.path forKey:@"Sent"];
                        } else if (f.flags & MCOIMAPFolderFlagStarred){
                            [updatedFolderNames setObject:f.path forKey:@"Starred"];
                        } else if (f.flags & MCOIMAPFolderFlagTrash) {
                            [updatedFolderNames setObject:f.path forKey:@"Trash"];
                        }
                        
                    }
                    folderNameLookup = [NSDictionary dictionaryWithDictionary:updatedFolderNames];
                    NSLog(@"New dictionary: %@", updatedFolderNames);
                }
                    break;
                case 3:
                    folderNameLookup = @{@"Inbox": @"INBOX",
                                         @"Sent": @"Sent",
                                         @"All Mail": @"INBOX",
                                         @"Starred": @"INBOX"
                                         };
                    break;
                case 4:
                    folderNameLookup = @{@"Inbox": @"INBOX",
                                         @"Sent": @"INBOX",
                                         @"All Mail": @"INBOX",
                                         @"Starred": @"INBOX"
                                         };
                    break;
                    
                default:
                    break;
            }
            
            for (NSString* HRName in self.contents){
                if ([HRName isEqualToString:@"Attachments"]){
                    [[self delegate] loadFolderIntoCache: HRName];
                } else {
                    if (![HRName isEqualToString:@"Setting"] && ![HRName isEqualToString:@"Logout"]) {
                        [[self delegate] loadFolderIntoCache:[self pathFromName: HRName]];
                    }
                }
            }
            
        }];
        firstLoad = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTableContents {
    
    //TODO: HACK: NOTE: So Gmail allows you to turn on if folders show up or not in imap, so
    //some of these folders might not actually exist...
    self.contents = @[@"Inbox",@"Inbox", @"Attachments", @"Sent", @"All Mail", @"Starred", @"Trash", @"Logout", @"Setting"];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 9;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row == 0 ) {
        SDGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupCell"];
        
        [[NSBundle mainBundle] loadNibNamed:[self nibNameForMainCell] owner:self options:nil];
        cell = groupCell;
        //self.groupCell = nil;
        
        [cell setParentTable: self];
        [cell setCellIndexPath:indexPath];
        cell = [self mainTable:tableView setItem:cell forRowAtIndexPath:indexPath];
        NSNumber *amt = [NSNumber numberWithInt:[self mainTable:tableView numberOfSubItemsforItem:cell atIndexPath:indexPath]];
        [subItemsAmt setObject:amt forKey:indexPath];
        
        [cell setSubCellsAmt: [[subItemsAmt objectForKey:indexPath] intValue]];
        BOOL isExpanded = [[expandedIndexes objectForKey:indexPath] boolValue];
        cell.isExpanded = isExpanded;
        if(cell.isExpanded)
        {
            [cell rotateExpandBtnToExpanded];
        }
        else
        {
            [cell rotateExpandBtnToCollapsed];
        }
        [cell.subTable reloadData];
        return cell;
    }
    else {
        
        static NSString *CellIdentifier = @"Cell";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[MenuViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.backgroundColor= [UIColor blackColor];
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0,   0.5, cell.contentView.frame.size.width, 1)];
        UIView *separator2 = [[UIView alloc] initWithFrame:CGRectMake(0, 1.0, cell.contentView.frame.size.width, 1)];
        separator.backgroundColor = [UIColor blackColor];
        separator2.backgroundColor =[UIColor darkGrayColor];
        UIView *selectedColor = [[UIView alloc] init];
        selectedColor.backgroundColor = [UIColor colorFromHexCode:@"#232323"];
        cell.selectedBackgroundView = selectedColor;
        
        if (indexPath.section == 0) {
            
            NSInteger idx = indexPath.row;
            if(idx > 1){
                [cell.contentView addSubview:separator];
                [cell.contentView addSubview:separator2];}
            NSString *name = [self.contents objectAtIndex:idx];
            cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", name]];
            switch (idx) {
                    break;
                case 1:cell.textLabel.text = @"Hộp thư đến";
                    break;
                case 2:cell.textLabel.text = @"Thư đính kèm"; break;
                case 3:cell.textLabel.text = @"Thư đã gửi"; break;
                case 4:cell.textLabel.text = @"Tất cả thư"; break;
                case 5:cell.textLabel.text = @"Thư gắn dấu sao"; break;
                case 6:cell.textLabel.text = @"Thùng rác"; break;
                case 7:
                {
                    cell.textLabel.text = @"Đăng xuất";
                    cell.imageView.image = [UIImage imageNamed:@"icon_sign_out.png"];
                    cell.textLabel.highlightedTextColor = [UIColor peterRiverColor];
                }
                    break;
                case 8:
                {
                    [cell.contentView addSubview:separator];
                    [cell.contentView addSubview:separator2];
                    cell.textLabel.text = @"Cài đặt Token";
                    cell.imageView.image = [UIImage imageNamed:@"icon_setting.png"];
                    cell.textLabel.highlightedTextColor = [UIColor peterRiverColor]; break;
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

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    if (section == 0) {
        [headerView setBackgroundColor:[UIColor clearColor]];
        return headerView;
    } else {
        [headerView setBackgroundColor:[UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0]];
        return headerView;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (IDIOM == IPAD) {
        if (section == 0) {
            return 50;
        } else {
            return 1;
        }
    }
    else {
        if (section == 0){
            return 30;
        } else {
            return 1;
        }
        
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >0)
    {
        if (IDIOM == IPAD) {
            return 60;
        }
        else {
            return 50;
        }
    }else{
        int amt =(listAccount.count/4 + 2);
        NSLog(@"Number SubView %d",amt);
        BOOL isExpanded = [[expandedIndexes objectForKey:indexPath] boolValue];
        if(isExpanded)
        {
            return [SDGroupCell getHeight] + [SDGroupCell getsubCellHeight] * amt;
        }
        return [SDGroupCell getHeight]  ;}
    
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate){
         if (IDIOM == IPHONE && indexPath.row!=0) {
            [self hideLeftViewoClick];
        }
        NSInteger idx = indexPath.row;
       if (idx != 7 && idx != 8 && idx != 0) {
            NSString *HRName = [self.contents objectAtIndex:idx];
            folderName = HRName;
            [self.delegate loadMailFolder:[self pathFromName:HRName] withHR:HRName];
        }
    }
    
    switch (indexPath.row) {
        case 7:
        {
            FUIAlertView *alertView = [[FUIAlertView alloc] initWithTitle:@"Đăng xuất" message:@"Xác nhận đăng xuất?" delegate:self cancelButtonTitle:@"Trở về" otherButtonTitles:@"Đồng ý", nil];
            alertView.titleLabel.textColor = [UIColor blackColor];
            alertView.tag = Logout;
            
            if ( IDIOM == IPAD ) {
                alertView.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
                alertView.messageLabel.textColor = [UIColor asbestosColor];
                alertView.messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
                alertView.backgroundOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
                alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
                alertView.defaultButtonColor = [UIColor cloudsColor];
                alertView.defaultButtonShadowColor = [UIColor cloudsColor];
                alertView.defaultButtonFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
                alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
            }
            else {
                alertView.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
                alertView.messageLabel.textColor = [UIColor asbestosColor];
                alertView.messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
                alertView.backgroundOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
                alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
                alertView.defaultButtonColor = [UIColor cloudsColor];
                alertView.defaultButtonShadowColor = [UIColor cloudsColor];
                alertView.defaultButtonFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
                alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
            }
            [alertView show];
        }
            break;
        case 8:
        {
            [self hideLeftView:nil];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Thiết lập"
                                                                message:@"Chọn kiểu Token"
                                                               delegate:self
                                                      cancelButtonTitle:@"Bỏ qua"
                                                      otherButtonTitles:@"Soft Token", @"Hard Token", @"Bảo vệ email", nil];
            alertView.tag = TokenSetting;
            [alertView show];
            
        }
            break;
        default:
            break;
    }
    
}

#pragma mark Helper Functions
- (NSString *)pathFromName:(NSString*) name {
    NSString *imapPath = [self.folderNameLookup objectForKey:name];
    if (!imapPath){
        if ([name isEqualToString:@"Attachments"]){
            imapPath = [self.folderNameLookup objectForKey:@"All Mail"];
        } else {
            imapPath = name;
        }
    }
    return imapPath;
}

#pragma mark PKReveal Functions
- (void)hideLeftView:(id)sender
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.revealController.focusedController == appDelegate.revealController.leftViewController)
    {
        [appDelegate.revealController showViewController:appDelegate.revealController.frontViewController];
    }
}

- (void)hideLeftViewoClick
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.revealController.focusedController == appDelegate.revealController.leftViewController)
    {
        [appDelegate.revealController showViewController:appDelegate.revealController.frontViewController];
    }
}

#pragma mark Functions
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == passwordHT){
        if(buttonIndex == 1) {
            
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
            NSString *passwrd = [[alertView textFieldAtIndex:0] text];
            HardTokenMethod *initMethod = [[HardTokenMethod alloc]init];
            if ([initMethod connect]) {
                long ckrv = 1;
                ckrv = [initMethod VerifyPIN:[passwrd cStringUsingEncoding:NSASCIIStringEncoding]];
                if (!ckrv) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"listCertHard" object:nil];
                }
            };
        }
    }
    
    if (alertView.tag == Logout) {
        if (buttonIndex == 1){
            [self logoutPressed];
        } }
    
    if (alertView.tag == TokenSetting) {
        int token = [[DBManager getSharedInstance]findTokenTypeById];
        if (buttonIndex == 1){
            NSLog(@"SOFT TOKEN");
            UIApplication *ourApplication = [UIApplication sharedApplication];
            NSURL *ourURL = [NSURL URLWithString:@"vnptcatokenmanager://?emailcall"];
            if ([ourApplication canOpenURL:ourURL]) {
                [ourApplication openURL:ourURL];
                if (token == NOTOKEN) {
                    [[DBManager getSharedInstance]saveTokenType:SOFTTOKEN];
                }
                else {
                    [[DBManager getSharedInstance]updateTokenType:SOFTTOKEN];
                }
            }
            else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Lỗi" message:@"Ứng dụng VNPTCA TokenManager chưa cài đặt!" delegate:nil cancelButtonTitle:@"Đồng ý" otherButtonTitles:nil];
                [alertView show];
            }
            
        }
        if (buttonIndex == 2) {
            NSLog(@"HARD TOKEN");
            [self hardTokenCall];
            if (token == NOTOKEN) {
                [[DBManager getSharedInstance]saveTokenType:HARDTOKEN];
            }
            else {
                [[DBManager getSharedInstance]updateTokenType:HARDTOKEN];
            }
        }
        
        if (buttonIndex == 3) {
            NSLog(@"Bảo vệ Email");
            [self.delegate loadTokenProtect];
        }
    }
}

- (void)hardTokenCall {
    UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:@"Mật khẩu Token"
                                                       message:nil delegate:self
                                             cancelButtonTitle:@"Thoát"
                                             otherButtonTitles:@"Đồng ý", nil];
    [alertPin setAlertViewStyle:UIAlertViewStyleSecureTextInput];
    alertPin.tag = passwordHT;
    [alertPin show];
    
}

- (void)logoutPressed {
    CheckNetWork* initCheck = [[CheckNetWork alloc]init];
    if ([initCheck checkNetworkAvailable]) {
        [self.delegate clearMessages];
        firstLoad = YES;
        [self hideLeftView:nil];
        [[AuthManager sharedManager] logout];
        [[AuthManager sharedManager] refresh];
        [MsgListViewController setUnlockMail:NO];
        
        [self.tableView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMessage" object:nil];
    }
    else {
        UIAlertView *fail = [[UIAlertView alloc] initWithTitle:@"Lỗi" message:@"Không có kết nối mạng!" delegate:self cancelButtonTitle:@"Trở về" otherButtonTitles:nil, nil];
        [fail show];
    }
}

- (NSInteger)mainTable:(UITableView *)mainTable numberOfItemsInSection:(NSInteger)section
{
    return 1;
}

- (NSInteger)mainTable:(UITableView *)mainTable numberOfSubItemsforItem:(SDGroupCell *)item atIndexPath:(NSIndexPath *)indexPath
{
    NSInteger count = (int)listAccount.count / 4;
    return count + 1;
}

- (SDGroupCell *)mainTable:(UITableView *)mainTable setItem:(SDGroupCell *)item forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [item.contentView setBackgroundColor:[UIColor colorFromHexCode:@"363636"]];
    [item.contentView setFrame:CGRectMake(0, 0, item.contentView.frame.size.width, 60)];
    NSString *name =[listAccount objectAtIndex:accIndex];
    NSString *emails = [listAccount objectAtIndex:accIndex+1];  if (!name.length) {
        name = emails;
    }
    NSString *mailtype =[listAccount objectAtIndex:accIndex+3];
    if (emails.length>0 ) {
        UIView *accountView = [[UIView alloc]init];
        [accountView setFrame:CGRectMake(0, 5, 180, 60)];
        switch ([mailtype integerValue]) {
            case 1:
                mailtype = @"@vdc.com.vn";
                break;
            case 2:
                mailtype = @"@gmail.com";
                break;
            case 3:
                mailtype = @"@yahoo.com.vn";
                break;
            case 4:
                mailtype = @"@outlook.com";
                break;
            default:
                break;
        }
        UILabel *displayName = [[UILabel alloc]init];
        displayName.textColor = [UIColor whiteColor];
        displayName.font =[UIFont fontWithName:@"HelveticaNeue" size:12];
        displayName.text =name;
        [displayName setFrame:CGRectMake(20, 4, accountView.frame.size.width, 20)];
        UILabel *email = [[UILabel alloc]init];
        email.textColor = [UIColor grayColor];
        email.font =[UIFont fontWithName:@"HelveticaNeue-Italic" size:10];
        email.text = [NSString stringWithFormat:@"%@%@",emails,mailtype];
        [email setFrame:CGRectMake(20, 26, accountView.frame.size.width, 20)];
        [accountView addSubview:displayName];
        [accountView addSubview:email];
        [item.contentView addSubview:accountView];
    }
    item.itemText.text =@"";
    
    return item;
}

- (SDSubCell *)item:(SDGroupCell *)item setSubItem:(SDSubCell *)subItem forRowAtIndexPath:(NSIndexPath *)indexPath
{    [subItem.contentView setBackgroundColor:[UIColor colorFromHexCode:@"363636"]];
    NSInteger row = indexPath.row;
    
    NSLog(@"List account %lu",(unsigned long)listAccount.count);
    
    if (row < listAccount.count / 4 ) {
        NSInteger currIndex = row*4;
        NSString *name =[listAccount objectAtIndex:currIndex];
        NSString *emails = [listAccount objectAtIndex:currIndex+1];
        if (!name.length) {
            name = emails;
        }
        NSString *mailtype =[listAccount objectAtIndex:currIndex+3];
        if (emails.length>0 ) {
            UIView *accountView = [[UIView alloc]init];
            [accountView setFrame:CGRectMake(0, 5, 180, 50)];
            switch ([mailtype integerValue]) {
                case 1:
                    mailtype = @"@vdc.com.vn";
                    break;
                case 2:
                    mailtype = @"@gmail.com";
                    break;
                case 3:
                    mailtype = @"@yahoo.com.vn";
                    break;
                case 4:
                    mailtype = @"@outlook.com";
                    break;
                default:
                    break;
            }
            UILabel *displayName = [[UILabel alloc]init];
            displayName.textColor = [UIColor whiteColor];
            displayName.font =[UIFont fontWithName:@"HelveticaNeue" size:12];
            displayName.text =name;
            [displayName setFrame:CGRectMake(20, 4, accountView.frame.size.width, 20)];
            UILabel *email = [[UILabel alloc]init];
            email.textColor = [UIColor grayColor];
            email.font =[UIFont fontWithName:@"HelveticaNeue-Italic" size:10];
            email.text = [NSString stringWithFormat:@"%@%@",emails,mailtype];
            [email setFrame:CGRectMake(20, 26, accountView.frame.size.width, 20)];
            UIButton *config = [[UIButton alloc]init];
            config = [UIButton buttonWithType:UIButtonTypeCustom];
            [config setFrame:CGRectMake(235, 10, 30, 30)];
            [config addTarget:self action:@selector(accountConfig:) forControlEvents:UIControlEventTouchUpInside];
            [config setImage:[UIImage imageNamed:@"icon_setting.png"] forState:UIControlStateNormal];
            UIButton *signout = [[UIButton alloc]init];
            signout = [UIButton buttonWithType:UIButtonTypeCustom];
            [signout setFrame:CGRectMake(200, 10, 30, 30)];
            [signout addTarget:self action:@selector(accountAdd:) forControlEvents:UIControlEventTouchUpInside];
            [signout setImage:[UIImage imageNamed:@"icon_sign_out.png"] forState:UIControlStateNormal];
            if (currIndex == accIndex) {
                [subItem.contentView setBackgroundColor:[UIColor colorFromHexCode:@"black"]];
            }
            [accountView addSubview:displayName];
            [accountView addSubview:email];
            [subItem.contentView addSubview:accountView];
        }
    }
    else{
        //addmail
        UIView *accountView = [[UIView alloc]init];
        [accountView setFrame:CGRectMake(0, 5, 180, 50)];
        UIButton *addAccount = [[UIButton alloc]init];
        addAccount = [UIButton buttonWithType:UIButtonTypeCustom];
        [addAccount setFrame:CGRectMake(subItem.contentView.frame.size.width/2-30, 10, 30, 30)];
        [addAccount setImage:[UIImage imageNamed:@"taomoi.png"] forState:UIControlStateNormal];
        [accountView addSubview:addAccount];
        [subItem.contentView addSubview:accountView];
        
    }
    if (indexPath.row>0) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0,   0.5, subItem.contentView.frame.size.width, 1)];
        UIView *separator2 = [[UIView alloc] initWithFrame:CGRectMake(0, 1.0, subItem.contentView.frame.size.width, 1)];
        separator.backgroundColor = [UIColor blackColor];
        separator2.backgroundColor =[UIColor darkGrayColor];
        [subItem.contentView addSubview:separator];[subItem.contentView addSubview:separator2];}
    return subItem;
}

- (void)expandingItem:(SDGroupCell *)item withIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"expandingItem");
}

- (void)collapsingItem:(SDGroupCell *)item withIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"collapsingItem");
}

- (NSString *) nibNameForMainCell
{
    return @"SDGroupCell";
}

#pragma mark - Delegate methods

- (void) mainTable:(UITableView *)mainTable itemDidChange:(SDGroupCell *)item
{
    NSLog(@"maindid change");
}

- (void) item:(SDGroupCell *)item subItemDidChange:(SDSelectableCell *)subItem
{
    
}

- (void) mainItemDidChange: (SDGroupCell *)item forTap:(BOOL)tapped
{
    if(delegate != nil && [delegate respondsToSelector:@selector(mainTable:itemDidChange:)] )
    {
        [delegate performSelector:@selector(mainTable:itemDidChange:) withObject:self.tableView withObject:item];
    }
    
}

- (void) mainItem:(SDGroupCell *)item subItemDidChange: (SDSelectableCell *)subItem forTap:(BOOL)tapped
{
    if(delegate != nil && [delegate respondsToSelector:@selector(item:subItemDidChange:)] )
    {
        [delegate performSelector:@selector(item:subItemDidChange:) withObject:item withObject:subItem];
    }
}

- (void) collapsableButtonTapped: (UIControl *) button withEvent: (UIEvent *) event
{
    UITableView *tableView = self.tableView;
    NSIndexPath * indexPath = [tableView indexPathForRowAtPoint: [[[event touchesForView: button] anyObject] locationInView: tableView]];
    if ( indexPath == nil )
        return;
    tableView.separatorColor = [UIColor clearColor];
    if ([[expandedIndexes objectForKey:indexPath] boolValue]) {
        [self collapsingItem:(SDGroupCell *)[tableView cellForRowAtIndexPath:indexPath] withIndexPath:indexPath];
    } else {
        [self expandingItem:(SDGroupCell *)[tableView cellForRowAtIndexPath:indexPath] withIndexPath:indexPath];
    }
    
	BOOL isExpanded = ![[expandedIndexes objectForKey:indexPath] boolValue];
	NSNumber *expandedIndex = [NSNumber numberWithBool:isExpanded];
	[expandedIndexes setObject:expandedIndex forKey:indexPath];
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void) groupCell:(SDGroupCell *)cell didSelectSubCell:(SDSelectableCell *)subCell withIndexPath:(NSIndexPath *)indexPath andWithTap:(BOOL)tapped
{
    if (indexPath.row < listAccount.count / 4){
        NSString *HRName = [self.contents objectAtIndex:0];
        folderName = HRName;
        [self.delegate loadMailFolder:[self pathFromName:HRName] withHR:HRName];
        
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        accIndex = indexPath.row*4;
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d",accIndex] forKey:@"accIndex"];
        [self hideLeftViewoClick];
        [self.tableView reloadData];
        [[AuthManager sharedManager] getAccountInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadMessage" object:nil];
    }
    else {
        [self accountAdd];
    }
}

-(void)accountAdd {
    if (IDIOM == IPHONE ) {
        [self hideLeftViewoClick];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%d",listAccount.count] forKey:@"accIndex"];
    AuthNavigationViewController *authViewController = [AuthNavigationViewController controllerWithLogin:@"Đăng nhập VNPTCA Mail"];
    authViewController.dismissOnSuccess = YES;
    authViewController.dismissOnError = YES;
    authViewController.delegate = self;
    [authViewController presentFromRootAnimated:YES completion:nil];
    
    return;
}

- (void) reloadMenu {
    listAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    accIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"] integerValue];
    [self.tableView reloadData];
}


@end
