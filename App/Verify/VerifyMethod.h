//
//  VerifyMethod.h
//  iMail
//
//  Created by Tran Ha on 11/13/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VerifyMethod : NSObject

/* return: 0 - Good ;
 1 - Revoke;
 2 - Expired;
 7 - Handle error;
 # - OCSP Connection Err */

- (int)selfVerify:(NSString *)username;
- (int)selfVerifybyCert:(long)certHandle;

+ (int)certVerify:(NSString *)certPath;
+ (int)selfverifyCertificate;
+ (int)selfverifybyCertHandle:(long)certhandle byTokenType:(int)tokentype;

@end
