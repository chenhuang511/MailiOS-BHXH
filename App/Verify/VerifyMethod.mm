//
//  VerifyMethod.m
//  iMail
//
//  Created by Tran Ha on 11/13/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "VerifyMethod.h"
#import "TokenType.h"
#import "DBManager.h"
#import "vdccaVerifier.h"
#import "ListCertTableViewController.h"

#import "x509v3.h"
#import "bio.h"

#include <string.h>
#include <fstream>
#import "cryptoki_ext.h"

#import "cryptoki_compat/pkcs11.h"

#include <openssl/pem.h>
#import <CommonCrypto/CommonDigest.h>
#import "AppDelegate.h"

#import "HardTokenMethod.h"

@implementation VerifyMethod

- (int)selfVerify:(NSString *)username {

  // Database
  NSArray *tokenInfo =
      [[DBManager getSharedInstance] findTokenTypeByEmail:username];
  if (![tokenInfo count]) {
    return 7;
  }
  int tokentype = [[tokenInfo objectAtIndex:0] integerValue];
  NSString *handleCertString = [tokenInfo objectAtIndex:1];
  long certHandle = [handleCertString longLongValue];
  if (!certHandle) {
    return 7;
  }
  // ExportCert
  if (tokentype == SOFTTOKEN) {
    if (![self exportCertSoftbyHandle:certHandle]) {
      return 7;
    };
  }
  if (tokentype == HARDPROTECT) {
    if (![self exportCertHardbyHandle:certHandle]) {
      return 7;
    };
  }

  NSString *issuer =
      [[NSBundle mainBundle] pathForResource:@"vnptca" ofType:@"pem"];
  NSString *certPath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];

  // for test only
  //    NSArray *paths =
  //    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
  //    NSUserDomainMask, YES);
  //    NSString *documentsDirectory = [paths objectAtIndex:0];
  //    NSString *certPath = [documentsDirectory
  //    stringByAppendingPathComponent:@"revoke.pem"];

  // Check Revoke
  int result = [vdccaVerifier do_it:(char *)[certPath UTF8String]
                           inCAcert:(char *)[issuer UTF8String]
                                url:"http://ocsp.vnpt-ca.vn/responder"];

  if (result) {
    return result;
  } else {
    // Check expired date
    NSData *certificateData =
        [[NSFileManager defaultManager] contentsAtPath:certPath];
    const unsigned char *certificateDataBytes =
        (const unsigned char *)[certificateData bytes];
    FILE *fp;
    X509 *certificateX509 = NULL;
    fp = fopen([certPath UTF8String], "r");
    PEM_read_X509(fp, &certificateX509, NULL, NULL);
    ListCertTableViewController *info =
        [[ListCertTableViewController alloc] init];
    NSDate *expiredate = [info CertificateGetExpiryDate:certificateX509];

    // Current date
    NSDate *currentDate = [AppDelegate getNetworkDate];
    if (!currentDate) {
      NSDate *currentDate = [NSDate date];
      NSTimeZone *currentTimeZone =
          [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
      NSTimeZone *nowTimeZone = [NSTimeZone systemTimeZone];
      NSInteger currentGMTOffset =
          [currentTimeZone secondsFromGMTForDate:currentDate];
      NSInteger nowGMTOffset = [nowTimeZone secondsFromGMTForDate:currentDate];
      NSTimeInterval interval = nowGMTOffset - currentGMTOffset;
      currentDate =
          [[NSDate alloc] initWithTimeInterval:interval sinceDate:currentDate];
    }
    if ([currentDate compare:expiredate] == NSOrderedDescending) {
      return 13; // Expired
    } else {
      return 0;
    }
  }
}

