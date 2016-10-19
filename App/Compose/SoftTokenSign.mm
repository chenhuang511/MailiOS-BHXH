//
//  SoftTokenSign.m
//  iMail
//
//  Created by Tran Ha on 23/04/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#include <iostream>
#include <fstream>

#import "SoftTokenSign.h"
#include <openssl/bio.h>
#include <openssl/conf.h>
#include <openssl/engine.h>
#include <openssl/err.h>

#import "openssl/ossl_typ.h"
#import "openssl/pkcs7.h"
#import "openssl/x509.h"
#import "openssl/err.h"

#import "cryptoki_compat/pkcs11.h"

#import "NSData+Base64.h"
#import "openssl/pem.h"
#import "HardTokenMethod.h"
#import "DBManager.h"
#import "VerifyMethod.h"

#import "HardTokenMethod.h"

@implementation SoftTokenSign
#define SHA1_LEN 20
#define ASN1_LEN 43
#define SHA1_OFFSET 20

- (BOOL)connectSoftToken:(NSString *)passwrd {
  HardTokenMethod *hud = [[HardTokenMethod alloc] init];
  [hud showGlobalProgressHUDWithTitle:NSLocalizedString(@"Loading", nil)];
  unsigned char *pinUser = (unsigned char *)[passwrd UTF8String];

  NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(
      NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *path = [libraryPath stringByAppendingPathComponent:@"data.db"];
  BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
  if (!fileExists) {
    return NO;
  }

  CK_SESSION_HANDLE m_hSession;
  int slotID = 0;
  C_OpenSession_s(slotID, CKF_SERIAL_SESSION, NULL, NULL, &m_hSession);
  int ckrv =
      C_Login_s(m_hSession, CKU_USER, pinUser, strlen((const char *)pinUser));
  if (ckrv) {
    C_CloseSession_s(m_hSession);
    UIAlertView *alertView = [[UIAlertView alloc]
            initWithTitle:NSLocalizedString(@"Error", nil)
                  message:NSLocalizedString(@"TokenPassWrong", nil)
                 delegate:nil
        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
        otherButtonTitles:nil];
    [alertView show];
    [hud dismissGlobalHUD];
    return NO;
  } else {
    //[[NSUserDefaults standardUserDefaults] setObject:passwrd
    // forKey:@"passwrd"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    C_Logout_s(m_hSession);
    C_CloseSession_s(m_hSession);
    [hud dismissGlobalHUD];
    return YES;
  }
}

- (NSString *)signMail:(NSString *)signData_
                  from:(NSString *)from
                    to:(NSString *)to
                    cc:(NSString *)cc
               subject:(NSString *)subject {
  // Get subject
  NSRange fromSubject = [signData_ rangeOfString:@"Subject: "];
  if (fromSubject.location != NSNotFound) {
    subject = [signData_ substringFromIndex:fromSubject.location];
    NSRange toSubject = [subject rangeOfString:@"MIME-Version"];
    subject = [subject substringToIndex:toSubject.location];
  }

  // Get content
  NSRange startContent = [signData_ rangeOfString:@"Content-Type:"];
  if (startContent.location != NSNotFound) {
    signData_ = [signData_ substringFromIndex:startContent.location];
  }
  const CK_ULONG MODULUS_BIT_LENGTH_1024 = 1024;
  const CK_ULONG MODULUS_BIT_LENGTH_2048 = 2048;
  CK_MECHANISM ckMechanismSign_SHA1 = {CKM_SHA1_RSA_PKCS, NULL_PTR, 0};

  NSData *certData;
  CK_SESSION_HANDLE m_hSession;
  CK_OBJECT_HANDLE m_hPriKey;

  CK_BYTE m_pSignature_1024[MODULUS_BIT_LENGTH_1024];
  CK_BYTE m_pSignature_2048[MODULUS_BIT_LENGTH_2048];
  CK_ULONG m_ulSignatureLen;
  CK_ULONG m_MODULUS_BIT_LENGTH = 2048;

  NSString *tfSignature;
  CK_RV ckrv = 0;
  CK_SLOT_ID flags = CKF_SERIAL_SESSION;
  CK_VOID_PTR p1 = NULL;
  int slotID = 0;
  C_OpenSession_s(slotID, flags, p1, NULL, &m_hSession);
  CK_MECHANISM pMechanism = {CKM_SHA_1, NULL_PTR, 0};

  ckrv = C_DigestInit_s(m_hSession, &pMechanism);

  if (CKR_OK != ckrv) {
    NSLog(@"%lu", ckrv);
    return @"1";
  }
  CK_BYTE pDigest[20] = {0};
  CK_ULONG ulDigestLen = sizeof(pDigest);

  // get Certhandle & mPrivateKey from database
  NSString *username = nil;
  NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count > 0 && accIndex < listAccount.count) {
    username = [listAccount objectAtIndex:accIndex + 1];
  }
  NSArray *tokenInfo =
      [[DBManager getSharedInstance] findTokenTypeByEmail:username];
  NSString *handleCertString = [tokenInfo objectAtIndex:1];
  NSString *handleKeyString = [tokenInfo objectAtIndex:2];
  CK_OBJECT_HANDLE hCKObj = [handleCertString longLongValue];
  m_hPriKey = [handleKeyString longLongValue];

  NSData *inDataSource_ = [signData_ dataUsingEncoding:NSUTF8StringEncoding];
  NSUInteger lenSource_ = [inDataSource_ length];
  Byte *inbyteDataSource_ = (Byte *)malloc([inDataSource_ length]);
  memcpy(inbyteDataSource_, [inDataSource_ bytes], lenSource_);

  ckrv = C_Digest_s(m_hSession, inbyteDataSource_, lenSource_, pDigest,
                    &ulDigestLen);
  if (CKR_OK != ckrv) {
    NSLog(@"%lu", ckrv);
    return @"2";
  }

  CK_ATTRIBUTE_PTR keyAttrs1 = (CK_ATTRIBUTE_PTR)malloc(sizeof(CK_ATTRIBUTE));
  keyAttrs1[0].type = CKA_VALUE;
  keyAttrs1[0].pValue = (CK_VOID_PTR)malloc(2048 * sizeof(CK_CHAR));
  keyAttrs1[0].ulValueLen = 2048 * sizeof(CK_CHAR);

  ckrv = C_GetAttributeValue_s(m_hSession, hCKObj, keyAttrs1, 1);

  certData = [[NSData alloc] initWithBytes:keyAttrs1->pValue
                                    length:keyAttrs1->ulValueLen];
  const unsigned char *certificateDataBytes =
      (const unsigned char *)[certData bytes];
  X509 *certificateX509 =
      d2i_X509(NULL, &certificateDataBytes, [certData length]);

  PKCS7 *p7;
  PKCS7_SIGNER_INFO *si;

  unsigned char *attr_buf = NULL;
  int auth_attr_len = 0;
  unsigned int len = 0;
  CK_RV rv;

  if (!(p7 = PKCS7_new())) {
    PKCS7err(PKCS7_F_PKCS7_SIGN, ERR_R_MALLOC_FAILURE);
    return @"3";
  }

  PKCS7_set_type(p7, NID_pkcs7_signed);
  PKCS7_content_new(p7, NID_pkcs7_data);

  if (!(si = PKCS7_add_signature(p7, certificateX509,
                                 X509_get_pubkey(certificateX509),
                                 EVP_sha1()))) {
    PKCS7err(PKCS7_F_PKCS7_SIGN, PKCS7_R_PKCS7_ADD_SIGNATURE_ERROR);
    return @"4";
  }
  PKCS7_add_certificate(p7, certificateX509);

  PKCS7_add_signed_attribute(si, NID_pkcs9_contentType, V_ASN1_OBJECT,
                             OBJ_nid2obj(NID_pkcs7_data));

  PKCS7_add1_attrib_digest(si, pDigest, 20);
  [self add_signed_time:si];

  auth_attr_len = ASN1_item_i2d((ASN1_VALUE *)si->auth_attr, &attr_buf,
                                ASN1_ITEM_rptr(PKCS7_ATTR_SIGN));

  NSString *passwrd =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"passwrd"];
  unsigned char *pinUser = (unsigned char *)[passwrd UTF8String];

  ckrv =
      C_Login_s(m_hSession, CKU_USER, pinUser, strlen((const char *)pinUser));
  rv = C_SignInit_s(m_hSession, &ckMechanismSign_SHA1, m_hPriKey);
  if (CKR_OK != rv) {
    NSLog(@"Failed to call SignInit!Error code 0x%08X.", int(rv));
    return @"5";
  }

  if (1024 == m_MODULUS_BIT_LENGTH) {
    m_ulSignatureLen = 128;
    rv = C_Sign_s(m_hSession, attr_buf, auth_attr_len, m_pSignature_1024,
                  &m_ulSignatureLen);

    if (CKR_OK != rv) {
      if (rv == CKR_CANCEL) {
        NSLog(@"UserCancelTransaction");
      } else if (rv == CKR_ARGUMENTS_BAD) {
        NSLog(@"CKR_ARGUMENTS_BAD");
      } else if (rv == CKR_BUFFER_TOO_SMALL) {
        NSLog(@"CKR_BUFFER_TOO_SMALL");
      } else {
        tfSignature = [NSString stringWithFormat:@"%@ ->%lu", @"TOMICALAB", rv];
        NSLog(@"TOMICALAB");
      }

      C_SignFinal_s(m_hSession, m_pSignature_1024, &m_ulSignatureLen);
      return @"6";
    }
    C_SignFinal_s(m_hSession, m_pSignature_1024, &m_ulSignatureLen);
  } else if (2048 == m_MODULUS_BIT_LENGTH) {
    m_ulSignatureLen = 256;

    rv = C_Sign_s(m_hSession, attr_buf, auth_attr_len, m_pSignature_2048,
                  &m_ulSignatureLen);
    if (CKR_OK != rv) {
      C_SignFinal_s(m_hSession, m_pSignature_2048, &m_ulSignatureLen);
      NSLog(@"Here signErr");
      return @"7";
    }
    C_SignFinal_s(m_hSession, m_pSignature_2048, &m_ulSignatureLen);
  }

  if (CKR_OK != rv) {
    NSLog(@"Failed to Sign!Error code 0x80");
    return @"8";
  }

  si->enc_digest = ASN1_OCTET_STRING_new();
  if (2048 == m_MODULUS_BIT_LENGTH) {
    ASN1_OCTET_STRING_set(si->enc_digest, (unsigned char *)m_pSignature_2048,
                          m_ulSignatureLen);
  } else {
    ASN1_OCTET_STRING_set(si->enc_digest, (unsigned char *)m_pSignature_1024,
                          m_ulSignatureLen);
  }

  OpenSSL_add_all_algorithms();
  ERR_load_crypto_strings();
  // PKCS7_set_detached(p7, 1);

  // P7Base64Encode
  unsigned char *buf2, *p, *sig_buf;
  sig_buf = NULL;
  len = i2d_PKCS7(p7, NULL);
  buf2 = (unsigned char *)OPENSSL_malloc(len);
  p = buf2;
  i2d_PKCS7(p7, &p);
  NSData *poutdata;
  poutdata = [[NSData alloc] initWithBytes:buf2 length:len];
  tfSignature = [poutdata base64EncodedString];
  // SMIME
  NSString *SMIME =
      [self SMIME_write_p7Base64:signData_:tfSignature:from:to:cc:subject];
  return SMIME;
}

