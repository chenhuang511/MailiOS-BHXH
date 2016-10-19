//
//  SoftToken_SignEnvelope.m
//  iMail
//
//  Created by Tran Ha on 13/05/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "AppDelegate.h"
#import "SoftToken_SignEnvelope.h"
#import "SoftDatabase.h"
#import "DBManager.h"
#import "VerifyMethod.h"
#import "MCTMsgViewController.h"

#import "ListCertTableViewController.h"
#import <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/pkcs7.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <openssl/x509.h>
#import "NSData+Base64.h"

static PKCS7 *p7Static = nil;

@implementation SoftToken_SignEnvelope

+ (PKCS7*)sharedObject {
    return p7Static;
}

- (int)signVerify: (NSData*)rfc822String {
    
    //return 0: sign err || return 1: good || return 2: revoke || return 3: expired || return 4: email err || return 5: unknown error
    
    const char *s = "-----BEGIN CERTIFICATE-----\nMIIFgzCCBGugAwIBAgIKYQUN0gAAAAAABDANBgkqhkiG9w0BAQUFADB+MQswCQYD\nVQQGEwJWTjEzMDEGA1UEChMqTWluaXN0cnkgb2YgSW5mb3JtYXRpb24gYW5kIENv\nbW11bmljYXRpb25zMRswGQYDVQQLExJOYXRpb25hbCBDQSBDZW50ZXIxHTAbBgNV\nBAMTFE1JQyBOYXRpb25hbCBSb290IENBMB4XDTA5MTIxNjA2NDgwOFoXDTE5MTIx\nNjA2NTgwOFowaTELMAkGA1UEBhMCVk4xEzARBgNVBAoTClZOUFQgR3JvdXAxHjAc\nBgNVBAsTFVZOUFQtQ0EgVHJ1c3QgTmV0d29yazElMCMGA1UEAxMcVk5QVCBDZXJ0\naWZpY2F0aW9uIEF1dGhvcml0eTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC\nggIBAM9bKEZoQ8hYhBh7/zAqnr6cHwt716QDw1PT4wvoVLexmU/hOIxzOW89oRvM\nvXTBxLTLWuu2pVb526pomizVVkdHUlcAodrmmQO3+T1sVPGasN3zbmpOl4t+bEWG\nKTm/7pWUzN9aKfjwoIyJI2zutTZjs6rwzhPnROzFUMKMgLVJsQR9ETgPXHQvf4Ip\nhGf6hCSkyFiTc+dpNdgPDkUbC3VFM6OMDErzlTgs43fajF5VwikZVbEBNuPkgRvn\nSch5DlX3AMqdHLyzESZqi6GlRK9TiIVuePoOAMFOT3QrP2WxEiws2UcK0YhRVHLA\nChlJgFodSql94zlDcS2C4aYiZq3c4AZOhQBa8G00Cs/kjTiijWwTI+wZ43PBdHu3\nNSqR7bE51k/qI0lrA8R6EpyngWeve2BPTFrmFC+VcgXlZTUyvzrQs/d99kYpfJVI\n5NgDvgspB7NOwPUg2IWioZLUe9e9AoDV5M2pGBTsBprIJFjYusqGp8fQ9n2e6TE8\nH1TPoNQ1CDuf4V0sZFBdq5oOfmrokBT2M53W8T02UwG+mxGGbasbNtn0tE3tiGNy\ngB4tzneRet568iLoWt23Sa3vNIa72sPGHxP/HGd1x1CO/2QVUWeKTyjFG7AK6Y4e\nyER7idkE6x0ps/iuk7Hg2s1KCaZx7W9RJonKnje9ePXHzJv7AgMBAAGjggEWMIIB\nEjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBQGacDV1QKKFY1Gfel84mgKVaxq\nrzALBgNVHQ8EBAMCAYYwEAYJKwYBBAGCNxUBBAMCAQAwGQYJKwYBBAGCNxQCBAwe\nCgBTAHUAYgBDAEEwHwYDVR0jBBgwFoAUzWJx5GG9/j3sskBg04F13Tqsa8YwPAYD\nVR0fBDUwMzAxoC+gLYYraHR0cDovL3B1YmxpYy5yb290Y2EuZ292LnZuL2NybC9t\naWNucmNhLmNybDBHBggrBgEFBQcBAQQ7MDkwNwYIKwYBBQUHMAKGK2h0dHA6Ly9w\ndWJsaWMucm9vdGNhLmdvdi52bi9jcnQvbWljbnJjYS5jcnQwDQYJKoZIhvcNAQEF\nBQADggEBAC7Hmww6+MYCl3890I/tIQEq+5df4jd2TR8ND8sWiWwBi5AWn8KMZznF\nnm7UjKoqwkj+7m5UGH5vMn2dsaU0gdqWADYAoHWcLn4ipFbaqJE985V2G5b6c4q7\ngqmrJD66iPrzQs/EPzwpCs6cUikHHt2/K52N9tPePIGRnQklitEApiDb8CooouUE\nCmJGChPDewIIrtPjE50oZIhlX9lG/tWIZFH8UnUpXBcpFWtwR1H8NRd/j9EMeucJ\nguxLkmcZvh9TRswe++dmccmF4uLV/lyUSF5ppvJXDnm7LAZVZoc2arVd/z2ahQ2v\nCRDsgYuAXUb4JV70WvcbTv5PNzuZXg0=\n-----END CERTIFICATE-----\n";
    
    const char *o = "-----BEGIN CERTIFICATE-----\nMIIGbjCCBFagAwIBAgIQVAGS0oKVMWQsRhkUBic9fzANBgkqhkiG9w0BAQUFADBp\nMQswCQYDVQQGEwJWTjETMBEGA1UEChMKVk5QVCBHcm91cDEeMBwGA1UECxMVVk5Q\nVC1DQSBUcnVzdCBOZXR3b3JrMSUwIwYDVQQDExxWTlBUIENlcnRpZmljYXRpb24g\nQXV0aG9yaXR5MB4XDTEwMDEwNTA3MTYwMFoXDTE5MTIxNjA2NTgwOFowXTELMAkG\nA1UEBhMCVk4xEzARBgNVBAoMClZOUFQgR3JvdXAxHjAcBgNVBAsMFVZOUFQtQ0Eg\nVHJ1c3QgTmV0d29yazEZMBcGA1UEAwwQVk5QVC1DQSBPcGVyYXRvcjCCAiIwDQYJ\nKoZIhvcNAQEBBQADggIPADCCAgoCggIBAM+e/WNE4L1RFsdeC9xnsGwF0iI7Zik7\nuvEdRobvlDOWKq7HFzTvb0/aafAorVPaWgStveg+sLLWHTlebhoMGOW5JmeaW1qb\nc/nbT7GLC54LNlabSW50d9T1XIMDtmTjl3SwPG952Ag+xJ1K0pESAQRVSrvQAs/r\nqUcTTj4EIR6nXY7b/pkKHL2qxDXGSb0MNVARiGvmew2txZXbJuI8cKXPwdUz47GB\nn74rg4q+39GgPVcOp0/5EoclhT5jrXdVy+nGGl7hjcpZfx9g6pp33cHHkmKFXlYV\nhz7W1is7mqDUCQcGN166vlBvBhHJHM+xAfH8UEmnylSBEhCg56b3UAo3oPPc3EuN\nd9PfAUbwPKc0ei9Nt9NPNdCNFq9i4Gr0hDaMtrJMj8CWwpES5hZ1V89XInWg+lIE\n2Io98zFB7iWfVexPbIp9UX3YkSI1M5KuLbVkxPbOHgTiUPzv9QsLDHrStJmsves2\n+6czwbEEGr3C5CrorNX9AXFtHH/imHymT8GBFbt/W+NIStlZ/D5tsHJtHEBPkXmi\nowGeV+vnJV/IqtB0E7tw9xTUoKiJU1T4+v7QwWf8Ln+Mvfv0SckgPLXMDACfGCD1\nZtu+PKCg9Pl17+QvmKiPJ5L9z+UigBKMKfLSkBCA5UD4spVCR9KjK8fHXcWT+CRc\ntmg/EUvbolbhAgMBAAGjggEcMIIBGDBCBggrBgEFBQcBAQQ2MDQwMgYIKwYBBQUH\nMAKGJmh0dHA6Ly9wdWIudm5wdC1jYS52bi9jZXJ0cy92bnB0Y2EuY2VyMB0GA1Ud\nDgQWBBTGHkBzqgCTs8cOJbkX942h2VkHSTAPBgNVHRMBAf8EBTADAQH/MB8GA1Ud\nIwQYMBaAFAZpwNXVAooVjUZ96XziaApVrGqvMD4GA1UdIAQ3MDUwMwYIKwYBBAGB\n+jowJzAlBggrBgEFBQcCARYZaHR0cDovL3B1Yi52bnB0LWNhLnZuL3JwYTAxBgNV\nHR8EKjAoMCagJKAihiBodHRwOi8vY3JsLnZucHQtY2Eudm4vdm5wdGNhLmNybDAO\nBgNVHQ8BAf8EBAMCAYYwDQYJKoZIhvcNAQEFBQADggIBAJqNuE8kXVEFz71v0YeH\nmkGAbYpvTDc0PEmQxVuE5sPGcnsSPWptZs2zBy12JM7kJz98PfzWpCBvgaVlxD2+\nMJp95o/RbfzVVdejstms8INBTnoboV3lo5dDFyg2c7XRh8+u8Wdv69crBd5L0GTG\nzQkWDUxVuudu2wfXy8hC7lkm8n+uWXcNuReE0zCWIrwTfaEfFuHyx4rSqdQYBr+P\nC3ibfyqst7fIrcWhmFVbr4ZjWiUSRgypK3lg2YvXuOBQosduIQwCUQIqG/nBdABo\n3L3OaY3u84Rn0Yf0sYyIiNYWBE5lb2SkYMJOjTMnszKnngXB7e8NXM2rgxp+nZAJ\naAT9PWEqttweXtL96ffJpkz8qsHx8w2JGycyK1eIp81BBYx8H0+fLWZycBL0JXRC\n3JCgmbxODlgIpUXlCf7nSF4fCB557/0KgFbx7LDcFqKJcjNOyuR0H/DR1rNHNhtH\nbAJ8Wk8rMJMhIY/sKKlTe4mJ8FIQYk7wWNbAob6oyFc+zYjc36T7Ut8iEceQkk9+\ndDcmj7Vur21EivVk/cWpVMqtoVuMguF8qGyF66lkSYzDOjErRkaLqwX4fdvUgQF+\nM2g5rON574Uw06d40nCZ/JR8JkBUwk16g0WBseXFCmw0OBotPkgTMjxSBSa+UPWh\nXu1+pe2YX+hN0EWMzrbsvX0L\n-----END CERTIFICATE-----\n";
    
    const char *m = "-----BEGIN CERTIFICATE-----\nMIID1zCCAr+gAwIBAgIQG+Rzih8+wI9Hn6bPNcWYIjANBgkqhkiG9w0BAQUFADB+\nMQswCQYDVQQGEwJWTjEzMDEGA1UEChMqTWluaXN0cnkgb2YgSW5mb3JtYXRpb24g\nYW5kIENvbW11bmljYXRpb25zMRswGQYDVQQLExJOYXRpb25hbCBDQSBDZW50ZXIx\nHTAbBgNVBAMTFE1JQyBOYXRpb25hbCBSb290IENBMB4XDTA4MDUxNjAxMTI0OVoX\nDTQwMDUxNjAxMjAzMlowfjELMAkGA1UEBhMCVk4xMzAxBgNVBAoTKk1pbmlzdHJ5\nIG9mIEluZm9ybWF0aW9uIGFuZCBDb21tdW5pY2F0aW9uczEbMBkGA1UECxMSTmF0\naW9uYWwgQ0EgQ2VudGVyMR0wGwYDVQQDExRNSUMgTmF0aW9uYWwgUm9vdCBDQTCC\nASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKE/WVEO/jD/YduWeBSL20M8\nNr5hr9y1P2Ae0w0BQa34yYpCjsjtMoZHxf619+rWRDcQEsNICFFQuuVX6c41yY4c\ncwmFM0zhuzisjq23EwQuZoFXLcz7Gv0unIv9CUDwYBebcUVtfePbKtK7mt3rzF7k\nAN/VbDCFm71Xfy3UJNOA++AoUb6w1mEHzOWgR+eRbS+HWOi0rcGxRrPcWh04Cdn7\ntSeYnl788fRI/+ihO/9QM9kmq7KZYp3Me8hSTZ5cQotvdH78lBPeCtLwtWr4lkxQ\nnOYhjsHllwFOzZ+wQBl8G1lvXDgZmjfa0YE5FjLvga2wIWsRl8LBCL1vI1wED9MC\nAwEAAaNRME8wCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYE\nFM1iceRhvf497LJAYNOBdd06rGvGMBAGCSsGAQQBgjcVAQQDAgEAMA0GCSqGSIb3\nDQEBBQUAA4IBAQBMnc1+IyCAHCjP8PHJ3xHKsmlTo/JfDLNlnC9U4RxQKuBVF8QX\nvqiTUUaqhu0kZC9PE46wtBScfEO+LU5jUmzb1nAXWUdbolqzx5Z6tg31LQ3ZZDqv\n0FQ60RNotvo4DgXr4Pww90ybX+LuZ3v4Yup0r3JUTNT6Xovs67gngSyYjvfKoFGW\nc8YXifn0U5c/V8PbVShJc09KNypnhMUTvsbJ7glHYr+osup85V8k2zu4dDWw4YWP\nipdIjud4Z4nL5aQC7FtXobnHlrfB6eVdjpmmpyWaHbDO1jtrM/K+SeEt1oeBuXau\np/zNs8Z2Mq9NUFJsLQ2yvddQ5dN1Y59dzQqZ\n-----END CERTIFICATE-----\n";
    
    BIO *in = NULL, *out = NULL, *tbio = NULL, *cont = NULL, *obio = NULL, *sbio = NULL;
    X509_STORE *st = NULL;
    X509 *cacert = NULL, *subcert = NULL, *opercert = NULL;
    PKCS7 *p7 = NULL;
    
    // NSData to const char
    const char *data = (const char*) [rfc822String bytes];
    
    in = BIO_new(BIO_s_mem());
    
    if (!data) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                        message:NSLocalizedString(@"CheckInternet", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                              otherButtonTitles:nil];
        [alert show];
        return 0;
    }
    
    BIO_puts(in, data);
    
    int ret = 1;
    
    OpenSSL_add_all_algorithms();
    ERR_load_crypto_strings();
    
    /* Set up trusted CA certificate store */
    st = X509_STORE_new();
    
    /* Read in signer certificate and private key */
    tbio = [self BIO_write_:m];
    if (!tbio) {
        //goto err;
        return 0;
    }
    
    obio = [self BIO_write_:o];
    
    if (!obio) {
        //goto err;
        return 0;
    }
    
    sbio = [self BIO_write_:s];
    
    if (!sbio) {
        //goto err;
        return 0;
    }
    
    cacert = PEM_read_bio_X509(tbio, NULL, 0, NULL);
    subcert = PEM_read_bio_X509(sbio, NULL, 0, NULL);
    opercert = PEM_read_bio_X509(obio, NULL, 0, NULL);
    
    if (!cacert) {
        //goto err;
        return 0;
    }
    if (!subcert) {
        //goto err;
        return 0;
    }
    if (!opercert) {
        //goto err;
        return 0;
    }
    if (!X509_STORE_add_cert(st, cacert)) {
        //goto err;
        return 0;
    }
    if (!X509_STORE_add_cert(st, subcert)) {
        //goto err;
        return 0;
    }
    if (!X509_STORE_add_cert(st, opercert)) {
        //goto err;
        return 0;
    }
    if (!in) {
        //goto err;
        return 0;
    }
    /* Sign content */
    p7 = SMIME_read_PKCS7(in, &cont);
    
    if (!p7) {
        //goto err;
        return 0;
    }
    if (!PKCS7_verify(p7, NULL, st, cont, NULL, 0)) {
        NSLog(@"Verification Failure");
        return 0;
        //goto err;
    }
    
    NSLog(@"Verification Sucessfull");
    p7Static = p7;
    ret = 0;
    //Export base64 PEM file
    [self getBase64_pkcs7:p7];
    
    //Verify cert
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];
    
    /* For test only
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [documentsDirectory stringByAppendingPathComponent:@"2.cer"];
     */
    
    int result = [VerifyMethod certVerify:path];
    if (result == 0)  {
        // Verify expired date
        NSData *certificateData = [[NSFileManager defaultManager] contentsAtPath:path];
        const unsigned char *certificateDataBytes = (const unsigned char *)[certificateData bytes];
        // X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certificateData length]);
        FILE *fp; X509 *certificateX509 = NULL;
        fp = fopen([path UTF8String],"r");
        PEM_read_X509(fp,&certificateX509,NULL,NULL);
        ListCertTableViewController *info = [[ListCertTableViewController alloc]init];
        NSDate *expiredate = [info CertificateGetExpiryDate:certificateX509];
        
        // Current date
        NSDate *currentdate = [AppDelegate getNetworkDate];
        if (!currentdate) {
            NSDate* currentDate = [NSDate date];
            NSTimeZone* currentTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            NSTimeZone* nowTimeZone = [NSTimeZone systemTimeZone];
            NSInteger currentGMTOffset = [currentTimeZone secondsFromGMTForDate:currentDate];
            NSInteger nowGMTOffset = [nowTimeZone secondsFromGMTForDate:currentDate];
            NSTimeInterval interval = nowGMTOffset - currentGMTOffset;
            currentDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:currentDate];
        }
        if ([currentdate compare:expiredate] == NSOrderedDescending) {
            return 3; //Expired
        } else {
            //Verify email
            NSString *certmail = [info CertificateGetAltName:certificateX509];
            NSString *frommail = [MCTMsgViewController shareFromEmail];
            if ([certmail isEqualToString:frommail]) {
                return 1; //Good
            } else {
                return 4; //Email invalid
            }
        }
    } else if (result == 1) {
        return 2; // Revoke
    } else {
        return 5; // Unknown error
    }
    
    //err: {
    //    if (data) {
    //
    //    }
    //    if (ret)
    //    {
    //        NSLog(@"Error Verifying Data");
    //        ERR_print_errors_fp(stderr);
    //    }
    //
    //    if (p7)
    //        PKCS7_free(p7);
    //
    //    if (cacert)
    //        X509_free(cacert);
    //
    //    if (in)
    //        BIO_free(in);
    //    if (out)
    //        BIO_free(out);
    //    if (tbio)
    //        BIO_free(tbio);
    //    return 0;
    //}
}

