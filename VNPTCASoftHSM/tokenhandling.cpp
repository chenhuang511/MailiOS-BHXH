/* $Id: tokenhandling.cpp 6270 2012-04-20 07:41:05Z jerry $ */

/*
 * Copyright (c) 2008-2009 .SE (The Internet Infrastructure Foundation).
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/************************************************************
 *
 * Functions for token handling.
 *
 ************************************************************/

#include "tokenhandling.h"
#include "userhandling.h"
//#include "log.h"
#include "SoftDatabase.h"

#include <stdlib.h>
#include <stdio.h>
#include "sqlite3/sqlite3.h"

//#define EXEC_DB(db, sql) \
//  if(sqlite3_exec(db, sql, NULL, NULL, NULL)) { \
//    free(soPIN); \
//    sqlite3_close(db); \
//    return CKR_DEVICE_ERROR; \
// }

#define EXEC_DB(db, sql) \
if(sqlite3_exec(db, sql, NULL, NULL, NULL)) { \
sqlite3_close(db); \
return CKR_DEVICE_ERROR; \
}

// The database schema

static char sqlDBSchemaVersion[] = "PRAGMA user_version = 100";

static char sqlCreateTableToken[] = "CREATE TABLE Token ("
	"variableID INTEGER PRIMARY KEY,"
	"value TEXT DEFAULT NULL);";

static char sqlCreateTableObjects[] = "CREATE TABLE Objects ("
	"objectID INTEGER PRIMARY KEY);";

static char sqlCreateTableAttributes[] = "CREATE TABLE Attributes ("
	"attributeID INTEGER PRIMARY KEY,"
	"objectID INTEGER DEFAULT NULL,"
	"type INTEGER DEFAULT NULL,"
	"value BLOB DEFAULT NULL,"
	"length INTEGER DEFAULT 0);";

static char sqlCreateTableBackup[] = "CREATE TABLE Backup ("
    "attributeID INTEGER PRIMARY KEY,"
    "objectID INTEGER DEFAULT NULL,"
    "type INTEGER DEFAULT NULL,"
    "value BLOB DEFAULT NULL,"
    "length INTEGER DEFAULT 0);";

static char sqlDeleteTrigger[] =
		"CREATE TRIGGER deleteTrigger BEFORE DELETE ON Objects "
			"BEGIN "
			"DELETE FROM Attributes "
			"WHERE objectID = OLD.objectID; "
			"END;";

static char sqlCreateIndexAttributes[] =
		"CREATE INDEX idxObject ON Attributes (objectID, type);"
			"CREATE INDEX idxTypeValue ON Attributes (type, value);";

// Initialize a token

CK_RV softInitToken(SoftSlot *currentSlot, CK_UTF8CHAR_PTR pPin,
		CK_ULONG ulPinLen, CK_UTF8CHAR_PTR pLabel, CK_UTF8CHAR_PTR pImei) {
	// Digest the PIN
	char *soPIN = digestPIN(pPin, ulPinLen);
//	char temp[] = "12345678";
//	char *soPIN = new char[9];
//	strcpy(soPIN, temp);

	//	// Open the database
	sqlite3 *db = NULL;
	int result = sqlite3_open(currentSlot->dbPath, &db);
	if (result) {
		if (db != NULL) {
			sqlite3_close(db);
		}
		free(soPIN);
		return CKR_DEVICE_ERROR;
	}
	// Clear the database.
	EXEC_DB(db, "DROP TABLE IF EXISTS Token");
	EXEC_DB(db, "DROP TABLE IF EXISTS Objects");
	EXEC_DB(db, "DROP TABLE IF EXISTS Attributes");
    EXEC_DB(db, "DROP TABLE IF EXISTS Backup");
	EXEC_DB(db, "DROP TRIGGER IF EXISTS deleteTrigger");
	EXEC_DB(db, "DROP INDEX IF EXISTS idxObject");
	EXEC_DB(db, "DROP INDEX IF EXISTS idxTypeValue");
	//	EXEC_DB(db, "VACUUM");

	// Add the structure
	EXEC_DB(db, sqlDBSchemaVersion);
	EXEC_DB(db, sqlCreateTableToken);
	EXEC_DB(db, sqlCreateTableObjects);
	EXEC_DB(db, sqlCreateTableAttributes);
	EXEC_DB(db, sqlDeleteTrigger);
	EXEC_DB(db, sqlCreateIndexAttributes);
    EXEC_DB(db, sqlCreateTableBackup);
	sqlite3_close(db);
    
	// Open a connection to the new db
	SoftDatabase *softDB = new SoftDatabase(NULL);
	CK_RV initDB = softDB->init(currentSlot->dbPath);
	if (initDB != CKR_OK) {
		free(soPIN);
		delete softDB;
		//  DEBUG_MSG("C_InitToken", "Could not create a connection to the database");
		return CKR_DEVICE_ERROR;
	}
    const char* number_unlock = "0";
	// Add token info
	softDB->saveTokenInfo(DB_TOKEN_LABEL, (char*) pLabel, 32);
	softDB->saveTokenInfo(DB_TOKEN_SOPIN, soPIN, strlen(soPIN));
    softDB->saveTokenInfo(DB_TOKEN_IMEI, (char*) pImei, strlen((const char*)pImei));
    softDB->saveTokenInfo(DB_TOKEN_UNLOCK , (char*) number_unlock, strlen((const char*)number_unlock));

	// Close
    free(soPIN);
	delete softDB;

	currentSlot->readDB();

	//	// DEBUG_MSG("C_InitToken", "OK");
	return initDB;
}
