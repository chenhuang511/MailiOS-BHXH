//
//  WebService.m
//  iMail
//
//  Created by Tran Ha on 07/06/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "WebService.h"
#import "PhoneServiceSvc.h"

@implementation WebService

- (NSString*)GetCertMail:(NSString*) email {
    PhoneServicePortBinding* binding =  [PhoneServiceSvc PhoneServicePortBinding];
    PhoneServiceSvc_GetKeyMail *parms = [[PhoneServiceSvc_GetKeyMail alloc] init];
    parms.MailAddress = email;
    PhoneServicePortBindingResponse *response = [binding GetKeyMailUsingParameters:parms];
    NSString* cert = [self responseCert:response];
    return cert;
}

- (NSString*)SaveMail:(NSString *)email cert:(NSString*) cert {
    PhoneServicePortBinding* binding =  [PhoneServiceSvc PhoneServicePortBinding];
    PhoneServiceSvc_SaveMail *parms = [[PhoneServiceSvc_SaveMail alloc] init];
    parms.MailAddress = email;
    parms.PublicKey = cert;
    PhoneServicePortBindingResponse *response = [binding SaveMailUsingParameters:parms];
    NSString *sucess = [self responseSave:response];
    return sucess;
}

- (NSString*)GetCertPhone :(NSString*) phones {
    /* 
     phones = @"+84943737870#+84444444"
     */
    PhoneServicePortBinding* binding =  [PhoneServiceSvc PhoneServicePortBinding];
    PhoneServiceSvc_GetContact *parms = [[PhoneServiceSvc_GetContact alloc] init];
    parms.ListContact = phones;
    PhoneServicePortBindingResponse *response = [binding GetContactUsingParameters:parms];
    NSString* cert = [self responseCert:response];
    return cert;
    /*
     cert = @"+84943737870$ABCD#+84444$"
     */
}

- (NSString*)responsePhoneCert :(PhoneServicePortBindingResponse*)soapResponse {
    id bodyPart;
    for (bodyPart in soapResponse.bodyParts)
    {
        if ([bodyPart isKindOfClass:[PhoneServiceSvc_GetContactResponse class]])
        {
            NSNumber* jsonSax = [bodyPart return_];
            NSString *response = [NSString stringWithFormat:@"%@", jsonSax];
            return response;
        }
    }
    return nil;
}

- (NSString*)responseCert :(PhoneServicePortBindingResponse*)soapResponse {
    id bodyPart;
    for (bodyPart in soapResponse.bodyParts)
    {
        if ([bodyPart isKindOfClass:[PhoneServiceSvc_GetKeyMailResponse class]])
        {
            NSNumber* jsonSax = [bodyPart return_];
            NSString *response = [NSString stringWithFormat:@"%@", jsonSax];
            return response;
        }
    }
    return nil;
}

- (NSString*)responseSave: (PhoneServicePortBindingResponse*)soapResponse {
    id bodyPart;
    for (bodyPart in soapResponse.bodyParts)
    {
        if ([bodyPart isKindOfClass:[PhoneServiceSvc_SaveMailResponse class]])
        {
            NSNumber* jsonSax = [bodyPart return_];
            NSString *response = [NSString stringWithFormat:@"%@", jsonSax];
            return response;
        }
    }
    return nil;
}



@end