- (int)selfVerifybyCert:(long)certHandle byTokenType:(int)tokentype {

  if (!certHandle) {
    return 7;
  }
  // ExportCert
  if (tokentype == SOFTTOKEN) {
    if (![self exportCertSoftbyHandle:certHandle]) {
      return 7;
    };
  }
  if (tokentype == HARDPROTECT) {
    if (![self exportCertHardbyHandle:certHandle]) {
      return 7;
    };
  }

  NSString *issuer =
      [[NSBundle mainBundle] pathForResource:@"vnptca" ofType:@"pem"];
  NSString *certPath =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];

  // for test only
  //    NSArray *paths =
  //    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
  //    NSUserDomainMask, YES);
  //    NSString *documentsDirectory = [paths objectAtIndex:0];
  //    NSString *certPath = [documentsDirectory
  //    stringByAppendingPathComponent:@"revoke.pem"];

  // Check Revoke
  int result = [vdccaVerifier do_it:(char *)[certPath UTF8String]
                           inCAcert:(char *)[issuer UTF8String]
                                url:"http://ocsp.vnpt-ca.vn/responder"];

  if (result) {
    return result;
  } else {
    // Check expired date
    NSData *certificateData =
        [[NSFileManager defaultManager] contentsAtPath:certPath];
    const unsigned char *certificateDataBytes =
        (const unsigned char *)[certificateData bytes];
    FILE *fp;
    X509 *certificateX509 = NULL;
    fp = fopen([certPath UTF8String], "r");
    PEM_read_X509(fp, &certificateX509, NULL, NULL);
    ListCertTableViewController *info =
        [[ListCertTableViewController alloc] init];
    NSDate *expiredate = [info CertificateGetExpiryDate:certificateX509];

    // Current date
    NSDate *currentDate = [AppDelegate getNetworkDate];
    if (!currentDate) {
      NSDate *currentDate = [NSDate date];
      NSTimeZone *currentTimeZone =
          [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
      NSTimeZone *nowTimeZone = [NSTimeZone systemTimeZone];
      NSInteger currentGMTOffset =
          [currentTimeZone secondsFromGMTForDate:currentDate];
      NSInteger nowGMTOffset = [nowTimeZone secondsFromGMTForDate:currentDate];
      NSTimeInterval interval = nowGMTOffset - currentGMTOffset;
      currentDate =
          [[NSDate alloc] initWithTimeInterval:interval sinceDate:currentDate];
    }
    if ([currentDate compare:expiredate] == NSOrderedDescending) {
      return 13; // Expired
    } else {
      return 0;
    }
  }
}

+ (int)certVerify:(NSString *)certPath {
  NSString *issuer =
      [[NSBundle mainBundle] pathForResource:@"vnptca" ofType:@"pem"];
  int result = [vdccaVerifier do_it:(char *)[certPath UTF8String]
                           inCAcert:(char *)[issuer UTF8String]
                                url:"http://ocsp.vnpt-ca.vn/responder"];
  return result;
}

+ (int)selfverifybyCertHandle:(long)certhandle byTokenType:(int)tokentype {

  VerifyMethod *initObj = [[VerifyMethod alloc] init];
  int result = [initObj selfVerifybyCert:certhandle byTokenType:tokentype];

  if (result) {
    UIAlertView *alert;
    switch (result) {
    case 1: {
      alert = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Notifi", nil)
                    message:NSLocalizedString(@"Revoked_Cert", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:nil];
    } break;
    case 13: {
      alert = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Notifi", nil)
                    message:NSLocalizedString(@"Expired_Cert", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:nil];
    } break;
    default:
      alert = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Notifi", nil)
                    message:NSLocalizedString(@"UnknownErr", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:nil];
      break;
    }
    [alert show];
  }
  return result;
}

/* return: 0 - Good ;
 1 - Revoke;
 2 - Expired;
 7 - Handle error;
 # - OCSP Connection Err */

+ (int)selfverifyCertificate {
  NSString *username = nil;
  NSInteger accIndex = [[[NSUserDefaults standardUserDefaults]
      objectForKey:@"accIndex"] integerValue];
  NSMutableArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count > 0 && accIndex < listAccount.count) {
    username = [listAccount objectAtIndex:accIndex + 1];
  }
  VerifyMethod *initObj = [[VerifyMethod alloc] init];
  int result = [initObj selfVerify:username];
  if (result) {
    UIAlertView *alert;
    switch (result) {
    case 1: {
      alert = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Notifi", nil)
                    message:NSLocalizedString(@"Revoked_Cert", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:nil];
    } break;
    case 13: {
      alert = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Notifi", nil)
                    message:NSLocalizedString(@"Expired_Cert", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:nil];
    } break;
    default:
      alert = [[UIAlertView alloc]
              initWithTitle:NSLocalizedString(@"Notifi", nil)
                    message:NSLocalizedString(@"UnknownErr", nil)
                   delegate:nil
          cancelButtonTitle:NSLocalizedString(@"Back", nil)
          otherButtonTitles:nil];
      break;
    }
    [alert show];
  }
  return result;
}

- (void)copydata {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  // src
  NSString *src =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];
  // dest
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *dest =
      [documentsDirectory stringByAppendingPathComponent:@"out.pem"];
  // copy
  if ([fileManager fileExistsAtPath:dest]) {
    [fileManager removeItemAtPath:dest error:nil];
  }
  [fileManager copyItemAtPath:src toPath:dest error:nil];
}

