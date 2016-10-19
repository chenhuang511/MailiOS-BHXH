//
//  vdccaVerifier.h
//  VerifyCertificate
//
//  Created by Chen on 7/5/14.
//  Copyright (c) 2014 vdc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <include/openssl/x509.h>
#include <include/openssl/x509v3.h>
#include <include/openssl/ssl.h>
#include <include/openssl/pem.h>
#include <include/openssl/ocsp.h>
#include <include/openssl/err.h>
#include <string.h>

@interface vdccaVerifier : NSObject

+ (int)do_it:(char *)x509file inCAcert:(char *)inCAcert url:(char *)url;

@end
