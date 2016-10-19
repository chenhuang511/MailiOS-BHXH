//
//  ComposeCommonMethod.m
//  iMail
//
//  Created by Macbook Pro on 5/16/15.
//  Copyright (c) 2015 com.vdcca. All rights reserved.
//

#import "ComposeCommonMethod.h"

#import "MBProgressHUD.h"

@implementation ComposeCommonMethod

+ (NSString *)parseAndBase64AddressName:(NSString *)addressName {
    addressName = [addressName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSRange prefix = [addressName rangeOfString:@"<"];
    NSRange endfix = [addressName rangeOfString:@">"];
    NSString *t = addressName;
    if (prefix.location != NSNotFound && endfix.location != NSNotFound) {
        
        // Display name
        NSString *name_parse = [t substringFromIndex:0];
        NSRange end = [name_parse rangeOfString:@"<"];
        NSString *name = [name_parse substringToIndex:end.location];
        if (name.length == 0) return addressName;
        
        // Address
        t = addressName;
        NSString *address_parse = [t substringFromIndex:prefix.location + 1];
        NSRange end_address = [address_parse rangeOfString:@">"];
        NSString *address = [address_parse substringToIndex:end_address.location];
        
        // Base64 display name
        NSData *dataTemp = [name dataUsingEncoding:NSUTF8StringEncoding];
        NSString *base64Name = [dataTemp base64Encoding];
        t = [NSString stringWithFormat:@"=?UTF-8?B?%@?= <%@>", base64Name, address];
    }
    return t;
}

+ (void)saveCertToDatabaseBy: (NSString *)r_mail andCert: (NSString *)base64 {
    NSArray *checkExist =
    [[DBManager getSharedInstance] findByEmail:r_mail];
    // Kiểm tra người gửi tồn tại trong DB
    if (!checkExist) {
        int _id = [[DBManager getSharedInstance] getLastObjectID];
        BOOL sucess = [[DBManager getSharedInstance] saveData:(_id + 1)
                                                       r_mail:r_mail
                                                     certdata:base64];
        NSLog(@"Chèn dữ liệu database = %d", sucess);
    } else {
        NSString *certdata = [checkExist objectAtIndex:1];
        NSString *_id = [checkExist objectAtIndex:0];
        if (![certdata isEqualToString:base64]) {
            NSLog(@"Updating database...");
            BOOL sucess =
            [[DBManager getSharedInstance] updateData:[_id intValue]
                                               r_mail:r_mail
                                             certdata:base64];
            NSLog(@"Update dữ liệu database = %d", sucess);
        }
    }
}

+ (void)chooseSignSuccess {
    UIWindow *window = [[UIApplication sharedApplication] delegate].window;
    [MBProgressHUD hideHUDForView:window animated:YES];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:window animated:YES];
    hud.labelText = NSLocalizedString(@"ChooseSign", nil);
    hud.labelFont = [UIFont boldSystemFontOfSize:13];
    hud.mode = MBProgressHUDModeCustomView;
    hud.margin = 12.0f;
    hud.yOffset = [[UIScreen mainScreen] bounds].size.height / 2 - 70.0f;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:0.8];
}

@end
