//
//  HeaderView.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/4/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "HeaderView.h"
#import "UIColor+FlatUI.h"
#import "FPMimetype.h"
#import "DelayedAttachment.h"
#import "ComposerViewController.h"
#import "Composer_iPhoneViewController.h"
#import "UTIFunctions.h"

#import "AuthManager.h"
#import "AuthNavigationViewController.h"
#import "SoftToken_SignEnvelope.h"
#import "CertInfoView.h"

#import "FPPopoverController.h"
#import "MCOMessageView.h"
#import "MessageDetailViewController_iPhone.h"
#import "TokenType.h"
#import "ActionPickerViewController.h"

#import "FFCircularProgressView.h"

@interface HeaderView () <UIActionSheetDelegate, AuthViewControllerDelegate> {
}

@property MCOIMAPMessage *message;
@property NSArray *attachments;
@end

@implementation HeaderView

#define buttonSign 0

- (id)initWithFrame:(CGRect)frame
               message:(MCOAbstractMessage *)message
    delayedAttachments:(NSArray *)attachments {
  self = [super initWithFrame:frame];
  if (self) {
    if ([message isKindOfClass:[MCOIMAPMessage class]]) {
      self.message = (MCOIMAPMessage *)message;
      self.attachments = attachments;
      [self render];
    }

    if ([message isKindOfClass:[MCOMessageParser class]]) {
      self.message = (MCOIMAPMessage *)message;
      self.attachments = attachments;
      [self render];
    }
  }
  return self;
}

- (UIView *)generateSpacer {

  if (IDIOM == IPHONE) {
    UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 5)];
    spacer.backgroundColor = [UIColor clearColor];
    return spacer;
  } else {
    UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 10)];
    spacer.backgroundColor = [UIColor clearColor];
    return spacer;
  }
}

- (UIView *)generateHR {
  UIView *hr = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
  hr.backgroundColor = [UIColor cloudsColor];
  return hr;
}

- (void)render {
  [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

  MCOMessageHeader *header = [self.message header];
  NSMutableArray *headerLabels = [[NSMutableArray alloc] init];

  NSString *fromString = [[header from] displayName]
                             ? [[header from] displayName]
                             : [[header from] mailbox];
  if (fromString) {
    if (IDIOM == IPAD) {
      fromString =
          [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"From", nil),
                                     fromString];
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 25)];
      label.text = fromString;
      label.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
      [headerLabels addObject:label];
    } else {
      fromString =
          [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"From", nil),
                                     fromString];
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
      label.text = fromString;
      label.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
      [headerLabels addObject:label];
    }
  }

  if ([self displayNamesFromAddressArray:[header to]]) {
    if (IDIOM == IPAD) {
      NSString *toString = [NSString
          stringWithFormat:@"%@ %@", NSLocalizedString(@"To", nil),
                           [self displayNamesFromAddressArray:[header to]]];
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 25)];
      label.text = toString;
      label.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
      label.textColor = [UIColor grayColor];
      [headerLabels addObject:label];
    } else {
      NSString *toString = [NSString
          stringWithFormat:@"%@ %@", NSLocalizedString(@"To", nil),
                           [self displayNamesFromAddressArray:[header to]]];
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
      label.text = toString;
      label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
      label.textColor = [UIColor grayColor];
      [headerLabels addObject:label];
    }
  }

  if ([self displayNamesFromAddressArray:[header cc]]) {
    if (IDIOM == IPAD) {
      NSString *ccString = [NSString
          stringWithFormat:@"CC: %@",
                           [self displayNamesFromAddressArray:[header cc]]];
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 25)];
      label.text = ccString;
      label.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
      label.textColor = [UIColor grayColor];
      [headerLabels addObject:label];
    } else {
      NSString *ccString = [NSString
          stringWithFormat:@"CC: %@",
                           [self displayNamesFromAddressArray:[header cc]]];
      UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
      label.text = ccString;
      label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
      label.textColor = [UIColor grayColor];
      [headerLabels addObject:label];
    }
  }

  [headerLabels addObject:[self generateSpacer]];
  [headerLabels addObject:[self generateHR]];
  [headerLabels addObject:[self generateSpacer]];

  NSUInteger count = [self.attachments count];
  NSString *headSubject = [header subject];
  if (!headSubject || [headSubject isEqualToString:@"(null)"]) {
    headSubject = NSLocalizedString(@"NoSubject", nil);
  }
  NSString *message = [NSString stringWithFormat:@"%@", self.message];
  if (!([message rangeOfString:@"pkcs7" options:NSCaseInsensitiveSearch]
            .location == NSNotFound)) {
    count = count - 1;
  }

