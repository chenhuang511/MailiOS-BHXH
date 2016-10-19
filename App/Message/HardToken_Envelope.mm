//
//  HardToken_Envelope.m
//  iMail
//
//  Created by Tran Ha on 13/06/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "HardToken_Envelope.h"
#import "DBManager.h"
#import <openssl/evp.h>
#include <openssl/pem.h>
#include <openssl/pkcs7.h>
#include <openssl/err.h>
#include <openssl/bio.h>
#include <x509.h>
#import "NSData+Base64.h"
#include "hardtoken/cryptoki_linux.h"
#import "hardtoken/cryptoki_ext.h"
#include <include/openssl/x509v3.h>

#import "EADevice.h"
#import "DeviceAudio.h"
#import "pkcs11.h"
#include "rand.h"
#include <include/openssl/x509.h>
#include <include/openssl/x509v3.h>
#include <include/openssl/err.h>
#include <include/openssl/pkcs12.h>

@implementation HardToken_Envelope

- (NSString *)deCryptMailHT {
    
    BIO* in = NULL, *out = NULL;
    CK_RV ckrv = 0;
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    PKCS7 *p7;
    NSData *certData;
    CK_OBJECT_HANDLE m_hPriKey;
    CK_RV rv;
    CK_SESSION_HANDLE m_hSession;
    CK_MECHANISM_H ckMechanismDec = {CKM_RSA_PKCS, NULL_PTR, 0};
    
    CK_SLOT_ID_PTR m_pSlotList;
    m_pSlotList = NULL_PTR;
    
    //Get session
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"TokenSession"];
    m_hSession = [session longLongValue];
    
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
    
    //Attrs
    CK_ATTRIBUTE_PTR_H keyAttrs1 = (CK_ATTRIBUTE_PTR_H)malloc(sizeof(CK_ATTRIBUTE_H));
    keyAttrs1[0].type = CKA_VALUE;
    keyAttrs1[0].pValue = (CK_VOID_PTR) malloc(2048* sizeof(CK_CHAR));
    keyAttrs1[0].ulValueLen = 2048 * sizeof(CK_CHAR);
    
    ckrv = C_GetAttributeValue(m_hSession, hCKObj, keyAttrs1, 1);
    certData = [[NSData alloc] initWithBytes:keyAttrs1->pValue length:keyAttrs1->ulValueLen];
    const unsigned char* certificateDataBytes = (const unsigned char*)[certData bytes];
    X509* certificateX509 = d2i_X509(NULL, &certificateDataBytes,  [certData length]);
    
    ASN1_OCTET_STRING *os = NULL;
    ckrv = C_DecryptInit(m_hSession, &ckMechanismDec, m_hPriKey);
    
    /* Open content being signed */
    NSString *fileDecryptPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"fullMsnPath.txt"];
    //Test; ko xoa
    //NSString *txtFileContents = [NSString stringWithContentsOfFile:fullMsnPath encoding:NSUTF8StringEncoding error:NULL];
    const char *data = [fileDecryptPath UTF8String];
    in = BIO_new_file(data, "r");
    
    p7 = SMIME_read_PKCS7(in, NULL);
    
    if(!PKCS7_type_is_enveloped(p7)){
        NSLog(@"type is not enveloped");
    }
    
    CK_BYTE dataDecrypt[4096];
    unsigned char* dataEncrypt;
    CK_ULONG dataEncryptLen;
    STACK_OF(PKCS7_RECIP_INFO) *rsk = NULL;
    PKCS7_RECIP_INFO *ri = NULL;
    int i;
    CK_ULONG dataDecryptLen;
    
    BIO *out1 = NULL, *etmp = NULL, *bio = NULL, *in_bio = NULL;
    EVP_CIPHER_CTX* evp_ctx = NULL;
    const EVP_CIPHER* evp_cipher = NULL;
    unsigned char *ek = NULL;
    int eklen = 0;
    X509_ALGOR* enc_alg = NULL;
    
    OpenSSL_add_all_algorithms();
    ERR_load_CRYPTO_strings();
    
    rsk = p7->d.enveloped->recipientinfo;
    for(i = 0; i < sk_PKCS7_RECIP_INFO_num(rsk); i++){
        ri = sk_PKCS7_RECIP_INFO_value(rsk, i);
        if(!pkcs7_cmp_ri_H(ri, certificateX509))
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
    
    if (!ri) return NULL;
    
    if (ri) {
        dataEncrypt = ri->enc_key->data;
        dataEncryptLen = ri->enc_key->length;
        enc_alg = p7->d.enveloped->enc_data->algorithm;
        evp_cipher = EVP_get_cipherbyname("DES-EDE3-CBC");
        os = p7->d.enveloped->enc_data->enc_data;
        rv = C_Decrypt(m_hSession, dataEncrypt, dataEncryptLen, dataDecrypt, &dataDecryptLen);
        if (rv) {
            rv = C_Decrypt(m_hSession, dataEncrypt, dataEncryptLen, dataDecrypt, &dataDecryptLen);
        }
        NSLog(@"C_Decrypt: %lu", rv);
        evp_ctx = NULL;
        if ((etmp = BIO_new(BIO_f_cipher())) == NULL)
        {
            NSLog(@"Fail0.0");
        }
        BIO_get_cipher_ctx(etmp,&evp_ctx);
        long getCipherCtx = etmp->method->ctrl(etmp, BIO_C_GET_CIPHER_CTX, 0, &evp_ctx);
        if(!getCipherCtx) {
            NSLog(@"Get cipher context fail");
        }
        if (EVP_CipherInit_ex(evp_ctx,evp_cipher,NULL,NULL,NULL,0) <= 0){
            NSLog(@"Fail0");
        }
        
        if (EVP_CIPHER_asn1_to_param(evp_ctx,enc_alg->parameter) < 0) {
            NSLog(@"Fail1");
        }
        
        if (ek == NULL) {
            ek = (unsigned char*)malloc(dataDecryptLen);
            ek = dataDecrypt;
            eklen = (int)dataDecryptLen;
            
        }
        if (eklen != EVP_CIPHER_CTX_key_length(evp_ctx)) {
            if(!EVP_CIPHER_CTX_set_key_length(evp_ctx, eklen)) {
                /* Use random key as MMA defence */
                OPENSSL_cleanse(ek, eklen);
                ek = NULL;
                ek = dataDecrypt;
                eklen = (int)dataDecryptLen;
            }
        }
        
        /* Clear errors so we don't leak information useful in MMA */
        ERR_clear_error();
        if (EVP_CipherInit_ex(evp_ctx,NULL,NULL,ek,NULL,0) <= 0)
            return 0;
        
        if (ek) {
            OPENSSL_cleanse(ek, eklen);
            ek = NULL;
        }
        
        if (out1 == NULL)
            out1 = etmp;
        else
            BIO_push(out1, etmp);
        etmp = NULL;
        
#if 1
        if (PKCS7_is_detached(p7) || (in_bio != NULL)) {
            bio = in_bio;
        }
        else {
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
                    i = BIO_read(out1, buf, sizeof(buf) - 1);
                    if (i <= 0)
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
    NSLog(@"Delete tmp file: %d", a);
    return temp;
}

static int pkcs7_cmp_ri_H(PKCS7_RECIP_INFO *ri, X509 *pcert)
{
	int ret;
	ret = X509_NAME_cmp(ri->issuer_and_serial->issuer,
                        pcert->cert_info->issuer);
	if (ret)
		return ret;
	return M_ASN1_INTEGER_cmp(pcert->cert_info->serialNumber,
                              ri->issuer_and_serial->serial);
}

@end