- (NSString*)deCryptMail {
    BIO* in = NULL, *out = NULL;
    CK_RV ckrv = 0;
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    CK_VOID_PTR p1 = NULL;
    int slotID = 0;
    PKCS7 *p71;
    CK_SESSION_HANDLE m_hSession;
    NSData *certData;
    CK_OBJECT_HANDLE m_hPriKey;
    
    //get Certhandle & mPrivateKey from database
    NSString *username = nil;
    NSInteger accIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"] integerValue];
    NSMutableArray *listAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    if (listAccount.count > 0 && accIndex < listAccount.count) {
        username = [listAccount objectAtIndex:accIndex+1];
    }
    NSArray *tokenInfo = [[DBManager getSharedInstance]findTokenTypeByEmail:username];
    NSString *handleCertString = [tokenInfo objectAtIndex:1];
    NSString *handleKeyString = [tokenInfo objectAtIndex:2];
    CK_OBJECT_HANDLE hCKObj = [handleCertString longLongValue];
    m_hPriKey = [handleKeyString longLongValue];
    
    //begin decrypt
    OpenSSL_add_all_algorithms();
    ERR_load_crypto_strings();
    
    CK_MECHANISM ckMechanismDec = {CKM_RSA_PKCS, NULL_PTR, 0};
    
    ckrv = C_OpenSession_s(slotID, flags, p1, NULL, &m_hSession);
    
    CK_ATTRIBUTE_PTR keyAttrs1 = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs1[0].type = CKA_VALUE;
    keyAttrs1[0].pValue = (CK_VOID_PTR) malloc(2048 * sizeof(CK_CHAR));
    keyAttrs1[0].ulValueLen = 2048 * sizeof(CK_CHAR);
    
    CK_ULONG ulRetCount = 0;
    ckrv = C_FindObjects_s(m_hSession, &hCKObj, 1, &ulRetCount);
    ckrv = C_GetAttributeValue_s(m_hSession, hCKObj, keyAttrs1, 1);
    
    certData = [[NSData alloc] initWithBytes:keyAttrs1->pValue length:keyAttrs1->ulValueLen];
    const unsigned char *certificateDataBytes = (const unsigned char *)[certData bytes];
    X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certData length]);
    
    ASN1_OCTET_STRING *os = NULL;
    CK_RV rv;
    
    NSString *passwrd = [[NSUserDefaults standardUserDefaults]stringForKey:@"passwrd"];
    unsigned char *pinUser = (unsigned char *) [passwrd UTF8String];
    ckrv = C_Login_s(m_hSession, CKU_USER, pinUser, strlen((const char*) pinUser));
    
    rv = C_DecryptInit_s(m_hSession, &ckMechanismDec, m_hPriKey);
    NSLog(@"C_DecryptInits: %lu", rv);
    
    /* Open content being signed */
    // NSString to BIO
    NSString *fullMsnPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fullMsnPath.txt"];
    //Test; ko xoa
    //NSString *txtFileContents = [NSString stringWithContentsOfFile:fullMsnPath encoding:NSUTF8StringEncoding error:NULL];
    const char* char_fullMsn = [fullMsnPath UTF8String];
    in = BIO_new_file(char_fullMsn, "r");
    
    p71 = SMIME_read_PKCS7(in, NULL);
    if (!p71) {
        return nil;
    }
    if(!PKCS7_type_is_enveloped(p71)) {
        NSLog(@"type is not enveloped");
    }
    CK_BYTE dataDecrypt[4096];
    unsigned char *dataEncrypt;
    CK_ULONG dataEncryptLen;
    STACK_OF(PKCS7_RECIP_INFO) *rsk=NULL;
    PKCS7_RECIP_INFO *ri=NULL;
    long i;
    CK_ULONG dataDecryptLen;
    
    BIO *out1 = NULL, *etmp = NULL, *bio = NULL, *in_bio = NULL;
    EVP_CIPHER_CTX *evp_ctx = NULL;
    const EVP_CIPHER *evp_cipher = NULL;
    unsigned char *ek = NULL;
    int eklen = 0;
    X509_ALGOR *enc_alg = NULL;
    
    rsk = p71->d.enveloped->recipientinfo;
    for (i = 0; i < sk_PKCS7_RECIP_INFO_num(rsk); i++)
    {
        ri = sk_PKCS7_RECIP_INFO_value(rsk,i);
        if (!pkcs7_cmp_ri(ri, certificateX509))
            break;
        ri = NULL;
    }
    
    //creat decrypted file to read
    NSString *outString;
    NSString *decry_ = [NSTemporaryDirectory() stringByAppendingPathComponent:@"decry_.txt"];
    [@"" writeToFile:decry_
          atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSFileHandle *fileHandler= [NSFileHandle fileHandleForWritingAtPath:decry_];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (ri) {
        dataEncrypt = ri->enc_key->data;
        dataEncryptLen = ri->enc_key->length;
        enc_alg = p71->d.enveloped->enc_data->algorithm;
        evp_cipher = EVP_get_cipherbyname("DES-EDE3-CBC");
        os = p71->d.enveloped->enc_data->enc_data;
        rv = C_Decrypt_s(m_hSession, dataEncrypt, dataEncryptLen, dataDecrypt, &dataDecryptLen);
        if(rv) {
            rv = C_Decrypt_s(m_hSession, dataEncrypt, dataEncryptLen, dataDecrypt, &dataDecryptLen); }
        NSLog(@"C_Decrypt: %lu", rv);
        evp_ctx = NULL;
        if ((etmp = BIO_new(BIO_f_cipher())) == NULL)
        {
            NSLog(@"Fail0.0");
        }
        long getCipherCtx = etmp->method->ctrl(etmp, BIO_C_GET_CIPHER_CTX, 0, &evp_ctx);
        if(!getCipherCtx) {
            NSLog(@"Get cipher context fail");
        }
        if (EVP_CipherInit_ex(evp_ctx,evp_cipher,NULL,NULL,NULL,0) <= 0){
            NSLog(@"Fail0");
        }
        if (EVP_CIPHER_asn1_to_param(evp_ctx,enc_alg->parameter) < 0){
            NSLog(@"Fail1");
        }
        
        if (ek == NULL)
        {
            ek = (unsigned char*)malloc(dataDecryptLen);
            ek = dataDecrypt;
            eklen = dataDecryptLen;
        }
        if (eklen != EVP_CIPHER_CTX_key_length(evp_ctx)) {
            /* Some S/MIME clients don't use the same key
             * and effective key length. The key length is
             * determined by the size of the decrypted RSA key.
             */
            if(!EVP_CIPHER_CTX_set_key_length(evp_ctx, eklen))
            {
                /* Use random key as MMA defence */
                // Hạ 64 bit
                //OPENSSL_cleanse(ek, eklen);
                ek = NULL;
                ek = dataDecrypt;
                eklen = dataDecryptLen;
                
            }
        }
        /* Clear errors so we don't leak information useful in MMA */
        ERR_clear_error();
        if (EVP_CipherInit_ex(evp_ctx,NULL,NULL,ek,NULL,0) <= 0)
            return 0;
        
        if (ek) {
            // Hạ 64 bit
            //OPENSSL_cleanse(ek, eklen);
            ek = NULL;
        }
        if (out1 == NULL)
            out1 = etmp;
        else
            BIO_push(out1, etmp);
        etmp = NULL;
        
#if 1
        if (PKCS7_is_detached(p71) || (in_bio != NULL)) {
            bio = in_bio;
        }
        else
        {
#if 0
            bio = BIO_new(BIO_s_mem());
            /* We need to set this so that when we have read all
             * the data, the encrypt BIO, if present, will read
             * EOF and encode the last few bytes */
            BIO_set_mem_eof_return(bio,0);
            
            if (os->length > 0)
                BIO_write(bio,(char *)os->data, os->length);
#else
            if (os->length > 0){
                bio = BIO_new_mem_buf(os->data, os->length);
            }
            else {
                bio = BIO_new(BIO_s_mem());
                BIO_set_mem_eof_return(bio, 0);
            }
            if (bio == NULL)
                return 0;
#endif
        }
        BIO_push(out1,bio);
        bio = NULL;
#endif
        int ret;
        flags = 0;
        i = 0;
        char buf[4096] = {0};
        for (long i = 0; i < sizeof(buf); i++) {
            buf[i] = '\0';
        }
        
        if (flags & PKCS7_TEXT) {
            BIO *tmpbuf, *bread;
            /* Encrypt BIOs can't do BIO_gets() so add a buffer BIO */
            if(!(tmpbuf = BIO_new(BIO_f_buffer()))) {
                PKCS7err(PKCS7_F_PKCS7_DECRYPT, ERR_R_MALLOC_FAILURE);
                BIO_free_all(out1);
            }
            if(!(bread = BIO_push(tmpbuf, out1))) {
                PKCS7err(PKCS7_F_PKCS7_DECRYPT, ERR_R_MALLOC_FAILURE);
                BIO_free_all(tmpbuf);
                BIO_free_all(out1);
            }
            ret = SMIME_text(bread, out);
            if (ret > 0 && BIO_method_type(out1) == BIO_TYPE_CIPHER)
            {
                if (!BIO_get_cipher_status(out1))
                    ret = 0;
            }
            BIO_free_all(bread);
        } else {
            @autoreleasepool {
                for(;;) {
                    i = BIO_read(out1, buf, sizeof(buf)- 1);
                    if(i <= 0)
                    {
                        ret = 1;
                        if (BIO_method_type(out1) == BIO_TYPE_CIPHER)
                        {
                            long check = out1->method->ctrl(out1, BIO_C_GET_CIPHER_STATUS, 0, NULL);
                            if (!check) {
                                ret = 0;
                            }
                        }
                        break;
                    }
                    outString = [NSString stringWithUTF8String:buf];
                    [fileHandler seekToEndOfFile];
                    [fileHandler writeData:[outString dataUsingEncoding:NSUTF8StringEncoding]];
                    outString = nil;
                }
                BIO_free_all(out1);
                [fileHandler closeFile];
            }
        }
    }
    
    NSString *temp = [NSString stringWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"decry_.txt"] encoding:NSUTF8StringEncoding error:NULL];
    BOOL a = [fileManager removeItemAtPath:decry_ error:nil];
    if ([temp isEqualToString:@""]) {
        temp = nil;
    }
    NSLog(@"Delete tmp file: %hhd", a);
    return  temp;
}

