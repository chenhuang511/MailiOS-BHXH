//
//  CheckValidSession.m
//  iMail
//
//  Created by Macbook Pro on 6/30/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import "CheckValidSession.h"

@implementation CheckValidSession

+ (void)checkValidSession:(MCOIMAPSession *)session {

  if (session) {

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    MCOIMAPOperation *noopOperation = nil;
    @try {
      noopOperation = [session noopOperation];
    }
    @catch (NSException *e) {
      NSLog(@"noopOperation exception: %@", e);
      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
      return;
    }

    [noopOperation start:^(NSError *error) {

      [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

      if (!error) {
        NSLog(@"noopOperation Success!");
      } else {
        NSLog(@"noopOperation failed: %@", error);
        if (error.code == 5) {
          [[AuthManager sharedManager] refreshSession];
        }
      }
    }];
  }
}

@end
