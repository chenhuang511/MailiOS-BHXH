//
//  ComposerViewController.m
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "AuthManager.h"
#import "Composer_iPhoneViewController.h"
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
#import "FPPopoverController.h"
#import "MCOMessageView.h"

#import "CheckNetWork.h"
#import "MsgListViewController.h"

#import "Base64.h"
#import "DBManager.h"
#import "MBProgressHUD.h"
#import "pem.h"
#import "x509.h"

#import "AuthNavigationViewController.h"
#import "ListFileDocuments.h"
#import "TRAddressBookSuggestion.h"
#import "TokenType.h"
#import "WebService.h"
#import <AssetsLibrary/AssetsLibrary.h>

#import "ListAllFolders.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "Constants.h"

#define SKIPERR 13

typedef enum {
  ToTextFieldTag,
  CcTextFieldTag,
  SubjectTextFieldTag
} TextFildTag;

@interface Composer_iPhoneViewController () <
    UIPopoverControllerDelegate, UITableViewDataSource, UITableViewDelegate,
    UIActionSheetDelegate, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate, ListFileDocumentsDelegate,
    AuthViewControllerDelegate> {
  __weak IBOutlet UIScrollView *_theScrollView;
}

@property(weak, nonatomic) IBOutlet FUIButton *attachButton;
@property(weak, nonatomic) IBOutlet UIView *attachmentSeparatorView;
@property(weak, nonatomic) IBOutlet UILabel *attachmentsTitleLabel;

@end

