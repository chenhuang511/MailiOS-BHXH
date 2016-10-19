//
//  AppDelegate.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "AppDelegate.h"

#include <MailCore/MailCore.h>
#import "ComposerViewController.h"
#import "Composer_iPhoneViewController.h"
#import "MenuViewController.h"
#import "MsgListViewController.h"

#import "AuthManager.h"

#import "INKWelcomeViewController.h"
#import "INKWelcomeViewController_iPhone.h"
#import "UTIFunctions.h"
#import "AuthNavigationViewController.h"

#import "TokenType.h"

#import "DBManager.h"
#import "TokenType.h"
#import "Reachability.h"
#import "ios-ntp.h"
#import "KeychainItemWrapper.h"

#import "CheckValidSession.h"

@implementation AppDelegate

static NSDate *currentDate;
Reachability *reachability;

+ (NSDate *)getNetworkDate {
  return currentDate;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // network notification
  reachability = [Reachability reachabilityForInternetConnection];
  [reachability startNotifier];

  NSString *bundleIdentifier = [AppDelegate bundleSeedID];
  NSString *accessGroup = [NSString
      stringWithFormat:@"%@.VDC-IT.VNPT-TokenManager", bundleIdentifier];
  KeychainItemWrapper *wrapper =
      [[KeychainItemWrapper alloc] initWithIdentifier:@"machineIdentifier"
                                          accessGroup:accessGroup];
  NSString *uuid_id = [wrapper objectForKey:(__bridge id)kSecAttrService];
  NSLog(@"keychain = %@", uuid_id);

  // test only
  // NSString *new_id = @"97fdb550bafffaebe51c596bf92d731be4373905";
  //[wrapper setObject:new_id forKey:(__bridge id)kSecAttrService];

  if (IDIOM == IPAD) {
    NSLog(@"This is Ipad");
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor cloudsColor]
                                  highlightedColor:[UIColor concreteColor]
                                      cornerRadius:3];

    UISplitViewController *splitViewController =
        (UISplitViewController *)self.window.rootViewController;
    UINavigationController *leftNavigationController =
        [splitViewController.viewControllers objectAtIndex:0];

    UINavigationController *navigationController =
        [splitViewController.viewControllers lastObject];
    splitViewController.delegate = (id)navigationController.topViewController;

    MenuViewController *listController = [[MenuViewController alloc] init];
    listController.delegate = (id)leftNavigationController.topViewController;

    NSDictionary *options = @{
      PKRevealControllerAllowsOverdrawKey : [NSNumber numberWithBool:YES],
      PKRevealControllerDisablesFrontViewInteractionKey :
          [NSNumber numberWithBool:NO],
      PKRevealControllerRecognizesResetTapOnFrontViewKey :
          [NSNumber numberWithBool:NO],
      PKRevealControllerRecognizesPanningOnFrontViewKey :
          [NSNumber numberWithBool:NO]
    };

    self.revealController = [PKRevealController
        revealControllerWithFrontViewController:splitViewController
                             leftViewController:listController
                            rightViewController:nil
                                        options:options];

    [self.window setRootViewController:self.revealController];
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (sysVer > 7.0) {
      [[UILabel appearance]
          setFont:[UIFont
                      fontWithDescriptor:
                          [UIFontDescriptor fontDescriptorWithFontAttributes:@{
                            @"NSCTFontUIUsageAttribute" : UIFontTextStyleBody,
                            @"NSFontNameAttribute" : @"HelveticaNeue"
                          }] size:16.0]];
    } else {
      [[UILabel appearance]
          setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0]];
    }
  } else {

    NSLog(@"This is Iphone!");
    [UIBarButtonItem configureFlatButtonsWithColor:[UIColor cloudsColor]
                                  highlightedColor:[UIColor concreteColor]
                                      cornerRadius:3];

    UINavigationController *splitViewController =
        (UINavigationController *)self.window.rootViewController;
    UINavigationController *leftNavigationController =
        [splitViewController.viewControllers objectAtIndex:0];
    UINavigationController *navigationController =
        [splitViewController.viewControllers lastObject];
    splitViewController.delegate = (id)navigationController.topViewController;

    MenuViewController *listController = [[MenuViewController alloc] init];
    listController.delegate = (id)leftNavigationController.topViewController;

    NSDictionary *options = @{
      PKRevealControllerAllowsOverdrawKey : [NSNumber numberWithBool:YES],
      PKRevealControllerDisablesFrontViewInteractionKey :
          [NSNumber numberWithBool:NO],
      PKRevealControllerRecognizesResetTapOnFrontViewKey :
          [NSNumber numberWithBool:NO],
      PKRevealControllerRecognizesPanningOnFrontViewKey :
          [NSNumber numberWithBool:NO]
    };

    self.revealController = [PKRevealController
        revealControllerWithFrontViewController:splitViewController
                             leftViewController:listController
                            rightViewController:nil
                                        options:options];

    [self.window setRootViewController:self.revealController];
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (sysVer > 7.0) {
      [[UILabel appearance]
          setFont:[UIFont
                      fontWithDescriptor:
                          [UIFontDescriptor fontDescriptorWithFontAttributes:@{
                            @"NSCTFontUIUsageAttribute" : UIFontTextStyleBody,
                            @"NSFontNameAttribute" : @"HelveticaNeue"
                          }] size:14.0]];
    } else {
      [[UILabel appearance]
          setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0]];
    }
  }

  [self.window makeKeyAndVisible];
  self.window.backgroundColor = [UIColor whiteColor];
  [UIApplication sharedApplication].statusBarStyle =
      UIStatusBarStyleLightContent;

  // Pre Keyboard
  UITextField *lagFreeField = [[UITextField alloc] init];
  [self.window addSubview:lagFreeField];
  [lagFreeField becomeFirstResponder];
  [lagFreeField resignFirstResponder];
  [lagFreeField removeFromSuperview];

  return YES;
}

- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {

  NSLog(@"Calling Application Bundle ID: %@", sourceApplication);
  NSLog(@"URL scheme:%@", [url scheme]);
  NSLog(@"URL query: %@", [url query]);

  // Nhận file data.db
  UIPasteboard *appPasteBoard =
      [UIPasteboard pasteboardWithName:@"TokenBoard" create:NO];
  NSData *data = [appPasteBoard dataForPasteboardType:@"database"];
  NSError *error = nil;
  NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(
      NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *path = [libraryPath stringByAppendingPathComponent:@"data.db"];
  [data writeToFile:path options:NSDataWritingAtomic error:&error];
  NSLog(@"Nhận file data.db thành công");

  // Nhận mật khẩu
  /*
  UIPasteboard *appPasteBoard_Pass = [UIPasteboard
  pasteboardWithName:@"PassBoard"
                                                               create:NO];
  NSData *dataPass = [appPasteBoard_Pass dataForPasteboardType:@"passWrd_"];
  NSString* passwrd = [[NSString alloc] initWithData:dataPass
  encoding:NSUTF8StringEncoding];
  NSLog(@"Nhận mật khẩu thành công: %@", passwrd);
  [appPasteBoard setValue:@"" forPasteboardType:@"passWrd_"];

  [[NSUserDefaults standardUserDefaults] setObject:passwrd forKey:@"passwrd"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  */

  if ([[url query] isEqualToString:@"softtokencall"]) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"softTokenCall"
                                                        object:nil];
  }

  // Nhận file gọi từ chương trình khác
  NSString *filepath = [url absoluteString];
  NSArray *parts = [filepath componentsSeparatedByString:@"/"];
  NSString *filename = [parts objectAtIndex:[parts count] - 1];
  filename = [filename
      stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *documentpath =
      [documentsDirectory stringByAppendingPathComponent:filename];

  NSString *inboxPath =
      [documentsDirectory stringByAppendingPathComponent:@"Inbox"];
  filepath = [inboxPath stringByAppendingPathComponent:filename];

  if ([fileManager fileExistsAtPath:documentpath] == YES) {
    documentpath = [self getNextAvailableFileName:documentpath];
  }
  [fileManager copyItemAtPath:filepath toPath:documentpath error:&error];
  [fileManager removeItemAtPath:filepath error:&error];

  if (error == nil) {

//    NSData *filedata_ = [NSData dataWithContentsOfFile:documentpath];
//    NSString *filename_ = [documentpath lastPathComponent];
//    NSString *fileUTI_ = [UTIFunctions UTIFromFilename:filename];

//    MCOAttachment *attachment = [[MCOAttachment alloc] init];
//    [attachment setData:filedata_];
//    [attachment setMimeType:[UTIFunctions mimetypeFromUTI:fileUTI_]];
//    [attachment
//        setFilename:[UTIFunctions filenameFromFilename:filename_ UTI:fileUTI_]];
      MCOAttachment *attachment = [MCOAttachment attachmentWithContentsOfFile:documentpath];

    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    PKRevealController *root;
    UISplitViewController *focused;
    UIViewController *presented;
    if (window.rootViewController.presentedViewController) {
      root = (PKRevealController *)
                 window.rootViewController.presentedViewController;
    } else {
      root = (PKRevealController *)[window rootViewController];
      focused = (UISplitViewController *)[root focusedController];
      presented = focused.presentedViewController;
    }

    if (IDIOM == IPAD) {
      ComposerViewController *vc =
          [[ComposerViewController alloc] initWithTo:@[
          ] CC:@[] BCC:@[] subject:@"" message:@""
                                         attachments:@[ attachment ]
                                  delayedAttachments:@[]];
      UINavigationController *nc =
          [[UINavigationController alloc] initWithRootViewController:vc];
      nc.modalPresentationStyle = UIModalPresentationPageSheet;

      if (presented &&
          [presented isKindOfClass:[AuthNavigationViewController class]]) {
        AuthNavigationViewController *authViewController =
            (AuthNavigationViewController *)presented;
        [authViewController
            setCompletionHandler:^(AuthNavigationViewController *viewController,
                                   GTMOAuth2Authentication *auth,
                                   NSError *error) {
              if (!error && auth) {
                [viewController setDismissHandler:^(BOOL dismissed) {
                  if (dismissed) {
                    [root presentViewController:nc animated:YES completion:nil];
                  }
                }];
              }
            }];
      } else {
        [root presentViewController:nc animated:YES completion:nil];
      }

    } else {
      Composer_iPhoneViewController *vc =
          [[Composer_iPhoneViewController alloc] initWithTo:@[
          ] CC:@[] BCC:@[] subject:@"" message:@""
                                                attachments:@[ attachment ]
                                         delayedAttachments:@[]];
      UINavigationController *nc =
          [[UINavigationController alloc] initWithRootViewController:vc];

      if (presented &&
          [presented isKindOfClass:[AuthNavigationViewController class]]) {
        AuthNavigationViewController *authViewController =
            (AuthNavigationViewController *)presented;
        [authViewController
            setCompletionHandler:^(AuthNavigationViewController *viewController,
                                   GTMOAuth2Authentication *auth,
                                   NSError *error) {
              if (!error && auth) {
                [viewController setDismissHandler:^(BOOL dismissed) {
                  if (dismissed) {
                    [root presentViewController:nc animated:YES completion:nil];
                  }
                }];
              }
            }];
      } else {
        [root presentViewController:nc animated:YES completion:nil];
      }
    }
  }

  return YES;
}

