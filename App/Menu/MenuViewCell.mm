//
//  MenuViewCell.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/2/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "MenuViewCell.h"
#import "FlatUIKit.h"
#import "TokenType.h"
#import "Constants.h"

@implementation MenuViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if ( IDIOM == IPAD ){
            self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:17];
        }
        else {
            self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
        }
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    NSDictionary *colors = @{@"Hộp thư đến": [UIColor peterRiverColor],
                             @"Thư đính kèm": [UIColor peterRiverColor],
                             @"Thư gắn dấu sao": [UIColor peterRiverColor],
                             @"Thư đã gửi": [UIColor peterRiverColor],
                             @"Tất cả thư": [UIColor peterRiverColor]
                             };
    
    if (selected) {
        UIColor* color = [colors objectForKey:self.textLabel.text];
        if (!color){
            color = [UIColor peterRiverColor];
        }
        self.textLabel.textColor = color;
    } else {
        self.textLabel.textColor = [UIColor whiteColor];
    }
    self.backgroundColor = [UIColor colorFromHexCode:cellBgColor];
}

@end
