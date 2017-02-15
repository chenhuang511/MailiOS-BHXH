//
//  ComposerViewController.m
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "AuthManager.h"
#import "ComposerViewController.h"
#import "FUIButton.h"
#import "FlatUIKit.h"
#import "NSString+Email.h"
#import "TRAddressBookCellFactory.h"
#import "TRAddressBookSource+GoogleContacts.h"
#import "TRAddressBookSource.h"
#import "TRAutocompleteView.h"
#import "UIPopoverController+FlatUI.h"
#import "UTIFunctions.h"

#import "DelayedAttachment.h"
#import "FPMimetype.h"
#import "MCOMessageView.h"

#import "CheckNetWork.h"
#import "MsgListViewController.h"

#import "Base64.h"
#import "DBManager.h"
#import "DeviceAudio.h"
#import "MBProgressHUD.h"
#import "pem.h"
#import "x509.h"

#import "TokenType.h"
#import "WebService.h"

#import "AuthNavigationViewController.h"
#import "ListFileDocuments.h"
#import "TRAddressBookSuggestion.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "ListAllFolders.h"
#import "Constants.h"

#import "ComposeCommonMethod.h"

#define SKIPERR 13

typedef enum {
  ToTextFieldTag,
  CcTextFieldTag,
  SubjectTextFieldTag
} TextFildTag;

@interface ComposerViewController () <
    UIPopoverControllerDelegate, UIActionSheetDelegate,
    AuthViewControllerDelegate, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate, ListFileDocumentsDelegate>
@property(nonatomic, strong) UIPopoverController *filepickerPopover;
@property(weak, nonatomic) IBOutlet FUIButton *attachButton;
@property(weak, nonatomic) IBOutlet UIView *attachmentSeparatorView;
@property(weak, nonatomic) IBOutlet UILabel *attachmentsTitleLabel;
@end

@implementation ComposerViewController {
  NSString *_toString;
  NSString *_ccString;
  NSString *_bccString;
  NSString *_subjectString;
  NSString *_bodyString;
  NSMutableArray *_attachmentsArray;
  NSArray *_delayedAttachmentsArray;
  TRAutocompleteView *_autocompleteView;
  TRAutocompleteView *_autocompleteViewCC;

  UIPopoverController *pop;
  BOOL keyboardState;
}

@synthesize toField, ccField, subjectField, messageBox, toLabel, subjectLabel,
    attachmentsTitleLabel;

- (id)initWithMessage:(MCOIMAPMessage *)msg
               ofType:(NSString *)type
              content:(NSString *)content
          attachments:(NSArray *)attachments
   delayedAttachments:(NSArray *)delayedAttachments {
  self = [super init];

  NSArray *recipients = @[];
  NSArray *cc = @[];
  NSArray *bcc = @[];
  NSString *subject = [[msg header] subject];

  if ([type isEqual:@"Chuyển tiếp"]) {
    // TODO: Will crash if subject is null
    if (subject) {
      subject = [[[msg header] forwardHeader] subject];
      forward_ = YES;
    }
  }

  if ([@[ @"Trả lời", @"Trả lời tất cả" ] containsObject:type]) {

    subject = [[[msg header] replyHeaderWithExcludedRecipients:@[]] subject];
    recipients = @[
      [[[[msg header] replyHeaderWithExcludedRecipients:@[]] to]
          mco_nonEncodedRFC822StringForAddresses]
    ];
    // recipients = @[[[[msg header] from] RFC822String]];
  }
  if ([@[ @"Trả lời tất cả" ] containsObject:type]) {
    cc = @[
      [[[[msg header] replyAllHeaderWithExcludedRecipients:@[]] cc]
          mco_nonEncodedRFC822StringForAddresses]
    ];
  }

  NSString *body = @"";
  if (content) {
    NSString *date =
        [NSDateFormatter localizedStringFromDate:[[msg header] date]
                                       dateStyle:NSDateFormatterMediumStyle
                                       timeStyle:NSDateFormatterMediumStyle];

    NSString *replyLine = [NSString
        stringWithFormat:@"Lúc %@, %@ đã viết:", date,
                         [[[msg header] from] nonEncodedRFC822String]];
    body = [NSString
        stringWithFormat:@"\n\n\n%@\n> %@", replyLine,
                         [content
                             stringByReplacingOccurrencesOfString:@"\n"
                                                       withString:@"\n> "]];
  }
  return [self initWithTo:recipients
                       CC:cc
                      BCC:bcc
                  subject:subject
                  message:body
              attachments:attachments
       delayedAttachments:delayedAttachments];
}

