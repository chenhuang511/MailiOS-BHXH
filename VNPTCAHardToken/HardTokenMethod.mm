//
//  HardTokenMethod.m
//  iMail
//
//  Created by Tran Ha on 11/06/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "HardTokenMethod.h"
#import "ListCertTableViewController.h"
#import "x509v3.h"
#import "bio.h"

#include <string.h>
#include <fstream>
#import "cryptoki_ext.h"
#import "EADevice.h"
#import "DeviceAudio.h"

#import "MBProgressHUD.h"
#import "VerifyMethod.h"
#include <openssl/pem.h>
#import <CommonCrypto/CommonDigest.h>

static NSString *serial_objc = nil;

@implementation HardTokenMethod

+ (NSString*)shareSerial {
    return serial_objc;
}

- (BOOL)connect {
    
    [self showGlobalProgressHUDWithTitle:NSLocalizedString(@"ConnectToToken", nil)];
    
    CK_RV rv;
    rv = C_Initialize(NULL_PTR);
    if (CKR_OK != rv && rv != CKR_CRYPTOKI_ALREADY_INITIALIZED) {
        [self dismissGlobalHUD];
        [self ShowErr:NSLocalizedString(@"ErrorToken", nil)];
        return FALSE;
    }
    
    m_pSlotList = NULL_PTR;
    m_hSession = NULL_PTR;
    CK_ULONG ulCount = 0;
    
    rv = C_GetSlotList(TRUE, NULL_PTR, &ulCount);
    if(CKR_OK != rv ) {
        [self dismissGlobalHUD];
        [self ShowErr:NSLocalizedString(@"ErrorToken", nil)];
        return FALSE;
    }
    
    if(0 >= ulCount) {
        [self dismissGlobalHUD];
        [self ShowErr:NSLocalizedString(@"ErrorToken", nil)];
        return FALSE;
    }
    
    m_pSlotList = (CK_SLOT_ID_PTR)new CK_SLOT_ID[ulCount];
    
    if (! m_pSlotList) {
        [self dismissGlobalHUD];
        [self ShowErr:NSLocalizedString(@"ErrorToken", nil)];
        return FALSE;
    }
    
    rv = C_GetSlotList(TRUE, m_pSlotList, &ulCount);
    if(CKR_OK != rv ) {
        [self dismissGlobalHUD];
        [self ShowErr:NSLocalizedString(@"ErrorToken", nil)];
        return FALSE;
    }
    if(0 >= ulCount) {
        [self dismissGlobalHUD];
        [self ShowErr:NSLocalizedString(@"ErrorToken", nil)];
        return FALSE;
    }
    
    rv = C_CloseAllSessions(m_pSlotList[0]);
    rv = C_OpenSession(m_pSlotList[0],  CKF_RW_SESSION | CKF_SERIAL_SESSION, &m_pApplication, NULL_PTR, &m_hSession);
    
    CK_TOKEN_INFO tokenInfo;
    rv = C_GetTokenInfo(m_pSlotList[0], &tokenInfo);
    unsigned char *serial = tokenInfo.serialNumber;
    serial_objc = [NSString stringWithFormat:@"%s", serial];
    
    NSString *session = [NSString stringWithFormat:@"%ld", m_hSession] ;
    [[NSUserDefaults standardUserDefaults] setObject:session forKey:@"TokenSession"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    ListCertTableViewController *getAllCert = [[ListCertTableViewController alloc]init];
    [getAllCert getAllCert];
    
    NSString *passHardToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"HardPasswrd"];
    if (passHardToken) {
        const char *pin = [passHardToken cStringUsingEncoding:NSASCIIStringEncoding];
        CK_ULONG ulPIN = strlen(pin);
        CK_BYTE_PTR pPIN = (CK_BYTE_PTR)pin;
        C_Login(m_hSession, CKU_USER, pPIN, ulPIN);
    }
    
    [self dismissGlobalHUD];
    
    if (CKR_OK != rv ) {
        [self ShowErr:NSLocalizedString(@"ErrorToken", nil)];
        [self dismissGlobalHUD];
        delete[] m_pSlotList;
        m_pSlotList = NULL_PTR;
        return FALSE;
    } else {
        return TRUE;
    }
}

