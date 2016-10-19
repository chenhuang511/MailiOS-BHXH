//
//  PreviewViewController.h
//  VNPTCA Mail
//
//  Created by HungNP on 6/24/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate>
@property(nonatomic,strong) UIWebView *webview;
@property(nonatomic,strong) NSData *data;
@property(nonatomic,strong) NSString *mimeType;
- (id)initWithPreview:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil title:(NSString *) title data:(NSData *)data mimeType:(NSString *)mimeType;
@end
