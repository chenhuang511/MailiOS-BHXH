//
//  CheckValidSession.h
//  iMail
//
//  Created by Macbook Pro on 6/30/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>

#import "AuthManager.h"

@interface CheckValidSession : NSObject

+ (void)checkValidSession:(MCOIMAPSession *)session;

@end
