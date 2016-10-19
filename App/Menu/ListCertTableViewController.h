//
//  ListCertTableViewController.h
//  iMail
//
//  Created by Tran Ha on 22/04/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "main.h"

#import "x509v3.h"
#import "bio.h"
#include "x509cert.h"

#include <string.h>
#include <fstream>

#include "hardtoken/cryptoki_linux.h"
#import "hardtoken/cryptoki_ext.h"
#include "hardtoken/pkcs11.h"

#include "cryptoki_compat/pkcs11.h"
#import "EADevice.h"
#import "DeviceAudio.h"


@class MsgListViewController;
@interface ListCertTableViewController :  UITableViewController <UITextFieldDelegate, UIAlertViewDelegate>
{
    UIAlertView *inprogress;
    CK_SLOT_ID_PTR m_pSlotList;
    CK_VOID_PTR m_pApplication;
    CK_SESSION_HANDLE m_hSession;
    CK_SESSION_HANDLE m_hSessionKH;
    
    CK_OBJECT_HANDLE m_hPubKey;
    CK_OBJECT_HANDLE m_hPriKey;
    
    UITextField *tfData,*tfSignature,*tfPassword,*tfCert;
    NSData *certData;
    NSString *certLabel;
    NSString *KeyContainer;
    
    NSMutableArray *arrayCertLabel;
    NSMutableArray *arrayCertData;
    
    NSMutableArray *arrayKeyContainer;
    UIPickerView *certPickerView;
    
    CK_ULONG m_MODULUS_BIT_LENGTH;
    
    UIToolbar *keyboardToolbar;
    NSString *Correct_pin;
}

@property(nonatomic,assign) MsgListViewController *delegate;
@property(nonatomic) NSString *TokenType;

- (NSDate *)CertificateGetExpiryDate:(X509 *)certificateX509;
- (NSString *) CertificateGetSubjectName: (X509 *)certificateX509;
- (NSString*)CertificateGetAltName: (X509 *)certificateX509;

- (NSDictionary *)findcert:(int)sessionID :(int)handle;
- (long) findPrivateKey: (long) certHandle;
- (void) getAllCert;
-(int)checkEmailHandel;
-(void)selectCertificateDefault:(int) handel;
+ (NSArray*)shareTitleLabel;

@end
