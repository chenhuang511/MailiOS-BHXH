//
//  ComposeCommonMethod.h
//  iMail
//
//  Created by Macbook Pro on 5/16/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DBManager.h"

@interface ComposeCommonMethod : NSObject

+ (NSString *)parseAndBase64AddressName:(NSString *)addressName;
+ (void)saveCertToDatabaseBy: (NSString *)r_mail andCert: (NSString *)base64;
+ (void)chooseSignSuccess;

@end