//- (void)copydata {
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    //src
//    NSString *libraryPath =
//    [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,
//    YES) objectAtIndex:0];
//    NSString *src = [libraryPath
//    stringByAppendingPathComponent:@"VNPTMail_Database.db"];
//    //dest
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//    NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *dest = [documentsDirectory
//    stringByAppendingPathComponent:@"VNPTMail_Database.db"];
//    //copy
//    if ([fileManager fileExistsAtPath:dest]) {
//        [fileManager removeItemAtPath:dest error:nil];
//    }
//    [fileManager copyItemAtPath:src toPath:dest error:nil];
//}

+ (NSString *)bundleSeedID {
  NSDictionary *query = [NSDictionary
      dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),
                                   kSecClass, @"bundleSeedID", kSecAttrAccount,
                                   @"", kSecAttrService, (id)kCFBooleanTrue,
                                   kSecReturnAttributes, nil];
  CFDictionaryRef result = nil;
  OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query,
                                        (CFTypeRef *)&result);
  if (status == errSecItemNotFound)
    status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
  if (status != errSecSuccess)
    return nil;
  NSString *accessGroup = [(__bridge NSDictionary *)result
      objectForKey:(__bridge id)(kSecAttrAccessGroup)];
  NSArray *components = [accessGroup componentsSeparatedByString:@"."];
  NSString *bundleSeedID = [[components objectEnumerator] nextObject];
  CFRelease(result);
  return bundleSeedID;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Get TokenPasteBoard
  NSLog(@"Mail become Active");
  UIPasteboard *appPasteBoard =
      [UIPasteboard pasteboardWithName:@"TokenBoard" create:NO];
  NSData *data = [appPasteBoard dataForPasteboardType:@"database"];
  if (data) {
    NSError *error = nil;
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [libraryPath stringByAppendingPathComponent:@"data.db"];
    [data writeToFile:path options:NSDataWritingAtomic error:&error];
    NSLog(@"Nhận file data.db thành công");
  }
  currentDate = [NSDate networkDate];
  NSLog(@"Network Date %@", currentDate);

  // remove all token information
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"passwrd"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"HardPasswrd"];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"TokenSession"];

  // check session
  NSArray *listAccount =
      [[NSUserDefaults standardUserDefaults] objectForKey:@"listAccount"];
  if (listAccount.count > 0) {
    [CheckValidSession checkValidSession:[AuthManager getImapSession_]];
  }
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
}

