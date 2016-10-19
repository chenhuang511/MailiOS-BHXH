//
//  AuthViewController.m
//  ThatInbox
//
//  Created by Andrey Yastrebov on 18.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "AuthViewController.h"
#import "UIColor+FlatUI.h"
#import "UINavigationBar+FlatUI.h"
#import "Constants.h"

@interface AuthViewController ()
- (void)hideBackButton:(BOOL)hide;
@end

@implementation AuthViewController

- (void)hideBackButton:(BOOL)hide
{
    if (hide) {
        //        self.navigationItem.leftBarButtonItem = nil;
    }
    else {
        UIBarButtonItem *bb = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleDone target:self.webView action:@selector(goBack)];
        
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor peterRiverColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor belizeHoleColor], UITextAttributeTextColor, nil] forState:UIControlStateHighlighted];
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor lightGrayColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateDisabled];
        
        //        self.navigationItem.leftBarButtonItem = bb;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
    [back addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
    UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
    [back setImage:backImage forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:back];
    self.navigationItem.leftBarButtonItem = backButton;
    
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor colorFromHexCode:barColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationItem.rightBarButtonItem = nil;
    NSString *html = [NSString stringWithFormat:@"<html><body bgcolor=silver><div align=center>%@</div></body></html>", NSLocalizedString(@"LoadingLoginPage", nil)];
    self.initialHTMLString = html;
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self hideBackButton:![webView canGoBack]];
    [super webViewDidFinishLoad:webView];
}

- (void)dismissView{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
