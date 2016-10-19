//
//  SIMenuConfiguration.m
//  NavigationMenu
//
//  Created by Ivan Sapozhnik on 2/20/13.
//  Copyright (c) 2013 Ivan Sapozhnik. All rights reserved.
//

#import "SIMenuConfiguration.h"
#import "UIColor+FlatUI.h"

@implementation SIMenuConfiguration

//Menu width
+ (float)menuWidth
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    //return window.frame.size.width;
    return window.bounds.size.width;
    
}

//Menu item height
+ (float)itemCellHeight
{
    return 50.0f;
}

//Animation duration of menu appearence
+ (float)animationDuration
{
    return 0.3f;
}

//Menu substrate alpha value
+ (float)backgroundAlpha
{
    return 0.6f;
}

//Menu alpha value
+ (float)menuAlpha
{
    return 1;
}

//Value of bounce
+ (float)bounceOffset
{
    return -7.0;
}

//Arrow image near title
+ (UIImage *)arrowImage
{
    return [UIImage imageNamed:@"icon_arrow_down.png"];
}

//Distance between Title and arrow image
+ (float)arrowPadding
{
    return 0.0f;
}

//Items color in menu
+ (UIColor *)itemsColor
{
    return [UIColor blueMenuColor];
}

+ (UIColor *)mainColor
{
    return [UIColor blackColor];
}

+ (float)selectionSpeed
{
    return 0.05;
}

+ (UIColor *)itemTextColor
{
    return [UIColor whiteColor];
}

+ (UIColor *)selectionColor
{
    return [UIColor colorWithRed:45.0/255.0 green:105.0/255.0 blue:166.0/255.0 alpha:0.5];
    //return [UIColor blueMenuColor];
}
@end
