//
//  ListCertTableViewController.m
//  iMail
//
//  Created by Tran Ha on 22/04/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "ListCertTableViewController.h"
#import "ListCertViewCell.h"
#import "MsgListViewController.h"
#include "MBProgressHUD.h"
#import "DBManager.h"
#import "TokenType.h"
#import "HardTokenMethod.h"

#import "WebService.h"
#import "MCTMsgViewController.h"
#import "VerifyMethod.h"

#define passwordHT 0

const CK_ULONG MODULUS_BIT_LENGTH_1024 = 1024;
const CK_ULONG MODULUS_BIT_LENGTH_2048 = 2048;

@interface ListCertTableViewController ()

@end

@implementation ListCertTableViewController
@synthesize delegate = _delegate;
@synthesize TokenType;

static NSArray *TitleLabel;
static NSArray *SubtitleLabel;
static NSArray *MailLabel;
static NSArray *handle;
CK_SESSION_HANDLE _sessionID;
unsigned long* handlep = new unsigned long[10];

+ (NSArray*)shareTitleLabel {
    return TitleLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title =  NSLocalizedString(@"ChooseCert", nil);
    [self.tableView registerNib:[UINib nibWithNibName:@"ListCertViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"CustomCellReuseID"];
    if ([TokenType isEqualToString:@"SoftToken"]) {
        [self listCert];
    }
    if ([TokenType isEqualToString:@"HardToken"]) {
        [self getAllCert];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [SubtitleLabel count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CustomCellReuseID";
    ListCertViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    cell.Title.text = [TitleLabel objectAtIndex:indexPath.row];
    NSString* endtime = [SubtitleLabel objectAtIndex:indexPath.row];
    cell.subTitle.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"DateExpire", nil), endtime];
    cell.subTitle.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:12];
    
    NSString* email = [MailLabel objectAtIndex:indexPath.row];
    cell.subMail.text = [NSString stringWithFormat:@"Email: %@", email];
    cell.subMail.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:12];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Chọn chứng thư %d", indexPath.row);
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MCTMsgViewController *getbase64 = [[MCTMsgViewController alloc]init];
    
    if ([TokenType isEqualToString:@"SoftToken"]) {
        int handle_int = [[handle objectAtIndex:indexPath.row]intValue];
        long subject = handlep[handle_int];
        
        CK_SLOT_ID flags = CKF_SERIAL_SESSION;
        _sessionID = -1;
        CK_VOID_PTR p = NULL;
        int slotID = 0;
        C_OpenSession_s(slotID, flags, p, NULL, &_sessionID);
        
        long PriHandleKey = [self findPrivateKey:subject];
        if (PriHandleKey == 0) {
            UIAlertView *fail = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil) message:NSLocalizedString(@"KeyPair", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Back", nil) otherButtonTitles:nil];
            [fail show];
        }
        else {
            
            // Kiểm tra chứng thư
            HardTokenMethod *hud = [[HardTokenMethod alloc]init];
            [hud showGlobalProgressHUDWithTitle:NSLocalizedString(@"VerifyCert", nil)];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    int result = [VerifyMethod selfverifybyCertHandle:subject byTokenType:SOFTTOKEN];
                    if (result) {
                        return;
                    }
                    // Save database
                    NSString *username = nil;
                    NSInteger accIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"] integerValue];
                    NSMutableArray *listAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
                    if (listAccount.count > 0 && accIndex < listAccount.count) {
                        username = [listAccount objectAtIndex:accIndex + 1];
                    }
                    
                    NSArray *tokenTypeInfo = [[DBManager getSharedInstance]findTokenTypeByEmail:username];
                    if (!tokenTypeInfo) {
                        [[DBManager getSharedInstance]saveTokenType_byEmail:username tokenType:SOFTTOKEN pubkey:subject prikey:PriHandleKey serial:@"SID"];
                    } else {
                        [[DBManager getSharedInstance]updateTokenType_byEmai:username tokenType:SOFTTOKEN pubkey:subject prikey:PriHandleKey serial:@"SID"];
                    }
                    
                    // Webservice Soft Token
                    HardTokenMethod *exportCert = [[HardTokenMethod alloc]init];
                    [exportCert exportCertSoft:handle_int];
                    NSString *r_mail = [listAccount objectAtIndex:accIndex + 1];
                    NSString *base64 = [getbase64 getBase64];
                    WebService *saveMail = [[WebService alloc]init];
                    NSString *sucess = [saveMail SaveMail:username cert:base64];
                    NSLog(@"Webservice update = %@", sucess);
                });

                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud dismissGlobalHUD];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"closePopOver" object:nil];
                });
            });
        }
    }
    
    if ([TokenType isEqualToString:@"HardToken"]) {
        
        CK_OBJECT_CLASS dataClass = CKO_PRIVATE_KEY;
        CK_ULONG ulRetCount = 0;
        int numObj = 0;
        CK_OBJECT_HANDLE hCKObj;
        CK_RV ckrv = 0;
        BOOL IsToken = true;
        
        CK_ATTRIBUTE_H pTempl[] =
        {
            {CKA_CLASS, &dataClass, sizeof(dataClass)},
            {CKA_TOKEN, &IsToken, sizeof(true)}
        };
        
        ckrv = C_FindObjectsInit(m_hSession, pTempl, 2);
        do
        {
            ckrv = C_FindObjects(m_hSession, &hCKObj, 1, &ulRetCount);
            if (ckrv != CKR_OK)
            {
                break;
            }
            
            if (1 != ulRetCount)
            {
                break;
            }
            
            CK_ATTRIBUTE_H pAttrTemp[] =
            {
                {CKA_CLASS, NULL, 0},
                {CKA_KEY_TYPE,NULL,0},
                {CKA_LABEL, NULL, 0},
                {CKA_MODULUS,NULL,0},
                {CKA_ID,NULL,0}
            };
            
            ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 5);
            if (ckrv != CKR_OK) {
                break;
            }
            
            pAttrTemp[0].pValue = new char[pAttrTemp[0].ulValueLen];
            pAttrTemp[1].pValue = new char[pAttrTemp[1].ulValueLen];
            pAttrTemp[2].pValue = new char[pAttrTemp[2].ulValueLen];
            pAttrTemp[3].pValue = new char[pAttrTemp[3].ulValueLen];
            pAttrTemp[4].pValue = new char[pAttrTemp[4].ulValueLen];
            
            memset(pAttrTemp[0].pValue,0 ,pAttrTemp[0].ulValueLen);
            memset(pAttrTemp[1].pValue,0 ,pAttrTemp[1].ulValueLen);
            memset(pAttrTemp[2].pValue,0 ,pAttrTemp[2].ulValueLen);
            memset(pAttrTemp[3].pValue,0 ,pAttrTemp[3].ulValueLen);
            memset(pAttrTemp[4].pValue,0 ,pAttrTemp[4].ulValueLen);
            
            ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 5);
            if (ckrv != CKR_OK){
                delete[] pAttrTemp[0].pValue;
                delete[] pAttrTemp[1].pValue;
                delete[] pAttrTemp[2].pValue;
                delete[] pAttrTemp[3].pValue;
                delete[] pAttrTemp[4].pValue;
            }
            numObj++;
            NSData *poutdata;
            poutdata = [[NSData alloc] initWithBytes:pAttrTemp[4].pValue length:pAttrTemp[4].ulValueLen];
            NSString *outString = [[NSString alloc] initWithData:poutdata encoding:NSASCIIStringEncoding];
            KeyContainer = [arrayKeyContainer objectAtIndex:indexPath.row];
            if ([KeyContainer isEqualToString:outString])
            {
                CK_ULONG ulModulusLen = pAttrTemp[3].ulValueLen;
                CK_ULONG ulObjNum = 0;
                CK_OBJECT_CLASS ulClass = CKO_PRIVATE_KEY;
                CK_BBOOL blTrue = TRUE;
                CK_ATTRIBUTE_H findPriKey[]  =
                {
                    {CKA_CLASS, &ulClass, sizeof(ulClass)},
                    {CKA_TOKEN, &blTrue, sizeof(blTrue)},
                    {CKA_MODULUS, pAttrTemp[3].pValue, ulModulusLen},
                };
                m_MODULUS_BIT_LENGTH = 1024;
                
                ckrv = C_FindObjectsInit(m_hSession, findPriKey, 3);
                if(ckrv != CKR_OK){
                    break;
                }
                
                ckrv = C_FindObjects(m_hSession, &hCKObj, 1, &ulObjNum);
                if(ckrv != CKR_OK)
                {
                    break;
                }
                if(ulObjNum < 1){
                    break;
                }
                m_hPriKey = hCKObj;
                break;
            }
            delete[] pAttrTemp[0].pValue;
            delete[] pAttrTemp[1].pValue;
            delete[] pAttrTemp[2].pValue;
            delete[] pAttrTemp[3].pValue;
            delete[] pAttrTemp[4].pValue;
        } while(TRUE);
        
        ckrv = C_FindObjectsFinal(m_hSession);
        if (m_hPriKey < 1) {
            NSLog(@"Key Not Found");
            return;
        }
        
        HardTokenMethod *hud = [[HardTokenMethod alloc]init];
        [hud showGlobalProgressHUDWithTitle:NSLocalizedString(@"VerifyCert", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                
                // Kiểm tra chứng thư
                NSString* handleCert = [handle objectAtIndex:indexPath.row];
                int result = [VerifyMethod selfverifybyCertHandle:handleCert.intValue byTokenType:HARDTOKEN];
                if (result) {
                    return;
                }
                // Save database
                NSString *username = nil;
                NSInteger accIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"] integerValue];
                NSMutableArray *listAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
                if (listAccount.count > 0 && accIndex < listAccount.count) {
                    username = [listAccount objectAtIndex:accIndex+1];
                }
                NSArray *tokenTypeInfo = [[DBManager getSharedInstance]findTokenTypeByEmail:username];
                NSString* serial = [HardTokenMethod shareSerial];
                if (!tokenTypeInfo) {
                    [[DBManager getSharedInstance]saveTokenType_byEmail:username tokenType:HARDPROTECT pubkey:handleCert.intValue prikey:m_hPriKey serial:serial];
                } else {
                    [[DBManager getSharedInstance]updateTokenType_byEmai:username tokenType:HARDPROTECT pubkey:handleCert.intValue prikey:m_hPriKey serial:serial];
                }
                
                /* Webservice Cert Hard */
                HardTokenMethod *exportCert = [[HardTokenMethod alloc]init];
                [exportCert exportCertHard:indexPath.row];
                NSString *r_mail = [listAccount objectAtIndex:accIndex+1];
                NSString *base64 = [getbase64 getBase64];
                WebService *saveMail = [[WebService alloc]init];
                NSString *sucess = [saveMail SaveMail:username cert:base64];
                NSLog(@"Webservice update = %@", sucess);
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud dismissGlobalHUD];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"closePopOver" object:nil];
            });
        });
    }
}

