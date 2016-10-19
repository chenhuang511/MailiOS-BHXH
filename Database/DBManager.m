//
//  DBManager.m
//  iMail
//
//  Created by Tran Ha on 04/06/2014.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "DBManager.h"
#import <sqlite3.h>

static DBManager *sharedInstance = nil;
static sqlite3 *database = nil;
static sqlite3 *tokentype = nil;
static sqlite3_stmt *statement = nil;

static sqlite3 *protected = nil;

@implementation DBManager

+ (DBManager*) getSharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[super allocWithZone:NULL]init];
        [sharedInstance createDB];
    }
    return sharedInstance;
}

- (BOOL)createDB {
    // Build the path to the database file
    NSString* path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    databasePath = [[NSString alloc] initWithString:[path stringByAppendingPathComponent: @"VNPTMail_Database.db"]];
    BOOL isSuccess = YES;
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: databasePath ] == NO)
    {
        const char *dbpath = [databasePath UTF8String];
        //tb_receiver
        if (sqlite3_open(dbpath, &database) == SQLITE_OK)
        {
            char *errMsg;
            const char *sql_stmt = "create table if not exists tb_receiver (_id integer primary key autoincrement, r_mail text, certdata text)";
            if (sqlite3_exec(database, sql_stmt, NULL, NULL, &errMsg)!= SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table");
            }
            sqlite3_close(database);
        }
        else {
            isSuccess = NO;
            NSLog(@"Failed to open/create database");
        }
        
        //tokentype
        if (sqlite3_open(dbpath, &tokentype) == SQLITE_OK)
        {
            char *errMsg_;
            const char *sql_stmt = "create table if not exists tokentype (type integer, pubkey integer, prikey integer, r_mail text, serial text)";
            if (sqlite3_exec(tokentype, sql_stmt, NULL, NULL, &errMsg_)!= SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table");
            }
            sqlite3_close(tokentype);
        }
        else {
            isSuccess = NO;
            NSLog(@"Failed to open/create database");
        }
        
        //protected email
        if (sqlite3_open(dbpath, &protected) == SQLITE_OK)
        {
            char *errMsg_;
            const char *sql_stmt = "create table if not exists protected (_id integer primary key autoincrement, protectedType integer, serialH text, serial text, email text)";
            if (sqlite3_exec(protected, sql_stmt, NULL, NULL, &errMsg_)!= SQLITE_OK)
            {
                isSuccess = NO;
                NSLog(@"Failed to create table");
            }
            sqlite3_close(protected);
        }
        else {
            isSuccess = NO;
            NSLog(@"Failed to open/create database");
        }
    }
    
    return isSuccess;
}

- (BOOL)saveProtected: (int)_id protectedType:(int)protectedType serialHash:(NSString*)serialH serial:(NSString*)serial email:(NSString*)email {
    sqlite3_close(protected);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &protected) == SQLITE_OK) {
        
        NSString *insertSQL = [NSString stringWithFormat:@"insert into protected (_id, protectedType, serialH, serial, email) values (\"%d\", \"%d\",\"%@\",\"%@\",\"%@\")", _id, protectedType, serialH, serial, email];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(protected, insert_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Lưu Protected thành công");
            [self closeDatabase];
            return YES;
        }
        else {
            NSLog(@"Lưu Protected thất bại");
            [self closeDatabase];
            return NO;
        }
    }
    return NO;
}

