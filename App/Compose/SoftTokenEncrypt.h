//
//  SoftTokenEncrypt.h
//  iMail
//
//  Created by Tran Ha on 16/05/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ComposeCommonMethod.h"

@interface SoftTokenEncrypt : NSObject

- (NSString *)encrypMail:(NSString *)content_
                    from:(NSString *)from
                      to:(NSString *)to
                      cc:(NSString *)cc
                 subject:(NSString *)subject;

@end
