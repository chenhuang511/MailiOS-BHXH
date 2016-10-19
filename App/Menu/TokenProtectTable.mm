//
//  TokenProtectTable.m
//  iMail
//
//  Created by Tran Ha on 7/31/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "TokenProtectTable.h"
#import "MsgListViewController.h"
#import "DBManager.h"
#import "FlatUIKit.h"
#import "cryptoki_compat/pkcs11.h"
#import "HardTokenMethod.h"
#import "ListCertTableViewController.h"
#import "TokenType.h"

@interface TokenProtectTable ()

@end

@implementation TokenProtectTable

NSString *status;
NSString *device;
NSString *serial;
NSString *device_selected;
NSString *username;
NSMutableIndexSet *expandedSections;
BOOL checkpass = NO;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self action:@selector(dismissTokenProtect:)forControlEvents:
     UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItem = backButton;
    
    UIButton *next = [UIButton buttonWithType:UIButtonTypeCustom];
    [next setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [next addTarget:self action:@selector(saveDatabase:)forControlEvents:
     UIControlEventTouchUpInside];
    UIImage *nextImage = [UIImage imageNamed:@"send.png"];
    [next setImage:nextImage forState:UIControlStateNormal];
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithCustomView:next];
    self.navigationItem.rightBarButtonItem = nextButton;
    NSInteger accIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"] integerValue];
 
    NSMutableArray *listAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    if (listAccount.count > 0 && accIndex <listAccount.count) {
        username = [listAccount objectAtIndex:accIndex + 1];
    }
  
    NSArray *protect = [[DBManager getSharedInstance]findProtected:username];
    NSString *tokenType = [protect objectAtIndex:0];
    if ([tokenType isEqualToString:@"0"] || !tokenType) {
        status = @"Tắt";
        device = @"Không";
        serial = @"Không";
    } else if ([tokenType isEqualToString:@"1"]) {
        status = @"Bật";
        device = @"Soft Token";
        serial = @"UUID";
    } else if ([tokenType isEqualToString:@"2"]) {
        status = @"Bật";
        device = @"Hard Token";
        serial = [protect objectAtIndex:2];
    }
    
    expandedSections = [[NSMutableIndexSet alloc] init];
    device_selected = @"Chưa chọn";
}