- (id)initWithTo:(NSArray *)to
                    CC:(NSArray *)cc
                   BCC:(NSArray *)bcc
               subject:(NSString *)subject
               message:(NSString *)message
           attachments:(NSArray *)attachments
    delayedAttachments:(NSArray *)delayedAttachments {
  self = [super init];

  _toString = [self emailStringFromArray:to];
  _ccString = [self emailStringFromArray:cc];
  _bccString = [self emailStringFromArray:bcc];
  _subjectString = subject;
  if ([message length] > 0) {
    NSString *sig =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"signature"];
    if ([message isEqualToString:sig]) {
      _bodyString = [NSString stringWithFormat:@"\n\n\n\n\n%@", message];
    } else {
      _bodyString = message;
    }
  } else {
    _bodyString = @"";
  }
  _attachmentsArray =
      [NSMutableArray arrayWithArray:attachments]; // attachments;
  _delayedAttachmentsArray = delayedAttachments;

  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  totaldata_ = 0;
  toLabel.text = NSLocalizedString(@"To", nil);
  subjectLabel.text = NSLocalizedString(@"Subject", nil);
  attachmentsTitleLabel.text = NSLocalizedString(@"AttachFile", nil);

  // UNLOCK
  [MsgListViewController setUnlockMail:YES];

  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone;

  NSString *username = nil;
  NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count > 0 && accIndex < listAccount.count) {
    username = [listAccount objectAtIndex:accIndex + 1];
  }
  token_ = [[[[DBManager getSharedInstance] findTokenTypeByEmail:username]
      objectAtIndex:0] intValue];

  toField.text = _toString;
  ccField.text = _ccString;
  subjectField.text = _subjectString;
  messageBox.text = _bodyString;
  messageBox.scrollEnabled = YES;

  self.navigationController.navigationBarHidden = NO;
  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor
                                              colorFromHexCode:barColor]];

  UIBarButtonItem *backButton =
      [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(closeWindow:)];
  [backButton setBackgroundImage:[UIImage imageNamed:@"bg.png"]
                        forState:UIControlStateNormal
                      barMetrics:UIBarMetricsDefault];

  UIBarButtonItem *sendButton =
      [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", nil)
                                       style:UIBarButtonItemStylePlain
                                      target:self
                                      action:@selector(sendEmail:)];
  [sendButton setBackgroundImage:[UIImage imageNamed:@"bg.png"]
                        forState:UIControlStateNormal
                      barMetrics:UIBarMetricsDefault];

  for (UIBarButtonItem *bb in @[ backButton, sendButton ]) {
    [bb setTitleTextAttributes:[NSDictionary
                                   dictionaryWithObjectsAndKeys:
                                       [UIFont fontWithName:@"HelveticaNeue"
                                                       size:16.0],
                                       UITextAttributeFont,
                                       [UIColor whiteColor],
                                       UITextAttributeTextColor,
                                       [UIColor clearColor],
                                       UITextAttributeTextShadowColor, nil]
                      forState:UIControlStateNormal];
    [bb setTitleTextAttributes:[NSDictionary
                                   dictionaryWithObjectsAndKeys:
                                       [UIFont fontWithName:@"HelveticaNeue"
                                                       size:16.0],
                                       UITextAttributeFont,
                                       [UIColor belizeHoleColor],
                                       UITextAttributeTextColor, nil]
                      forState:UIControlStateHighlighted];
    [bb setTitleTextAttributes:[NSDictionary
                                   dictionaryWithObjectsAndKeys:
                                       [UIFont fontWithName:@"HelveticaNeue"
                                                       size:16.0],
                                       UITextAttributeFont,
                                       [UIColor lightGrayColor],
                                       UITextAttributeTextColor,
                                       [UIColor clearColor],
                                       UITextAttributeTextShadowColor, nil]
                      forState:UIControlStateDisabled];
  }

  self.attachButton.buttonColor = [UIColor cloudsColor];
  self.attachButton.shadowColor = [UIColor peterRiverColor];

  self.navigationItem.leftBarButtonItem = backButton;
  self.navigationItem.rightBarButtonItem = sendButton;
  self.navigationItem.title = NSLocalizedString(@"Compose", nil);

  [self configureViewForAttachments];

  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWasShown:)
             name:UIKeyboardDidShowNotification
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillHide:)
             name:UIKeyboardWillHideNotification
           object:nil];
  keyboardState = NO;

  [toField becomeFirstResponder];

  // Gợi ý
  [self autoCompleteView:username];

  // Thanh lựa chọn navigation
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"reload"];
  [[NSUserDefaults standardUserDefaults] synchronize];
//  if (self.navigationItem) {
//    CGRect frame =
//        CGRectMake(0, 0.0, 120,
//                   self.navigationController.navigationBar.bounds.size.height);
//    SINavigationMenuView *menu = [[SINavigationMenuView alloc]
//        initWithFrame:frame
//                title:NSLocalizedString(@"SecureOptions", nil)];
//    menu.SIWidth = self.view.frame.size.width;
//
//    [menu displayMenuInView:self.navigationController.view];
//    menu.items = @[
//      NSLocalizedString(@"SignEmail", nil),
//      NSLocalizedString(NSLocalizedString(@"EncryptEmail", nil), nil)
//    ];
//    menu.delegate = self;
//    self.navigationItem.titleView = menu;
//    BOOL isAlwaySign =
//        [[NSUserDefaults standardUserDefaults] boolForKey:@"luonky"];
//    if (isAlwaySign) {
//      sign_ = NO;
//      [menu itemChecked];
//      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC),
//                     dispatch_get_main_queue(), ^{
//                       [self didSelectItemAtIndex:0];
//                     });
//    }
//  }
}

- (void)autoCompleteView:(NSString *)username {
  TRAddressBookSource *source =
      [[TRAddressBookSource alloc] initWithMinimumCharactersToTrigger:2];
  if ([username rangeOfString:@"gmail"].location != NSNotFound) {
    [source useGoogleContacts:YES];
  }

  TRAddressBookCellFactory *cellFactory = [[TRAddressBookCellFactory alloc]
      initWithCellForegroundColor:[UIColor blackColor]
                         fontSize:14];

  NSArray *contactArray =
      [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]
                                         objectForKey:@"KeyContacts"]];
  NSMutableArray *suggesArr = [[NSMutableArray alloc] init];
  if (contactArray.count > 0) {
    for (int i = 0; i < contactArray.count; i++) {
      NSString *displayName =
          [[contactArray objectAtIndex:i] objectForKey:@"displayName"];
      NSString *mailbox =
          [[contactArray objectAtIndex:i] objectForKey:@"mailbox"];
      TRAddressBookSuggestion *suggestion = [[TRAddressBookSuggestion alloc]
          initWith:[NSString
                       stringWithFormat:@"%@ <%@>", displayName, mailbox]];
      suggestion.subheaderText = mailbox;
      suggestion.headerText = displayName;
      [suggesArr addObject:suggestion];
    }
  }

  NSMutableArray *allAddress = [NSMutableArray new];
  [allAddress addObjectsFromArray:source.emails];
  [allAddress addObjectsFromArray:suggesArr];
  source.emails = allAddress;
  contactArray = suggesArr = allAddress = nil;

  _autocompleteView =
      [TRAutocompleteView autocompleteViewBindedTo:toField
                                       usingSource:source
                                       cellFactory:cellFactory
                                      presentingIn:self.navigationController];

  _autocompleteViewCC =
      [TRAutocompleteView autocompleteViewBindedTo:ccField
                                       usingSource:source
                                       cellFactory:cellFactory
                                      presentingIn:self.navigationController];

  for (TRAutocompleteView *av in @[ _autocompleteView, _autocompleteViewCC ]) {
    av.separatorColor = [UIColor whiteColor];
  }
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellId = @"CellId";

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];

  if (nil == cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:cellId];
  }

  cell.textLabel.text =
      [NSString stringWithFormat:@"Cell %d", (int)indexPath.row];

  return cell;
}

