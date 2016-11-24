//
//  FormTableController.h
//  TableWithTextField
//
//  Created by Andrew Lim on 4/15/11.
#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>
@interface LoginFormController : UIViewController<UITextFieldDelegate,UITableViewDataSource,UITableViewDelegate>
{
	UITextField* name_Field ;
	UITextField* password_Field ;
    UITextField* displayname_Field;
    
	UITextField* imap_Field ;
	UITextField* imapport_Field ;
    UITextField* imapEmail_Field ;
    UITextField* imapPass_Field;
    
	UITextField* smtp_Field ;
	UITextField* smtpport_Field ;
    UITextField* smtpEmail_Field;
    UITextField* smtpPass_Field;
    
    UITableView* _tableView;
    CGFloat _initialTVHeight;
}

-(UITextField*) makeTextField: (NSString*)text
                  placeholder: (NSString*)placeholder;

- (IBAction)textFieldFinished:(id)sender ;

- (void)addBackButton;

@property (nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) MCOSMTPSession *smtpSession;
@property (nonatomic,copy) NSString* name ;
@property (nonatomic,copy) NSString* displayname ;
@property (nonatomic,copy) NSString* password ;

@property (nonatomic,copy) NSString* imap ;
@property (nonatomic,copy) NSString* imapport ;
@property (nonatomic,copy) NSString* imapEmail ;
@property (nonatomic,copy) NSString* imapPass ;

@property (nonatomic,copy) NSString* smtp ;
@property (nonatomic,copy) NSString* smtpport ;
@property (nonatomic,copy) NSString* smtpEmail ;
@property (nonatomic,copy) NSString* smtpPass ;

@end