- (void)saveDatabase: (id)sender {
    // Set giá trị UnlockMail = YES để tránh hỏi Pass Token khi vừa thiết lập xong
    //UNLOCK
    [MsgListViewController setUnlockMail:YES];
    // Database
    NSString *_id = [[[DBManager getSharedInstance]findProtected:username]objectAtIndex:3];
    if ([device_selected isEqualToString:@"Soft Token"] && checkpass) {
        if (_id) {
            [[DBManager getSharedInstance]updateProtected:[_id intValue] protectedType:SOFTTOKEN serialHash:@"0" serial:@"0" email:username];
        } else {
            int id_int = [[DBManager getSharedInstance]getLastIDProtected];
            [[DBManager getSharedInstance]saveProtected:(id_int + 1) protectedType:SOFTTOKEN serialHash:@"0" serial:@"0" email:username];
        }
        [self showResult:1];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if ([device_selected isEqualToString:@"Hard Token"] && checkpass) {
        NSLog(@"SHA1 = %@", [HardTokenMethod sha1:[HardTokenMethod shareSerial]]);
        if (_id) {
            [[DBManager getSharedInstance]updateProtected:[_id intValue] protectedType:HARDTOKEN serialHash:[HardTokenMethod sha1:[HardTokenMethod shareSerial]] serial:[HardTokenMethod shareSerial] email:username];
        } else {
            int id_int = [[DBManager getSharedInstance]getLastIDProtected];
             [[DBManager getSharedInstance]saveProtected:(id_int + 1) protectedType:HARDTOKEN serialHash:[HardTokenMethod sha1:[HardTokenMethod shareSerial]] serial:[HardTokenMethod shareSerial] email:username];
        }
        [self showResult:2];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if ([device_selected isEqualToString:@"Tắt"]) {
        if (_id) {
            [[DBManager getSharedInstance]updateProtected:[_id intValue] protectedType:NOTOKEN serialHash:@"0" serial:@"0" email:username];
        } else {
            int id_int = [[DBManager getSharedInstance]getLastIDProtected];
            [[DBManager getSharedInstance]saveProtected:(id_int + 1) protectedType:NOTOKEN serialHash:@"0" serial:@"0" email:username];
        }
        [self showResult:0];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if ([device_selected isEqualToString:@"Chưa chọn"]) {
        UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
                                                           message:NSLocalizedString(@"SecurityDevice", nil)
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                 otherButtonTitles:nil];
        [alertPin show];
    }
}

- (void)showResult: (int)tokenType {
    NSString *msg = nil;
    if (tokenType == 1) {
        msg = NSLocalizedString(@"TokenProtect_Soft", nil);
    }
    if (tokenType == 2) {
        msg = NSLocalizedString(@"TokenProtect_Hard", nil);
    }
    if (tokenType == 0) {
        msg = NSLocalizedString(@"TurnOffSecurity", nil);
    }
    UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
                                                       message:msg
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                             otherButtonTitles:nil];
    
    [alertPin show];
}

- (BOOL)tableView:(UITableView *)tableView canCollapseSection:(NSInteger)section
{
    if (section > 0) return YES;
    
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;
            break;
        case 1:
            if ([self tableView:tableView canCollapseSection:section])
            {
                if ([expandedSections containsIndex:section])
                {
                    return 4;
                }
                
                return 1;
            }
        default:
            return 1;
            break;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"CurrentSecurity", nil);
    }
    if (section == 1) {
        return NSLocalizedString(@"SetUpSercu", nil);
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 40;
            break;
        case 1:
            return 20;
            break;
        default:
            return 1;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellidentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellidentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellidentifier] ;
    }
    
    if (indexPath.section == 0) {
        UILabel *header = [[UILabel alloc]init];
        header.font = [UIFont systemFontOfSize:17];
        header.clipsToBounds = YES;
        header.textAlignment = NSTextAlignmentLeft;
        
        UILabel *subHeader = [[UILabel alloc]init];
        subHeader.font = [UIFont systemFontOfSize:17];
        subHeader.clipsToBounds = YES;
        subHeader.textColor = [UIColor colorFromHexCode:@"#999999"];
        
        switch (indexPath.row) {
            case 0:
                header.text = NSLocalizedString(@"EmailSecurity", nil);
                [header sizeToFit];
                [header setFrame:CGRectMake(20, 0, header.frame.size.width, cell.frame.size.height)];
                [cell addSubview:header];
                subHeader.text = status;
                [subHeader sizeToFit];
                [subHeader setFrame:CGRectMake(cell.frame.size.width - 10 - subHeader.frame.size.width, 0, subHeader.frame.size.width, cell.frame.size.height)];
                cell.accessoryView = subHeader;
                break;
            case 1:
                header.text = NSLocalizedString(@"DeviceSecurity", nil);
                [header sizeToFit];
                [header setFrame:CGRectMake(20, 0, header.frame.size.width, cell.frame.size.height)];
                [cell addSubview:header];
                subHeader.text = device;
                [subHeader sizeToFit];
                [subHeader setFrame:CGRectMake(cell.frame.size.width - 10 - subHeader.frame.size.width, 0, subHeader.frame.size.width, cell.frame.size.height)];
                cell.accessoryView = subHeader;
                break;
            case 2:
                header.text = NSLocalizedString(@"DeviceSerial", nil);
                [header sizeToFit];
                [header setFrame:CGRectMake(20, 0, header.frame.size.width, cell.frame.size.height)];
                [cell addSubview:header];
                subHeader.text = serial;
                [subHeader sizeToFit];
                [subHeader setFrame:CGRectMake(cell.frame.size.width - 10 - subHeader.frame.size.width, 0, subHeader.frame.size.width, cell.frame.size.height)];
                cell.accessoryView = subHeader;
                break;
                
            default:
                break;
        }
    }
    
    if (indexPath.section == 1) {
        if (!indexPath.row) {
            UILabel *header = [[UILabel alloc]init];
            header.font = [UIFont systemFontOfSize:17];
            header.clipsToBounds = YES;
            header.textAlignment = NSTextAlignmentLeft;
            header.text =  NSLocalizedString(@"ChooseSecurity", nil);
            [header sizeToFit];
            [header setFrame:CGRectMake(20, 0, header.frame.size.width, cell.frame.size.height)];
            [cell addSubview:header];
        } else {
            switch (indexPath.row) {
                case 1:
                    cell.textLabel.text = @"      Soft Token";
                    cell.textLabel.font = [UIFont systemFontOfSize:17];
                    cell.textLabel.textColor = [UIColor colorFromHexCode:@"#797979"];
                    if ([device_selected isEqualToString:@"Soft Token"] && checkpass) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    }
                    else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
                case 2:
                    cell.textLabel.text = @"      Hard Token";
                    cell.textLabel.font = [UIFont systemFontOfSize:17];
                    cell.textLabel.textColor = [UIColor colorFromHexCode:@"#797979"];
                    if ([device_selected isEqualToString:@"Hard Token"] && checkpass) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    }
                    else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
                default:
                    cell.textLabel.text = NSLocalizedString(@"TurnOffSeEmail", nil);
                    cell.textLabel.font = [UIFont systemFontOfSize:17];
                    cell.textLabel.textColor = [UIColor colorFromHexCode:@"#797979"];
                    if ([device_selected isEqualToString:@"Tắt"]) {
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    }
                    else {
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    break;
            }
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    //expand - collapse
    if (indexPath.section == 1) {
        if (!indexPath.row) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            NSInteger section = indexPath.section;
            BOOL currentlyExpanded = [expandedSections containsIndex:section];
            NSInteger rows;
            
            NSMutableArray *tmpArray = [NSMutableArray array];
            
            if (currentlyExpanded) {
                rows = [self tableView:tableView numberOfRowsInSection:section];
                [expandedSections removeIndex:section];
            }
            else {
                [expandedSections addIndex:section];
                rows = [self tableView:tableView numberOfRowsInSection:section];
            }
            for (int i = 1; i < rows; i++) {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i
                                                               inSection:section];
                [tmpArray addObject:tmpIndexPath];
            }
            if (currentlyExpanded) {
                [tableView deleteRowsAtIndexPaths:tmpArray
                                 withRowAnimation:UITableViewRowAnimationTop];
            }
            else {
                [tableView insertRowsAtIndexPaths:tmpArray
                                 withRowAnimation:UITableViewRowAnimationTop];
            }
        }
    }
    
    //selected
    if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            if (![device_selected isEqualToString:@"Soft Token"] || !checkpass) {
                device_selected = @"Soft Token";
            } else {
                device_selected = @"Chưa chọn";
            }
            if ([device_selected isEqualToString:@"Soft Token"]) {
                UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TokenPass", nil)
                                                                   message:nil delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Out", nil)
                                                         otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
                [alertPin setAlertViewStyle:UIAlertViewStyleSecureTextInput];
                alertPin.tag = 1;
                [alertPin show];
            }
            [self updateSections];
        }
        
        if (indexPath.row == 2) {
            if (![device_selected isEqualToString:@"Hard Token"] || !checkpass) {
                device_selected = @"Hard Token";
            } else {
                device_selected = @"Chưa chọn";
            }
            if ([device_selected isEqualToString:@"Hard Token"]) {
                UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TokenPass", nil)
                                                                   message:nil delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Out", nil)
                                                         otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
                [alertPin setAlertViewStyle:UIAlertViewStyleSecureTextInput];
                alertPin.tag = 1;
                [alertPin show];
            }
            [self updateSections];
        }
        if (indexPath.row == 3) {
            if (![device_selected isEqualToString:@"Tắt"]) {
                device_selected = @"Tắt";
            } else {
                device_selected = @"Chưa chọn";
            }
            
            [self updateSections];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
            NSString *passwrd = [[alertView textFieldAtIndex:0] text];
            
            if ([device_selected isEqualToString:@"Soft Token"]) {
                NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString* path = [libraryPath stringByAppendingPathComponent:@"data.db"];
                BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
                if (!fileExists) {
                    UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
                                                                       message:NSLocalizedString(@"NoToken", nil)
                                                                      delegate:nil
                                                             cancelButtonTitle:NSLocalizedString(@"Back", nil)
                                                             otherButtonTitles:nil];
                    
                    [alertPin show];
                } else {
                    if ([self checkPassSoft:passwrd]) {
                        if ([self checkAvaiableSoft]) {
                            checkpass = YES;
                        } else {
                            checkpass = NO;
                            UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
                                                                               message:NSLocalizedString(@"Contain", nil)
                                                                              delegate:nil
                                                                     cancelButtonTitle:NSLocalizedString(@"Back", nil)
                                                                     otherButtonTitles:nil];
                            
                            [alertPin show];
                        }
                        
                    } else {
                        checkpass = NO;
                        UIAlertView *alertPin = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
                                                                           message:NSLocalizedString(@"PasswordWrong", nil)
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"Back", nil)
                                                                 otherButtonTitles:nil];
                        
                        [alertPin show];
                    }
                    [self updateSections];
                }
            }
            if ([device_selected isEqualToString:@"Hard Token"]) {
                HardTokenMethod *initMethod = [[HardTokenMethod alloc]init];
                if ([initMethod connect]) {
                    long ckrv = [initMethod VerifyPIN:[passwrd cStringUsingEncoding:NSASCIIStringEncoding]];
                    if (ckrv == CKR_OK) {
                        checkpass = YES;
                        [[NSUserDefaults standardUserDefaults] setObject:passwrd forKey:@"HardPasswrd"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    } else {
                        checkpass = NO;
                    }
                } else {
                    checkpass = NO;
                }
            }
            [self updateSections];
        }
    }
    else {
        checkpass = NO;
        [self updateSections];
    }
}