@implementation Composer_iPhoneViewController {
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

@synthesize toField, ccField, subjectField, messageBox, attachLabel, attachLine,
    toLabel, subjectLabel, attLabel;

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
      forward = YES;
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

- (void)textViewDidChange:(UITextView *)textView {
  float height = textView.contentSize.height;
  [UITextView beginAnimations:nil context:nil];
  [UITextView setAnimationDuration:0.5];

  CGRect frame = textView.frame;
  frame.size.height = height + 10.0; // Give it some padding
  textView.frame = frame;
  [UITextView commitAnimations];
  CGFloat scrollViewHeight = attachLine.frame.origin.y;
  //    for (UIView* view in _theScrollView.subviews)
  //    {
  scrollViewHeight += textView.frame.size.height;
  //    }
  [_theScrollView setContentSize:(CGSizeMake(_theScrollView.frame.size.width,
                                             scrollViewHeight))];
}

- (CGFloat)textViewHeightForAttributedText:(NSAttributedString *)text
                                  andWidth:(CGFloat)width {
  UITextView *textView = [[UITextView alloc] init];
  [textView setAttributedText:text];
  CGSize size = [textView sizeThatFits:CGSizeMake(width, FLT_MAX)];
  return size.height;
}

- (void)initView {

  CGRect screenRect = [[UIScreen mainScreen] bounds];
  CGRect toLabelFrame = CGRectMake(15, 10, 30, 20);
  [toLabel setFrame:toLabelFrame];
  CGRect toFieldFrame =
      CGRectMake(15 + 30 + 10, 10, screenRect.size.width - 15 - 45, 20);
  [toField setFrame:toFieldFrame];
  CGRect line1 = CGRectMake(15, toField.frame.origin.y + 30,
                            screenRect.size.width - 15 - 15, 1);
  [_line1 setFrame:line1];
  CGRect ccLabelFrame = CGRectMake(15, line1.origin.y + 20 - 20 / 2, 25, 20);
  [_ccLabel setFrame:ccLabelFrame];
  CGRect ccFieldFrame = CGRectMake(15 + 25 + 10, line1.origin.y + 20 - 20 / 2,
                                   screenRect.size.width - 15 - 50, 20);
  [ccField setFrame:ccFieldFrame];
  CGRect line2 = CGRectMake(15, ccField.frame.origin.y + 30,
                            screenRect.size.width - 15 - 15, 1);
  [_line2 setFrame:line2];
  CGRect subjectLabelFrame =
      CGRectMake(15, line2.origin.y + 20 - 20 / 2, 60, 20);
  [subjectLabel setFrame:subjectLabelFrame];
  CGRect subjectFieldFrame =
      CGRectMake(15 + 60 + 5, line2.origin.y + 20 - 20 / 2,
                 screenRect.size.width - 100, 20);
  [subjectField setFrame:subjectFieldFrame];
  CGRect line3 = CGRectMake(15, subjectField.frame.origin.y + 30,
                            screenRect.size.width - 15 - 15, 1);
  [_line3 setFrame:line3];
  CGRect attLabelFrame = CGRectMake(15, line3.origin.y + 20 - 20 / 2, 100, 20);
  [attLabel setFrame:attLabelFrame];

  if (btn_) {
    [btn_ removeFromSuperview];
  }
  btn_ = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  CGRect attButtonFrame = CGRectMake(screenRect.size.width - 15 - 30,
                                     line3.origin.y + 20 - 20 / 2, 22, 22);
  [btn_ setFrame:attButtonFrame];
  [btn_ setImage:[UIImage imageNamed:@"attachment_co.png"]
        forState:UIControlStateNormal];
  [btn_ addTarget:self
                action:@selector(attachButtonPressed:)
      forControlEvents:UIControlEventTouchUpInside];
  [_theScrollView addSubview:btn_];
  CGRect attLabelFrame_Title = CGRectMake(15, attLabelFrame.origin.y + 30 + 5,
                                          screenRect.size.width - 15 - 15, 1);
  [attachLabel setFrame:attLabelFrame_Title];

  self.navigationController.navigationBarHidden = NO;
  [self.navigationController.navigationBar
      configureFlatNavigationBarWithColor:[UIColor
                                              colorFromHexCode:barColor]];
  [self.navigationController.navigationBar setTitleTextAttributes:@{
    NSForegroundColorAttributeName : [UIColor whiteColor]
  }];

  UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
  [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [back addTarget:self
                action:@selector(closeWindow_IphoneCompose:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
  [back setImage:backImage forState:UIControlStateNormal];
  UIBarButtonItem *backButton =
      [[UIBarButtonItem alloc] initWithCustomView:back];

  UIButton *send = [UIButton buttonWithType:UIButtonTypeCustom];
  [send setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [send addTarget:self
                action:@selector(sendEmail:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *sendImage = [UIImage imageNamed:@"send.png"];
  [send setImage:sendImage forState:UIControlStateNormal];
  UIBarButtonItem *sendButton =
      [[UIBarButtonItem alloc] initWithCustomView:send];

  self.navigationItem.leftBarButtonItems = @[ backButton ];
  self.navigationItem.rightBarButtonItems = @[ sendButton ];

  self.attachButton.buttonColor = [UIColor cloudsColor];
  self.attachButton.shadowColor = [UIColor peterRiverColor];

  [self configureViewForAttachments];
  keyboardState = NO;

  // MenuFromNavigation
  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"reload"];
  [[NSUserDefaults standardUserDefaults] synchronize];
//  if (self.navigationItem) {
//    CGRect frame =
//        CGRectMake(0.0, 0.0, 120,
//                   self.navigationController.navigationBar.bounds.size.height);
//
//    SINavigationMenuView *menu = [[SINavigationMenuView alloc]
//        initWithFrame:frame
//                title:NSLocalizedString(@"SecureOptions", nil)];
//    menu.SIWidth = [[UIScreen mainScreen] bounds].size.width;
//    [menu displayMenuInView:self.navigationController.view];
//    menu.items = @[
//      NSLocalizedString(@"SignEmail", nil),
//      NSLocalizedString(@"EncryptEmail", nil)
//    ];
//    menu.delegate = self;
//    self.navigationItem.titleView = menu;
//    BOOL isAlwaySign =
//        [[NSUserDefaults standardUserDefaults] boolForKey:@"luonky"];
//    if (isAlwaySign) {
//      sign = NO;
//      [menu itemChecked];
//      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC),
//                     dispatch_get_main_queue(), ^{
//                       [self didSelectItemAtIndex:0];
//                     });
//    }
//  }
  attachLabel.text = nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self initView];
  self.messageBox.scrollEnabled = NO;
  totaldata = 0;
  attLabel.text = NSLocalizedString(@"AttachFile", nil);
  toLabel.text = NSLocalizedString(@"To", nil);
  subjectLabel.text = NSLocalizedString(@"Subject", nil);

  // Unlock
  [MsgListViewController setUnlockMail:YES];

  NSString *username = nil;
  NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count > 0 && accIndex < listAccount.count) {
    username = [listAccount objectAtIndex:accIndex + 1];
  }
  token = [[[[DBManager getSharedInstance] findTokenTypeByEmail:username]
      objectAtIndex:0] intValue];

  if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    self.edgesForExtendedLayout = UIRectEdgeNone;

  // Ẩn bàn phím khi nhấn ra ngoài vùng nhập liệu
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
      initWithTarget:self
              action:@selector(dismissKeyboard)];
  [self.view addGestureRecognizer:tap];
  [_theScrollView setContentSize:CGSizeMake(self.view.frame.size.width, 2000)];

  toField.text = _toString;
  ccField.text = _ccString;
  subjectField.text = _subjectString;
  self.messageBox.text = _bodyString;
  [toField becomeFirstResponder];

  // Gợi ý
  [self autoCompleteView:username];

  mailtype = [[[NSUserDefaults standardUserDefaults] objectForKey:@"mailtype"]
      integerValue];
}

- (void)dismissKeyboard {
  [self.view endEditing:YES];
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
}

- (void)singleTapRecognized:(UIGestureRecognizer *)gestureRecognizer {
  // End of MenuFromNavigation
  [self.messageBox becomeFirstResponder];
  [self.messageBox setEditable:YES];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
  // Focus first character
  textView.selectedRange = NSMakeRange(0, 0);
  return YES;
}

- (void)configureViewForAttachments {
  // Delete
  [self.attachmentView_ removeFromSuperview];
  self.attachmentView_ = nil;
  self.attachmentView_ = [[UIView alloc]
      initWithFrame:CGRectMake(0, self.attachLabel.frame.origin.y,
                               [[UIScreen mainScreen] bounds].size.width - 15 -
                                   15,
                               0)];

  if (([_attachmentsArray count] + [_delayedAttachmentsArray count]) > 0) {
    NSMutableArray *attachmentLabels = [[NSMutableArray alloc] init];
    NSMutableArray *attachmentNames = [[NSMutableArray alloc] init];
    int tag = 0;
    for (MCOAttachment *a in _attachmentsArray) {
      UIButton *label = [UIButton buttonWithType:UIButtonTypeCustom];
      label.frame = CGRectMake(0, 0, 100, 60);
      label.contentHorizontalAlignment =
          UIControlContentHorizontalAlignmentLeft;
      label.contentEdgeInsets = UIEdgeInsetsMake(10, 50, 10, 0);
      [label.titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
      [label setTitle:[a filename] forState:UIControlStateNormal];
      [label setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
      [label.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:12]];
      label.tag = tag;
      tag++;
      [label addTarget:self
                    action:@selector(attachmentTapped:)
          forControlEvents:UIControlEventTouchUpInside];
      UIImageView *imageview =
          [[UIImageView alloc] initWithFrame:CGRectMake(17, 15, 22, 22)];
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
      label.frame = CGRectMake(0, 0, 100, 60);
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
          [[UIImageView alloc] initWithFrame:CGRectMake(17, 15, 22, 22)];
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

    int startingHeight = self.attachmentsTitleLabel.frame.origin.y +
                         self.attachmentsTitleLabel.frame.size.height / 2;
    int i = 0;
    for (UIButton *attachmentLabel in attachmentLabels) {
      attachmentLabel.frame =
          CGRectMake(10, startingHeight - 10,
                     [[UIScreen mainScreen] bounds].size.width - 70,
                     attachmentLabel.frame.size.height);
      i = i + attachmentLabel.frame.size.height;
      [self.attachmentView_
          setFrame:CGRectMake(self.attachmentView_.frame.origin.x,
                              self.attachmentView_.frame.origin.y,
                              self.attachmentView_.frame.size.width,
                              self.attachmentView_.frame.size.height +
                                  attachmentLabel.frame.size.height)];

      [self.attachmentView_ addSubview:attachmentLabel];

      startingHeight += attachmentLabel.frame.size.height - 30;
    }
    CGRect lastAttachRect = [self.attachmentView_ frame];

    [UIView animateWithDuration:0.5
        delay:0.2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.attachLine.frame =
              CGRectMake(self.attachLine.frame.origin.x,
                         lastAttachRect.origin.y + i / 2 + 4,
                         self.attachmentView_.frame.size.width,
                         self.attachLine.frame.size.height);

          self.messageBox.frame = CGRectMake(self.messageBox.frame.origin.x,
                                             self.attachLine.frame.origin.y + 9,
                                             self.messageBox.frame.size.width,
                                             self.messageBox.frame.size.height);
        }

        completion:^(BOOL finished) {
          [self updateSendButton];
        }];
  } else {
    CGRect lastAttachRect = [self.attachLabel frame];
    [UIView animateWithDuration:0.5
        delay:0.2
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
          self.attachLine.frame = CGRectMake(
              self.attachLine.frame.origin.x,
              lastAttachRect.origin.y + lastAttachRect.size.height - 7,
              self.attachmentView_.frame.size.width,
              self.attachLine.frame.size.height);

          self.messageBox.frame = CGRectMake(self.messageBox.frame.origin.x,
                                             self.attachLine.frame.origin.y + 9,
                                             self.messageBox.frame.size.width,
                                             self.messageBox.frame.size.height);
        }
        completion:^(BOOL finished) {
          [self updateSendButton];
        }];
  }
  [_theScrollView addSubview:self.attachmentView_];
  [_theScrollView addSubview:self.messageBox];
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
    alertSend = [self isEmailTextFieldValid];
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

- (void)closeWindow_IphoneCompose:(id)sender {
  if ((subjectField.text.length != 0) || (messageBox.text.length != 0)) {
    alertDestroy = YES;
  } else {
    alertDestroy = NO;
  }

  if (!alertDestroy && !alertSend) {
    [self dismissKeyboard];
    [self dismissViewControllerAnimated:YES completion:nil];
    sign = NO;
    encrypto = NO;
  } else {
    [self.view endEditing:YES];
    FUIAlertView *alertView = [[FUIAlertView alloc]
            initWithTitle:nil
                  message:NSLocalizedString(@"DestroyMail", nil)
                 delegate:self
        cancelButtonTitle:NSLocalizedString(@"Back", nil)
        otherButtonTitles:NSLocalizedString(@"Ok", nil), nil];
    alertView.messageLabel.textColor = [UIColor asbestosColor];
    alertView.messageLabel.font =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
    alertView.backgroundOverlay.backgroundColor =
        [[UIColor blackColor] colorWithAlphaComponent:0.8];
    alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
    alertView.defaultButtonColor = [UIColor cloudsColor];
    alertView.defaultButtonShadowColor = [UIColor cloudsColor];
    alertView.defaultButtonFont =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
    alertView.tag = 0;
    [alertView show];
  }
}

- (void)reloadMenuView {
  [self dismissKeyboard];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"reload"];
  [[NSUserDefaults standardUserDefaults] synchronize];
//  CGRect frame = CGRectMake(
//      0, 0.0, 120, self.navigationController.navigationBar.bounds.size.height);
//  SINavigationMenuView *menu = [[SINavigationMenuView alloc]
//      initWithFrame:frame
//              title:NSLocalizedString(@"SecureOptions", nil)];
//  menu.SIWidth = [[UIScreen mainScreen] bounds].size.width;
//  [menu displayMenuInView:self.navigationController.view];
//
//  menu.items = @[
//    NSLocalizedString(@"SignEmail", nil),
//    NSLocalizedString(@"EncryptEmail", nil)
//  ];
//  menu.delegate = self;
//  [menu itemUnchecked];
//  self.navigationItem.titleView = menu;
//  sign = NO;
//  encrypto = NO;
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
        sign = NO;
        encrypto = NO;
        [self dismissViewControllerAnimated:YES completion:nil];
      }
    }
  }
}

