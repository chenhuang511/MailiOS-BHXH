//
//  CertInfoView.m
//  iMail
//
//  Created by Tran Ha on 14/05/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "CertInfoView.h"
#import "CertInfoViewCell.h"
#import "FlatUIKit.h"
#import "Constants.h"

@interface CertInfoView ()
@end

@implementation CertInfoView
@synthesize dict;
NSArray *TitleLabel;
NSArray *SubtitleLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor colorFromHexCode:barColor]];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self action:@selector(close_certView:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItems = @[backButton];
    
    self.title = NSLocalizedString(@"Info", nil);
    [self.tableView registerNib:[UINib nibWithNibName:@"CertInfoViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"CustomCellReuseID"];
    
    NSString *serial = [dict objectForKey:@"serial"];
    NSString *name  = [dict objectForKey:@"name"];
    NSString *issuer = [dict objectForKey:@"issuer"];
    NSString *validDate = [dict objectForKey:@"validDate"];
    NSString *expireDate = [dict objectForKey:@"expireDate"];
    NSString *email = [dict objectForKey:@"email"];
    
    TitleLabel = [[NSArray alloc] initWithObjects: NSLocalizedString(@"Info_ID", nil), NSLocalizedString(@"Info_Owner", nil), NSLocalizedString(@"Info_Email", nil), NSLocalizedString(@"Info_Company", nil), NSLocalizedString(@"Info_Start", nil), NSLocalizedString(@"Info_Expire", nil), nil];
    SubtitleLabel = [[NSArray alloc] initWithObjects: serial, name, email, issuer, validDate, expireDate, nil];
}

- (void)close_certView: (id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [TitleLabel count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CustomCellReuseID";
    CertInfoViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.header.text = [TitleLabel objectAtIndex:indexPath.row];
    cell.header.font = [UIFont boldSystemFontOfSize:16];
    cell.content.text = [SubtitleLabel objectAtIndex:indexPath.row];
    cell.content.font = [UIFont italicSystemFontOfSize:14];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