- (BOOL)exportCertSoftbyHandle:(NSInteger)i {

  // Step 0: Open Session
  CK_SLOT_ID flags = CKF_SERIAL_SESSION;
  CK_SESSION_HANDLE sessionID = -1;
  CK_VOID_PTR p = NULL;
  int slotID = 0;
  int rv = C_OpenSession_s(slotID, flags, p, NULL, &sessionID);
  if (rv) {
    return FALSE;
  }

  // Step 1: Make a ck_attribute
  const char *key = "CERT";
  CK_ATTRIBUTE_PTR keyAttrs = (CK_ATTRIBUTE_PTR)malloc(sizeof(CK_ATTRIBUTE));
  keyAttrs->type = CKA_LABEL;
  keyAttrs->pValue = (void *)key;

  // Step 2: Find cert
  rv = C_FindObjectsInit_s(sessionID, keyAttrs,
                           sizeof(keyAttrs) / sizeof(CK_ATTRIBUTE));

  if (rv) {
    return FALSE;
  }

  // Step 3:  Get the first object handle of key
  unsigned long *handlep = new unsigned long[10];
  unsigned long *handle_countp = new unsigned long[20];
  unsigned long MAX_OBJECT = 10;
  rv = C_FindObjects_s(sessionID, handlep, MAX_OBJECT, handle_countp);
  if (rv) {
    return FALSE;
  }

  // Step 4: Build cert
  CK_ATTRIBUTE_PTR keyAttrs1 = (CK_ATTRIBUTE_PTR)malloc(sizeof(CK_ATTRIBUTE));
  keyAttrs1[0].type = CKA_VALUE;
  keyAttrs1[0].pValue = (CK_VOID_PTR)malloc(2048 * sizeof(CK_CHAR));
  keyAttrs1[0].ulValueLen = 2048 * sizeof(CK_CHAR);
  rv = C_GetAttributeValue_s(sessionID, i, keyAttrs1, 1);
  if (rv) {
    return FALSE;
  }

  // Step 5: Lay gia tri chung thu
  void *temp = keyAttrs1->pValue;
  char *certByte = (char *)(temp);
  int len = keyAttrs1->ulValueLen;

  // Step 6: Ghi ra file
  std::string filePath = getenv("HOME");
  filePath += "/tmp/test.cer";
  std::ofstream outFile(filePath, std::ofstream::binary);
  outFile.write(certByte, len);
  outFile.close();
  NSString *src =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.cer"];
  NSData *certData = [[NSFileManager defaultManager] contentsAtPath:src];
  const unsigned char *certificateDataBytes =
      (const unsigned char *)[certData bytes];
  X509 *certificateX509 =
      d2i_X509(NULL, &certificateDataBytes, [certData length]);

  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *libraDirectory = [paths objectAtIndex:0];
  NSString *dest =
      [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];

  BIO *out = BIO_new_file([dest UTF8String], "w");
  PEM_write_bio_X509(out, certificateX509);
  BIO_free(out);
  return TRUE;
}

