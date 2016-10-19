//
//  ComposerViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
#import "FUIButton.h"
#import "SINavigationMenuView.h"
#import "FUIAlertView.h"
#import "MBProgressHUD.h"

#import "ComposeCommonMethod.h"

@interface Composer_iPhoneViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate, SINavigationMenuDelegate, FUIAlertViewDelegate, MBProgressHUDDelegate>
{
    UIButton * btn_;
    NSMutableArray *emailHaveCert;
    BOOL alertDestroy;
    BOOL alertSend;
    BOOL sign;
    BOOL encrypto;
    BOOL signEncrypt;
    int token;
    float totaldata;
    BOOL forward;
    float OffsetY;
    NSInteger mailtype;
}

@property(nonatomic, weak) IBOutlet UITextField *toField;
@property(nonatomic, weak) IBOutlet UITextField *ccField;
@property(nonatomic, weak) IBOutlet UITextField *subjectField;

@property(nonatomic, weak) IBOutlet UITextView *messageBox;
@property (weak, nonatomic) IBOutlet UILabel *attachLabel;
@property(nonatomic, strong) IBOutlet UIView *attachmentView_;
 
@property (strong, nonatomic) IBOutlet UILabel *toLabel;
@property (weak, nonatomic) IBOutlet UILabel *ccLabel;

@property (strong, nonatomic) IBOutlet UILabel *subjectLabel;
@property (strong, nonatomic) IBOutlet UILabel *attLabel;

@property (weak, nonatomic) IBOutlet UIView *attachLine;
@property (weak, nonatomic) IBOutlet UIView *line1;
@property (weak, nonatomic) IBOutlet UIView *line2;
@property (weak, nonatomic) IBOutlet UIView *line3;

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