- (NSDictionary *)verifyInfo: (PKCS7*)p7  {
    
    NSDictionary *dict;
    NSString *serial;
    NSString *name;
    NSString *issuer;
    NSString *expireDate;
    NSString *validDate;
    NSString *email;
    
    STACK_OF(X509) *certs = NULL;
    certs = p7->d.sign->cert;
    
    int i;
    for (i = 0; certs && i < sk_X509_num(certs); i++) {
        X509 *x = sk_X509_value(certs,i);
        
        //Get Email from X509
        int loc = X509_get_ext_by_NID(x, NID_subject_alt_name, -1);
        if (loc >= 0) {
            
            //Serial
            ASN1_INTEGER* serial_asn = X509_get_serialNumber(x);
            BIGNUM *bnser = ASN1_INTEGER_to_BN(serial_asn, NULL);
            char *asciiHex = BN_bn2hex(bnser);
            serial = [NSString stringWithUTF8String:asciiHex];
            
            //CN
            ListCertTableViewController *method = [[ListCertTableViewController alloc]init];
            name = [method CertificateGetSubjectName:x];
            
            //issuer
            
            issuer = [self issuer:x];
            
            //expiryDate
            ASN1_TIME *get_notAfter = X509_get_notAfter(x);
            ASN1_TIME *get_notBefore = X509_get_notBefore(x);
            expireDate = [self date:get_notAfter];
            validDate = [self date:get_notBefore];
            
            //mail
            email = [method CertificateGetAltName:x];
            
            
            dict = [NSDictionary dictionaryWithObjectsAndKeys:
                    issuer, @"issuer",
                    name, @"name",
                    serial, @"serial",
                    validDate, @"validDate",
                    expireDate, @"expireDate",
                    email, @"email",
                    nil];
        }
        
    }
    return dict;
}

