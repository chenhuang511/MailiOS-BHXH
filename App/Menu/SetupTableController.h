//
//  SetupTableController.h
//  iMail
//
//  Created by Thanh on 8/12/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FUIAlertView.h"

@interface SetupTableController : UITableViewController <FUIAlertViewDelegate>
{
    NSString *appver;
    UISwitch *switchLuonKy, *switchProtect, *switchSignature, *switchLanguage;
    NSString *status;
    NSString *device;
    NSString *serial;
    NSString *device_selected;
    NSString *username;
    NSMutableIndexSet *expandedSections, *expandedSectionSign, *expandedSectionLang;
    UITextField *signature_text;
    UIButton *btnEng, *btnVi;
    float iosVer;
}

@end


