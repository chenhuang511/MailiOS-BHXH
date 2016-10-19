//
//  HardTokenMethod.h
//  iMail
//
//  Created by Tran Ha on 11/06/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cryptoki_ext.h"
#import "MBProgressHUD.h"

@interface HardTokenMethod : NSObject
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
    
    NSMutableArray *Title;
    NSMutableArray *SubTitle;
    NSMutableArray *ValidTo;
    NSMutableArray *arrayKeyContainer;
    UIPickerView *certPickerView;
    
    CK_ULONG m_MODULUS_BIT_LENGTH;
    
    UIToolbar *keyboardToolbar;
    NSString *Correct_pin;
}

- (BOOL) connect;
- (CK_RV) VerifyPIN:(char const *)pin;
- (BOOL)connect_nonAlert;
- (CK_RV) VerifyPIN_NonAlert :(char const *)pin;

- (MBProgressHUD *)showGlobalProgressHUDWithTitle:(NSString *)title;
- (void)dismissGlobalHUD;
- (void)exportCertHard:(NSInteger)index;
- (void)exportCertSoft:(NSInteger)i;

+ (NSString*)shareSerial;
+ (NSString*) sha1:(NSString*)input;
@end
