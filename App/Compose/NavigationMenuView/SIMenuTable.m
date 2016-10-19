//
//  SAMenuTable.m
//  NavigationMenu
//
//  Created by Ivan Sapozhnik on 2/19/13.
//  Copyright (c) 2013 Ivan Sapozhnik. All rights reserved.
//

#import "SIMenuTable.h"
#import "SIMenuCell.h"
#import "SIMenuConfiguration.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Extension.h"
#import "SICellSelection.h"
#import "UIColor+FlatUI.h"

@interface SIMenuTable () {
    CGRect endFrame;
    CGRect startFrame;
    NSIndexPath *currentIndexPath;
}
@property (nonatomic, strong) UITableView *table;
@property (nonatomic, strong) NSArray *items;
@end

@implementation SIMenuTable

- (id)initWithFrame:(CGRect)frame items:(NSArray *)items
{
    self = [super initWithFrame:frame];
    if (self) {
        self.items = [NSArray arrayWithArray:items];
        
        self.layer.backgroundColor = [UIColor color:[SIMenuConfiguration mainColor] withAlpha:0.0].CGColor;
        self.clipsToBounds = YES;
        
        endFrame = self.bounds;
        startFrame = endFrame;
        startFrame.origin.y -= self.items.count*[SIMenuConfiguration itemCellHeight];
        
        self.table = [[UITableView alloc] initWithFrame:startFrame style:UITableViewStylePlain];
        self.table.delegate = self;
        self.table.dataSource = self;
        self.table.backgroundColor = [UIColor clearColor];
        self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        //self.table.tintColor = [UIColor whiteColor];
        //self.table.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.table.bounds.size.height, [SIMenuConfiguration menuWidth], self.table.bounds.size.height)];
        header.backgroundColor = [UIColor color:[SIMenuConfiguration itemsColor] withAlpha:[SIMenuConfiguration menuAlpha]];
        //header.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.table addSubview:header];
        
    }
    return self;
}

- (void)show
{
    [self addSubview:self.table];
    if (!self.table.tableFooterView) {
        [self addFooter];
    }
    [UIView animateWithDuration:[SIMenuConfiguration animationDuration] animations:^{
        self.layer.backgroundColor = [UIColor color:[SIMenuConfiguration mainColor] withAlpha:[SIMenuConfiguration backgroundAlpha]].CGColor;
        self.table.frame = endFrame;
        self.table.contentOffset = CGPointMake(0, [SIMenuConfiguration bounceOffset]);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:[self bounceAnimationDuration] animations:^{
            self.table.contentOffset = CGPointMake(0, 0);
        }];
    }];
}

- (void)hide
{
    [UIView animateWithDuration:[self bounceAnimationDuration] animations:^{
        self.table.contentOffset = CGPointMake(0, [SIMenuConfiguration bounceOffset]);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:[SIMenuConfiguration animationDuration] animations:^{
            self.layer.backgroundColor = [UIColor color:[SIMenuConfiguration mainColor] withAlpha:0.0].CGColor;
            self.table.frame = startFrame;
        } completion:^(BOOL finished) {
            //            [self.table deselectRowAtIndexPath:currentIndexPath animated:NO];
            SIMenuCell *cell = (SIMenuCell *)[self.table cellForRowAtIndexPath:currentIndexPath];
            [cell setSelected:NO withCompletionBlock:^{
                
            }];
            currentIndexPath = nil;
            [self removeFooter];
            [self.table removeFromSuperview];
            [self removeFromSuperview];
        }];
    }];
}

- (float)bounceAnimationDuration
{
    float percentage = 28.57;
    return [SIMenuConfiguration animationDuration]*percentage/100.0;
}

- (void)addFooter
{
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [SIMenuConfiguration menuWidth], self.table.bounds.size.height - (self.items.count * [SIMenuConfiguration itemCellHeight]))];
    self.table.tableFooterView = footer;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTap:)];
    [footer addGestureRecognizer:tap];
}

- (void)removeFooter
{
    self.table.tableFooterView = nil;
}

- (void)onBackgroundTap:(id)sender
{
    [self.menuDelegate didBackgroundTap];
}

- (void)dealloc
{
    self.items = nil;
    self.table = nil;
    self.menuDelegate = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [SIMenuConfiguration itemCellHeight];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    SIMenuCell *cell = (SIMenuCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[SIMenuCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    /*
     cell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
     cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
     */
    cell.textLabel.text = [self.items objectAtIndex:indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:14.0];
    
    // Set màu checkbox
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (sysVer > 7.0) {
        // Các thông số SIMenuConfig menuColor và menuAlpha ko có tác dụng nếu để dòng này
        cell.backgroundColor = [UIColor blueMenuColor];
        [[UITableViewCell appearance] setTintColor:[UIColor whiteColor]];
    }
    
    //Luôn ký
    BOOL isAlwaySign = [[NSUserDefaults standardUserDefaults]boolForKey:@"luonky"];
    BOOL isReloadMenu = [[NSUserDefaults standardUserDefaults]boolForKey:@"reload"];
    
    if (isAlwaySign && !isReloadMenu && indexPath.row == 0){
        if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"SignEmail", nil)])
        {
        UIImageView *checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_selected.png"]];
        checkmark.backgroundColor = [UIColor clearColor];
        checkmark.frame = CGRectMake(0, 0, 15, 15);
        checkmark.center = checkmark.superview.center;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.accessoryView = checkmark;
        [cell addSubview:checkmark];  }
    }
    else {
        UIView* bg = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 15, 15)];
        bg.backgroundColor = [UIColor blueMenuColor];
        bg.center = bg.superview.center;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = bg;
        [cell addSubview:bg];
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor blueMenuColor];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentIndexPath = indexPath;
    
    SIMenuCell *cell = (SIMenuCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:YES withCompletionBlock:^{
        [self.menuDelegate didSelectItemAtIndex:indexPath.row];
    }];
    
    UITableViewCell *cell_ = [tableView cellForRowAtIndexPath:indexPath];
    
    UIImageView *checkmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check_selected.png"]];
    checkmark.frame = CGRectMake(0, 0, 15, 15);
    checkmark.backgroundColor = [UIColor clearColor];
    checkmark.center = checkmark.superview.center;
    
    if (cell_.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell_.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    } else {
        cell_.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.accessoryView = checkmark;
        [cell addSubview:checkmark];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SIMenuCell *cell = (SIMenuCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelected:NO withCompletionBlock:^{
        
    }];
}


@end
