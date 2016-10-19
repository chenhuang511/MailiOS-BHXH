//
//  SoftTokenEncrypt.m
//  iMail
//
//  Created by Tran Ha on 16/05/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "SoftTokenEncrypt.h"
#import "SoftTokenSign.h"
#include <openssl/err.h>

#import "openssl/pkcs7.h"
#import "openssl/x509.h"
#import "openssl/err.h"
#import "SoftDatabase.h"
#import "openssl/pem.h"

@implementation SoftTokenEncrypt

- (NSString *)encrypMail:(NSString *)content_
                    from:(NSString *)from
                      to:(NSString *)to
                      cc:(NSString *)cc
                 subject:(NSString *)subject {

  NSString *SMIME;

  // Test
  // content_ = @"123456789";

  BIO *in = NULL, *out = NULL, *tbio = NULL;
  X509 *rcert = NULL;
  STACK_OF(X509) *recips = NULL;
  PKCS7 *p7 = NULL;
  int ret = 1;

  int flags = PKCS7_STREAM;

  OpenSSL_add_all_algorithms();
  ERR_load_crypto_strings();

  // Get subject
  if (subject.length > 0) {
    NSRange fromSubject = [content_ rangeOfString:@"Subject: "];
    subject = [content_ substringFromIndex:fromSubject.location];
    NSRange toSubject = [subject rangeOfString:@"MIME-Version"];
    subject = [subject substringToIndex:toSubject.location];
  }
  // creat tmp file
  NSRange start = [content_ rangeOfString:@"Content-Type:"];
  if (start.location != NSNotFound) {
    content_ = [content_ substringFromIndex:start.location];
  }

  // file cert
  NSString *certPath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.cer"];
  const char *cfilename = [certPath UTF8String];
  tbio = BIO_new_file(cfilename, "r");

  /* Write SMIME */
  NSString *tmpFilePath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.txt"];
  const char *cString =
      [tmpFilePath cStringUsingEncoding:NSASCIIStringEncoding];

  /* Read Content */
  NSString *contentFilePath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"content.txt"];
  [content_ writeToFile:contentFilePath
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:nil];
  const char *contentFile =
      [contentFilePath cStringUsingEncoding:NSASCIIStringEncoding];
  in = BIO_new_file(contentFile, "r");
  if (!in) {
    goto err;
  }
    
  /* Read in recipient certificate */
  if (!tbio)
    goto err;

  rcert = PEM_read_bio_X509(tbio, NULL, 0, NULL);

  if (!rcert)
    goto err;

  /* Create recipient STACK and add recipient cert to it */
  recips = sk_X509_new_null();

  if (!recips || !sk_X509_push(recips, rcert))
    goto err;

  rcert = NULL;

  /* encrypt content */
  p7 = PKCS7_encrypt(recips, in, EVP_des_ede3_cbc(), flags);

  if (!p7)
    goto err;

  out = BIO_new_file(cString, "w");
  if (!out)
    goto err;

  /* Write out S/MIME message */
  if (!SMIME_write_PKCS7(out, p7, in, flags))
    goto err;

  ret = 0;

err:
  if (ret) {
    fprintf(stderr, "Error Encrypting Data\n");
    ERR_print_errors_fp(stderr);
  }

  if (p7)
    PKCS7_free(p7);
  if (rcert)
    X509_free(rcert);
  if (recips)
    sk_X509_pop_free(recips, X509_free);

  if (in)
    BIO_free(in);
  if (out)
    BIO_free(out);
  if (tbio)
    BIO_free(tbio);

  SMIME = [NSString stringWithContentsOfFile:tmpFilePath
                                    encoding:NSUTF8StringEncoding
                                       error:NULL];

  /* Add header information */
  NSString *mime_eol = @"\r\n";
  NSDate *now = [NSDate date];
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"EEE, dd MMM YYYY HH:mm:ss ZZZ";
  //[dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  [dateFormatter setLocale:locale];
  NSString *currentTime = [dateFormatter stringFromDate:now];

  NSString *inform =
      [NSString stringWithFormat:@"Date: %@%@", currentTime, mime_eol];
  from = [ComposeCommonMethod parseAndBase64AddressName:from];
  inform = [NSString stringWithFormat:@"%@From: %@%@", inform, from, mime_eol];
  to = [ComposeCommonMethod parseAndBase64AddressName:to];
  inform = [NSString stringWithFormat:@"%@To: %@%@", inform, to, mime_eol];
  if (!(cc.length == 0)) {
    cc = [ComposeCommonMethod parseAndBase64AddressName:cc];
    inform = [NSString stringWithFormat:@"%@Cc: %@%@", inform, cc, mime_eol];
  }
  inform = [NSString stringWithFormat:@"%@%@", inform, subject];

  SMIME = [NSString stringWithFormat:@"%@%@", inform, SMIME];

  /* Delete temp file */
  NSError *error;
  [[NSFileManager defaultManager] removeItemAtPath:tmpFilePath error:&error];
  [[NSFileManager defaultManager] removeItemAtPath:contentFilePath
                                             error:&error];
  return SMIME;
}

- (BIO *)BIO_write_2:(const char *)data {
  BIO *bio;
  bio = BIO_new(BIO_s_mem());
  BIO_puts(bio, data);
  return bio;
}

@end