- (void)listCert {
    
    NSMutableArray *Title = [NSMutableArray array];
    NSMutableArray *SubTitle = [NSMutableArray array];
    NSMutableArray *MailTitle = [NSMutableArray array];
    NSMutableArray *handle_mutable = [NSMutableArray array];
    
    NSLog(@"Quét thông tin chứng thư...!");
    
    // Step 0: Open Session
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    CK_SESSION_HANDLE _sessionID = -1;
    CK_VOID_PTR p = NULL;
    int slotID = 0;
    int rv = C_OpenSession_s(slotID, flags, p, NULL, &_sessionID);
    assert(rv == 0);
    
    // Step 1: Make a ck_attribute
    const char* key = "CERT";
    CK_ATTRIBUTE_PTR keyAttrs = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs->type = CKA_LABEL;
    keyAttrs->pValue = (void*)key;
    
    // Step 2: Find cert
    C_FindObjectsInit_s(_sessionID, keyAttrs, sizeof(keyAttrs)/sizeof(CK_ATTRIBUTE));
    
    // Step 3:  Get the first object handle of key
    unsigned long* handle_countp = new unsigned long[20];
    unsigned long MAX_OBJECT = 10;
    rv = C_FindObjects_s(_sessionID, handlep, MAX_OBJECT, handle_countp);
    assert(rv == 0);
    
    for (int i = 0; i < *handle_countp; i++){
        NSDictionary *dict = [self findcert:_sessionID :handlep[i]];
        if (dict) {
            NSNumber* xWrapped = [NSNumber numberWithInt:i];
            [handle_mutable addObject:xWrapped];
            
            NSString *subject  = [dict objectForKey:@"subjectname"];
            NSString *endtime = [dict objectForKey:@"endtime"];
            NSString *email = [dict objectForKey:@"email"];
            [Title  addObject:subject];
            [SubTitle  addObject:endtime];
            [MailTitle addObject:email];
        }
        handle = [NSArray arrayWithArray:handle_mutable];
        TitleLabel = [NSArray arrayWithArray:Title];
        SubtitleLabel =[NSArray arrayWithArray:SubTitle];
        MailLabel = [NSArray arrayWithArray:MailTitle];
    }
}

