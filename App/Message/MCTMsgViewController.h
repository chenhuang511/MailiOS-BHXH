//
//  MCTMsgViewController.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/20/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include <MailCore/MailCore.h>
#import "HeaderView.h"
#import "ListAllFolders.h"
#import "MCOMessageView.h"
#import "FUIAlertView.h"

@class MCOMessageView;
@class MCOIMAPAsyncSession;
@class MCOMAPMessage;

@interface MCTMsgViewController : UIViewController <MCOMessageViewDelegate, HeaderViewDelegate, FUIAlertViewDelegate> {
    IBOutlet MCOMessageView * _messageView;
    HeaderView *_headerView;
    UIScrollView * _scrollView;
    UIView * _messageContentsView;
    
    NSMutableDictionary * _storage;
    NSMutableSet * _pending;
    NSMutableArray * _ops;
    MCOIMAPSession * _session;
    MCOIMAPMessage * _message;
    NSMutableDictionary * _callbacks;
    NSString * _folder;
    
    float totalSize;
    int tokenType;
    MCOIMAPMessage *messageTemp;
}

@property (nonatomic, copy) NSString * folder;
@property (nonatomic, copy) NSMutableArray *delayedAttachment;
@property (nonatomic, strong) MCOIMAPSession * session;
@property (nonatomic, strong) MCOIMAPMessage * message;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *imageMimeType;

- (NSString *)msgContent;
- (NSString*)getBase64;
+ (NSString*)shareFromEmail;

@end