- (BOOL)exportCertHardbyHandle:(NSInteger)index {

  NSString *session =
      [[NSUserDefaults standardUserDefaults] stringForKey:@"TokenSession"];
  CK_SESSION_HANDLE m_hSession = [session longLongValue];

  NSMutableArray *arrayCertData = [[NSMutableArray alloc] init];
  NSMutableArray *arrayKeyContainer = [[NSMutableArray alloc] init];
  int i = 0;
  CK_RV ckrv = 0;

  CK_OBJECT_CLASS dataClass = CKO_CERTIFICATE;
  BOOL IsToken = true;
  CK_ATTRIBUTE_H pTempl[] = {{CKA_CLASS, &dataClass, sizeof(dataClass)},
                             {CKA_TOKEN, &IsToken, sizeof(true)}};

  ckrv = C_FindObjectsInit(m_hSession, pTempl, 2);
  if (ckrv) {
    return FALSE;
  }

  CK_OBJECT_HANDLE hCKObj;
  CK_ULONG ulRetCount = 0;

  int numObj = 0; // object numbers

  do {
    ckrv = C_FindObjects(m_hSession, &hCKObj, 1, &ulRetCount);
    if (CKR_OK != ckrv) {
      break;
    }
    if (1 != ulRetCount)
      break;

    CK_ATTRIBUTE_H pAttrTemp[] = {{CKA_CLASS, NULL, 0},
                                  {CKA_CERTIFICATE_TYPE, NULL, 0},
                                  {CKA_LABEL, NULL, 0},
                                  {CKA_SUBJECT, NULL, 0},
                                  {CKA_ID, NULL, 0},
                                  {CKA_VALUE, NULL, 0},
                                  {CKA_SERIAL_NUMBER, NULL, 0},
                                  {CKA_CONTAINER_NAME, NULL, 0},
                                  {CKA_START_DATE, NULL, 0}};

    ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 9);
    if (ckrv != CKR_OK) {
      break;
    }

    pAttrTemp[0].pValue = new char[pAttrTemp[0].ulValueLen];
    pAttrTemp[1].pValue = new char[pAttrTemp[1].ulValueLen];
    pAttrTemp[2].pValue = new char[pAttrTemp[2].ulValueLen + 1];
    pAttrTemp[3].pValue = new char[pAttrTemp[3].ulValueLen + 1];
    pAttrTemp[4].pValue = new char[pAttrTemp[4].ulValueLen + 1];
    pAttrTemp[5].pValue = new char[pAttrTemp[5].ulValueLen];
    pAttrTemp[6].pValue = new char[pAttrTemp[6].ulValueLen];
    pAttrTemp[7].pValue = new char[pAttrTemp[7].ulValueLen];
    pAttrTemp[8].pValue = new char[1024];

    memset(pAttrTemp[0].pValue, 0, pAttrTemp[0].ulValueLen);
    memset(pAttrTemp[1].pValue, 0, pAttrTemp[1].ulValueLen);
    memset(pAttrTemp[2].pValue, 0, pAttrTemp[2].ulValueLen + 1);
    memset(pAttrTemp[3].pValue, 0, pAttrTemp[3].ulValueLen + 1);
    memset(pAttrTemp[4].pValue, 0, pAttrTemp[4].ulValueLen + 1);
    memset(pAttrTemp[5].pValue, 0, pAttrTemp[5].ulValueLen);
    memset(pAttrTemp[6].pValue, 0, pAttrTemp[6].ulValueLen);
    memset(pAttrTemp[7].pValue, 0, pAttrTemp[7].ulValueLen);
    memset(pAttrTemp[8].pValue, 0, 1024);

    ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 9);

    if (ckrv != CKR_OK) {
      delete[] pAttrTemp[0].pValue;
      delete[] pAttrTemp[1].pValue;
      delete[] pAttrTemp[2].pValue;
      delete[] pAttrTemp[3].pValue;
      delete[] pAttrTemp[4].pValue;
      delete[] pAttrTemp[5].pValue;
      delete[] pAttrTemp[6].pValue;
      delete[] pAttrTemp[7].pValue;
      delete[] pAttrTemp[8].pValue;
      break;
    }

    numObj++;

    NSData *mData = [[NSData alloc] initWithBytes:pAttrTemp[2].pValue
                                           length:pAttrTemp[2].ulValueLen];
    mData = [[NSData alloc] initWithBytes:pAttrTemp[5].pValue
                                   length:pAttrTemp[5].ulValueLen];
    [arrayCertData addObject:mData];
    NSData *certData = mData;

    mData = [[NSData alloc] initWithBytes:pAttrTemp[7].pValue
                                   length:pAttrTemp[7].ulValueLen];
    NSString *cka_keyContainer =
        [[NSString alloc] initWithData:mData encoding:NSASCIIStringEncoding];
    [arrayKeyContainer addObject:cka_keyContainer];

    const unsigned char *certificateDataBytes =
        (const unsigned char *)[certData bytes];
    X509 *certificateX509 =
        d2i_X509(NULL, &certificateDataBytes, [certData length]);

    // Save cert?
    i++;
    if (index == hCKObj) {
      NSArray *paths = NSSearchPathForDirectoriesInDomains(
          NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *libraDirectory = [paths objectAtIndex:0];
      NSString *dest =
          [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];
      BIO *out = BIO_new_file([dest UTF8String], "w");
      PEM_write_bio_X509(out, certificateX509);
      BIO_free(out);
      return TRUE;
    }

    delete[] pAttrTemp[0].pValue;
    delete[] pAttrTemp[1].pValue;
    delete[] pAttrTemp[2].pValue;
    delete[] pAttrTemp[3].pValue;
    delete[] pAttrTemp[4].pValue;
    delete[] pAttrTemp[5].pValue;
    delete[] pAttrTemp[6].pValue;
    delete[] pAttrTemp[7].pValue;
    delete[] pAttrTemp[8].pValue;

  } while (true);
}

@end
