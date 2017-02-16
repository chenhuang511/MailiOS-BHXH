//
//  MessageCell.h
//  ThatInbox
//
//  Created by Andrey Yastrebov on 20.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

#define UNREAD 0
#define READ 1
#define FLAG 2
#define UNREAD_FLAG 3

@interface MailIndicatorView : UIView
@property (nonatomic, strong) UIColor * indicatorColor;
@property (nonatomic, strong) UIColor * innerColor;
@end

@class MCOIMAPMessage;

@interface MessageCell : MGSwipeTableCell

@property (weak, nonatomic) IBOutlet UILabel *fromTextField;
@property (weak, nonatomic) IBOutlet UILabel *dateTextField;
@property (weak, nonatomic) IBOutlet UILabel *subjectTextField;
@property (weak, nonatomic) IBOutlet UILabel *attachmentTextField;
@property (weak, nonatomic) IBOutlet UIImageView *attachementIcon;
@property (weak, nonatomic) IBOutlet UIImageView *signIcon;
@property (weak, nonatomic) IBOutlet UIImageView *avatarIcon;

- (void)setMessage:(MCOIMAPMessage *)message;

@end
