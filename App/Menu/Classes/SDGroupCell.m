//
//  SDGroupCell.m
//  SDNestedTablesExample
//
//  Created by Daniele De Matteis on 21/05/2012.
//  Copyright (c) 2012 Daniele De Matteis. All rights reserved.
//

#import "SDGroupCell.h"
#import <QuartzCore/QuartzCore.h>
#import "MenuViewController.h"
#import "UIColor+FlatUI.h"
#import "Constants.h"

@implementation SDGroupCell

@synthesize isExpanded, subTable, subCell, subCellsAmt, selectedSubCellsAmt, selectableSubCellsState, cellIndexPath;

+ (int) getHeight
{
    return height;
}

+ (int) getsubCellHeight
{
    return subCellHeight;
}

- (void) setSubCellsAmt:(int)newSubCellsAmt
{
    subCellsAmt = newSubCellsAmt;
    if(subCellsAmt == 0)
    {
        expandBtn.hidden = YES;
    }
    else 
    {
        expandBtn.hidden = NO;
    }
}

#pragma mark - Lifecycle

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
    {
        subCellsCommand = AllSubCellsCommandNone;
    }
    return self;
}

- (void) setupInterface
{
    [super setupInterface];
    
    CGRect bgrndFrame = self.backgroundView.frame;
    bgrndFrame.size.height = 50;
    self.backgroundView.frame = bgrndFrame;
    self.backgroundColor = [UIColor colorFromHexCode:cellBgColor];
    expandBtn.frame = CGRectMake(100, 6, 300, 44);
    [expandBtn setBackgroundColor:[UIColor clearColor]];
    [expandBtn setImage:[UIImage imageNamed:@"icon_arrow_collapse.png"] forState:UIControlStateNormal];
    [expandBtn addTarget:self.parentTable action:@selector(collapsableButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [expandBtn addTarget:self action:@selector(rotateExpandBtn:) forControlEvents:UIControlEventTouchUpInside];
    expandBtn.alpha = 0.45;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSubmenu:) name:@"reloadSubmenu" object:nil];
}

#pragma mark - behavior
-(void)reloadSubmenu{
 
}
-(void) rotateExpandBtn:(id)sender
{
    isExpanded = !isExpanded;
    switch (isExpanded) {
        case 0:
            [self rotateExpandBtnToCollapsed];
            break;
        case 1:
            [self rotateExpandBtnToExpanded];
            break;
        default:
            break;
    }
}

- (void)rotateExpandBtnToExpanded
{
    [UIView beginAnimations:@"rotateDisclosureButt" context:nil];
    [UIView setAnimationDuration:0.4];
    expandBtn.transform = CGAffineTransformMakeRotation(M_PI);
    [UIView commitAnimations];
}

- (void)rotateExpandBtnToCollapsed
{
    [UIView beginAnimations:@"rotateDisclosureButt" context:nil];
    [UIView setAnimationDuration:0.4];
    expandBtn.transform = CGAffineTransformMakeRotation(M_PI*2);
    [UIView commitAnimations];
}

- (SelectableCellState) toggleCheck
{
    SelectableCellState cellState = [super toggleCheck];
    if (self.selectableCellState == Checked)
    {
        expandBtn.alpha = 1.0;
    }
    else if (self.selectableCellState == Halfchecked)
    {
        expandBtn.alpha = 0.75;
    }
    else
    {
        expandBtn.alpha = 0.45;
    }
    return cellState;
}

- (void)check {
    [super check];
    expandBtn.alpha = 1.0;
}

- (void) uncheck {
    [super uncheck];
    expandBtn.alpha = 0.45;
}

- (void) halfCheck {
    [super halfCheck];
    expandBtn.alpha = 0.75;
}

- (void) subCellsToggleCheck
{
    
    if (self.selectableCellState == Checked)
    {
        subCellsCommand = AllSubCellsCommandChecked;
    }
    else
    {
        subCellsCommand = AllSubCellsCommandUnchecked;
    }
    for (int i = 0; i < subCellsAmt; i++)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [self tableView:subTable didSelectRowAtIndexPath:indexPath];
    }
    subCellsCommand = AllSubCellsCommandNone;
}

- (void) tapTransition
{
    [super tapTransition];
}

#pragma mark - Table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return subCellsAmt;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SDSubCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SubCell"];
    
    if (cell == nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"SDSubCell" owner:self options:nil];
        cell = subCell;
        self.subCell = nil;
    }
    
    SelectableCellState cellState = [[selectableSubCellsState objectForKey:indexPath] intValue];
    switch (cellState) {
        default:
            break;
    };
    
    cell = [self.parentTable item:self setSubItem:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    tableView.separatorColor = [UIColor clearColor];
  
    SDSubCell *cell = (SDSubCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell == nil)
    {
        cell = (SDSubCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
        
    } 
    [tableView reloadData];
    [self toggleCell:cell atIndexPath:indexPath];
}


- (void) toggleCell:(SDSubCell *)cell atIndexPath: (NSIndexPath *) pathToToggle
{
    [cell tapTransition];
    
    BOOL cellTapped;
    switch (subCellsCommand)
    {
        case AllSubCellsCommandChecked:
            cellTapped = NO;
            break;
        case AllSubCellsCommandUnchecked:
            cellTapped = NO;
            break;
        default:
            cellTapped = YES;
            break;
    }
    isExpanded = !isExpanded;
    switch (isExpanded) {
        case 0:
            [self rotateExpandBtnToCollapsed];
            break;
        case 1:
            [self rotateExpandBtnToExpanded];
            break;
        default:
            break;
    }
    [self.parentTable groupCell:self didSelectSubCell:cell withIndexPath:pathToToggle andWithTap:cellTapped];
}

@end