- (NSString *)getNextAvailableFileName:(NSString *)filePath {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *suffix = [filePath pathExtension];
  filePath = [filePath stringByDeletingPathExtension];
  if ([fm fileExistsAtPath:[NSString
                               stringWithFormat:@"%@.%@", filePath, suffix]]) {
    int maxIterations = 100;
    for (int numDuplicates = 1; numDuplicates < maxIterations;
         numDuplicates++) {
      NSString *testPath = [NSString
          stringWithFormat:@"%@(%d).%@", filePath, numDuplicates, suffix];
      if (![fm fileExistsAtPath:testPath]) {
        return testPath;
      }
    }
  }
  return [NSString stringWithFormat:@"%@.%@", filePath, suffix];
}

#pragma mark - INK
//- (void) replyBlob:(INKBlob *)blob action:(INKAction*)action
// error:(NSError*)error
//{
//
//    MCOAttachment *attachment = [[MCOAttachment alloc] init];
//    [attachment setData:[blob data]];
//    [attachment setMimeType:[UTIFunctions mimetypeFromUTI:[blob uti]]];
//    [attachment setFilename:[UTIFunctions filenameFromFilename:[blob filename]
//    UTI:[blob uti]]];
//
//    ComposerViewController *vc = [[ComposerViewController alloc]
//    initWithTo:@[] CC:@[] BCC:@[] subject:@"" message:@""
//    attachments:@[attachment] delayedAttachments:@[]];
//    UINavigationController *nc = [[UINavigationController alloc]
//    initWithRootViewController:vc];
//    nc.modalPresentationStyle = UIModalPresentationPageSheet;
//
//    PKRevealController *root = (PKRevealController *)[[[[UIApplication
//    sharedApplication] delegate] window] rootViewController];
//    UISplitViewController *focused = (UISplitViewController *)[root
//    focusedController];
//    UIViewController *presented = focused.presentedViewController;
//
//    if (presented && [presented isKindOfClass:[AuthNavigationViewController
//    class]])
//    {
//        AuthNavigationViewController *authViewController =
//        (AuthNavigationViewController *)presented;
//        [authViewController
//        setCompletionHandler:^(AuthNavigationViewController *viewController,
//        GTMOAuth2Authentication *auth, NSError *error)
//         {
//             if (!error && auth)
//             {
//                 [viewController setDismissHandler:^(BOOL dismissed)
//                  {
//                      if (dismissed)
//                      {
//                          [root presentViewController:nc animated:YES
//                          completion:nil];
//                      }
//                  }];
//             }
//         }];
//    }
//    else {
//        [root presentViewController:nc animated:YES completion:nil];
//    }
//}

@end