- (void)sendEmail:(id)sender {
  if (![toField.text isEmailValid]) {
    FUIAlertView *alertView = [[FUIAlertView alloc]
            initWithTitle:NSLocalizedString(@"EmailNotCorrect", nil)
                  message:NSLocalizedString(@"NotEnterEmail", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil, nil];
    alertView.titleLabel.textColor = [UIColor blackColor];
    alertView.titleLabel.font =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    alertView.messageLabel.textColor = [UIColor asbestosColor];
    alertView.messageLabel.font =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    alertView.backgroundOverlay.backgroundColor =
        [[UIColor blackColor] colorWithAlphaComponent:0.8];
    alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
    alertView.defaultButtonColor = [UIColor cloudsColor];
    alertView.defaultButtonShadowColor = [UIColor cloudsColor];
    alertView.defaultButtonFont =
        [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
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

- (void)sendEmailOper {

  // Gửi mail mã hoá; nhiều người
  if (encrypto) {
    NSArray *toArray = [self emailArrayFromString:toField.text];
    NSArray *ccArray = [self emailArrayFromString:ccField.text];
    NSMutableArray *invalidEmail = [[NSMutableArray alloc] init];
    emailHaveCert = [[NSMutableArray alloc] init];

    for (int i = 0; i < [toArray count]; i++) {
      BOOL check = [self checkEmailHaveCert:[toArray objectAtIndex:i]];
      if (!check) {
        [invalidEmail addObject:[toArray objectAtIndex:i]];
      } else {
        [emailHaveCert addObject:[toArray objectAtIndex:i]];
      }
    }

    for (int i = 0; i < [ccArray count]; i++) {
      BOOL check = [self checkEmailHaveCert:[ccArray objectAtIndex:i]];
      if (!check) {
        [invalidEmail addObject:[ccArray objectAtIndex:i]];
      } else {
        [emailHaveCert addObject:[ccArray objectAtIndex:i]];
      }
    }
    if ([invalidEmail count] > 0 && [emailHaveCert count] > 0) {
      NSString *stringEmail = [invalidEmail componentsJoinedByString:@","];
      NSLog(@"Email that not have cert to encrypt is %@", stringEmail);
      NSString *msg = [NSString
          stringWithFormat:@"%@ %@", NSLocalizedString(@"ListErrMail", nil),
                           stringEmail];
      [self.view endEditing:YES];
      FUIAlertView *alertView = [[FUIAlertView alloc]
              initWithTitle:nil
                    message:msg
                   delegate:self
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:NSLocalizedString(@"SendSkipErr", nil), nil];
      alertView.messageLabel.textColor = [UIColor asbestosColor];
      alertView.messageLabel.font =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
      alertView.backgroundOverlay.backgroundColor =
          [[UIColor blackColor] colorWithAlphaComponent:0.8];
      alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
      alertView.defaultButtonColor = [UIColor cloudsColor];
      alertView.defaultButtonShadowColor = [UIColor cloudsColor];
      alertView.defaultButtonFont =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
      alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
      alertView.tag = SKIPERR;
      [alertView show];
    } else if ([invalidEmail count] > 0 && [emailHaveCert count] == 0) {
      FUIAlertView *alertView = [[FUIAlertView alloc]
              initWithTitle:nil
                    message:NSLocalizedString(@"AllErrMail", nil)
                   delegate:self
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:nil];
      alertView.messageLabel.textColor = [UIColor asbestosColor];
      alertView.messageLabel.font =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
      alertView.backgroundOverlay.backgroundColor =
          [[UIColor blackColor] colorWithAlphaComponent:0.8];
      alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
      alertView.defaultButtonColor = [UIColor cloudsColor];
      alertView.defaultButtonShadowColor = [UIColor cloudsColor];
      alertView.defaultButtonFont =
          [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
      alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
      alertView.tag = SKIPERR;
      [alertView show];
    } else if ([invalidEmail count] == 0) {
      for (int i = 0; i < [emailHaveCert count]; i++) {
        NSMutableArray *arr = [[NSMutableArray alloc] init];
        [arr addObject:[emailHaveCert objectAtIndex:i]];
        [self sendEmailto:arr
                         cc:@[]
                        bcc:@[]
                withSubject:subjectField.text
                   withBody:[messageBox.text
                                stringByReplacingOccurrencesOfString:@"\n"
                                                          withString:@"<br />"]
            withAttachments:_attachmentsArray];
      }
      sign = NO;
      encrypto = NO;
      [self dismissViewControllerAnimated:YES completion:nil];
    }
  } else {
    // Gửi bình thường
    [self sendEmailto:[self emailArrayFromString:toField.text]
                     cc:[self emailArrayFromString:ccField.text]
                    bcc:@[]
            withSubject:subjectField.text
               withBody:[messageBox.text
                            stringByReplacingOccurrencesOfString:@"\n"
                                                      withString:@"<br />"]
        withAttachments:_attachmentsArray];

    sign = NO;
    encrypto = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (BOOL)checkEmailHaveCert:(NSString *)to_ {

  // Build "to" Maibox, parse DisplayName + Mailbox if exists
  if ([to_ rangeOfString:@" "].location != NSNotFound) {
    to_ = [to_ stringByReplacingOccurrencesOfString:@" " withString:@""];
  }
  NSRange prefix = [to_ rangeOfString:@"<"];
  NSRange endfix = [to_ rangeOfString:@">"];
  if (prefix.location != NSNotFound && endfix.location != NSNotFound) {
    NSString *to_parse = [to_ substringFromIndex:prefix.location + 1];
    NSRange end = [to_parse rangeOfString:@">"];
    to_ = [to_parse substringToIndex:end.location];
  }

  // Get cert
  NSArray *receiverArr = [[DBManager getSharedInstance] findByEmail:to_];
  if (receiverArr) {
    return YES;
  } else {
    // Get webservice
    WebService *initWebBase = [[WebService alloc] init];
    NSString *certContent = [initWebBase GetCertMail:to_];
    if (certContent.length > 20) {
      [ComposeCommonMethod saveCertToDatabaseBy:to_ andCert:certContent];
      return YES;
    } else {
      return NO;
    }
  }
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

  // Lấy filename  và đóng
  [_attachmentsArray addObject:attachment];
  [self dismissViewControllerAnimated:YES completion:nil];
  [self configureViewForAttachments];
}

- (IBAction)attachButtonPressed:(FUIButton *)sender {
  [self.view endEditing:YES];

  if (totaldata >= 20) {
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
  } else {
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
        hud.labelText = NSLocalizedString(@"PleaseWait", nil);
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
        totaldata = totaldata - (fileDeleteData.length / 1024.0f / 1024.0f);
        if (totaldata < 0) {
          totaldata = 0;
        }
        [_attachmentsArray removeObject:da];
        [self configureViewForAttachments];
      }
    } break;
    }
  }
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

  if (totaldata + fdata >= 20) {
    UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Error", nil)
                  message:NSLocalizedString(@"ErrorAttachment", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil];
    [alert show];
    return;
  }
  totaldata = totaldata + fdata;

  NSLog(@"Total Data  %.4f", totaldata);
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

#pragma mark - EMAIL HELPERS
- (NSString *)emailStringFromArray:(NSArray *)emails {
  return [emails componentsJoinedByString:@", "];
}

- (NSArray *)emailArrayFromString:(NSString *)emailstring {
  // Need to remove empty emails with trailing ,
  NSArray *emails = [emailstring
      componentsSeparatedByCharactersInSet:
          [NSCharacterSet characterSetWithCharactersInString:@","]];
  NSPredicate *notBlank =
      [NSPredicate predicateWithFormat:@"length > 0 AND SELF != ' '"];
  return [emails filteredArrayUsingPredicate:notBlank];
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

- (void)sendEmailto:(NSArray *)to
                 cc:(NSArray *)cc
                bcc:(NSArray *)bcc
        withSubject:(NSString *)subject
           withBody:(NSString *)body
    withAttachments:(NSArray *)attachments {

  [self.view endEditing:YES];
  MCOSMTPSession *smtpSession = [[AuthManager sharedManager] getSmtpSession];
  NSString *username = smtpSession.username;

  MCOMessageBuilder *builder = [[MCOMessageBuilder alloc] init];

  /* Mailcore Not Sign && Not Encrypt */
  [[builder header]
      setFrom:[MCOAddress addressWithDisplayName:nil mailbox:username]];

  // To
  NSMutableArray *toma = [[NSMutableArray alloc] init];
  for (NSString *toAddress in to) {
    NSString *toAddressMix =
        [ComposeCommonMethod parseAndBase64AddressName:toAddress];
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:toAddressMix];
    [toma addObject:newAddress];
  }
  [[builder header] setTo:toma];
  // CC
  NSMutableArray *ccma = [[NSMutableArray alloc] init];
  for (NSString *ccAddress in cc) {
    NSString *ccAddressMix =
        [ComposeCommonMethod parseAndBase64AddressName:ccAddress];
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:ccAddressMix];
    [ccma addObject:newAddress];
  }
  [[builder header] setCc:ccma];
  // Bcc
  NSMutableArray *bccma = [[NSMutableArray alloc] init];
  for (NSString *bccAddress in bcc) {
    NSString *bccAddressMix =
        [ComposeCommonMethod parseAndBase64AddressName:bccAddress];
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:bccAddressMix];
    [bccma addObject:newAddress];
  }
  [[builder header] setBcc:bccma];

  // Normal subject
  [[builder header] setSubject:subject];
  // Normal body
  if (!sign && !encrypto) {
    [builder setHTMLBody:body];
  }

  /* Sending attachments */
  if ([attachments count] > 0) {
    [builder setAttachments:attachments];
  }

  NSData *rfc822Data = [builder data];
  MCOSMTPSendOperation *sendOperation = nil;

  // Gửi mail bình thường
  if (!sign && !encrypto) {
    sendOperation = [smtpSession sendOperationWithData:rfc822Data];
  }
    
err:
  NSLog(@"Send Operation");
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  [sendOperation start:^(NSError *error) {
    sign = NO;
    encrypto = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (error) {
      for (int i = 0; i < 2; i++) {
        [CheckNetWork playSoundWhenDone:@"ct-busy.caf"];
      }
      NSLog(@"%@ Error sending email:%@", username, error);
      UIAlertView *alertView = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Error", nil)
                    message:NSLocalizedString(@"CantSendEmail", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
          otherButtonTitles:nil];
      [alertView show];
    } else {
      if (mailtype != 2 && mailtype != 4) {
        [self saveOperationWithData:rfc822Data];
      }
      NSLog(@"%@ Successfully sent email!", username);
      [CheckNetWork playSoundWhenDone:@"mail-sent.caf"];
      UIWindow *window = [[UIApplication sharedApplication] delegate].window;
      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
      hud.userInteractionEnabled = YES;
      hud.labelText = NSLocalizedString(@"SuccessSendEmail", nil);
      hud.labelFont = [UIFont systemFontOfSize:14];
      hud.mode = MBProgressHUDModeCustomView;
      hud.margin = 12.0f;
      hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
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
                                     flags:MCOMessageFlagSeen];

  [op start:^(NSError *error, uint32_t createdUID) {
    if (error == nil) {
      NSLog(@"created message with UID %lu", (unsigned long)createdUID);
    } else {
      NSLog(@"Error copy email %@", error.description);
    }
  }];
}

- (IBAction)attachmentTapped:(id)sender {
  if (!forward) {
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

// Giữ nguyên màu cho thanh status
- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
  [[UIApplication sharedApplication]
      setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
}

- (void)viewDidUnload {
  [super viewDidUnload];
}

- (void)willAnimateRotationToInterfaceOrientation:
            (UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration {
  [self initView];
}

@end