//  HoangTD edit
//  if (headSubject) {
//    /*This is IPAD */
//    if (IDIOM == IPAD) {
//      // Khởi tạo khu vực báo chữ ký/mã hoá
//      UIView *signZone = [[UIView alloc]
//          initWithFrame:CGRectMake(0, 0, self.frame.size.width - 110, 0)];
//      if (!([message rangeOfString:@"pkcs7" options:NSCaseInsensitiveSearch]
//                .location == NSNotFound)) {
//        signZone = [[UIView alloc]
//            initWithFrame:CGRectMake(0, 0, self.frame.size.width - 100, 25)];
//      }
//      NSString *subjectString = headSubject;
//
//      // Phân tích độ dài header
//      NSDictionary *attributes =
//          [NSDictionary dictionaryWithObjectsAndKeys:
//                            [UIFont fontWithName:@"HelveticaNeue-Bold" size:18],
//                            NSFontAttributeName, nil];
//      CGFloat characterWidth =
//          [[[NSAttributedString alloc] initWithString:subjectString
//                                           attributes:attributes] size].width;
//
//      int widthPerLines = 400;
//      int numberOfLines = (int)((characterWidth / widthPerLines) + 1);
//      UILabel *label = [[UILabel alloc]
//          initWithFrame:CGRectMake(0, 0, self.frame.size.width - 100,
//                                   numberOfLines * 30)];
//      label.numberOfLines = numberOfLines;
//
//      label.text = subjectString;
//      label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
//      [headerLabels addObject:label];
//      NSString *cantVerify =
//          [[NSUserDefaults standardUserDefaults] stringForKey:@"CantVerify"];
//
//      if ([cantVerify isEqualToString:@"YES"]) {
//        UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//        mailsigned = [[UIButton alloc]
//            initWithFrame:CGRectMake(self.frame.size.width - 65, 0, 30, 30)];
//        UIImage *cert = [UIImage imageNamed:@"mail_cert_large.png"];
//        [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//        [mailsigned addTarget:self
//                       action:@selector(viewCantVerify:)
//             forControlEvents:UIControlEventTouchUpInside];
//        [signZone addSubview:mailsigned];
//        [[NSUserDefaults standardUserDefaults] setObject:@"NO"
//                                                  forKey:@"CantVerify"];
//      } else {
//        /* Load MIMETYPE kiểm tra chữ ký/mã hoá để hiển thị */
//        /* Nếu tồn tại chữ ký/mã hoá, giảm 1 file attachment */
//        /* Thư được ký */
//        if (!([message rangeOfString:@"filename: smime.p7s"].location ==
//              NSNotFound) &&
//            !([message rangeOfString:@"pkcs7" options:NSCaseInsensitiveSearch]
//                  .location == NSNotFound)) {
//
//          NSString *messageInfo = NSLocalizedString(@"MessageInfoSign", nil);
//          UILabel *messageLabelInfo = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 0, self.frame.size.width - 70, 14)];
//          messageLabelInfo.text = messageInfo;
//          messageLabelInfo.font =
//              [UIFont fontWithName:@"HelveticaNeue" size:12];
//          messageLabelInfo.textColor = [UIColor grayColor];
//          [signZone addSubview:messageLabelInfo];
//
//          NSString *dateString = [NSDateFormatter
//              localizedStringFromDate:[header date]
//                            dateStyle:NSDateFormatterMediumStyle
//                            timeStyle:NSDateFormatterMediumStyle];
//          UILabel *label = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 16, self.frame.size.width - 70, 14)];
//          label.text = dateString;
//          label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
//          label.textColor = [UIColor grayColor];
//          [signZone addSubview:label];
//
//          NSString *savedValue =
//              [[NSUserDefaults standardUserDefaults] stringForKey:@"VERIFY"];
//          if (!savedValue) {
//            FFCircularProgressView *circularPV = [[FFCircularProgressView alloc]
//                initWithFrame:CGRectMake(self.frame.size.width - 85, 0.0, 25.0,
//                                         25.0)];
//            circularPV.hideProgressIcons = YES;
//            [signZone addSubview:circularPV];
//            [circularPV startSpinProgressBackgroundLayer];
//          }
//          if ([savedValue isEqualToString:@"YES"]) {
//            UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//            mailsigned = [[UIButton alloc]
//                initWithFrame:CGRectMake(self.frame.size.width - 85, 0, 30,
//                                         30)];
//            UIImage *cert = [UIImage imageNamed:@"mail_cert.png"];
//            [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//            [mailsigned addTarget:self
//                           action:@selector(viewCert:)
//                 forControlEvents:UIControlEventTouchUpInside];
//            [signZone addSubview:mailsigned];
//          } else if (savedValue) {
//            UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//            mailsigned = [[UIButton alloc]
//                initWithFrame:CGRectMake(self.frame.size.width - 85, 0, 30,
//                                         30)];
//            UIImage *cert;
//            if ([savedValue isEqualToString:@"IVALIDEMAIL"]) {
//              cert = [UIImage imageNamed:@"mail_cert_invalidmail.png"];
//            } else {
//              cert = [UIImage imageNamed:@"mail_cert_fail.png"];
//            }
//            [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//            [mailsigned addTarget:self
//                           action:@selector(viewWarning:)
//                 forControlEvents:UIControlEventTouchUpInside];
//            [signZone addSubview:mailsigned];
//          }
//        }
//
//        /* Thư được mã hoá */
//        else if (!([message rangeOfString:@"filename: smime.p7m"].location ==
//                   NSNotFound) &&
//                 !([message rangeOfString:@"pkcs7"
//                                  options:NSCaseInsensitiveSearch].location ==
//                   NSNotFound)) {
//
//          NSString *messageInfo = NSLocalizedString(@"MessageInfoEncrypt", nil);
//          UILabel *messageLabelInfo = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 0, self.frame.size.width - 70, 14)];
//          messageLabelInfo.text = messageInfo;
//          messageLabelInfo.font =
//              [UIFont fontWithName:@"HelveticaNeue" size:12];
//          messageLabelInfo.textColor = [UIColor grayColor];
//          [signZone addSubview:messageLabelInfo];
//
//          NSString *dateString = [NSDateFormatter
//              localizedStringFromDate:[header date]
//                            dateStyle:NSDateFormatterMediumStyle
//                            timeStyle:NSDateFormatterMediumStyle];
//          UILabel *label = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 16, self.frame.size.width - 70, 14)];
//          label.text = dateString;
//          label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
//          label.textColor = [UIColor grayColor];
//          [signZone addSubview:label];
//
//          UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//          mailsigned = [[UIButton alloc]
//              initWithFrame:CGRectMake(self.frame.size.width - 85, 0, 30, 30)];
//          UIImage *cert = [UIImage imageNamed:@"mail_noencrypt.png"];
//          [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//          [mailsigned addTarget:self
//                         action:@selector(viewDecryptInfo:)
//               forControlEvents:UIControlEventTouchUpInside];
//          [signZone addSubview:mailsigned];
//        } else {
//          if ([header date]) {
//            NSString *dateString = [NSDateFormatter
//                localizedStringFromDate:[header date]
//                              dateStyle:NSDateFormatterMediumStyle
//                              timeStyle:NSDateFormatterMediumStyle];
//            UILabel *label =
//                [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
//            label.text = dateString;
//            label.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
//            label.textColor = [UIColor grayColor];
//            [headerLabels addObject:label];
//          }
//        }
//      }
//      [headerLabels addObject:signZone];
//      UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 8)];
//      spacer.backgroundColor = [UIColor clearColor];
//      [headerLabels addObject:spacer];
//    }
//    /* This is Iphone */
//    else {
//      // Khởi tạo khu vực báo chữ ký/mã hoá
//      UIView *signZone = [[UIView alloc]
//          initWithFrame:CGRectMake(0, 0, self.frame.size.width - 100, 0)];
//      if (!([message rangeOfString:@"pkcs7" options:NSCaseInsensitiveSearch]
//                .location == NSNotFound)) {
//        signZone = [[UIView alloc]
//            initWithFrame:CGRectMake(0, 0, self.frame.size.width - 100, 30)];
//      }
//      NSString *subjectString = headSubject;
//
//      // Phân tích độ dài header
//      NSDictionary *attributes =
//          [NSDictionary dictionaryWithObjectsAndKeys:
//                            [UIFont fontWithName:@"HelveticaNeue-Bold" size:14],
//                            NSFontAttributeName, nil];
//      CGFloat characterWidth =
//          [[[NSAttributedString alloc] initWithString:subjectString
//                                           attributes:attributes] size].width;
//
//      int widthPerLines = 270;
//      int numberOfLines = (int)((characterWidth / widthPerLines) + 1);
//      UILabel *label = [[UILabel alloc]
//          initWithFrame:CGRectMake(0, 0, self.frame.size.width - 100,
//                                   numberOfLines * 20)];
//      label.numberOfLines = numberOfLines;
//      label.text = subjectString;
//      label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
//
//      [headerLabels addObject:label];
//      NSString *cantVerify =
//          [[NSUserDefaults standardUserDefaults] stringForKey:@"CantVerify"];
//
//      if ([cantVerify isEqualToString:@"YES"]) {
//        UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//        mailsigned = [[UIButton alloc]
//            initWithFrame:CGRectMake(self.frame.size.width - 70, 0, 30, 30)];
//        UIImage *cert = [UIImage imageNamed:@"mail_cert_large.png"];
//        [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//        [mailsigned addTarget:self
//                       action:@selector(viewCantVerify:)
//             forControlEvents:UIControlEventTouchUpInside];
//        [signZone addSubview:mailsigned];
//        [[NSUserDefaults standardUserDefaults] setObject:@"NO"
//                                                  forKey:@"CantVerify"];
//      } else {
//        /* Load MIMETYPE kiểm tra chữ ký/mã hoá để hiển thị */
//        /* Nếu tồn tại chữ ký/mã hoá, giảm 1 file attachment */
//        /* Thư được ký */
//        if (!([message rangeOfString:@"filename: smime.p7s"].location ==
//              NSNotFound) &&
//            !([message rangeOfString:@"pkcs7" options:NSCaseInsensitiveSearch]
//                  .location == NSNotFound)) {
//
//          NSString *savedValue =
//              [[NSUserDefaults standardUserDefaults] stringForKey:@"VERIFY"];
//
//          NSString *messageInfo = NSLocalizedString(@"MessageInfoSign", nil);
//          UILabel *messageLabelInfo = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 0, self.frame.size.width - 70, 14)];
//          messageLabelInfo.text = messageInfo;
//          messageLabelInfo.font =
//              [UIFont fontWithName:@"HelveticaNeue" size:12];
//          messageLabelInfo.textColor = [UIColor grayColor];
//          [signZone addSubview:messageLabelInfo];
//
//          NSString *dateString = [NSDateFormatter
//              localizedStringFromDate:[header date]
//                            dateStyle:NSDateFormatterMediumStyle
//                            timeStyle:NSDateFormatterMediumStyle];
//          UILabel *label = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 16, self.frame.size.width - 70, 14)];
//          label.text = dateString;
//          label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
//          label.textColor = [UIColor grayColor];
//          [signZone addSubview:label];
//
//          if (!savedValue) {
//            FFCircularProgressView *circularPV = [[FFCircularProgressView alloc]
//                initWithFrame:CGRectMake(self.frame.size.width - 65, 5.0, 20,
//                                         20)];
//            circularPV.hideProgressIcons = YES;
//            [signZone addSubview:circularPV];
//            [circularPV startSpinProgressBackgroundLayer];
//          }
//
//          if ([savedValue isEqualToString:@"YES"]) {
//            UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//            mailsigned = [[UIButton alloc]
//                initWithFrame:CGRectMake(self.frame.size.width - 70, 0, 30,
//                                         30)];
//            UIImage *cert = [UIImage imageNamed:@"mail_cert.png"];
//            [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//            [mailsigned addTarget:self
//                           action:@selector(viewCert:)
//                 forControlEvents:UIControlEventTouchUpInside];
//            [signZone addSubview:mailsigned];
//          } else if (savedValue) {
//            UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//            mailsigned = [[UIButton alloc]
//                initWithFrame:CGRectMake(self.frame.size.width - 70, 0, 30,
//                                         30)];
//            UIImage *cert;
//            if ([savedValue isEqualToString:@"IVALIDEMAIL"]) {
//              cert = [UIImage imageNamed:@"mail_cert_invalidmail.png"];
//            } else {
//              cert = [UIImage imageNamed:@"mail_cert_fail.png"];
//            }
//            [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//            [mailsigned addTarget:self
//                           action:@selector(viewWarning:)
//                 forControlEvents:UIControlEventTouchUpInside];
//
//            [signZone addSubview:mailsigned];
//          }
//        }
//
//        /* Thư được mã hoá */
//        else if (!([message rangeOfString:@"filename: smime.p7m"].location ==
//                   NSNotFound) &&
//                 !([message rangeOfString:@"pkcs7"
//                                  options:NSCaseInsensitiveSearch].location ==
//                   NSNotFound)) {
//
//          NSString *messageInfo = NSLocalizedString(@"MessageInfoEncrypt", nil);
//          UILabel *messageLabelInfo = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 0, self.frame.size.width - 70, 14)];
//          messageLabelInfo.text = messageInfo;
//          messageLabelInfo.font =
//              [UIFont fontWithName:@"HelveticaNeue" size:12];
//          messageLabelInfo.textColor = [UIColor grayColor];
//          [signZone addSubview:messageLabelInfo];
//
//          NSString *dateString = [NSDateFormatter
//              localizedStringFromDate:[header date]
//                            dateStyle:NSDateFormatterMediumStyle
//                            timeStyle:NSDateFormatterMediumStyle];
//          UILabel *label = [[UILabel alloc]
//              initWithFrame:CGRectMake(0, 16, self.frame.size.width - 70, 14)];
//          label.text = dateString;
//          label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
//          label.textColor = [UIColor grayColor];
//          [signZone addSubview:label];
//
//          UIButton *mailsigned = [UIButton buttonWithType:UIButtonTypeCustom];
//          mailsigned = [[UIButton alloc]
//              initWithFrame:CGRectMake(self.frame.size.width - 70, 0, 30, 30)];
//          UIImage *cert = [UIImage imageNamed:@"mail_noencrypt.png"];
//          [mailsigned setBackgroundImage:cert forState:UIControlStateNormal];
//          [mailsigned addTarget:self
//                         action:@selector(viewDecryptInfo:)
//               forControlEvents:UIControlEventTouchUpInside];
//          [signZone addSubview:mailsigned];
//        } else {
//          if ([header date]) {
//            NSString *dateString = [NSDateFormatter
//                localizedStringFromDate:[header date]
//                              dateStyle:NSDateFormatterMediumStyle
//                              timeStyle:NSDateFormatterMediumStyle];
//            UILabel *label =
//                [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
//            label.text = dateString;
//            label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
//            label.textColor = [UIColor grayColor];
//            [headerLabels addObject:label];
//          }
//        }
//      }
//
//      [headerLabels addObject:signZone];
//      [headerLabels addObject:[self generateSpacer]];
//    }
//  }
//
//  [headerLabels addObject:[self generateSpacer]];
//  [headerLabels addObject:[self generateHR]];

  int tag = 0;
  DelayedAttachment *da;

  if (count > 0) {
    [headerLabels addObject:[self generateSpacer]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
    label.text = @"Đính kèm:";
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    label.textColor = [UIColor grayColor];
    [headerLabels addObject:label];
  }

  for (da in self.attachments) {

    UIButton *label = [UIButton buttonWithType:UIButtonTypeCustom];

    if (IDIOM == IPAD) {
      // Hạ thêm
      if (([[da filename] rangeOfString:@"smime.p7s"].location == NSNotFound)) {
        label.frame = CGRectMake(0, 0, 300, 60);
        label.contentHorizontalAlignment =
            UIControlContentHorizontalAlignmentLeft;
        label.contentEdgeInsets = UIEdgeInsetsMake(10, 50, 10, 0);
        [label.titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [label setTitle:[da filename] forState:UIControlStateNormal];
        [label setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [label.titleLabel
            setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
        label.tag = tag;
        tag++;
      }
    } else {
      // Hạ thêm
      if (([[da filename] rangeOfString:@"smime.p7s"].location == NSNotFound)) {
        label.frame = CGRectMake(0, 0, 200, 20);
        label.contentHorizontalAlignment =
            UIControlContentHorizontalAlignmentLeft;
        label.contentEdgeInsets = UIEdgeInsetsMake(0, 30, 00, 0);
        [label.titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [label setTitle:[da filename] forState:UIControlStateNormal];
        [label setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [label.titleLabel
            setFont:[UIFont fontWithName:@"HelveticaNeue" size:13]];
      }
      label.tag = tag;
      tag++;
    }

    // Preview documents
    [label addTarget:self
                  action:@selector(onattachmentClick:)
        forControlEvents:UIControlEventTouchUpInside];

    UIImageView *imageview;

    if (IDIOM == IPAD) {
      imageview =
          [[UIImageView alloc] initWithFrame:CGRectMake(10, 13, 32, 32)];
    } else {
      imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    }

    NSString *pathToIcon;
    if (([[da filename] rangeOfString:@"smime.p7s"].location == NSNotFound)) {
      pathToIcon =
          [FPMimetype iconPathForMimetype:[da mimeType] Filename:[da filename]];
      imageview.image = [UIImage imageNamed:pathToIcon];
      imageview.contentMode = UIViewContentModeScaleAspectFit;
      [label addSubview:imageview];
    }

    [self grabDataWithBlock:^NSData *{
      return [da getData];
    } completion:^(NSData *data) {
      if ([pathToIcon isEqualToString:@"page_white_picture.png"]) {
        imageview.image = [UIImage imageWithData:data];
      }
    }];
    [headerLabels addObject:label];

    UIView *sp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 5)];
    sp.backgroundColor = [UIColor clearColor];
    [headerLabels addObject:sp];
  }

  if (count > 0) {
    [headerLabels addObject:[self generateHR]];
    [headerLabels addObject:[self generateSpacer]];
  }

  int startingHeight;

  if (IDIOM == IPAD) {
    startingHeight = 15;
  } else {
    startingHeight = 10;
  }

  for (UIView *l in headerLabels) {
    if (IDIOM == IPAD) {
      l.frame = CGRectMake(20, startingHeight, self.frame.size.width - 40,
                           l.frame.size.height);
      [self addSubview:l];
      startingHeight += l.frame.size.height;
    } else {
      l.frame = CGRectMake(20, startingHeight, self.frame.size.width - 40,
                           l.frame.size.height);
      [self addSubview:l];
      startingHeight += l.frame.size.height;
    }
  }

  self.frame = CGRectMake(0, 0, self.frame.size.width, startingHeight);
  self.backgroundColor = [UIColor whiteColor];
  if (IDIOM == IPAD) {
    self.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  } else {
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  }
}

//  HoangTD edit
//- (void)viewCert:(id)sender {
//  UIAlertView *alert =
//      [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
//                                 message:NSLocalizedString(@"ValidSign", nil)
//                                delegate:self
//                       cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//                       otherButtonTitles:NSLocalizedString(@"Cert", nil), nil];
//  alert.tag = buttonSign;
//  [alert show];
//}
//
//- (void)viewCantVerify:(id)sender {
//  UIAlertView *alert = [[UIAlertView alloc]
//          initWithTitle:NSLocalizedString(@"CantVerifyTitle", nil)
//                message:NSLocalizedString(@"CantVerify", nil)
//               delegate:nil
//      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//      otherButtonTitles:nil, nil];
//  [alert show];
//}
//
//- (void)viewWarning:(id)sender {
//  UIAlertView *alert;
//  NSString *savedValue =
//      [[NSUserDefaults standardUserDefaults] stringForKey:@"VERIFY"];
//  if ([savedValue isEqualToString:@"NO"]) {
//    alert = [[UIAlertView alloc]
//            initWithTitle:NSLocalizedString(@"Notifi", nil)
//                  message:NSLocalizedString(@"InvalidCert", nil)
//                 delegate:nil
//        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//        otherButtonTitles:nil];
//  } else if ([savedValue isEqualToString:@"REVOKE"]) {
//    alert =
//        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
//                                   message:NSLocalizedString(@"Revoked", nil)
//                                  delegate:nil
//                         cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//                         otherButtonTitles:nil];
//  } else if ([savedValue isEqualToString:@"EXPIRED"]) {
//    alert = [[UIAlertView alloc]
//            initWithTitle:NSLocalizedString(@"Notifi", nil)
//                  message:NSLocalizedString(@"Expired", nil)
//                 delegate:self
//        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//        otherButtonTitles:NSLocalizedString(@"Cert", nil), nil];
//      alert.tag = buttonSign;
//  } else if ([savedValue isEqualToString:@"IVALIDEMAIL"]) {
//    alert = [[UIAlertView alloc]
//            initWithTitle:NSLocalizedString(@"Notifi", nil)
//                  message:NSLocalizedString(@"InvalidEmail", nil)
//                 delegate:self
//        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//        otherButtonTitles:NSLocalizedString(@"Cert", nil), nil];
//      alert.tag = buttonSign;
//  } else if ([savedValue isEqualToString:@"UNKNOWN"]) {
//    alert =
//        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
//                                   message:NSLocalizedString(@"UnknownErr", nil)
//                                  delegate:nil
//                         cancelButtonTitle:NSLocalizedString(@"Ok", nil)
//                         otherButtonTitles:nil];
//  }
//  [alert show];
//}
//
//- (void)viewDecryptInfo:(id)sender {
//}

- (void)alertView:(UIAlertView *)alertView
    clickedButtonAtIndex:(NSInteger)buttonIndex {
//  HoangTD edit
//  if (alertView.tag == buttonSign) {
//    if (buttonIndex == [alertView cancelButtonIndex]) {
//    } else {
//      SoftToken_SignEnvelope *verifyInfo =
//          [[SoftToken_SignEnvelope alloc] init];
//      PKCS7 *p7 = [SoftToken_SignEnvelope sharedObject];
//      CertInfoView *certinfo =
//          [[CertInfoView alloc] initWithNibName:@"CertInfoView"
//                                         bundle:[NSBundle mainBundle]];
//      certinfo.dict = [verifyInfo verifyInfo:p7];
//      UINavigationController *nc =
//          [[UINavigationController alloc] initWithRootViewController:certinfo];
//      [self.delegate presentViewController:nc animated:YES completion:nil];
//    }
//  }
}

- (NSString *)displayNamesFromAddressArray:(NSArray *)addresses {
  if ([addresses count] == 0) {
    return nil;
  }
  NSMutableArray *names = [[NSMutableArray alloc] initWithArray:@[]];
  for (MCOAddress *a in addresses) {
    if ([a displayName]) {
      [names addObject:[a displayName]];
    } else {
      [names addObject:[a mailbox]];
    }
  }
  return [names componentsJoinedByString:@", "];
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

// Hưng thêm preview
- (void)onattachmentClick:(id)sender {
  UIActionSheet *popupQuery = [[UIActionSheet alloc]
               initWithTitle:nil
                    delegate:self
           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
      destructiveButtonTitle:nil
           otherButtonTitles:NSLocalizedString(@"Preview", nil),
                             NSLocalizedString(@"DownloadData", nil), nil];
  popupQuery.tag = [sender tag];
  popupQuery.actionSheetStyle = UIActionSheetStyleDefault;
  [popupQuery showInView:self.viewForBaselineLayout];
}

- (NSInteger)numberOfPreviewItemsInPreviewController:
        (QLPreviewController *)controller {
  return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller
                    previewItemAtIndex:(NSInteger)index {
  return [NSURL fileURLWithPath:dataURL];
}
- (void)hide:(BOOL)animated afterDelay:(NSTimeInterval)delay{
    MBProgressHUD *hud =
    [MBProgressHUD showHUDAddedTo:self.window animated:YES];
    hud.labelText = @"Cannot download file ";
    hud.labelFont = [UIFont boldSystemFontOfSize:13];
    hud.mode = MBProgressHUDModeCustomView;
    hud.margin = 12.0f;
    hud.yOffset =
    [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:3.0];
}
- (void)actionSheet:(UIActionSheet *)actionSheet
    clickedButtonAtIndex:(NSInteger)buttonIndex {
  switch (buttonIndex) {
  // Xem trước
  case 0: {
    DelayedAttachment *da = [self.attachments objectAtIndex:[actionSheet tag]];
    NSLog(@"File Name %@", da.filename);
    NSLog(@"Mime Type %@", da.mimeType);
    
    MBProgressHUD *hud =
      [MBProgressHUD showHUDAddedTo:self.viewForBaselineLayout animated:YES];
      hud.labelText = NSLocalizedString(@"PleaseWait", nil);
      //hud.delegate = self;
      [hud hide:YES afterDelay:60];
        dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
          NSData *data = [da getData];
          NSString *fileName = da.filename;
          dataURL =
              [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            
          dispatch_async(dispatch_get_main_queue(), ^{
            [data writeToFile:dataURL atomically:YES];
            [MBProgressHUD hideHUDForView:self.viewForBaselineLayout animated:YES];
            QLPreviewController *previewController =
                [[QLPreviewController alloc] init];
            previewController.delegate = self;
            previewController.dataSource = self;
            [previewController.navigationItem setRightBarButtonItem:nil];
            previewController.navigationController.navigationBar.translucent =
                NO;
            [self.delegate presentViewController:previewController
                                        animated:YES
                                      completion:nil];

          });
        });
  } break;
  // Download
  case 1: {
    MBProgressHUD *hud =
        [MBProgressHUD showHUDAddedTo:self.viewForBaselineLayout animated:YES];
    [hud hide:YES afterDelay:60];
   // hud.delegate = self;
    hud.labelText = NSLocalizedString(@"PleaseWait", nil);
    dispatch_async(
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          DelayedAttachment *da =
              [self.attachments objectAtIndex:[actionSheet tag]];
          NSData *data = [da getData];
          NSArray *paths = NSSearchPathForDirectoriesInDomains(
              NSDocumentDirectory, NSUserDomainMask, YES);
          NSString *documentsDirectory = [paths objectAtIndex:0];
          NSString *attachmentPath =
              [documentsDirectory stringByAppendingPathComponent:da.filename];
          dispatch_async(dispatch_get_main_queue(), ^{
            NSString *resultString;
            if ([da.mimeType isEqualToString:@"image/PNG"] ||
                [da.mimeType isEqualToString:@"image/png"] ||
                [da.mimeType isEqualToString:@"image/GIF"] ||
                [da.mimeType isEqualToString:@"image/gif"] ||
                [da.mimeType isEqualToString:@"image/JPEG"] ||
                [da.mimeType isEqualToString:@"image/jpeg"]) {
              UIImage *imageToSave = [UIImage imageWithData:data];
              UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
              resultString =
                  NSLocalizedString(@"FileDownloadToPhotoSuccess", nil);
            } else {
              [data writeToFile:attachmentPath atomically:YES];
              resultString = NSLocalizedString(@"FileDownloadSuccess", nil);
            }
            [MBProgressHUD hideHUDForView:self.viewForBaselineLayout animated:YES];
            MBProgressHUD *hud =
                [MBProgressHUD showHUDAddedTo:self.window animated:YES];
            hud.labelText = resultString;
            hud.labelFont = [UIFont boldSystemFontOfSize:13];
            hud.mode = MBProgressHUDModeCustomView;
            hud.margin = 12.0f;
            hud.yOffset =
                [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
            hud.removeFromSuperViewOnHide = YES;
            [hud hide:YES afterDelay:3.0];
          });
        });
  } break;
  default:
    break;
  }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:
        (UIInterfaceOrientation)interfaceOrientation {
  return NO;
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *error;
  if ([[NSFileManager defaultManager] fileExistsAtPath:dataURL]) {
    BOOL success = [fileManager removeItemAtPath:dataURL error:&error];
    if (success) {
      NSLog(@"File preview has been delete at Url %@", dataURL);
    } else {
      NSLog(@"Could not delete file -:%@ ", [error localizedDescription]);
    }
  }
}
@end