- (BOOL)updateProtected: (int)_id protectedType:(int)protectedType serialHash:(NSString*)serialH serial:(NSString*)serial email:(NSString*)email  {
    sqlite3_close(protected);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &protected) == SQLITE_OK) {
        
        NSString *insertSQL = [NSString stringWithFormat:@"UPDATE protected SET protectedType = '%d' WHERE _id = '%d'", protectedType, _id];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(protected, insert_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Update Protected Type thành công");
        }
        else {
            NSLog(@"error is %s",sqlite3_errmsg(protected));
            NSLog(@"Update Protected Type thất bại");
            [self closeDatabase];
            return NO;
        }
        
        NSString *insertSQL_ = [NSString stringWithFormat:@"UPDATE protected SET serialH = '%@' WHERE _id = '%d'", serialH, _id];
        const char *insert_stmt_ = [insertSQL_ UTF8String];
        sqlite3_prepare_v2(protected, insert_stmt_,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Update Serial Hash thành công");
        }
        else {
            NSLog(@"error is %s",sqlite3_errmsg(protected));
            NSLog(@"Update Serial Hash thất bại");
            [self closeDatabase];
            return NO;
        }
        
        NSString *insertSQLS = [NSString stringWithFormat:@"UPDATE protected SET serial = '%@' WHERE _id = '%d'", serial, _id];
        const char *insert_stmtS = [insertSQLS UTF8String];
        sqlite3_prepare_v2(protected, insert_stmtS,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Update Serial thành công");
        }
        else {
            NSLog(@"error is %s",sqlite3_errmsg(protected));
            NSLog(@"Update Serial Hash thất bại");
            [self closeDatabase];
            return NO;
        }
        
        NSString *insertSQLE = [NSString stringWithFormat:@"UPDATE protected SET email = '%@' WHERE _id = '%d'", email, _id];
        const char *insert_stmtE = [insertSQLE UTF8String];
        sqlite3_prepare_v2(protected, insert_stmtE,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Update Email thành công");
            [self closeDatabase];
            return YES;
        }
        else {
            NSLog(@"Error is %s",sqlite3_errmsg(protected));
            NSLog(@"Update Email thất bại");
            [self closeDatabase];
            return NO;
        }
    }

    return NO;
}

- (int)getLastIDProtected {
    sqlite3_close(protected);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &protected) == SQLITE_OK)
    {
        NSString *sqlNsStr = [NSString stringWithFormat:@"SELECT * FROM sqlite_sequence where name='protected'"];
        const char *sql = [sqlNsStr cStringUsingEncoding:NSUTF8StringEncoding];
        int lastrec=0;
        //    if(sqlite3_open([dbPath UTF8String], &masterDB) == SQLITE_OK){
        if (sqlite3_prepare_v2(protected, sql, -1, &statement, NULL) == SQLITE_OK) {
            while(sqlite3_step(statement) == SQLITE_ROW) {
                lastrec = sqlite3_column_int(statement, 1);
            }
        }
        [self closeDatabase];
        return lastrec;
    }
    return 0;
}

- (NSArray*)findProtected: (NSString*)email {
    sqlite3_close(protected);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &protected) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"select protectedType, serialH, serial, _id from protected where email=\"%@\"",email];
        const char *query_stmt = [querySQL UTF8String];
        NSMutableArray *resultArray = [[NSMutableArray alloc]init];
        if (sqlite3_prepare_v2(protected,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *protectedType = [[NSString alloc] initWithUTF8String:
                                    (const char *) sqlite3_column_text(statement, 0)];
                [resultArray addObject:protectedType];
                NSString *serialH = [[NSString alloc] initWithUTF8String:
                                      (const char *) sqlite3_column_text(statement, 1)];
                [resultArray addObject:serialH];
                NSString *serial = [[NSString alloc] initWithUTF8String:
                                     (const char *) sqlite3_column_text(statement, 2)];
                [resultArray addObject:serial];
                
                NSString *_id = [[NSString alloc] initWithUTF8String:
                                   (const char *) sqlite3_column_text(statement, 3)];
               [resultArray addObject:_id];
                
                [self closeDatabase];
                return resultArray;
            }
            else {
                NSLog(@"Not found findProtected");
                [self closeDatabase];
                return nil;
            }
        }
        sqlite3_reset(statement);
        sqlite3_finalize(statement);
        sqlite3_close(protected);
    }
    return nil;
}


