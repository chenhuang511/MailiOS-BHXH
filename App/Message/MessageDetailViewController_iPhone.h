//
//  MessageDetailViewController_iPhone.h
//  ThatInbox
//
//  Created by Tran Ha on 02/04/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "MCTMsgViewController.h"
#import <UIKit/UIKit.h>
#import "MCTMsgViewController.h"
#import "MessageListDelegate.h"

@interface MessageDetailViewController_iPhone : MCTMsgViewController <UINavigationControllerDelegate>

@property (nonatomic, assign) id<MessageListDelegate> delegate;

@end