// Tích chọn ký/mã hoá
- (void)didSelectItemAtIndex:(NSUInteger)index {
  if (index == 0) {
    sign_ = !sign_;
  }
  if (index == 1) {
    encrypto_ = !encrypto_;
  }
  if (sign_) {
    if (token_ == NOTOKEN) {
      [self reloadMenuView];
      UIAlertView *alertView =
          [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
                                     message:NSLocalizedString(@"NoToken", nil)
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"Back", nil)
                           otherButtonTitles:nil];
      [alertView show];
    }
    if (token_ == HARDTOKEN) {
      NSLog(@"Đã chọn ký Hard");
      [self.view endEditing:YES];
      FUIAlertView *alertPin = [[FUIAlertView alloc]
              initWithTitle:NSLocalizedString(@"TokenPass", nil)
                    message:nil
                   delegate:self
          cancelButtonTitle:NSLocalizedString(@"Out", nil)
          otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
      [alertPin setAlertViewStyle:FUIAlertViewStyleSecureTextInput];
      if (IDIOM == IPAD) {
        alertPin.titleLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        alertPin.messageLabel.textColor = [UIColor asbestosColor];
        alertPin.messageLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        alertPin.defaultButtonFont =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
      } else {
        alertPin.titleLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        alertPin.messageLabel.textColor = [UIColor asbestosColor];
        alertPin.messageLabel.font =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
        alertPin.defaultButtonFont =
            [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
      }
      alertPin.backgroundOverlay.backgroundColor =
          [[UIColor blackColor] colorWithAlphaComponent:0.8];
      alertPin.alertContainer.backgroundColor = [UIColor cloudsColor];
      alertPin.defaultButtonColor = [UIColor cloudsColor];
      alertPin.defaultButtonShadowColor = [UIColor cloudsColor];
      alertPin.defaultButtonTitleColor = [UIColor belizeHoleColor];

      alertPin.tag = passwordHT;
      [alertPin show];
    }
    if (token_ == SOFTTOKEN) {
      NSLog(@"Đã chọn ký Soft");

      UIApplication *ourApplication = [UIApplication sharedApplication];
      NSURL *ourURL = [NSURL URLWithString:@"vnptcatokenmanager://?emailcall"];
      if (![ourApplication canOpenURL:ourURL]) {
        [self reloadMenuView];
        UIAlertView *alertView = [[UIAlertView alloc]
                initWithTitle:NSLocalizedString(@"Error", nil)
                      message:NSLocalizedString(@"NotSetup", nil)
                     delegate:nil
            cancelButtonTitle:NSLocalizedString(@"Ok", nil)
            otherButtonTitles:nil];
        [alertView show];
        return;
      }

      NSString *passSoftToken =
          [[NSUserDefaults standardUserDefaults] stringForKey:@"passwrd"];
      if (!passSoftToken) {
        [self.view endEditing:YES];
        FUIAlertView *alertPin = [[FUIAlertView alloc]
                initWithTitle:NSLocalizedString(@"SoftPass", nil)
                      message:nil
                     delegate:self
            cancelButtonTitle:NSLocalizedString(@"Out", nil)
            otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
        [alertPin setAlertViewStyle:FUIAlertViewStyleSecureTextInput];
        if (IDIOM == IPAD) {
          alertPin.titleLabel.font =
              [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
          alertPin.messageLabel.textColor = [UIColor asbestosColor];
          alertPin.messageLabel.font =
              [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
          alertPin.defaultButtonFont =
              [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        } else {
          alertPin.titleLabel.font =
              [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
          alertPin.messageLabel.textColor = [UIColor asbestosColor];
          alertPin.messageLabel.font =
              [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
          alertPin.defaultButtonFont =
              [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
        }
        alertPin.backgroundOverlay.backgroundColor =
            [[UIColor blackColor] colorWithAlphaComponent:0.8];
        alertPin.alertContainer.backgroundColor = [UIColor cloudsColor];
        alertPin.defaultButtonColor = [UIColor cloudsColor];
        alertPin.defaultButtonShadowColor = [UIColor cloudsColor];
        alertPin.defaultButtonTitleColor = [UIColor belizeHoleColor];
        alertPin.tag = passwordST;
        [alertPin show];
      }
    }
  }
  if (encrypto_) {
    NSLog(@"Đã chọn mã hoá");
  }
}

//- (void)reloadMenuView {
//    CGRect frame = CGRectMake(0, 0.0, 40,
//    self.navigationController.navigationBar.bounds.size.height);
//    SINavigationMenuView *menu = [[SINavigationMenuView alloc]
//    initWithFrame:frame title:nil];
//    [menu displayMenuInView:self.navigationController.view];
//    menu.items = @[@"Ký Email", @"Mã hoá Email"];
//    menu.delegate = self;
//    self.navigationItem.titleView = menu;
//    sign_ = NO;
//    encrypto_ = NO;
//}

- (void)reloadMenuView {
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"reload"];
  [[NSUserDefaults standardUserDefaults] synchronize];

//  CGRect frame = CGRectMake(
//      0, 0.0, 120, self.navigationController.navigationBar.bounds.size.height);
//  SINavigationMenuView *menu = [[SINavigationMenuView alloc]
//      initWithFrame:frame
//              title:NSLocalizedString(@"SecureOptions", nil)];
//  menu.SIWidth = self.view.frame.size.width;
//  [menu displayMenuInView:self.navigationController.view];
//  menu.items = @[
//    NSLocalizedString(@"SignEmail", nil),
//    NSLocalizedString(NSLocalizedString(@"EncryptEmail", nil), nil)
//  ];
//  menu.delegate = self;
//  [menu itemUnchecked];
//  self.navigationItem.titleView = menu;
//  sign_ = NO;
//  encrypto_ = NO;
}

// End of MenuFromNavigation
- (void)configureViewForAttachments {
  // Delete
  [self.attachmentView removeFromSuperview];
  self.attachmentView = nil;
  self.attachmentView = [[UIView alloc]
      initWithFrame:CGRectMake(0,
                               self.attachmentsTitleLabel.frame.origin.y + 10,
                               self.view.frame.size.width, 0)];

  if (([_attachmentsArray count] + [_delayedAttachmentsArray count]) > 0) {
    NSMutableArray *attachmentLabels = [[NSMutableArray alloc] init];
    NSMutableArray *attachmentNames = [[NSMutableArray alloc] init];
    int tag = 0;
    for (MCOAttachment *a in _attachmentsArray) {
      UIButton *label = [UIButton buttonWithType:UIButtonTypeCustom];
      label.frame = CGRectMake(0, 0, 300, 60);
      label.contentHorizontalAlignment =
          UIControlContentHorizontalAlignmentLeft;
      label.contentEdgeInsets = UIEdgeInsetsMake(10, 50, 10, 0);
      [label.titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
      [label setTitle:[a filename] forState:UIControlStateNormal];
      [label setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
      [label.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
      label.tag = tag;
      tag++;

      [label addTarget:self
                    action:@selector(attachmentTapped:)
          forControlEvents:UIControlEventTouchUpInside];

      UIImageView *imageview =
          [[UIImageView alloc] initWithFrame:CGRectMake(10, 13, 32, 32)];
      NSString *pathToIcon =
          [FPMimetype iconPathForMimetype:[a mimeType] Filename:[a filename]];
      imageview.image = [UIImage imageNamed:pathToIcon];
      imageview.contentMode = UIViewContentModeScaleAspectFit;
      [label addSubview:imageview];

      [attachmentLabels addObject:label];
      NSLog(@"File Name %@", a.filename);
      if (a.filename)
        [attachmentNames addObject:a.filename];
      else {
        [attachmentNames addObject:@"attachment_"];
      }
    }

    for (DelayedAttachment *da in _delayedAttachmentsArray) {
      UIButton *label = [UIButton buttonWithType:UIButtonTypeRoundedRect];
      label.frame = CGRectMake(0, 0, 300, 60);
      label.contentHorizontalAlignment =
          UIControlContentHorizontalAlignmentLeft;
      label.contentEdgeInsets = UIEdgeInsetsMake(10, 50, 10, 0);
      [label.titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
      [label setTitle:[da filename] forState:UIControlStateNormal];
      [label setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
      [label.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:12]];
      label.tag = tag;
      tag++;

      [label addTarget:self
                    action:@selector(attachmentTapped:)
          forControlEvents:UIControlEventTouchUpInside];

      UIImageView *imageview =
          [[UIImageView alloc] initWithFrame:CGRectMake(10, 13, 32, 32)];
      NSString *pathToIcon =
          [FPMimetype iconPathForMimetype:[da mimeType] Filename:[da filename]];
      imageview.image = [UIImage imageNamed:pathToIcon];
      imageview.contentMode = UIViewContentModeScaleAspectFit;
      [label addSubview:imageview];

      [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
      [self grabDataWithBlock:^NSData * {
        if ([da isKindOfClass:[DelayedAttachment class]]) {
          return [da getData];
        } else {
          MCOAttachment *attachment = (MCOAttachment *)da;
          return attachment.data;
        }
      }
          completion:^(NSData *data) {
            if ([pathToIcon isEqualToString:@"page_white_picture.png"]) {
              imageview.image = [UIImage imageWithData:data];
            }

            MCOAttachment *attachment =
                [MCOAttachment attachmentWithData:data filename:da.filename];
            if (!_attachmentsArray) {
              _attachmentsArray = [NSMutableArray new];
            }
            [_attachmentsArray addObject:attachment];

            @synchronized(self) {
              NSMutableArray *delayedMut =
                  [NSMutableArray arrayWithArray:_delayedAttachmentsArray];
              [delayedMut removeObject:da];
              _delayedAttachmentsArray = delayedMut;
            }
            [self updateSendButton];
            if (_delayedAttachmentsArray.count == 0) {
              [UIApplication sharedApplication]
                  .networkActivityIndicatorVisible = NO;
            }
          }];

      [attachmentLabels addObject:label];
    }

    int i = 0;
    int startingHeight = self.attachmentView.frame.size.height / 2;
    for (UIButton *attachmentLabel in attachmentLabels) {
      i++;
      attachmentLabel.frame =
          CGRectMake(30, startingHeight, self.view.frame.size.width - 60,
                     attachmentLabel.frame.size.height);
      [self.attachmentView
          setFrame:CGRectMake(self.attachmentView.frame.origin.x,
                              self.attachmentView.frame.origin.y,
                              self.attachmentView.frame.size.width,
                              self.attachmentView.frame.size.height +
                                  attachmentLabel.frame.size.height - 4 * i)];

      [self.attachmentView addSubview:attachmentLabel];

      startingHeight += attachmentLabel.frame.size.height - 20;
    }
    CGRect lastAttachRect = [self.attachmentView frame];

    [UIView animateWithDuration:0.5
        delay:0.1
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.attachButton.frame =
              CGRectMake(self.attachButton.frame.origin.x,
                         lastAttachRect.origin.y + lastAttachRect.size.height,
                         self.attachButton.frame.size.width,
                         self.attachButton.frame.size.height);

          self.attachmentSeparatorView.frame =
              CGRectMake(self.attachmentSeparatorView.frame.origin.x,
                         lastAttachRect.origin.y + lastAttachRect.size.height +
                             self.attachButton.frame.size.height + 8,
                         self.attachmentSeparatorView.frame.size.width,
                         self.attachmentSeparatorView.frame.size.height);

          self.messageBox.frame =
              CGRectMake(self.messageBox.frame.origin.x,
                         self.attachmentSeparatorView.frame.origin.y + 9,
                         self.messageBox.frame.size.width,
                         self.messageBox.frame.size.height);
        }
        completion:^(BOOL finished) {
          [self updateSendButton];
        }];
  } else {
    CGRect lastAttachRect = [self.attachmentsTitleLabel frame];
    [UIView animateWithDuration:0.5
        delay:0.1
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.attachButton.frame =
              CGRectMake(self.attachButton.frame.origin.x,
                         lastAttachRect.origin.y + lastAttachRect.size.height,
                         self.attachButton.frame.size.width,
                         self.attachButton.frame.size.height);

          self.attachmentSeparatorView.frame =
              CGRectMake(self.attachmentSeparatorView.frame.origin.x,
                         lastAttachRect.origin.y + lastAttachRect.size.height +
                             self.attachButton.frame.size.height + 8,
                         self.attachmentSeparatorView.frame.size.width,
                         self.attachmentSeparatorView.frame.size.height);

          self.messageBox.frame =
              CGRectMake(self.messageBox.frame.origin.x,
                         self.attachmentSeparatorView.frame.origin.y + 9,
                         self.messageBox.frame.size.width,
                         self.messageBox.frame.size.height);
        }
        completion:^(BOOL finished) {
          [self updateSendButton];
        }];
  }
  [self.view addSubview:self.attachmentView];
}

- (void)grabDataWithBlock:(NSData * (^)(void))dataBlock
               completion:(void (^)(NSData *data))callback {
  dispatch_time_t popTime =
      dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
  dispatch_after(
      popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
      ^(void) {
        NSData *data = dataBlock();
        callback(data);
      });
}

- (void)updateSendButton {
  if ([_delayedAttachmentsArray count] > 0) {
    self.navigationItem.rightBarButtonItem.enabled = NO;
  } else {
    self.navigationItem.rightBarButtonItem.enabled =
        [self isEmailTextFieldValid];
    alertSend_ = [self isEmailTextFieldValid];
  }

  [self.navigationController.navigationBar layoutSubviews];
}

- (BOOL)isEmailTextFieldValid {
  NSString *emailTextFieldText = toField.text;

  if ([emailTextFieldText isEmailValid]) {
    return YES;
  }

  NSArray *emails = [emailTextFieldText componentsSeparatedByString:@", "];

  if (emails.count == 0) {
    return NO;
  } else {
    __block BOOL isValid = NO;
    [emails enumerateObjectsUsingBlock:^(NSString *email, NSUInteger idx,
                                         BOOL *stop) {
      if (email.length != 0) {
        isValid = [email isEmailValid];
        if (!isValid) {
          *stop = YES;
        }
      }
    }];

    return isValid;
  }
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardDidShowNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillHideNotification
              object:nil];
}

- (void)closeWindow:(id)sender {
  if ((subjectField.text.length != 0) || (messageBox.text.length != 0)) {
    alertDestroy_ = true;
  } else {
    alertDestroy_ = false;
  }

  if (!alertDestroy_ && !alertSend_) {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    sign_ = NO;
    encrypto_ = NO;
  } else {
    [self.view endEditing:YES];
    FUIAlertView *alertView = [[FUIAlertView alloc]
            initWithTitle:nil
                  message:NSLocalizedString(@"DestroyMail", nil)
                 delegate:self
        cancelButtonTitle:NSLocalizedString(@"Back", nil)
        otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    alertView.messageLabel.textColor = [UIColor asbestosColor];
    alertView.messageLabel.font = [UIFont systemFontOfSize:16];
    alertView.backgroundOverlay.backgroundColor =
        [[UIColor blackColor] colorWithAlphaComponent:0.8];
    alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
    alertView.defaultButtonColor = [UIColor cloudsColor];
    alertView.defaultButtonShadowColor = [UIColor cloudsColor];
    alertView.defaultButtonFont =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
    alertView.tag = 0;
    [alertView show];
  }
}

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {

  if (alertView.tag == SKIPERR) {
    if (buttonIndex == 0) {
      [self rollBackSendBtn];
    }
    if (buttonIndex == 1) {
      if ([emailHaveCert count] > 0) {
        for (int i = 0; i < [emailHaveCert count]; i++) {
          NSMutableArray *arr = [[NSMutableArray alloc] init];
          [arr addObject:[emailHaveCert objectAtIndex:i]];
          [self sendEmailto:arr
                           cc:@[]
                          bcc:@[]
                  withSubject:subjectField.text
                     withBody:
                         [messageBox.text
                             stringByReplacingOccurrencesOfString:@"\n"
                                                       withString:@"<br />"]
              withAttachments:_attachmentsArray];
        }
        sign_ = NO;
        encrypto_ = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
      }
    }
  }
}

- (void)sendEmail:(id)sender {

  // Additional check
  if (![toField.text isEmailValid]) {
    FUIAlertView *alertView = [[FUIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Notifi", nil)
                  message:NSLocalizedString(@"NotEnterEmail", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil, nil];

    alertView.titleLabel.textColor = [UIColor blackColor];
    alertView.titleLabel.font =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    alertView.messageLabel.textColor = [UIColor asbestosColor];
    alertView.messageLabel.font =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    alertView.backgroundOverlay.backgroundColor =
        [[UIColor blackColor] colorWithAlphaComponent:0.8];
    alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
    alertView.defaultButtonColor = [UIColor cloudsColor];
    alertView.defaultButtonShadowColor = [UIColor cloudsColor];
    alertView.defaultButtonFont =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
    [alertView show];

    [self updateSendButton];
    return;
  }

  CheckNetWork *initCheck = [[CheckNetWork alloc] init];
  if ([initCheck checkNetworkAvailable]) {
    [self updateIndicator];
    [self performSelector:@selector(sendEmailOper)
               withObject:self
               afterDelay:0.1];
  } else {
    UIAlertView *fail = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Error", nil)
                  message:NSLocalizedString(@"CheckInternet", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Back", nil)
        otherButtonTitles:nil, nil];
    [fail show];
  }
}

- (void)updateIndicator {
  UIActivityIndicatorView *uiBusy = [[UIActivityIndicatorView alloc]
      initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  uiBusy.hidesWhenStopped = YES;
  [uiBusy startAnimating];
  UIBarButtonItem *sendButton =
      [[UIBarButtonItem alloc] initWithCustomView:uiBusy];
  self.navigationItem.rightBarButtonItems = @[ sendButton ];
  [self.navigationController.navigationBar layoutSubviews];
}

- (void)rollBackSendBtn {
  UIButton *send = [UIButton buttonWithType:UIButtonTypeCustom];
  [send setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [send addTarget:self
                action:@selector(sendEmail:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *sendImage = [UIImage imageNamed:@"send.png"];
  [send setImage:sendImage forState:UIControlStateNormal];
  UIBarButtonItem *sendButton =
      [[UIBarButtonItem alloc] initWithCustomView:send];
  self.navigationItem.rightBarButtonItems = @[ sendButton ];
}

- (void)sendEmailOper {
    // Gửi bình thường
    [self sendEmailto:[self emailArrayFromString:toField.text]
                     cc:[self emailArrayFromString:ccField.text]
                    bcc:@[]
            withSubject:subjectField.text
               withBody:[messageBox.text
                            stringByReplacingOccurrencesOfString:@"\n"
                                                      withString:@"<br />"]
        withAttachments:_attachmentsArray];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Lấy dữ liệu Attachments từ Document Path
- (void)addItemFilePath:(ListFileDocuments *)controller
  didFinishEnteringItem:(NSString *)item {

  // Khởi tạo Array Attachment
  if (!_attachmentsArray) {
    _attachmentsArray = [NSMutableArray new];
  }
  // Lấy data
  NSData *attachment_data =
      [[NSFileManager defaultManager] contentsAtPath:item];
  MCOAttachment *attachment =
      [MCOAttachment attachmentWithData:attachment_data
                               filename:[item lastPathComponent]];

  // Lấy mimetype
  NSURL *url =
      [NSURL URLWithString:[item stringByAddingPercentEscapesUsingEncoding:
                                     NSUTF8StringEncoding]];
  CFStringRef pathExtension =
      (__bridge_retained CFStringRef)[[url lastPathComponent] pathExtension];
  CFStringRef type = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, pathExtension, NULL);
  CFRelease(pathExtension);
  NSString *mimeType =
      (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(
          type, kUTTagClassMIMEType);
  // attachment.mimeType = mimeType;

  // Lấy filename  và đóng
  // attachment.filename = [item lastPathComponent];
  [_attachmentsArray addObject:attachment];
  [self dismissViewControllerAnimated:YES completion:nil];
  [self configureViewForAttachments];
}

- (IBAction)attachButtonPressed:(FUIButton *)sender {
  [self.view endEditing:YES];
  if (totaldata_ >= 20) {
    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Error", nil)
                  message:NSLocalizedString(@"ErrorAttachment", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil];
    [alert show];
    return;
  }
  UIActionSheet *popupQuery = [[UIActionSheet alloc]
               initWithTitle:nil
                    delegate:self
           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
      destructiveButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"Albums", nil),
                             NSLocalizedString(@"SynchronizeFolder", nil), nil];
  popupQuery.tag = -1;
  popupQuery.actionSheetStyle = UIActionSheetStyleDefault;
  [popupQuery showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (actionSheet.tag == -1) {
    switch (buttonIndex) {
    case 0: {
      NSLog(@"Album");
      UIImagePickerController *pickerController =
          [[UIImagePickerController alloc] init];
      pickerController.delegate = self;
      dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:pickerController
                           animated:YES
                         completion:nil];
      });
    } break;
    case 1: {
      NSLog(@"Folder");
      ListFileDocuments *certinfo =
          [[ListFileDocuments alloc] initWithNibName:@"ListFileDocuments"
                                              bundle:nil];
      certinfo.delegate = self;
      UINavigationController *nc =
          [[UINavigationController alloc] initWithRootViewController:certinfo];
      dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:nc animated:YES completion:nil];
      });
    } break;
    default:
      break;
    }
  }

  else {
    switch (buttonIndex) {
    case 1: {
      MCOAttachment *da = [_attachmentsArray objectAtIndex:[actionSheet tag]];
      NSString *daMimeType = [da.mimeType lowercaseString];
      if ([daMimeType isEqualToString:@"application/vnd.ms-excel"] ||
          [daMimeType isEqualToString:@"application/msword"] ||
          [daMimeType isEqualToString:@"application/"
                                      @"vnd.openxmlformats-officedocument."
                                      @"wordprocessingml.document"] ||
          [daMimeType isEqualToString:@"text/plain"] ||
          [daMimeType isEqualToString:@"image/png"] ||
          [daMimeType isEqualToString:@"image/gif"] ||
          [daMimeType isEqualToString:@"image/jpeg"] ||
          [daMimeType isEqualToString:@"application/pdf"]) {
        MBProgressHUD *hud =
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Vui lòng chờ...";
        dispatch_async(
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                AuthNavigationViewController *preview =
                    [AuthNavigationViewController
                        controllerWithPreview:da.filename
                                         data:da.data
                                     mimeType:da.mimeType];
                preview.dismissOnSuccess = YES;
                preview.dismissOnError = YES;
                preview.delegate = self;
                [self presentViewController:preview
                                   animated:YES
                                 completion:nil];
              });
            });
      }
    } break;
    case 0: {
      MCOAttachment *da = [_attachmentsArray objectAtIndex:[actionSheet tag]];
      if (_attachmentsArray.count > 0) {
        NSLog(@"Delete Attachment");
        NSData *fileDeleteData = [da data];
        totaldata_ = totaldata_ - (fileDeleteData.length / 1024.0f / 1024.0f);
        if (totaldata_ < 0) {
          totaldata_ = 0;
        }
        [_attachmentsArray removeObject:da];
        [self configureViewForAttachments];
      }
    } break;
    }
  }
}

// Giữ nguyên màu cho thanh status
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
  [[UIApplication sharedApplication]
      setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
  // Khởi tạo Array Attachment
  if (!_attachmentsArray) {
    _attachmentsArray = [NSMutableArray new];
  }

  // Lấy data
  UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
  if (!image)
    image = [info objectForKey:UIImagePickerControllerOriginalImage];
  MCOAttachment *attachment =
      [MCOAttachment attachmentWithData:UIImageJPEGRepresentation(image, 1)
                               filename:@""];
  float fdata = (float)attachment.data.length / 1024.0f / 1024.0f;
  if (totaldata_ + fdata >= 20) {
    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Error", nil)
                  message:NSLocalizedString(@"ErrorAttachment", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil];
    [alert show];
    return;
  }
  totaldata_ = totaldata_ + fdata;

  NSLog(@"Total Data  %.4f", totaldata_);

  // Lấy mimetype
  NSURL *imagePath = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
  CFStringRef pathExtension = (__bridge_retained CFStringRef)[
      [imagePath lastPathComponent] pathExtension];
  CFStringRef type = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, pathExtension, NULL);
  CFRelease(pathExtension);
  NSString *mimeType =
      (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(
          type, kUTTagClassMIMEType);
  attachment.mimeType = mimeType;

  // Lấy filename và đóng cửa sổ
  __block NSString *fileName = nil;
  NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
  ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
  [library assetForURL:assetURL
           resultBlock:^(ALAsset *asset) {
             fileName = asset.defaultRepresentation.filename;
             if (!fileName) {
               CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(
                   kUTTagClassMIMEType,
                   UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType),
                   NULL);
               CFStringRef extension = UTTypeCopyPreferredTagWithClass(
                   uti, kUTTagClassFilenameExtension);
               int randNum = rand() % (999 - 1) + 1;
               fileName = [NSString
                   stringWithFormat:@"IMG_%d.%@", randNum,
                                    (__bridge_transfer NSString *)extension];
             }
             attachment.filename = fileName;
             [_attachmentsArray addObject:attachment];
             [self dismissViewControllerAnimated:YES completion:nil];
             [self configureViewForAttachments];
           }
          failureBlock:nil];
}

#pragma mark - Keyboard Listeners
- (int)keyboardHeight {
  int adjustment = 0;
  if (([_attachmentsArray count] + [_delayedAttachmentsArray count]) > 0) {
    adjustment = 44;
  }

  // 44 is an adjustment for the attachments bar.
  if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
    return 264 - adjustment;
  } else {
    return 352 - adjustment;
  }
}

- (void)keyboardWasShown:(id)sender {
  keyboardState = YES;
  self.view.frame =
      CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                 self.view.frame.size.width,
                 self.view.frame.size.height - [self keyboardHeight]);
  NSLog(@"Keyboard shown");
}

- (void)keyboardWillHide:(id)sender {
  keyboardState = NO;
  NSLog(@"Keyboard hiding");
  self.view.frame =
      CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
                 self.view.frame.size.width,
                 self.view.frame.size.height + [self keyboardHeight]);
}

- (void)willRotateToInterfaceOrientation:
            (UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
  if (keyboardState) {
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
      self.view.frame = CGRectMake(
          self.view.frame.origin.x, self.view.frame.origin.y,
          self.view.frame.size.width, self.view.frame.size.height + 264 - 352);
    } else {
      self.view.frame = CGRectMake(
          self.view.frame.origin.x, self.view.frame.origin.y,
          self.view.frame.size.width, self.view.frame.size.height + 352 - 264);
    }
  }
}

#pragma mark - EMAIL HELPERS

- (NSString *)emailStringFromArray:(NSArray *)emails {
  return [emails componentsJoinedByString:@", "];
}

- (NSArray *)emailArrayFromString:(NSString *)emailstring {
  // Need to remove empty emails with trailing
  NSArray *emails = [emailstring
      componentsSeparatedByCharactersInSet:
          [NSCharacterSet characterSetWithCharactersInString:@","]];
  NSPredicate *notBlank =
      [NSPredicate predicateWithFormat:@"length > 0 AND SELF != ' '"];

  return [emails filteredArrayUsingPredicate:notBlank];
}

- (void)sendEmailto:(NSArray *)to
                 cc:(NSArray *)cc
                bcc:(NSArray *)bcc
        withSubject:(NSString *)subject
           withBody:(NSString *)body
    withAttachments:(NSArray *)attachments {

  MCOSMTPSession *smtpSession = [[AuthManager sharedManager] getSmtpSession];

  NSString *username = smtpSession.username;

  MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];

  /* Mailcore Not Sign && Not Encrypt */
  [[builder header]
      setFrom:[MCOAddress addressWithDisplayName:nil mailbox:username]];
  NSMutableArray *toma = [[NSMutableArray alloc] init];
  for (NSString *toAddress in to) {
    NSString *toAddressMix =
        [ComposeCommonMethod parseAndBase64AddressName:toAddress];
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:toAddressMix];
    [toma addObject:newAddress];
  }
  [[builder header] setTo:toma];
  NSMutableArray *ccma = [[NSMutableArray alloc] init];
  for (NSString *ccAddress in cc) {
    NSString *ccAddressMix =
        [ComposeCommonMethod parseAndBase64AddressName:ccAddress];
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:ccAddressMix];
    [ccma addObject:newAddress];
  }
  [[builder header] setCc:ccma];
  NSMutableArray *bccma = [[NSMutableArray alloc] init];
  for (NSString *bccAddress in bcc) {
    NSString *bccAddressMix =
        [ComposeCommonMethod parseAndBase64AddressName:bccAddress];
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:bccAddressMix];
    [bccma addObject:newAddress];
  }

  [[builder header] setBcc:bccma];
  [[builder header] setSubject:subject];
  if (!sign_ && !encrypto_) {
    [builder setHTMLBody:body];
  }

  /* Sending attachments */
  if ([attachments count] > 0) {
    [builder setAttachments:attachments];
  }

  NSData *rfc822Data = [builder data];
  NSString *to_ = [to componentsJoinedByString:@", "];
  NSString *cc_ = [cc componentsJoinedByString:@", "];
  MCOSMTPSendOperation *sendOperation = nil;

  // Gửi mail bình thường
  if (!sign_ && !encrypto_) {
    sendOperation = [smtpSession sendOperationWithData:rfc822Data];
  }
    
