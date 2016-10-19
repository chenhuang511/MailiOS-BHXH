//
//  SoftToken_SignEnvelope.h
//  iMail
//
//  Created by Tran Ha on 13/05/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pkcs7.h"


@interface SoftToken_SignEnvelope : NSObject

- (int) signVerify: (NSData*) rfc822String;
- (NSDictionary *)verifyInfo: (PKCS7*)p7;
- (NSString*) deCryptMail;
- (void) getBase64_pkcs7: (PKCS7*)p7;
+ (PKCS7*)sharedObject;
@end