- (BOOL)saveData: (int)_id r_mail:(NSString*)r_mail certdata:(NSString*)certdata {
    sqlite3_close(database);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"insert into tb_receiver (_id, r_mail, certdata) values (\"%d\",\"%@\", \"%@\")",_id, r_mail, certdata];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(database, insert_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Lưu dữ liệu thành công");
            [self closeDatabase];
            return YES;
        }
        else {
            NSLog(@"Lưu dữ liệu thất bại");
            [self closeDatabase];
            return NO;
        }
    }
    return NO;
}

- (BOOL)updateData: (int)_id r_mail:(NSString*)r_mail certdata:(NSString*)certdata {
    sqlite3_close(database);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        
        NSString *insertSQL = [NSString stringWithFormat:@"UPDATE tb_receiver SET certdata = '%@' WHERE r_mail = '%@'", certdata, r_mail];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(database, insert_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Update dữ liệu thành công");
            [self closeDatabase];
            return YES;
        }
        else {
            NSLog(@"error is %s",sqlite3_errmsg(database));
            NSLog(@"Update dữ liệu thất bại");
            [self closeDatabase];
            return NO;
        }
    }
    return NO;
}

- (BOOL)saveTokenType_byEmail: (NSString*)r_mail tokenType:(int)tokenType pubkey:(int)pubkey prikey:(int)prikey serial:(NSString*)serial {
    sqlite3_close(tokentype);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &tokentype) == SQLITE_OK) {
        
        NSString *insertSQL = [NSString stringWithFormat:@"insert into tokentype (type, pubkey, prikey, r_mail, serial) values (\"%d\",\"%d\",\"%d\",\"%@\",\"%@\")", tokenType, pubkey, prikey, r_mail, serial];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(tokentype, insert_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Lưu dữ liệu TokenType thành công");
            [self closeDatabase];
            return YES;
        }
        else {
            NSLog(@"Lưu dữ liệu TokenType thất bại");
            [self closeDatabase];
            return NO;
        }
    }
    return NO;
}

- (BOOL)updateTokenType_byEmai: (NSString*)r_mail tokenType:(int)tokenType pubkey:(int)pubkey prikey:(int)prikey serial:(NSString*)serial {
    sqlite3_close(tokentype);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &tokentype) == SQLITE_OK) {
        
        NSString *insertSQL = [NSString stringWithFormat:@"UPDATE tokentype SET type = '%d', pubkey = '%d', prikey = '%d', serial = '%@' WHERE r_mail = '%@'", tokenType, pubkey, prikey, serial, r_mail];
        const char *insert_stmt = [insertSQL UTF8String];
        sqlite3_prepare_v2(tokentype, insert_stmt,-1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            NSLog(@"Update dữ liệu TokenType thành công");
            [self closeDatabase];
            return YES;
        }
        else {
            NSLog(@"error is %s",sqlite3_errmsg(tokentype));
            NSLog(@"Update dữ liệu TokenType thất bại");
            [self closeDatabase];
            return NO;
        }
    }
    return NO;
}

- (BOOL)deleteRow: (int)_id r_mail:(NSString*)r_mail {
    sqlite3_close(database);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK) {
        NSString *sql = nil;
        if (_id) {
            sql = [NSString stringWithFormat: @"delete from tb_receiver where _id =%d", _id];
        }
        if (r_mail) {
            sql = [NSString stringWithFormat: @"delete from tb_receiver where r_mail =%@", r_mail];
        }
        const char *del_stmt = [sql UTF8String];
        sqlite3_prepare_v2(database, del_stmt, -1, &statement, NULL);
        if (sqlite3_step(statement) == SQLITE_DONE)
        {
            return YES;
        } else {
            return NO;
        }
        sqlite3_reset(statement);
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return NO;
}

- (NSArray*)findById:(int)_id {
    sqlite3_close(database);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"select r_mail, certdata from tb_receiver where _id=\"%d\"",_id];
        const char *query_stmt = [querySQL UTF8String];
        NSMutableArray *resultArray = [[NSMutableArray alloc]init];
        if (sqlite3_prepare_v2(database,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *r_mail = [[NSString alloc] initWithUTF8String:
                                    (const char *) sqlite3_column_text(statement, 0)];
                [resultArray addObject:r_mail];
                NSString *certdata = [[NSString alloc] initWithUTF8String:
                                      (const char *) sqlite3_column_text(statement, 1)];
                [resultArray addObject:certdata];
                [self closeDatabase];
                return resultArray;
            }
            else {
                NSLog(@"Not found findbyID");
                [self closeDatabase];
                return nil;
            }
            
        }
        sqlite3_reset(statement);
        sqlite3_finalize(statement);
        sqlite3_close(database);
    }
    return nil;
}

