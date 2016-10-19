//
//  vdccaVerifier.h
//  VerifyCertificate
//
//  Created by Chen on 7/5/14.
//  Copyright (c) 2014 vdc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include "pem.h"
#include <openssl/ocsp.h>
#include <openssl/err.h>
#include <string.h>
@interface vdccaVerifier : NSObject

X509_STORE *setup_verify(BIO *bp, char *CAfile, char *CApath);
X509 *load_cert(BIO *err, const char *file, int format,
                const char *pass, ENGINE *e, const char *cert_descrip);
STACK_OF(X509) *load_certs(BIO *err, const char *file, int format,
                           const char *pass, ENGINE *e, const char *cert_descrip);
int do_it(char *x509file, char *issuerfile, char *inCAcert, char *url);
- (int)do_it:(char *)x509file
  issuerfile:(char *)issuerfile
    inCAcert:(char *)inCAcert
         url:(char *)url
                        ;

int OCSP_basic_verify1(OCSP_BASICRESP *bs, STACK_OF(X509) *certs,X509_STORE *st, unsigned long flags);
@end
