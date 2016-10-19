//
//  FileManager.h
//  iMail
//
//  Created by MACBOOK PRO on 2/2/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"
#import "MGSwipeButton.h"
#import "FlatUIKit.h"
#import "MBProgressHUD.h"
#import "QuickLook/QuickLook.h"
@interface FileManager : UIViewController <UITableViewDataSource, UITableViewDelegate, MGSwipeTableCellDelegate, FUIAlertViewDelegate, QLPreviewControllerDataSource,QLPreviewControllerDelegate> {
    NSString *dataURL;
    UITableView * _tableView;
    NSMutableArray *listFile;
    NSArray *listCreate;
    UILabel *label;
    NSIndexPath *indexPath_;
}

@end