- (BOOL)connect_nonAlert {
    
    [self showGlobalProgressHUDWithTitle:NSLocalizedString(@"ConnectToToken", nil)];
    
    CK_RV rv;
    rv = C_Initialize(NULL_PTR);
    if (CKR_OK != rv && rv != CKR_CRYPTOKI_ALREADY_INITIALIZED) {
        [self dismissGlobalHUD];
        NSLog (@"Lỗi kết nối Token 1");
        return FALSE;
    }
    
    m_pSlotList = NULL_PTR;
    m_hSession = NULL_PTR;
    CK_ULONG ulCount = 0;
    
    rv = C_GetSlotList(TRUE, NULL_PTR, &ulCount);
    if(CKR_OK != rv ) {
        [self dismissGlobalHUD];
        NSLog (@"Lỗi kết nối Token 2");
        return FALSE;
    }
    
    if(0 >= ulCount) {
        [self dismissGlobalHUD];
        NSLog (@"Lỗi kết nối Token 3");
        return FALSE;
    }
    
    m_pSlotList = (CK_SLOT_ID_PTR)new CK_SLOT_ID[ulCount];
    
    if (! m_pSlotList) {
        [self dismissGlobalHUD];
        NSLog (@"Lỗi kết nối Token 4");
        return FALSE;
    }
    
    rv = C_GetSlotList(TRUE, m_pSlotList, &ulCount);
    if(CKR_OK != rv ) {
        [self dismissGlobalHUD];
        NSLog (@"Lỗi kết nối Token 5");
        return FALSE;
    }
    if(0 >= ulCount) {
        [self dismissGlobalHUD];
        NSLog (@"Lỗi kết nối Token 6");
        return FALSE;
    }
    
    rv = C_OpenSession(m_pSlotList[0],  CKF_RW_SESSION | CKF_SERIAL_SESSION, &m_pApplication, NULL_PTR, &m_hSession);
    
    CK_TOKEN_INFO tokenInfo;
    rv = C_GetTokenInfo(m_pSlotList[0], &tokenInfo);
    unsigned char *serial = tokenInfo.serialNumber;
    serial_objc = [NSString stringWithFormat:@"%s", serial];
    
    NSString *session = [NSString stringWithFormat:@"%ld", m_hSession] ;
    [[NSUserDefaults standardUserDefaults] setObject:session forKey:@"TokenSession"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self dismissGlobalHUD];
    
    if(CKR_OK != rv ) {
        [self dismissGlobalHUD];
        NSLog (@"Lỗi kết nối Token 7");
        delete[] m_pSlotList;
        m_pSlotList = NULL_PTR;
        return FALSE;
    }
    else
    {
        return TRUE;
    }
}

- (CK_RV)VerifyPIN_NonAlert :(char const *)pin {
    
    [self showGlobalProgressHUDWithTitle:NSLocalizedString(@"CheckingPass", nil)];
    
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"TokenSession"];
    m_hSession = [session longLongValue];
    
    C_Logout(m_hSession);
    
    CK_RV rv = 0;
    
    if (0 == strlen(pin)) {
        [self dismissGlobalHUD];
        //[self ShowErr:@"Mật khẩu trống"];
        return -2;
    }
    
    CK_ULONG ulPIN = strlen(pin);
    CK_BYTE_PTR pPIN = (CK_BYTE_PTR)pin;
    
    rv = C_Login(m_hSession, CKU_USER, pPIN, ulPIN);
    
    if(CKR_OK != rv)
    {
        [self dismissGlobalHUD];
        if (CKR_PIN_INCORRECT == rv) {
            //[self ShowErr:@"Sai mật khẩu Token"];
        }
        else {
            //[self ShowErr:@"Không thể đăng nhập Token"];
        }
        return -3;
    }
    else {
        [self dismissGlobalHUD];
        return CKR_OK;
    }
}

- (CK_RV)VerifyPIN:(char const *)pin {
    
    [self showGlobalProgressHUDWithTitle:NSLocalizedString(@"CheckingPass", nil)];
    
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"TokenSession"];
    m_hSession = [session longLongValue];
    
    C_Logout(m_hSession);
    
    CK_RV rv = 0;
    
    if (0 == strlen(pin)) {
        [self dismissGlobalHUD];
        [self ShowErr:NSLocalizedString(@"PassisEmpty", nil)];
        return -2;
    }
    
    CK_ULONG ulPIN = strlen(pin);
    CK_BYTE_PTR pPIN = (CK_BYTE_PTR)pin;
    
    rv = C_Login(m_hSession, CKU_USER, pPIN, ulPIN);
    
    if(CKR_OK != rv)
    {
        [self dismissGlobalHUD];
        if (CKR_PIN_INCORRECT == rv) {
            [self ShowErr:NSLocalizedString(@"TokenPassWrong", nil)];
        }
        else {
            [self ShowErr:NSLocalizedString(@"CantLogin", nil)];
        }
        return -3;
    }
    else {
//        Correct_pin = [[NSString alloc] initWithFormat:@"%s", pin];
//        [[NSUserDefaults standardUserDefaults] setObject:Correct_pin forKey:@"HardPasswrd"];
//        [[NSUserDefaults standardUserDefaults] synchronize];
        [self dismissGlobalHUD];
        return CKR_OK;
    }
}

