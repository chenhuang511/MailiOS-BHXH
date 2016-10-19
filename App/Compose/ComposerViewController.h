//
//  ComposerViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import "MBProgressHUD.h"
#import "SINavigationMenuView.h"
#import "FUIAlertView.h"

@interface ComposerViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, MBProgressHUDDelegate,SINavigationMenuDelegate, FUIAlertViewDelegate>
{
    NSMutableArray *emailHaveCert;
    bool alertDestroy_;
    BOOL alertSend_;
    BOOL sign_;
    BOOL encrypto_;
    BOOL signEncrypt_;
    int token_;
    BOOL forward_ ;
    float totaldata_ ;
    NSInteger mailtype;
}


@property(nonatomic, weak) IBOutlet UITextField *toField;
@property(nonatomic, weak) IBOutlet UITextField *ccField;
@property(nonatomic, weak) IBOutlet UITextField *subjectField;

@property(nonatomic, weak) IBOutlet UITextView *messageBox;
@property(nonatomic, strong) IBOutlet UIView *attachmentView;
@property (strong, nonatomic) IBOutlet UILabel *toLabel;
@property (strong, nonatomic) IBOutlet UILabel *subjectLabel;
 
@property (strong, nonatomic) IBOutlet UILabel *attachlb;

- (id)initWithMessage:(MCOIMAPMessage *)msg
               ofType:(NSString*)type
              content:(NSString*)content
          attachments:(NSArray *)attachments
   delayedAttachments:(NSArray *)delayedAttachments;

- (id)initWithTo:(NSArray *)to
              CC:(NSArray *)cc
             BCC:(NSArray *)bcc
         subject:(NSString *)subject
         message:(NSString *)message
     attachments:(NSArray *)attachments
delayedAttachments:(NSArray *)delayedAttachments;


@end