- (BOOL)checkPassSoft: (NSString*)passwrd {
    unsigned char *pinUser = (unsigned char *) [passwrd UTF8String];
    CK_SESSION_HANDLE m_hSession;
    int slotID = 0;
    C_OpenSession_s(slotID, CKF_SERIAL_SESSION, NULL, NULL, &m_hSession);
    int ckrv = C_Login_s(m_hSession, CKU_USER, pinUser, strlen((const char*) pinUser));
    if (ckrv == CKR_OK) {
        C_Logout_s(m_hSession);
        C_CloseSession_s(m_hSession);
        return YES;
    }
    C_CloseSession_s(m_hSession);
    return NO;
}

- (void)updateSections {
    [self.tableView beginUpdates];
    NSIndexPath *baseIndex = [NSIndexPath indexPathForRow:1 inSection:1];
    NSIndexPath *nextIndex = [NSIndexPath indexPathForRow:2 inSection:1];
    NSIndexPath *lastIndex = [NSIndexPath indexPathForRow:3 inSection:1];
    NSArray *a = [[NSArray alloc] initWithObjects:baseIndex, nextIndex, lastIndex, nil];
    [self.tableView reloadRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)dismissTokenProtect:(id)sender {
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (BOOL)checkAvaiableSoft {
    
    NSMutableArray *Title = [NSMutableArray array];
    NSMutableArray *handle_mutable = [NSMutableArray array];
    unsigned long* handlep = new unsigned long[10];
    NSLog(@"Quét chứng thư...!");
    
    // Step 0: Open Session
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    CK_SESSION_HANDLE _sessionID = -1;
    CK_VOID_PTR p = NULL;
    int slotID = 0;
    int rv = C_OpenSession_s(slotID, flags, p, NULL, &_sessionID);
    assert(rv == 0);
    
    // Step 1: Make a ck_attribute
    const char* key = "CERT";
    CK_ATTRIBUTE_PTR keyAttrs = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs->type = CKA_LABEL;
    keyAttrs->pValue = (void*)key;
    
    // Step 2: Find cert
    C_FindObjectsInit_s(_sessionID, keyAttrs, sizeof(keyAttrs)/sizeof(CK_ATTRIBUTE));
    
    // Step 3:  Get the first object handle of key
    unsigned long* handle_countp = new unsigned long[20];
    unsigned long MAX_OBJECT = 10;
    rv = C_FindObjects_s(_sessionID, handlep, MAX_OBJECT, handle_countp);
    assert(rv == 0);
    
    ListCertTableViewController *findcert = [[ListCertTableViewController alloc]init];
    for (int i = 0; i < *handle_countp; i++){
        
        NSDictionary *dict = [findcert findcert:_sessionID :handlep[i]];
        if (dict) {
            NSNumber* xWrapped = [NSNumber numberWithInt:i];
            [handle_mutable addObject:xWrapped];
            NSString *subject  = [dict objectForKey:@"subjectname"];
            [Title  addObject:subject];
        }
    }
    if ([Title count] > 0) {
        for (int i = 0; i < [handle_mutable count]; i++) {
            int handle_int = [[handle_mutable objectAtIndex:i]intValue];
            long subject = handlep[handle_int];
            if ([findcert findPrivateKey:subject]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