- (void)ShowMsg: (NSString*) msg {
    UIAlertView *alertViewMsg = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil)
                                                           message:msg
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                 otherButtonTitles:nil];
    [alertViewMsg show];
}

- (void)ShowErr: (NSString*) msg {
    UIAlertView *alertViewErr = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                           message: msg
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                 otherButtonTitles:nil];
    [alertViewErr show];
}

- (MBProgressHUD *)showGlobalProgressHUDWithTitle:(NSString *)title {
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    hud.userInteractionEnabled = YES;
    hud.labelText = title;
    return hud;
}

- (void)dismissGlobalHUD {
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    [MBProgressHUD hideHUDForView:window animated:YES];
}

+ (NSString*)sha1:(NSString*)input {
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

- (void)exportCertSoft:(NSInteger)i {
    
    // Step 0: Open Session
    
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    CK_SESSION_HANDLE sessionID = -1;
    CK_VOID_PTR p = NULL;
    int slotID = 0;
    int rv = C_OpenSession_s(slotID, flags, p, NULL, &sessionID);
    
    // Step 1: Make a ck_attribute
    const char* key = "CERT";
    CK_ATTRIBUTE_PTR keyAttrs = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs->type = CKA_LABEL;
    keyAttrs->pValue = (void*)key;
    // Step 2: Find cert
    rv = C_FindObjectsInit_s(sessionID, keyAttrs, sizeof(keyAttrs)/sizeof(CK_ATTRIBUTE));
    
    // Step 3:  Get the first object handle of key
    unsigned long* handlep = new unsigned long[10];
    unsigned long* handle_countp = new unsigned long[20];
    unsigned long MAX_OBJECT = 10;
    rv = C_FindObjects_s(sessionID, handlep, MAX_OBJECT, handle_countp);
    //assert(rv == 0);
    
    // Step 4:
    CK_ATTRIBUTE_PTR keyAttrs1 = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs1[0].type = CKA_VALUE;
    keyAttrs1[0].pValue = (CK_VOID_PTR) malloc(2048 * sizeof(CK_CHAR));
    keyAttrs1[0].ulValueLen = 2048 * sizeof(CK_CHAR);
    // Step 5: Build cert
    rv = C_GetAttributeValue_s(sessionID, handlep[i], keyAttrs1, 1);
    // assert(rv == 0);
    if (rv == CKR_OK) {
        // Step 6: Lay gia tri chung thu
        //CK_ATTRIBUTE valueCert = (CK_ATTRIBUTE) keyAttrs1[0];
        
        void* temp = keyAttrs1->pValue;
        char* certByte = (char*) (temp);
        int len = keyAttrs1->ulValueLen;
        //Step 7: Ghi ra file
        std::string filePath = getenv("HOME");
        filePath += "/tmp/test.cer";
        std::ofstream outFile(filePath, std::ofstream::binary);
        outFile.write(certByte, len);
        outFile.close();
        NSString *src = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.cer"];
        certData = [[NSFileManager defaultManager] contentsAtPath:src];
        const unsigned char *certificateDataBytes = (const unsigned char *)[certData bytes];
        X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certData length]);
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *libraDirectory = [paths objectAtIndex:0];
        NSString *dest = [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];
        BIO* out = BIO_new_file([dest UTF8String], "w");
        PEM_write_bio_X509(out, certificateX509);
        BIO_free(out);
    }
}


