//
//  PreviewViewController.m
//  VNPTCA Mail
//
//  Created by HungNP on 6/24/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "PreviewViewController.h"
#import "UIColor+FlatUI.h"
@interface PreviewViewController ()

@end

@implementation PreviewViewController

- (id)initWithPreview:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
                title:(NSString *)title
                 data:(NSData *)data
             mimeType:(NSString *)mimeType {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
  }
  self.data = data;
  self.title = title;
  self.mimeType = mimeType;
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
  [back setFrame:CGRectMake(0.0f, 0.0f, 22.0f, 22.0f)];
  [back addTarget:self
                action:@selector(backtoType:)
      forControlEvents:UIControlEventTouchUpInside];
  UIImage *backImage = [UIImage imageNamed:@"bt_back.png"];
  [back setImage:backImage forState:UIControlStateNormal];
  UIBarButtonItem *backButton =
      [[UIBarButtonItem alloc] initWithCustomView:back];
  self.navigationItem.leftBarButtonItem = backButton;

  CGRect frame =
      CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
  self.webview = [[UIWebView alloc] initWithFrame:frame];
  self.webview.backgroundColor = [UIColor whiteColor];
  self.webview.delegate = self;
  self.webview.scrollView.delegate = self;

  if ([self.mimeType isEqualToString:@"image/JPEG"] ||
      [self.mimeType isEqualToString:@"image/jpeg"] ||
      [self.mimeType isEqualToString:@"image/PNG"] ||
      [self.mimeType isEqualToString:@"image/GIF"]) {
    self.webview.scalesPageToFit = YES;
    self.mimeType = [self.mimeType lowercaseString];
    [self.webview loadData:self.data
                  MIMEType:self.mimeType
          textEncodingName:nil
                   baseURL:nil];

  }

  else {
    self.webview.scalesPageToFit = YES;
    [self.webview loadData:self.data
                  MIMEType:self.mimeType
          textEncodingName:nil
                   baseURL:nil];
  }

  self.webview.scrollView.minimumZoomScale = 0.5;
  self.webview.scrollView.maximumZoomScale = 6.0;
  [self.view addSubview:self.webview];
}

- (void)backtoType:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
  aWebView.frame =
      CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

@end