err:
  NSLog(@"Send Operation");
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  [sendOperation start:^(NSError *error) {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    sign_ = NO;
    encrypto_ = NO;
    if (error) {
      NSLog(@"%@ Error sending email:%@", username, error);
      for (int i = 0; i < 2; i++) {
        [CheckNetWork playSoundWhenDone:@"ct-busy.caf"];
      }
      UIAlertView *alertView = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Error", nil)
                    message:NSLocalizedString(@"CantSendEmail", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
          otherButtonTitles:nil];
      [alertView show];
    } else {
      NSLog(@"%@ Successfully sent email!", username);
      if (mailtype != 2 && mailtype != 4) {
        [self saveOperationWithData:rfc822Data];
      }
      [CheckNetWork playSoundWhenDone:@"mail-sent.caf"];
      UIWindow *window = [[UIApplication sharedApplication] delegate].window;
      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
      hud.labelText = NSLocalizedString(@"SuccessSendEmail", nil);
      hud.labelFont = [UIFont systemFontOfSize:14];
      hud.mode = MBProgressHUDModeCustomView;
      hud.margin = 12.0f;
      hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 80.0f;
      hud.removeFromSuperViewOnHide = YES;
      [hud hide:YES afterDelay:3.0];
    }
  }];
}

- (void)saveOperationWithData:(NSData *)data {
  NSDictionary *folderNames = [ListAllFolders shareFolderNames];
  MCOIMAPAppendMessageOperation *op =
      [[[AuthManager sharedManager] getImapSession]
          appendMessageOperationWithFolder:[folderNames objectForKey:@"Sent"]
                               messageData:data
                                     flags:MCOIMAPFolderFlagNone];

  [op start:^(NSError *error, uint32_t createdUID) {
    if (error == nil) {
      NSLog(@"created message with UID %lu", (unsigned long)createdUID);
    } else {
      NSLog(@"Error copy email %@", error.description);
    }
  }];
}