- (NSDictionary *)findcert:(int)sessionID :(int)handle {
    NSDictionary *dict = 0;
    
    // Step 1:
    int rv = -1;
    CK_ATTRIBUTE_PTR keyAttrs1 = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs1[0].type = CKA_VALUE;
    keyAttrs1[0].pValue = (CK_VOID_PTR) malloc(2048 * sizeof(CK_CHAR));
    keyAttrs1[0].ulValueLen = 2048 * sizeof(CK_CHAR);
    
    // Step 2: Build cert
    rv = C_GetAttributeValue_s(sessionID, handle, keyAttrs1, 1);
    if(rv != CKR_OK) {
        return 0;
    }
    else {
        
        // Step 3: Lay gia tri chung thu
        //CK_ATTRIBUTE valueCert = (CK_ATTRIBUTE) keyAttrs1[0];
        void* temp = keyAttrs1->pValue;
        char* certByte = (char*) (temp);
        int len = keyAttrs1->ulValueLen;
        
        //Step 4: Ghi ra file - tam thoi la dung cach nay
        std::string filePath = getenv("HOME");
        filePath += "/tmp/test.cer";
        std::ofstream outFile(filePath,std::ofstream::binary);
        outFile.write(certByte, len);
        outFile.close();
        
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.cer"];
        NSData *certificateData = [[NSFileManager defaultManager] contentsAtPath:path];
        const unsigned char *certificateDataBytes = (const unsigned char *)[certificateData bytes];
        X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certificateData length]);
        
        Botan::X509_Certificate x509Cert(filePath);
        std::string startTime = x509Cert.start_time();
        std::string endTime = x509Cert.end_time();
        std::vector<std::string> subject = x509Cert.subject_info("X509.Certificate.serial");
        std::string serialNo = subject[0];
        std::string subjectName = x509Cert.subject_dn().get_attribute("Name")[0];
        std::string issuerName = x509Cert.issuer_dn().get_attribute("Name")[0];
        free(keyAttrs1);
        //free(keyAttrs1[0].pValue);
        
        std::vector<std::string> pubkey = x509Cert.subject_info("X509.Certificate.public_key");
        std::string publick = pubkey[0];
        NSString* publickey = [NSString stringWithUTF8String:publick.c_str()];
        
        NSString* subjectname = [self CertificateGetSubjectName: certificateX509];
        NSString* email = [self CertificateGetAltName:certificateX509];
        NSString* issuer = [NSString stringWithUTF8String:issuerName.c_str()];
        NSString* serialno = [NSString stringWithUTF8String:serialNo.c_str()];
        NSString* starttime = [NSString stringWithUTF8String:startTime.c_str()];
        NSString* endtime = [NSString stringWithUTF8String:endTime.c_str()];
        
        endtime = [self stringTodate:endtime];
        
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                subjectname, @"subjectname",
                issuer, @"issuer",
                serialno, @"serialno",
                starttime, @"starttime",
                endtime, @"endtime",
                publickey, @"publickey",
                email, @"email",
                nil];
        [self deleteTestFile];
        return dict;
    }
}

