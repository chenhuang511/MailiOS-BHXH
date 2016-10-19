//
//  ListFileDocuments.m
//  iMail
//
//  Created by Tran Ha on 7/3/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "ListFileDocuments.h"
#import "FlatUIKit.h"
#import "FileDocumentsDetails.h"
#import "Constants.h"

@interface ListFileDocuments ()

@end

@implementation ListFileDocuments
NSArray *fileName;
NSArray *date;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor colorFromHexCode:barColor]];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self action:@selector(close_listView:) forControlEvents:UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    //backImage = [backImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItems = @[backButton];
    
    self.title = @"Danh sách file";
    [self.tableView registerNib:[UINib nibWithNibName:@"FileDocumentsDetails" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"CustomCellReuseID_"];
    
    //Find file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    fileName = [self listFileAtPath:documentsDirectory];
    
    //Find date
    NSMutableArray *dateCreat = [[NSMutableArray alloc] init];
    for (int count = 0; count < (int)[fileName count]; count++) {
        NSLog(@"File %d: %@", (count + 1), [fileName objectAtIndex:count]);
        NSString *filepath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [fileName objectAtIndex:count]];
        NSFileManager* fm = [NSFileManager defaultManager];
        NSDictionary* attrs = [fm attributesOfItemAtPath:filepath error:nil];
        if (attrs != nil) {
            NSDate *date = (NSDate*)[attrs objectForKey: NSFileCreationDate];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm:ss dd-MM-yyyy"];
            NSString *dateString = [dateFormatter stringFromDate:date];
            [dateCreat addObject:dateString];
        }
    }
    date = [NSArray arrayWithArray:dateCreat];
}

- (NSArray *)listFileAtPath:(NSString *)path {
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
    return directoryContent;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)close_listView: (id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [fileName count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CustomCellReuseID_";
    FileDocumentsDetails *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.header.text = [fileName objectAtIndex:indexPath.row];
    cell.header.font = [UIFont boldSystemFontOfSize:15];
    cell.subHeader.text = [NSString stringWithFormat:@"Ngày khởi tạo: %@",[date objectAtIndex:indexPath.row]];
    cell.subHeader.font = [UIFont italicSystemFontOfSize:13];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //send file path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filepath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, [fileName objectAtIndex:indexPath.row]];
    [self.delegate addItemFilePath:self didFinishEnteringItem:filepath];
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
