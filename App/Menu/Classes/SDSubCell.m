//
//  SDSubCell.m
//  SDNestedTablesExample
//
//  Created by Daniele De Matteis on 21/05/2012.
//  Copyright (c) 2012 Daniele De Matteis. All rights reserved.
//

#import "SDSubCell.h"
#import "FlatUIKit.h"
#import "Constants.h"

@implementation SDSubCell

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
    {
    }
    return self;
}

- (void) setupInterface
{
    [self setClipsToBounds: YES];
    self.backgroundColor =[UIColor colorFromHexCode:cellBgColor];
    CGRect frame = self.itemText.frame;
    frame.size.width = self.frame.size.width;
    frame.origin.y = 20;
    frame.size.height = 60;
    self.itemText.frame = frame;
}

- (void) tapTransition
{
    [super tapTransition];
}

@end