#pragma mark - Delete Temp File after Web Services Processing Done
- (void)deleteTestFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDicrectory = [NSHomeDirectory()
                               stringByAppendingPathComponent:@"tmp"];
    NSString *testcer = [tmpDicrectory
                         stringByAppendingPathComponent:@"test.cer"];
    NSError *error;
    [fileManager removeItemAtPath:testcer error:&error];
}

- (long)findPrivateKey: (long) certHandle {
    // opensession
    CK_RV rv;
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    CK_SESSION_HANDLE sessionID = -1;
    CK_VOID_PTR p = NULL;
    int slotID = 0;
    rv = C_OpenSession_s(slotID, flags, p, NULL, &sessionID);
    
    // get id of certificate
    CK_ATTRIBUTE_PTR keyAttrs = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs->type = CKA_ID;
    keyAttrs->pValue = NULL_PTR;
    rv = C_GetAttributeValue_s(sessionID, certHandle, keyAttrs, 1);
    
    int len = keyAttrs->ulValueLen;
    keyAttrs->pValue = (CK_VOID_PTR) malloc(len*sizeof(CK_CHAR));
    rv = C_GetAttributeValue_s(sessionID, certHandle, keyAttrs, 1);
    
    char* cert_id;
    cert_id = (char*)keyAttrs->pValue;
    free(keyAttrs);
    
    // get key handle from cert id
    CK_ATTRIBUTE_PTR keyAttrs1 = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    char key []= {'P', 'R', 'I', 'V'};
    keyAttrs1->type = CKA_LABEL;
    keyAttrs1->pValue = (CK_CHAR*) malloc(4* sizeof(CK_CHAR));
    keyAttrs1->pValue = key;
    keyAttrs1->ulValueLen = 4;
    
    rv = C_FindObjectsInit_s(sessionID, keyAttrs1, 1);
    
    unsigned long* handlep = new unsigned long[20];
    unsigned long* handle_countp = new unsigned long[20];
    unsigned long MAX_OBJECT = 10;
    rv = C_FindObjects_s(sessionID, handlep, MAX_OBJECT, handle_countp);
    
    assert(rv == 0);
    free(keyAttrs1);
    
    CK_ATTRIBUTE_PTR keyAttrs2 = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs2->type = CKA_ID;
    keyAttrs2->pValue = NULL_PTR;
    
    rv = C_GetAttributeValue_s(sessionID, handlep[0], keyAttrs2, 1);
    
    int len2 = keyAttrs2->ulValueLen;
    keyAttrs2->pValue = (CK_CHAR*) malloc(len2*sizeof(CK_CHAR));
    
    long re = 0;
    
    for(int i = 0; i < *handle_countp; i++) {
        rv = C_GetAttributeValue_s(sessionID, handlep[i], keyAttrs2, 1);
        char* key_id = (char*)keyAttrs2->pValue;
        if(strcmp(key_id,cert_id) == 0) {
            re = handlep[i];
        }
    }
    free(keyAttrs2);
    NSLog(@"return: %ld", re);
    rv = C_CloseSession_s(sessionID);
    return re;
}