// Chèn header cho nội dung mail
- (NSString *)HeaderInsert:(NSString *)content {
  NSString *TexPlain = @"Content-Type: text/plain; charset=\"utf-8\"\r\n";
  NSString *ContentTransfer_Encoding =
      @"Content-Transfer-Encoding: 8BIT\r\n\r\n";
  NSString *signData_ = [NSString
      stringWithFormat:@"%@%@%@", TexPlain, ContentTransfer_Encoding, content];
  return signData_;
}

- (NSString *)HeaderInsert_Quote:(NSString *)content {
  NSString *TexPlain = @"Content-Type: text/plain; charset=\"utf-8\"\r\n";
  NSString *ContentTransfer_Encoding =
      @"Content-Transfer-Encoding: quoted-printable\r\n\r\n";
  NSString *signData_ = [NSString
      stringWithFormat:@"%@%@%@", TexPlain, ContentTransfer_Encoding, content];
  return signData_;
}

//Đóng gói SMIME
- (NSString *)SMIME_write_p7Base64:(NSString *)
                         signData_:(NSString *)
                        p7Encode64:(NSString *)
                              from:(NSString *)
                                to:(NSString *)
                                cc:(NSString *)subject {

  NSString *SMIME;
  NSString *mime_eol = @"\r\n";
  NSString *mime_prefix = @"application/x-pkcs7-";

  /* Random bound */
  char bound[33], c;
  int i;
  RAND_pseudo_bytes((unsigned char *)bound, 32);
  for (i = 0; i < 32; i++) {
    c = bound[i] & 0xf;
    if (c < 10)
      c += '0';
    else
      c += 'A' - 10;
    bound[i] = c;
  }
  bound[32] = 0;
  NSString *bound_ = [NSString stringWithFormat:@"%s", bound];

  /* SMIME Begin */
  SMIME = [NSString stringWithFormat:@"MIME-Version: 1.0%@", mime_eol];
  SMIME = [NSString
      stringWithFormat:@"%@Content-Type: multipart/signed; "
                       @"protocol=\"%@signature\"; micalg=\"sha1\"; "
                       @"boundary=\"----%@\"%@%@",
                       SMIME, mime_prefix, bound_, mime_eol, mime_eol];
  SMIME = [NSString stringWithFormat:@"%@This is an S/MIME signed message%@%@",
                                     SMIME, mime_eol, mime_eol];
  SMIME = [NSString stringWithFormat:@"%@------%@%@", SMIME, bound_, mime_eol];

  SMIME = [NSString stringWithFormat:@"%@%@%@", SMIME, signData_, mime_eol];
  SMIME = [NSString stringWithFormat:@"%@------%@%@", SMIME, bound_, mime_eol];

  /* Headers signature */
  SMIME = [NSString
      stringWithFormat:@"%@Content-Type: %@signature;", SMIME, mime_prefix];
  SMIME =
      [NSString stringWithFormat:@"%@ name=\"smime.p7s\"%@", SMIME, mime_eol];
  SMIME = [NSString stringWithFormat:@"%@Content-Transfer-Encoding: base64%@",
                                     SMIME, mime_eol];
  SMIME =
      [NSString stringWithFormat:@"%@Content-Disposition: attachment;", SMIME];
  SMIME = [NSString stringWithFormat:@"%@filename=\"smime.p7s\"%@%@", SMIME,
                                     mime_eol, mime_eol];

  /* Signature */
  SMIME = [NSString
      stringWithFormat:@"%@%@%@%@", SMIME, p7Encode64, mime_eol, mime_eol];
  /* End of SMIME */
  SMIME = [NSString
      stringWithFormat:@"%@------%s--%@%@", SMIME, bound, mime_eol, mime_eol];

  /* Information */
  NSDate *now = [NSDate date];
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"EEE, dd MMM YYYY HH:mm:ss ZZZ";
  //[dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
  NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
  [dateFormatter setLocale:locale];
  NSString *currentTime = [dateFormatter stringFromDate:now];

  NSString *inform =
      [NSString stringWithFormat:@"Date: %@%@", currentTime, mime_eol];
  inform = [NSString stringWithFormat:@"%@From: %@%@", inform, from, mime_eol];

  to = [ComposeCommonMethod parseAndBase64AddressName:to];
  inform = [NSString stringWithFormat:@"%@To: %@%@", inform, to, mime_eol];
  if (!(cc.length == 0)) {
    cc = [ComposeCommonMethod parseAndBase64AddressName:cc];
    inform = [NSString stringWithFormat:@"%@Cc: %@%@", inform, cc, mime_eol];
  }
  if (!(subject.length == 0)) {
    inform = [NSString stringWithFormat:@"%@%@", inform, subject];
  }
  SMIME = [NSString stringWithFormat:@"%@%@", inform, SMIME];

  // Test
  // NSLog(@"SMIME:\n%@", SMIME);
  return SMIME;
}

- (void)add_signed_time:(PKCS7_SIGNER_INFO *)si {
  ASN1_UTCTIME *sign_time;
  sign_time = X509_gmtime_adj(NULL, 0);
  PKCS7_add_signed_attribute(si, NID_pkcs9_signingTime, V_ASN1_UTCTIME,
                             (char *)sign_time);
}

@end
