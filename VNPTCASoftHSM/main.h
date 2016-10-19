/* $Id: main.h 5299 2011-07-07 11:09:10Z rb $ */

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

#ifndef SOFTHSM_MAIN_H
#define SOFTHSM_MAIN_H 1

#include "cryptoki.h"

class SoftSession;
static const char VERSION_MAJOR = ' ';
static const char VERSION_MINOR = ' ';
//static const int MAX_SESSION_COUNT;
//static const int MAX_PIN_LEN;
//static const int MIN_PIN_LEN;

CK_RV generateRsaKeyPair(CK_SESSION_HANDLE hSession, CK_BBOOL bTokenPuk,
                         CK_BBOOL bPrivatePuk, CK_BBOOL bTokenPrk, CK_BBOOL bPrivatePrk,
                         CK_OBJECT_HANDLE &hPuk, CK_OBJECT_HANDLE &hPrk, CK_ULONG keyLength, char* cID);
long genPKCS10Request(CK_SESSION_HANDLE sessionID, CK_SLOT_ID slotInitToken,
                      CK_UTF8CHAR userPin[], CK_ULONG handleKey);
unsigned char* GetPublicKeyValue(long hsession, long handle);
CK_RV importCert(CK_SESSION_HANDLE sessionID, const char* str, const char* s);
CK_RV ChangeData(int sessionId, int handleKey, const char* oldPin, const char* newPin);

CK_RV rsaKeyGen(SoftSession *session, CK_ATTRIBUTE_PTR pPublicKeyTemplate,
      CK_ULONG ulPublicKeyAttributeCount, CK_ATTRIBUTE_PTR pPrivateKeyTemplate, CK_ULONG ulPrivateKeyAttributeCount,
      CK_OBJECT_HANDLE_PTR phPublicKey, CK_OBJECT_HANDLE_PTR phPrivateKey);

#endif /* SOFTHSM_MAIN_H */
