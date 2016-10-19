//
//  DBManager.h
//  iMail
//
//  Created by Tran Ha on 04/06/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@interface DBManager : NSObject {
    NSString *databasePath;
    sqlite3 *databaseHandle;
}

+ (DBManager*)getSharedInstance;
- (BOOL)createDB;

//tb_receiver
- (BOOL)saveData: (int)_id r_mail:(NSString*)r_mail certdata:(NSString*)certdata;
- (BOOL)updateData: (int)_id r_mail:(NSString*)r_mail certdata:(NSString*)certdata;
- (BOOL)deleteRow: (int)_id r_mail:(NSString*)r_mail;
- (NSArray*)findById:(int)_id;
- (NSArray*)findByEmail:(NSString*)r_mail;
- (int)getLastObjectID;

//tokentype
- (BOOL)saveTokenType_byEmail: (NSString*)r_mail tokenType:(int)tokenType pubkey:(int)pubkey prikey:(int)prikey serial:(NSString*)serial;
- (BOOL)updateTokenType_byEmai: (NSString*)r_mail tokenType:(int)tokenType pubkey:(int)pubkey prikey:(int)prikey serial:(NSString*)serial;
- (NSArray*)findTokenTypeByEmail: (NSString*)r_mail;

//protected mail
- (BOOL)saveProtected: (int)_id protectedType:(int)protectedType serialHash:(NSString*)serialH serial:(NSString*)serial email:(NSString*)email;
- (BOOL)updateProtected: (int)_id protectedType:(int)protectedType serialHash:(NSString*)serialH serial:(NSString*)serial email:(NSString*)email;
- (NSArray*) findProtected: (NSString*)email;
- (int)getLastIDProtected;

@end