- (NSString *)stringTodate: (NSString*)date {
    NSRange start = [date rangeOfString:@" "];
    if (start.location != NSNotFound) {
        date = [date substringToIndex:start.location];
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"y/M/d"];
    NSDate *yourDate = [dateFormatter dateFromString:date];
    [dateFormatter setDateFormat:@"d/MM/yyyy"];
    date = [dateFormatter stringFromDate:yourDate];
    return date;
}

/* HardToken */
- (void)getAllCert {
    
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"TokenSession"];
    m_hSession = [session longLongValue];
    
    NSMutableArray *ValidTo = [[NSMutableArray alloc] init];
    NSMutableArray *Title = [[NSMutableArray alloc] init];
    NSMutableArray *MailTitle = [[NSMutableArray alloc] init];
    NSMutableArray *CertHandle = [[NSMutableArray alloc]init];
    
    arrayCertData = [[NSMutableArray alloc] init];
    arrayKeyContainer = [[NSMutableArray alloc] init];
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
        if (CKR_OK != ckrv)
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
            {CKA_ID ,NULL, 0}
        };
        
        ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 8);
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
        
        memset(pAttrTemp[0].pValue,0 ,pAttrTemp[0].ulValueLen);
        memset(pAttrTemp[1].pValue,0 ,pAttrTemp[1].ulValueLen);
        memset(pAttrTemp[2].pValue,0 ,pAttrTemp[2].ulValueLen+1);
        memset(pAttrTemp[3].pValue,0 ,pAttrTemp[3].ulValueLen+1);
        memset(pAttrTemp[4].pValue,0 ,pAttrTemp[4].ulValueLen+1);
        memset(pAttrTemp[5].pValue,0 ,pAttrTemp[5].ulValueLen);
        memset(pAttrTemp[6].pValue,0 ,pAttrTemp[6].ulValueLen);
        memset(pAttrTemp[7].pValue,0 ,pAttrTemp[7].ulValueLen);
        
        ckrv = C_GetAttributeValue(m_hSession, hCKObj, pAttrTemp, 8);
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
            break;
        }
        
        numObj++;
        
        // Cert data
        NSData * mData = [[NSData alloc] initWithBytes:pAttrTemp[5].pValue length:pAttrTemp[5].ulValueLen];
        certData = mData;
        
        // Key Container
        mData = [[NSData alloc] initWithBytes:pAttrTemp[7].pValue length:pAttrTemp[7].ulValueLen];
        NSString *cka_keyContainer = [[NSString alloc] initWithData:mData encoding:NSASCIIStringEncoding];
        [arrayKeyContainer addObject:cka_keyContainer];
        
        // Cert Handle
        [CertHandle addObject:[NSString stringWithFormat:@"%ld", hCKObj]];
        
        // X509 Certificate
        const unsigned char *certificateDataBytes = (const unsigned char *)[certData bytes];
        X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [certData length]);
        ASN1_INTEGER *serial = X509_get_serialNumber(certificateX509);
        BIGNUM *bnser = ASN1_INTEGER_to_BN(serial, NULL);
        int n = BN_num_bytes(bnser);
        unsigned char outbuf[n];
        BN_bn2bin(bnser, outbuf);
        
        // Subject, end date, email
        NSString *cka_label = [self CertificateGetSubjectName:certificateX509];
        [Title addObject:cka_label];
        NSString *cka_endDate = [NSDateFormatter localizedStringFromDate:[self CertificateGetExpiryDate:certificateX509]
                                                               dateStyle:NSDateFormatterShortStyle
                                                               timeStyle:NSDateFormatterNoStyle];
        
        [ValidTo addObject:cka_endDate];
        NSString *email = [self CertificateGetAltName:certificateX509];
        [MailTitle addObject:email];
        
        delete[] pAttrTemp[0].pValue;
        delete[] pAttrTemp[1].pValue;
        delete[] pAttrTemp[2].pValue;
        delete[] pAttrTemp[3].pValue;
        delete[] pAttrTemp[4].pValue;
        delete[] pAttrTemp[5].pValue;
        delete[] pAttrTemp[6].pValue;
        
    } while (true);
    
    C_FindObjectsFinal(m_hSession);
    
    TitleLabel = [NSArray arrayWithArray:Title];
    SubtitleLabel = [NSArray arrayWithArray:ValidTo];
    MailLabel = [NSArray arrayWithArray:MailTitle];
    handle = [NSArray arrayWithArray:CertHandle];
}

