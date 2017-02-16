//
//  MessageCell.m
//  ThatInbox
//
//  Created by Andrey Yastrebov on 20.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "TokenType.h"
#import "MessageCell.h"
#import "UIColor+FlatUI.h"
#import <MailCore/MailCore.h>
#import <QuartzCore/QuartzCore.h>
#import "AuthManager.h"
#import "MenuViewController.h"
#import "UIImageView+Letters.h"

@implementation MessageCell

- (id)initWithCoder:(NSCoder *)aDecoder {
  if (self = [super initWithCoder:aDecoder]) {
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor grayColor];
    bgColorView.layer.masksToBounds = YES;
    [self setSelectedBackgroundView:bgColorView];
  }
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

- (void)setMessage:(MCOIMAPMessage *)message {
  self.signIcon.alpha = 0;
  self.fromTextField.text = message.header.from.displayName
                                ? message.header.from.displayName
                                : message.header.from.mailbox;
  self.subjectTextField.text = message.header.subject
                                   ? message.header.subject
                                   : NSLocalizedString(@"NoSubject", nil);

  [self insertContactwithDisplayName:message.header.from.displayName
                          andMailbox:message.header.from.mailbox];

  NSString *HRName = [MenuViewController sharedFolderName];
  if ([HRName isEqualToString:@"Sent"]) {
    NSArray *toArray = message.header.to;
      NSString *toMailAddress = [[toArray objectAtIndex:0] displayName]
      ? [[toArray objectAtIndex:0] displayName]
      : [[toArray objectAtIndex:0] mailbox];
      NSUInteger addressCount = toArray.count;
      if (addressCount > 1) {
          if (addressCount == 2) {
              toMailAddress = [NSString stringWithFormat:@"%@, %@", toMailAddress, [[toArray objectAtIndex:1] displayName]?[[toArray objectAtIndex:1] displayName]:[[toArray objectAtIndex:1] mailbox]];
          } else {
              toMailAddress = [NSString stringWithFormat:@"%@ + %d others", toMailAddress, (int)addressCount - 1];
          }
      }
      self.fromTextField.text = toMailAddress;
  }
  NSDate *date = message.header.date;
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"dd"];
  NSString *stringdate = [dateFormatter stringFromDate:date];
  [dateFormatter setDateFormat:@"MM"];
  NSString *stringmonth = [dateFormatter stringFromDate:date];
  [dateFormatter setDateFormat:@"EEEE"];
  NSString *stringDOW = [dateFormatter stringFromDate:date];
  if ([stringDOW rangeOfString:@"day"].location != NSNotFound) {
    stringDOW = [self dateOfWeekToDate:stringDOW];
    self.dateTextField.text = [NSString
        stringWithFormat:@"%@, %@/%@", stringDOW, stringdate, stringmonth];
  } else {
    self.dateTextField.text = [NSString
        stringWithFormat:@"%@, %@/%@", stringDOW, stringdate, stringmonth];
  }

  if (IDIOM == IPAD) {
    [self.subjectTextField
        setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
    [self.fromTextField setFont:[UIFont systemFontOfSize:14]];
    [self.dateTextField setFont:[UIFont systemFontOfSize:14]];
    [self.attachmentTextField setFont:[UIFont systemFontOfSize:13]];
  } else {
    [self.subjectTextField
        setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15.0f]];
    [self.fromTextField setFont:[UIFont systemFontOfSize:12]];
    [self.dateTextField setFont:[UIFont systemFontOfSize:12]];
  }

    NSArray *attachments = [message attachments];
    // Giảm 1 file attachment (smime.p7s-m-b-z) nếu mail được ký
    NSUInteger count = attachments.count;

  if (count > 0) {
    [self.attachementIcon setImage:[UIImage imageNamed:@"attachment"]];
    MCOAttachment *firstAttachment = message.attachments[0];

    if (count == 1) {
      self.attachmentTextField.text = firstAttachment.filename;
      if (IDIOM == IPAD) {
        // set text size for Ipad
      } else {
        [self.attachmentTextField setFont:[UIFont systemFontOfSize:12]];
      }
    } else if (count > 1) {
      self.attachmentTextField.text =
          [NSString stringWithFormat:@"%@ + %d %@", firstAttachment.filename,
                                     (int)(attachments.count - 1),
                                     NSLocalizedString(@"OtherAtt", nil)];
      if (IDIOM == IPAD) {
        // set text size for Ipad
      } else {
        [self.attachmentTextField setFont:[UIFont systemFontOfSize:12]];
      }
    }
  } else {
    [self.attachementIcon setImage:[UIImage imageNamed:@"blank"]];
    self.attachmentTextField.text = nil;
  }
    
  //avatar
  [self.avatarIcon setImageWithString:self.fromTextField.text color:nil circular:true textAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Futura-Medium" size:20.0f], NSForegroundColorAttributeName:[UIColor whiteColor]}];

}

