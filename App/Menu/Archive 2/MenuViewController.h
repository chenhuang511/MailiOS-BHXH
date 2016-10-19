//
//  MenuViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlatUIKit.h"
#import "MBProgressHUD.h"

#import "SDSelectableCell.h"
#import "SDGroupCell.h"
#import "SDSubCell.h"
#import "AuthNavigationViewController.h"

@protocol MenuViewDelegate <NSObject>

@property (strong) NSString *folderParent;

- (void)loadMailFolder:(NSString *)folderPath withHR:(NSString*) name;
- (void)loadFolderIntoCache:(NSString*)imapPath;
- (void)clearMessages;
- (void)loadTokenProtect;

- (void) mainTable:(UITableView *)mainTable itemDidChange:(SDGroupCell *)item;
- (void) item:(SDGroupCell *)item subItemDidChange:(SDSelectableCell *)subItem;

@end

@interface MenuViewController : UITableViewController <FUIAlertViewDelegate, MenuViewDelegate, AuthViewControllerDelegate>
{
	NSMutableDictionary *expandedIndexes;
    NSMutableDictionary *selectableCellsState;
    NSMutableDictionary *selectableSubCellsState;
}

- (void) mainItemDidChange: (SDGroupCell *)item forTap:(BOOL)tapped;
- (void) mainItem:(SDGroupCell *)item subItemDidChange: (SDSelectableCell *)subItem forTap:(BOOL)tapped;
- (NSInteger) mainTable:(UITableView *)mainTable numberOfItemsInSection:(NSInteger)section;
- (NSInteger) mainTable:(UITableView *)mainTable numberOfSubItemsforItem:(SDGroupCell *)item atIndexPath:(NSIndexPath *)indexPath;
- (SDGroupCell *) mainTable:(UITableView *)mainTable setItem:(SDGroupCell *)item forRowAtIndexPath:(NSIndexPath *)indexPath;
- (SDSubCell *) item:(SDGroupCell *)item setSubItem:(SDSubCell *)subItem forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) collapsingItem:(SDGroupCell *)item withIndexPath:(NSIndexPath *)indexPath;
- (void) expandingItem:(SDGroupCell *)item withIndexPath:(NSIndexPath *)indexPath;

- (void) reloadMenu;

@property (assign) int mainItemsAmt;
@property (strong) NSMutableDictionary *subItemsAmt;


@property (assign) IBOutlet SDGroupCell *groupCell;

- (void) collapsableButtonTapped: (UIControl *)button withEvent: (UIEvent *)event;
- (void) groupCell:(SDGroupCell *)cell didSelectSubCell:(SDSelectableCell *)subCell withIndexPath: (NSIndexPath *)indexPath andWithTap:(BOOL)tapped;

@property (nonatomic, weak) id<MenuViewDelegate> delegate;
@property (nonatomic, strong) NSDictionary *folderNameLookup;

+ (NSString*)sharedFolderName;
- (void) loadFolderIntoCacheMenu;

@end


