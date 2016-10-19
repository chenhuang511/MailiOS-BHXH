//
//  INKWelcomeViewController_iPhone.m
//  ThatInbox
//
//  Created by Tran Ha on 27/03/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "INKWelcomeViewController_iPhone.h"

@interface INKWelcomeViewController_iPhone ()

@end

CGFloat const scrollViewHeight_iPhone = 320.f;
CGFloat const scrollViewMargin_iPhone = 0.f;

NSString *nsuserdefaultsHasRunFlowKeyName_iPhone = @"com.inkmobility.hasRunWelcomeFlow";

@implementation INKWelcomeViewController_iPhone
@synthesize PageView, nextViewController_iPhone;

+ (BOOL) shouldRunWelcomeFlow_iPhone {
    //You should run if not yet run
    return ![[NSUserDefaults standardUserDefaults] boolForKey:nsuserdefaultsHasRunFlowKeyName_iPhone];
}

+ (void) setShouldRunWelcomeFlow_iPhone:(BOOL)should {
    //ShouldRun is opposite of hasRun
    [[NSUserDefaults standardUserDefaults] setBool:!should forKey:nsuserdefaultsHasRunFlowKeyName_iPhone];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


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
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat scrollViewWidth = self.view.bounds.size.width;
    CGRect pageFrame = CGRectMake((self.view.bounds.size.width - scrollViewWidth), (self.view.bounds.size.height - scrollViewHeight_iPhone), scrollViewWidth, scrollViewHeight_iPhone);
    
    PageView = [PageView initWithFrame:pageFrame];
    
    NSString* appID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    NSMutableArray *views = [NSMutableArray arrayWithCapacity:4];
    NSMutableArray *images = [NSMutableArray arrayWithObjects:@"OnboardStep2_iPhone", @"OnboardStep3_iPhone", nil];
    
    if ([appID isEqualToString:@"com.inkmobility.ThatPhoto"]) {
        [images insertObject:@"WelcomeThatPhoto" atIndex:0];
    } else if ([appID isEqualToString:@"com.inkmobility.thatinbox"]) {
        [images insertObject:@"WelcomeThatInbox_iPhone" atIndex:0];
    } else if ([appID isEqualToString:@"com.inkmobility.ThatPDF"]) {
        [images insertObject:@"WelcomeThatPDF" atIndex:0];
    } else if ([appID isEqualToString:@"com.inkmobility.thatcloud"]) {
        [images insertObject:@"WelcomeThatCloud" atIndex:0];
    }
    for (NSString *imageName in images) {
        UIView *welcomeScreen = [[UIView alloc] init];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
        imageView.frame = CGRectMake(CGRectGetMidX(welcomeScreen.bounds) - CGRectGetMidX(imageView.bounds), 0, imageView.bounds.size.width, imageView.bounds.size.height);
        imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
        [welcomeScreen addSubview:imageView];
        welcomeScreen.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        [views addObject:welcomeScreen];
    }
    
    [PageView setScrollViewContents:views];
}

- (void) viewWillLayoutSubviews {
    CGFloat scrollViewWidth = self.view.bounds.size.width;
    CGRect pageFrame = CGRectMake((self.view.bounds.size.width - scrollViewWidth), (self.view.bounds.size.height - scrollViewHeight_iPhone), scrollViewWidth, scrollViewHeight_iPhone);
    [self.PageView setFrame:pageFrame];
}
- (IBAction)skipWelcome:(id)sender {
    [INKWelcomeViewController_iPhone setShouldRunWelcomeFlow_iPhone:NO];
    [[[UIApplication sharedApplication] keyWindow] setRootViewController:self.nextViewController_iPhone];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