- (void)insertContactwithDisplayName:(NSString *)displayName
                          andMailbox:(NSString *)mailbox {
  // Source Data
  NSMutableArray *tempArray, *contactArray;
  tempArray =
      [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults]
                                         objectForKey:@"KeyContacts"]];
  contactArray = [NSMutableArray arrayWithArray:tempArray];

  // Insert Data
  NSArray *keys = [NSArray arrayWithObjects:@"displayName", @"mailbox", nil];
  NSString *displayName_ = @"";
  NSString *mailbox_ = @"";
  if (displayName.length > 0) {
    displayName_ = displayName;
  }
  if (mailbox.length > 0) {
    mailbox_ = mailbox;
  }
  NSArray *insertData = [NSArray arrayWithObjects:displayName_, mailbox_, nil];
  NSDictionary *insertDictionary =
      [NSDictionary dictionaryWithObjects:insertData forKeys:keys];

  // Check and insert
  if (tempArray.count == 0) {
    [self doInsetContactWithContactArray:contactArray
                     andInsertDictionary:insertDictionary];
    return;
  } else {
    for (int i = 0; i < tempArray.count; i++) {
      NSDictionary *contact = [contactArray objectAtIndex:i];
      NSString *sourceContactString =
          [NSString stringWithFormat:@"%@", contact];
      NSString *insertContactString =
          [NSString stringWithFormat:@"%@", insertDictionary];
      if ([insertContactString isEqualToString:sourceContactString]) {
        return;
      }
    }
    tempArray = nil;
  }

  [self doInsetContactWithContactArray:contactArray
                   andInsertDictionary:insertDictionary];
  contactArray = nil;
}

- (void)doInsetContactWithContactArray:(NSMutableArray *)contactArray
                   andInsertDictionary:(NSDictionary *)insertDictionary {
  [contactArray addObject:insertDictionary];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"KeyContacts"];
  [[NSUserDefaults standardUserDefaults]
      setObject:[NSArray arrayWithArray:contactArray]
         forKey:@"KeyContacts"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)dateOfWeekToDate:(NSString *)date {
  NSString *newdate;
  if ([date rangeOfString:@"Monday"].location != NSNotFound) {
    newdate = [date stringByReplacingOccurrencesOfString:@"Monday"
                                              withString:NSLocalizedString(
                                                             @"Monday1", nil)];
    return newdate;
  } else if ([date rangeOfString:@"Tuesday"].location != NSNotFound) {
    newdate = [date stringByReplacingOccurrencesOfString:@"Tuesday"
                                              withString:NSLocalizedString(
                                                             @"Tuesday1", nil)];
    return newdate;
  } else if ([date rangeOfString:@"Wednesday"].location != NSNotFound) {
    newdate =
        [date stringByReplacingOccurrencesOfString:@"Wednesday"
                                        withString:NSLocalizedString(
                                                       @"Wednesday1", nil)];
    return newdate;
  } else if ([date rangeOfString:@"Thursday"].location != NSNotFound) {
    newdate =
        [date stringByReplacingOccurrencesOfString:@"Thursday"
                                        withString:NSLocalizedString(
                                                       @"Thursday1", nil)];
    return newdate;
  } else if ([date rangeOfString:@"Friday"].location != NSNotFound) {
    newdate = [date stringByReplacingOccurrencesOfString:@"Friday"
                                              withString:NSLocalizedString(
                                                             @"Friday1", nil)];
    return newdate;
  } else if ([date rangeOfString:@"Saturday"].location != NSNotFound) {
    newdate =
        [date stringByReplacingOccurrencesOfString:@"Saturday"
                                        withString:NSLocalizedString(
                                                       @"Saturday1", nil)];
    return newdate;
  } else if ([date rangeOfString:@"Sunday"].location != NSNotFound) {
    newdate = [date stringByReplacingOccurrencesOfString:@"Sunday"
                                              withString:NSLocalizedString(
                                                             @"Sunday1", nil)];
    return newdate;
  }
  return newdate;
}

@end
