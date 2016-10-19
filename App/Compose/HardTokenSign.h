//
//  HardTokenSign.h
//  iMail
//
//  Created by Tran Ha on 07/05/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <include/openssl/x509.h>
#include <include/openssl/x509v3.h>
#include <include/openssl/err.h>
#include <include/openssl/pkcs12.h>
#include "NSData+Base64.h"
#include "rand.h"

#include "hardtoken/cryptoki_linux.h"
#import "hardtoken/cryptoki_ext.h"

#import "EADevice.h"
#import "DeviceAudio.h"
#import "MBProgressHUD.h"

#import "ComposeCommonMethod.h"

@interface HardTokenSign : NSObject

- (NSString*)signMail_H :(NSString*)signData :(NSString*)from :(NSString*)to :(NSString*)cc :(NSString*) subject;

@end
