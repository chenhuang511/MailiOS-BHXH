//
//  SoftTokenSign.h
//  iMail
//
//  Created by Tran Ha on 23/04/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ComposeCommonMethod.h"

@interface SoftTokenSign : NSObject

- (NSString *)signMail:(NSString *)signData_
                  from:(NSString *)from
                    to:(NSString *)to
                    cc:(NSString *)cc
               subject:(NSString *)subject;

- (NSString *)HeaderInsert:(NSString *)content;

- (NSString *)HeaderInsert_Quote:(NSString *)content;

- (BOOL)connectSoftToken:(NSString *)passwrd;

@end