- (void)exportCertHard:(NSInteger)index {
    
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"TokenSession"];
    CK_SESSION_HANDLE m_hSession = [session longLongValue];
    
    NSMutableArray *arrayCertData = [[NSMutableArray alloc] init];
    NSMutableArray *arrayKeyContainer = [[NSMutableArray alloc] init];
    int i = 0;
    
    CK_OBJECT_CLASS dataClass = CKO_CERTIFICATE;
    BOOL IsToken = true;
    CK_ATTRIBUTE_H pTempl[] =
    {
        {CKA_CLASS, &dataClass, sizeof(dataClass)},
        {CKA_TOKEN, &IsToken, sizeof(true)}
    };
    
    C_FindObjectsInit(m_hSession, pTempl, 2);
    
    CK_OBJECT_HANDLE hCKObj;
    CK_ULONG ulRetCount = 0;
    CK_RV ckrv = 0;
    int numObj = 0;//object numbers
    do
    {
        ckrv = C_FindObjects(m_hSession, &hCKObj, 1, &ulRetCount);
        if(CKR_OK != ckrv)
        {
            break;
        }
        if(1 != ulRetCount)
            break;
        
        CK_ATTRIBUTE_H pAttrTemp[] =
        {
            {CKA_CLASS, NULL, 0},
            {CKA_CERTIFICATE_TYPE,NULL,0},
            {CKA_LABEL, NULL, 0},
            {CKA_SUBJECT,NULL,0},
            {CKA_ID,NULL,0},
            {CKA_VALUE,NULL,0},
            {CKA_SERIAL_NUMBER, NULL, 0},
            {CKA_CONTAINER_NAME ,NULL, 0},
            {CKA_START_DATE, NULL, 0}
        };
        
        ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 9);
        if(ckrv != CKR_OK)
        {
            break;
        }
        
        pAttrTemp[0].pValue = new char[pAttrTemp[0].ulValueLen];
        pAttrTemp[1].pValue = new char[pAttrTemp[1].ulValueLen];
        pAttrTemp[2].pValue = new char[pAttrTemp[2].ulValueLen+1];
        pAttrTemp[3].pValue = new char[pAttrTemp[3].ulValueLen+1];
        pAttrTemp[4].pValue = new char[pAttrTemp[4].ulValueLen+1];
        pAttrTemp[5].pValue = new char[pAttrTemp[5].ulValueLen ];
        pAttrTemp[6].pValue = new char[pAttrTemp[6].ulValueLen ];
        pAttrTemp[7].pValue = new char[pAttrTemp[7].ulValueLen ];
        pAttrTemp[8].pValue = new char[1024];
        
        memset(pAttrTemp[0].pValue,0 ,pAttrTemp[0].ulValueLen);
        memset(pAttrTemp[1].pValue,0 ,pAttrTemp[1].ulValueLen);
        memset(pAttrTemp[2].pValue,0 ,pAttrTemp[2].ulValueLen+1);
        memset(pAttrTemp[3].pValue,0 ,pAttrTemp[3].ulValueLen+1);
        memset(pAttrTemp[4].pValue,0 ,pAttrTemp[4].ulValueLen+1);
        memset(pAttrTemp[5].pValue,0 ,pAttrTemp[5].ulValueLen);
        memset(pAttrTemp[6].pValue,0 ,pAttrTemp[6].ulValueLen);
        memset(pAttrTemp[7].pValue,0 ,pAttrTemp[7].ulValueLen);
        memset(pAttrTemp[8].pValue,0 ,1024);
        
        ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 9);
        
        if(ckrv != CKR_OK)
        {
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
        
        NSData *mData = [[NSData alloc] initWithBytes:pAttrTemp[2].pValue length:pAttrTemp[2].ulValueLen];
        mData = [[NSData alloc] initWithBytes:pAttrTemp[5].pValue length:pAttrTemp[5].ulValueLen];
        [arrayCertData addObject:mData];
        NSData *certData = mData;
        
        mData = [[NSData alloc] initWithBytes:pAttrTemp[7].pValue length:pAttrTemp[7].ulValueLen];
        NSString *cka_keyContainer = [[NSString alloc] initWithData:mData encoding:NSASCIIStringEncoding];
        [arrayKeyContainer addObject:cka_keyContainer];
        
        const unsigned char *certificateDataBytes = (const unsigned char *)[certData bytes];
        X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certData length]);
        
        //Save cert?
        i++;
        if (index == i - 1) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *libraDirectory = [paths objectAtIndex:0];
            NSString *dest = [NSTemporaryDirectory() stringByAppendingPathComponent:@"smout.pem"];
            BIO* out = BIO_new_file([dest UTF8String], "w");
            PEM_write_bio_X509(out, certificateX509);
            BIO_free(out);
            
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
    } while(true);
}

@end
