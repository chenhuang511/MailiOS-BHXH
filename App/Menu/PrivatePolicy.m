//
//  PrivatePolicy.m
//  iMail
//
//  Created by Tran Ha on 9/19/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "PrivatePolicy.h"
#import "FFCircularProgressView.h"

@interface PrivatePolicy ()

@end

@implementation PrivatePolicy
FFCircularProgressView *circularPV;
UIWebView *webView;
UILabel *fail;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self action:@selector(dismissWebView)forControlEvents:
     UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItem = backButton;
    
    circularPV = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 15, self.view.frame.size.height/2 - 60, 30.0, 30.0)];
    circularPV.hideProgressIcons = YES;
    [circularPV startSpinProgressBackgroundLayer];
    [self.view addSubview:circularPV];
    if (fail) {
        [fail removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissWebView {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    if(!webView.isLoading) {
        [circularPV removeFromSuperview];
    }
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [circularPV removeFromSuperview];
    fail = [[UILabel alloc ] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 100, self.view.frame.size.height/2 - 60, 200, 30.0)];
    fail.text = NSLocalizedString(@"ConnectProblem", nil);
    fail.textAlignment =  NSTextAlignmentCenter;
    fail.textColor = [UIColor grayColor];
    fail.font = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];
    fail.layer.borderWidth = 1.0f;
    fail.layer.borderColor = [[UIColor grayColor]CGColor];
    [self.view addSubview:fail];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (webView) {
        [webView removeFromSuperview];
    }
    webView = [[UIWebView alloc]initWithFrame:
               CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [webView setOpaque:NO];
    webView.delegate = self;
    webView.backgroundColor = [UIColor clearColor];
    webView.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    NSString *urlString = @"http://tokenmanager.vnpt-ca.vn:7006/uuid/policy.html";
    NSURL *nsurl = [NSURL URLWithString:urlString];
    //NSURLRequest *nsrequest = [NSURLRequest requestWithURL:nsurl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [webView loadRequest:request];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:webView];
}


@end