// Ngày hết hạn
- (NSDate *)CertificateGetExpiryDate:(X509 *)certificateX509 {
    NSDate *expiryDate = nil;
    if (certificateX509 != NULL) {
        ASN1_TIME *certificateExpiryASN1 = X509_get_notAfter(certificateX509);
        if (certificateExpiryASN1 != NULL) {
            ASN1_GENERALIZEDTIME *certificateExpiryASN1Generalized = ASN1_TIME_to_generalizedtime(certificateExpiryASN1, NULL);
            if (certificateExpiryASN1Generalized != NULL) {
                unsigned char *certificateExpiryData = ASN1_STRING_data(certificateExpiryASN1Generalized);
                
                NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
                NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];
                expiryDateComponents.year   = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
                expiryDateComponents.month  = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
                expiryDateComponents.day    = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
                NSCalendar *calendar = [NSCalendar currentCalendar];
                expiryDate = [calendar dateFromComponents:expiryDateComponents];
            }
        }
    }
    return expiryDate;
}

// Chủ chứng thư
- (NSString *)CertificateGetSubjectName: (X509 *)certificateX509 {
    NSString *issuer = nil;
    if (certificateX509 != NULL) {
        X509_NAME *issuerX509Name = X509_get_subject_name(certificateX509);
        
        if (issuerX509Name != NULL) {
            int nid = OBJ_txt2nid("CN"); // organization
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

// Email
- (NSString*)CertificateGetAltName: (X509 *)certificateX509 {
    GENERAL_NAMES *sANs;
    void *ext = X509_get_ext_d2i(certificateX509, NID_subject_alt_name, 0, 0);
    if (!(sANs = (GENERAL_NAMES*)ext)) {
        NSLog(@"No subjectAltName extension" );
        return @"Không tồn tại";
    }
    
    int i, numAN = sk_GENERAL_NAME_num(sANs);
    for (i = 0; i < numAN; ++i) {
        GENERAL_NAME *sAN = sk_GENERAL_NAME_value(sANs, i) ;
        if (GEN_EMAIL == sAN->type) {
            unsigned char *mail;
            ASN1_STRING_to_UTF8 (&mail, sAN->d.rfc822Name);
            //usigned char to nsstring
            NSString *email = [NSString stringWithUTF8String:(char *)mail];
            return email;
        }
    }
    return @"Không tồn tại";
}

// kiem tra email index co trung voi email token.
-(int)checkEmailHandel {
    
    NSString* libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* path = [libraryPath stringByAppendingPathComponent:@"data.db"];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!fileExists) {
        return -1;
    }
    
    NSMutableArray *Title = [NSMutableArray array];
    NSMutableArray *SubTitle = [NSMutableArray array];
    NSMutableArray *MailTitle = [NSMutableArray array];
    NSMutableArray *handle_mutable = [NSMutableArray array];
    
    NSLog(@"Quét thông tin chứng thư... !");
    
    // Step 0: Open Session
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    CK_SESSION_HANDLE _sessionID = -1;
    CK_VOID_PTR p = NULL;
    int slotID = 0;
    int rv = C_OpenSession_s(slotID, flags, p, NULL, &_sessionID);
    assert(rv == 0);
    
    // Step 1: Make a ck_attribute
    const char* key = "CERT";
    CK_ATTRIBUTE_PTR keyAttrs = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    keyAttrs->type = CKA_LABEL;
    keyAttrs->pValue = (void*)key;
    
    // Step 2: Find cert
    C_FindObjectsInit_s(_sessionID, keyAttrs, sizeof(keyAttrs)/sizeof(CK_ATTRIBUTE));
    
    // Step 3:  Get the first object handle of key
    unsigned long* handle_countp = new unsigned long[20];
    unsigned long MAX_OBJECT = 10;
    rv = C_FindObjects_s(_sessionID, handlep, MAX_OBJECT, handle_countp);
    assert(rv == 0);
    
    for (int i = 0; i < *handle_countp; i++){
        NSDictionary *dict = [self findcert:_sessionID :handlep[i]];
        if (dict) {
            NSNumber* xWrapped = [NSNumber numberWithInt:i];
            [handle_mutable addObject:xWrapped];
            
            NSString *subject  = [dict objectForKey:@"subjectname"];
            NSString *endtime = [dict objectForKey:@"endtime"];
            NSString *email = [dict objectForKey:@"email"];
            [Title  addObject:subject];
            [SubTitle  addObject:endtime];
            [MailTitle addObject:email];
        }
    }
    
    //Get email index.
    NSString *accIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"];
    NSMutableArray *listAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
    NSInteger mailtype;
    NSString *username;
    if (accIndex != nil) {
        mailtype = [[[NSUserDefaults standardUserDefaults]objectForKey:@"mailtype"] integerValue];
        username = [listAccount objectAtIndex:([accIndex intValue] + 1)];
    }
    int handel = 0;
    int dem = 0;
    for (int i = 0; i < MailTitle.count; i++) {
        if ([username isEqualToString:[MailTitle objectAtIndex:i]]) {
            dem++;
            if (dem == 1) {
                handel = [[handle_mutable objectAtIndex:i]intValue]+1;
            } else {
                return 0;
            }
        }
    }
    return handel;
}

// Tu dong luu chung thu neu trung email.
-(void)selectCertificateDefault:(int) handel {
    MCTMsgViewController *getbase64 = [[MCTMsgViewController alloc]init];
    int handle_int = handel-1;
    long subject = handlep[handle_int];
    
    CK_SLOT_ID flags = CKF_SERIAL_SESSION;
    _sessionID = -1;
    CK_VOID_PTR p = NULL;
    int slotID = 0;
    C_OpenSession_s(slotID, flags, p, NULL, &_sessionID);
    
    long PriHandleKey = [self findPrivateKey:subject];
    if (PriHandleKey == 0) {
        UIAlertView *fail = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notifi", nil) message:NSLocalizedString(@"KeyPair", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"Back", nil) otherButtonTitles:nil];
        [fail show];
    }
    else {
        
        // Kiểm tra chứng thư
        NSLog(@"VerifyCert");
        HardTokenMethod *hud = [[HardTokenMethod alloc]init];
        [hud showGlobalProgressHUDWithTitle:NSLocalizedString(@"VerifyCert", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                int result = [VerifyMethod selfverifybyCertHandle:subject byTokenType:SOFTTOKEN];
                if (result) {
                    return;
                }
                
                // Save database
                NSString *username = nil;
                NSInteger accIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"accIndex"] integerValue];
                NSMutableArray *listAccount = [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
                if (listAccount.count > 0 && accIndex < listAccount.count) {
                    username = [listAccount objectAtIndex:accIndex + 1];
                }
                NSArray *tokenTypeInfo = [[DBManager getSharedInstance]findTokenTypeByEmail:username];
                if (!tokenTypeInfo) {
                    [[DBManager getSharedInstance]saveTokenType_byEmail:username tokenType:SOFTTOKEN pubkey:subject prikey:PriHandleKey serial:@"SID"];
                } else {
                    [[DBManager getSharedInstance]updateTokenType_byEmai:username tokenType:SOFTTOKEN pubkey:subject prikey:PriHandleKey serial:@"SID"];
                }
                
                /* Webservice Soft Token*/
                HardTokenMethod *exportCert = [[HardTokenMethod alloc]init];
                [exportCert exportCertSoft:handle_int];
                NSString *r_mail = [listAccount objectAtIndex:accIndex + 1];
                NSString *base64 = [getbase64 getBase64];
                WebService *saveMail = [[WebService alloc]init];
                NSString *sucess = [saveMail SaveMail:username cert:base64];
                NSLog(@"Webservice update = %@", sucess);
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud dismissGlobalHUD];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"closePopOver" object:nil];
            });
        });
    }
}

@end
