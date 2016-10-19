//
//  CheckNetWork.h
//  ThatInbox
//
//  Created by Tran Ha on 07/04/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckNetWork : UIViewController

- (BOOL)checkNetworkAvailable;
+ (void)playSoundWhenDone: (NSString*)sound;

@end
