//
//  ListAllFolders.h
//  iMail
//
//  Created by Tran Ha on 1/5/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CheckValidSession.h"

@interface ListAllFolders : NSObject

+ (NSDictionary*)shareFolderNames;

- (void)findFolderName:(void (^) (BOOL success))completion;

@end