- (NSArray*)findByEmail:(NSString*)r_mail {
    sqlite3_close(database);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"select _id, certdata from tb_receiver where r_mail=\"%@\"",r_mail];
        const char *query_stmt = [querySQL UTF8String];
        NSMutableArray *resultArray = [[NSMutableArray alloc]init];
        if (sqlite3_prepare_v2(database,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *_id = [[NSString alloc] initWithUTF8String:
                                 (const char *) sqlite3_column_text(statement, 0)];
                [resultArray addObject:_id];
                NSString *certdata = [[NSString alloc] initWithUTF8String:
                                      (const char *) sqlite3_column_text(statement, 1)];
                [resultArray addObject:certdata];
                [self closeDatabase];
                return resultArray;
            }
            else {
                NSLog(@"Not found (findbyEmail)");
                [self closeDatabase];
                return nil;
            }
        }
    }
    return nil;
}

- (NSArray*)findTokenTypeByEmail: (NSString*)r_mail {
    sqlite3_close(tokentype);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &tokentype) == SQLITE_OK)
    {
        NSString *querySQL = [NSString stringWithFormat:
                              @"select type, pubkey, prikey, serial from tokentype where r_mail=\"%@\"",r_mail];
        const char *query_stmt = [querySQL UTF8String];
        NSMutableArray *resultArray = [[NSMutableArray alloc]init];
        if (sqlite3_prepare_v2(tokentype,
                               query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_ROW)
            {
                NSString *type = [[NSString alloc] initWithUTF8String:
                                           (const char *) sqlite3_column_text(statement, 0)];
                [resultArray addObject:type];
                NSString *pubkey = [[NSString alloc] initWithUTF8String:
                                     (const char *) sqlite3_column_text(statement, 1)];
                [resultArray addObject:pubkey];
                NSString *prikey = [[NSString alloc] initWithUTF8String:
                                    (const char *) sqlite3_column_text(statement, 2)];
                [resultArray addObject:prikey];
                NSString *serial = [[NSString alloc] initWithUTF8String:
                                    (const char *) sqlite3_column_text(statement, 3)];
                [resultArray addObject:serial];
                [self closeDatabase];
                return resultArray;
            }
            else {
                NSLog(@"Not found findProtected");
                [self closeDatabase];
                return nil;
            }
        }
        sqlite3_reset(statement);
        sqlite3_finalize(statement);
        sqlite3_close(tokentype);
    }
    return nil;
}


- (int)getLastObjectID {
    sqlite3_close(database);
    const char *dbpath = [databasePath UTF8String];
    if (sqlite3_open(dbpath, &database) == SQLITE_OK)
    {
        NSString *sqlNsStr = [NSString stringWithFormat:@"SELECT * FROM sqlite_sequence where name='tb_receiver'"];
        const char *sql = [sqlNsStr cStringUsingEncoding:NSUTF8StringEncoding];
        int lastrec=0;
        //    if(sqlite3_open([dbPath UTF8String], &masterDB) == SQLITE_OK){
        if (sqlite3_prepare_v2(database, sql, -1, &statement, NULL) == SQLITE_OK) {
            while(sqlite3_step(statement) == SQLITE_ROW) {
                lastrec = sqlite3_column_int(statement, 1);
            }
        }
        [self closeDatabase];
        return lastrec;
    }
    return 0;
}

- (void)closeDatabase {
    sqlite3_reset(statement);
    sqlite3_finalize(statement);
    sqlite3_close(database);
    sqlite3_close(tokentype);
    sqlite3_close(protected);
}

@end