- (IBAction)attachmentTapped:(id)sender {
  if (!forward_) {
    UIActionSheet *popupQuery = [[UIActionSheet alloc]
                 initWithTitle:nil
                      delegate:self
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
        destructiveButtonTitle:nil
             otherButtonTitles:NSLocalizedString(@"RemoveAtt", nil),
                               NSLocalizedString(@"View", nil), nil];

    popupQuery.tag = [sender tag];
    NSLog(@"Sender Tag %d", (int)[sender tag]);
    popupQuery.actionSheetStyle = UIActionSheetStyleDefault;
    [popupQuery showInView:self.view];
  } else {
    UIActionSheet *popupQuery = [[UIActionSheet alloc]
                 initWithTitle:nil
                      delegate:self
             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
        destructiveButtonTitle:nil
             otherButtonTitles:NSLocalizedString(@"RemoveAtt", nil), nil];

    popupQuery.tag = [sender tag];
    NSLog(@"Sender Tag %d", (int)[sender tag]);
    popupQuery.actionSheetStyle = UIActionSheetStyleDefault;
    [popupQuery showInView:self.view];
  }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  if (textField.tag == ToTextFieldTag) {
    [self updateSendButton];
  }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  if (textField.tag == ToTextFieldTag) {
    [self updateSendButton];
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  NSUInteger nextTextFieldTag = textField.tag + 1;
  [textField resignFirstResponder];
  if (nextTextFieldTag < 3) {
    UITextField *newTextField =
        (UITextField *)[self.view viewWithTag:nextTextFieldTag];
    [newTextField becomeFirstResponder];
  } else if (nextTextFieldTag == 3) {
    [messageBox becomeFirstResponder];
    return NO;
  }
  return YES;
}

@end