- (NSString *)issuer :(X509 *)certificateX509 {
    NSString *issuer = nil;
    if (certificateX509 != NULL) {
        X509_NAME *issuerX509Name = X509_get_issuer_name(certificateX509);
        if (issuerX509Name != NULL) {
            int nid = OBJ_txt2nid("CN");
            int index = X509_NAME_get_index_by_NID(issuerX509Name, nid, -1);
            X509_NAME_ENTRY *issuerNameEntry = X509_NAME_get_entry(issuerX509Name, index);
            if (issuerNameEntry) {
                ASN1_STRING *issuerNameASN1 = X509_NAME_ENTRY_get_data(issuerNameEntry);
                
                if (issuerNameASN1 != NULL) {
                    unsigned char *issuerName = ASN1_STRING_data(issuerNameASN1);
                    issuer = [NSString stringWithUTF8String:(char *)issuerName];
                }
            }
        }
    }
    return issuer;
}


- (NSString*)date : (ASN1_TIME*)certificateExpiryASN1 {
    NSString* expiryDate;
    if (certificateExpiryASN1 != NULL) {
        ASN1_GENERALIZEDTIME *certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(certificateExpiryASN1, NULL);
        if (certificateExpiryASN1Generalized != NULL) {
            unsigned char *certificateExpiryData = ASN1_STRING_data(certificateExpiryASN1Generalized);
            
            NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
            NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];
            
            expiryDateComponents.year   = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
            expiryDateComponents.month  = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
            expiryDateComponents.day    = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
            expiryDateComponents.hour   = [[expiryTimeStr substringWithRange:NSMakeRange(8, 2)] intValue];
            expiryDateComponents.minute = [[expiryTimeStr substringWithRange:NSMakeRange(10, 2)] intValue];
            expiryDateComponents.second = [[expiryTimeStr substringWithRange:NSMakeRange(12, 2)] intValue];
            
            NSCalendar *calendar = [NSCalendar currentCalendar];
            NSDate *expiryDate_ = [calendar dateFromComponents:expiryDateComponents];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat: @"dd-MM-yyyy"];
            expiryDate = [formatter stringFromDate:expiryDate_];
        }
    }
    return expiryDate;
}

