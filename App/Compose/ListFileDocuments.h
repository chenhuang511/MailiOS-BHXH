//
//  ListFileDocuments.h
//  iMail
//
//  Created by Tran Ha on 7/3/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ListFileDocuments;

@protocol ListFileDocumentsDelegate <NSObject>
- (void)addItemFilePath:(ListFileDocuments *)controller didFinishEnteringItem:(NSString *)item;
@end

@interface ListFileDocuments : UITableViewController
@property (nonatomic, weak) id <ListFileDocumentsDelegate> delegate;
@end
