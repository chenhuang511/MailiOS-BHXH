//
//  ListAllFolders.m
//  iMail
//
//  Created by Tran Ha on 1/5/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import "ListAllFolders.h"
#import "AuthManager.h"
#import "CheckNetWork.h"
#import <MailCore/MailCore.h>

static NSDictionary *folderNameFinding;

@implementation ListAllFolders

+ (NSDictionary *)shareFolderNames {
  return folderNameFinding;
}

- (void)findFolderName:(void (^)(BOOL success))completion {

  /* 'dispatch_async' giúp kết thúc hàm lắng nghe 'Finished_OAuth' Notification,
   * khiến hàm '[_sharedObject startLogin]' phía Authmanager kết thúc và thoát
   * ra khỏi tiến trình 'dispatch_once' và bắt đầu thực hiện một hàm
   * '[AuthManager sharedManager]' mới. Nếu không sử dụng dispatch_async, tiến
   * trình 'dispatch_once' chưa kết thúc trong khi hàm '[AuthManager
   * sharedManager]' đã gọi tiếp một tiến trình mới và ứng dụng sẽ bị đơ (rối
   * loạn tiến trình) */

  CheckNetWork *init = [[CheckNetWork alloc] init];
  if (![init checkNetworkAvailable]) {
    completion(NO);
    return;
  }

  dispatch_async(
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, kNilOptions), ^{

        folderNameFinding = nil;
        MCOIMAPFetchFoldersOperation *fetchFolders = [[[AuthManager
                sharedManager] getImapSession] fetchAllFoldersOperation];
        [fetchFolders start:^(NSError *error, NSArray *folders) {

          if (error) {
            NSLog(@"error finding folder: %@", error.description);
            if (error.code == 5) {
              [CheckValidSession
                  checkValidSession:
                      [[AuthManager sharedManager] getImapSession]];
            }
          }
          NSInteger type = [[[NSUserDefaults standardUserDefaults]
              objectForKey:@"mailtype"] integerValue];
          NSMutableDictionary *updatedFolderNames = [[NSMutableDictionary alloc]
              initWithDictionary:folderNameFinding];
          [updatedFolderNames setObject:@"INBOX" forKey:@"Inbox"];
          for (MCOIMAPFolder *f in folders) {
            if (f.flags & MCOIMAPFolderFlagInbox) {
              [updatedFolderNames setObject:f.path forKey:@"Inbox"];
            } else if (f.flags & MCOIMAPFolderFlagSentMail) {
              [updatedFolderNames setObject:f.path forKey:@"Sent"];
            } else if (f.flags & MCOIMAPFolderFlagJunk) {
              [updatedFolderNames setObject:f.path forKey:@"Spam"];
            } else if (f.flags & MCOIMAPFolderFlagTrash) {
              [updatedFolderNames setObject:f.path forKey:@"Trash"];
            } else if (f.flags & MCOIMAPFolderFlagAll) {
              [updatedFolderNames setObject:f.path forKey:@"All Mail"];
            }
          }

          if (type == 3) {
            [updatedFolderNames setObject:@"Trash" forKey:@"Trash"];
            [updatedFolderNames setObject:@"Bulk Mail" forKey:@"Spam"];
            [updatedFolderNames setObject:@"Sent" forKey:@"Sent"];
          }

          if ([updatedFolderNames objectForKey:@"All Mail"] == nil) {
            [updatedFolderNames setObject:@"INBOX" forKey:@"All Mail"];
          }

          folderNameFinding =
              [NSDictionary dictionaryWithDictionary:updatedFolderNames];

          // Save folder path to Nsuserdefault
          if (!error) {
            NSString *accIndex = [[NSUserDefaults standardUserDefaults]
                objectForKey:@"accIndex"];
            NSMutableArray *listAccount = [[NSUserDefaults standardUserDefaults]
                objectForKey:@"listAccount"];
            if (accIndex != nil) {
              NSString *username =
                  [listAccount objectAtIndex:([accIndex intValue] + 1)];
              username = [NSString stringWithFormat:@"%@_MailPath", username];

              [[NSUserDefaults standardUserDefaults] setObject:folderNameFinding
                                                        forKey:username];
            }
          }

          NSLog(@"New dictionary: %@", updatedFolderNames);
          if (error) {
            completion(NO);
          } else {
            completion(YES);
          }
        }];
      });
}

@end
