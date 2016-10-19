//
//  MoveToMailboxes.h
//  iMail
//
//  Created by Tran Ha on 12/30/14.
//  Copyright (c) 2014 com.vdcca. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import <MailCore/MCOIMAPMessage.h>

// Pass data back
@class MoveToMailboxes;

@protocol MoveToMailboxesDelegate <NSObject>

- (void)passDestFolderName:(MoveToMailboxes *)controller
     didFinishEnteringItem:(NSString *)destFolder message:(NSIndexPath *)message;

@end

@interface MoveToMailboxes
    : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  UITableView *_tableView;
  NSMutableArray *folderlist;
}

@property(nonatomic, weak) NSString *fromFolder;
@property(nonatomic, weak) NSIndexPath *message;
@property(nonatomic, weak) NSString *content;
@property(nonatomic, weak) id<MoveToMailboxesDelegate> delegate;

+ (UIImage *)changeColorImage:(UIImage *)image withColor:(UIColor *)color;

@end