- (BIO*) BIO_write_ : (const char *)data {
    BIO *bio;
    bio = BIO_new(BIO_s_mem());
    BIO_puts(bio, data);
    return bio;
}

static int pkcs7_cmp_ri(PKCS7_RECIP_INFO *ri, X509 *pcert)
{
    int ret;
    ret = X509_NAME_cmp(ri->issuer_and_serial->issuer,
                        pcert->cert_info->issuer);
    if (ret)
        return ret;
    return M_ASN1_INTEGER_cmp(pcert->cert_info->serialNumber,
                              ri->issuer_and_serial->serial);
}

- (void)getBase64_pkcs7: (PKCS7*)p7 {
    
    CRYPTO_malloc_init();
    ERR_load_crypto_strings();
    OpenSSL_add_all_algorithms();
    
    STACK_OF(X509) *certs = NULL;
    certs = p7->d.sign->cert ;
    
    int i, rv;
    NSString *certPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];
    //NSString *base64 = [NSString stringWithContentsOfFile:certPath encoding:NSUTF8StringEncoding error:NULL];
    BIO* out = BIO_new_file([certPath UTF8String], "w");
    for (i = 0; certs && i < sk_X509_num(certs); i++) {
        X509 *x = sk_X509_value(certs,i);
        int loc = X509_get_ext_by_NID(x, NID_subject_alt_name, -1);
        if (loc >= 0 && x->altname != NULL) {
            rv =  PEM_write_bio_X509(out,x);
            BIO_free(out);
        }
    }
}

@end
