//
//  CheckNetWork.m
//  ThatInbox
//
//  Created by Tran Ha on 07/04/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "CheckNetWork.h"
#import "Reachability.h"
#import <AudioToolbox/AudioToolbox.h>

@interface CheckNetWork ()

@end

@implementation CheckNetWork

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)checkNetworkAvailable {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        NSLog(@"Không có kết nối mạng");
        return NO;
    } else {
        //NSLog(@"There IS internet connection");
        return YES;
    }
}

// Âm thanh gửi mail thành công
+ (void)playSoundWhenDone: (NSString*)sound {
    SystemSoundID completeSound;
    sound = [NSString stringWithFormat:@"/System/Library/Audio/UISounds/%@", sound];
    NSURL *audioPath = [NSURL URLWithString:sound];
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)audioPath, &completeSound);
    AudioServicesPlaySystemSound (completeSound);
}

@end
