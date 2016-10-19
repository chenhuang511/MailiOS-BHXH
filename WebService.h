//
//  WebService.h
//  iMail
//
//  Created by Tran Ha on 07/06/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebService : NSObject
- (NSString*)GetCertMail:(NSString*) email;
- (NSString*)SaveMail:(NSString *)email cert:(NSString*) cert;
@end
