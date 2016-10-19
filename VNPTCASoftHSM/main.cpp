#include "config.h"
#include "main.h"
//#include "log.h"
#include "botan/botan_compat.h"
#include "file.h"
#include "SoftHSMInternal.h"
#include "userhandling.h"
#include "util.h"
#include "mechanisms.h"
#include "string.h"
#include "MutexFactory.h"
// Standard includes
#include <stdio.h>
#include <stdlib.h>
#include <memory>
//#include <sstream>
#include "botan/x509self.h"
//#include "botan/pkcs10.h"
// C POSIX library header
#include <ctime>
#include <assert.h>

// Includes for the crypto library
#include "botan/init.h"
#include "botan/md5.h"
#include "botan/rmd160.h"
#include "botan/sha160.h"
#include "botan/sha2_32.h"
#include "botan/sha2_64.h"
#include "botan/filters.h"
#include "botan/pipe.h"
#include "botan/emsa3.h"
#include "botan/emsa4.h"
#include "botan/emsa_raw.h"
#include "botan/eme_pkcs.h"
#include "botan/pk_keys.h"
#include "botan/bigint.h"
#include "botan/rsa.h"
//#include "pkcs11wrapper/Converter.h"
//#include <jni.h>
#include <vector>
#include <iterator>

using namespace std;

// Slots
#define SLOT_INVALID 9999
#define SLOT_INIT_TOKEN 0
#define SLOT_NO_INIT_TOKEN 1

// PIN
#define SLOT_0_SO1_PIN "12345678"
#define SLOT_0_SO2_PIN "123456789"
#define SLOT_0_USER1_PIN "12345678"
#define SLOT_0_USER2_PIN "12345"
#define jLongToCKULong(x) ((CK_ULONG) x)

// CKA_TOKEN
const CK_BBOOL ON_TOKEN = CK_TRUE;
const CK_BBOOL IN_SESSION = CK_FALSE;

// CKA_PRIVATE
const CK_BBOOL IS_PRIVATE = CK_TRUE;
const CK_BBOOL IS_PUBLIC = CK_FALSE;

// Dung de sinh Keypair va PKCS#10 request
CK_SESSION_HANDLE mSessionRW;
CK_OBJECT_HANDLE mPuk = CK_INVALID_HANDLE;
CK_OBJECT_HANDLE mPrk = CK_INVALID_HANDLE;
extern FILE* of;
const char* uPIN;
//LOG
//#include <android/log.h>
//
//#define  LOG_TAG    "main.cpp"
//#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
// Keeps the internal state
std::auto_ptr<SoftHSMInternal> state(NULL);

// A list with Cryptoki version number
// and pointers to the API functions.
CK_FUNCTION_LIST_s function_list = { { 2, 20 }, C_Initialize_s, C_Finalize,
		C_GetInfo, C_GetFunctionList, C_GetSlotList_s, C_GetSlotInfo,
		C_GetTokenInfo_s, C_GetMechanismList, C_GetMechanismInfo, C_InitToken_s,
		C_InitPIN_s, C_SetPIN_s, C_OpenSession_s, C_CloseSession_s, C_CloseAllSessions_s,
		C_GetSessionInfo, C_GetOperationState, C_SetOperationState, C_Login_s,
		C_Logout_s, C_CreateObject, C_CopyObject, C_DestroyObject,
		C_GetObjectSize, C_GetAttributeValue_s, C_SetAttributeValue,
		C_FindObjectsInit_s, C_FindObjects_s, C_FindObjectsFinal_s, C_EncryptInit,
		C_Encrypt, C_EncryptUpdate, C_EncryptFinal, C_DecryptInit_s, C_Decrypt_s,
		C_DecryptUpdate, C_DecryptFinal, C_DigestInit_s, C_Digest_s, C_DigestUpdate,
		C_DigestKey, C_DigestFinal, C_SignInit_s, C_Sign_s, C_SignUpdate,
		C_SignFinal_s, C_SignRecoverInit, C_SignRecover, C_VerifyInit, C_Verify,
		C_VerifyUpdate, C_VerifyFinal, C_VerifyRecoverInit, C_VerifyRecover,
		C_DigestEncryptUpdate, C_DecryptDigestUpdate, C_SignEncryptUpdate,
		C_DecryptVerifyUpdate, C_GenerateKey, C_GenerateKeyPair_s, C_WrapKey,
		C_UnwrapKey, C_DeriveKey, C_SeedRandom, C_GenerateRandom,
		C_GetFunctionStatus, C_CancelFunction, C_WaitForSlotEvent };
extern CK_FUNCTION_LIST_s function_list;

//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_rsaKeyGen(
//		SoftSession *session, CK_ATTRIBUTE_PTR pPublicKeyTemplate,
//		CK_ULONG ulPublicKeyAttributeCount,
//		CK_ATTRIBUTE_PTR pPrivateKeyTemplate,
//		CK_ULONG ulPrivateKeyAttributeCount, CK_OBJECT_HANDLE_PTR phPublicKey,
//		CK_OBJECT_HANDLE_PTR phPrivateKey) {
//	return (jlong) rsaKeyGen(session, pPublicKeyTemplate,
//			ulPublicKeyAttributeCount, pPrivateKeyTemplate,
//			ulPrivateKeyAttributeCount, phPublicKey, phPrivateKey);
//}
// Initialize the labrary

CK_RV C_Initialize_s(CK_VOID_PTR pInitArgs) {
	//DEBUG_MSG("C_Initialize", "Calling");

	//CHECK_DEBUG_RETURN(state.get() != NULL, "C_Initialize", "Already initialized",
	//	CKR_CRYPTOKI_ALREADY_INITIALIZED);

	SoftHSMInternal *softHSM = NULL;
	CK_C_INITIALIZE_ARGS_PTR_s args = (CK_C_INITIALIZE_ARGS_PTR_s) pInitArgs;

	// Do we have any arguments?
	if (args != NULL_PTR) {
		// Reserved for future use. Must be NULL_PTR
		//CHECK_DEBUG_RETURN(args->pReserved != NULL_PTR, "C_Initialize",
		//	"pReserved must be NULL_PTR", CKR_ARGUMENTS_BAD);

		// Are we not supplied with mutex functions?
		if (args->CreateMutex == NULL_PTR && args->DestroyMutex == NULL_PTR
				&& args->LockMutex == NULL_PTR && args->UnlockMutex == NULL_PTR) {

			// Can we create our own mutex functions?
			if (args->flags & CKF_OS_LOCKING_OK) {
				// Use our own mutex functions.
				MutexFactory::i()->setCreateMutex(OSCreateMutex);
				MutexFactory::i()->setDestroyMutex(OSDestroyMutex);
				MutexFactory::i()->setLockMutex(OSLockMutex);
				MutexFactory::i()->setUnlockMutex(OSUnlockMutex);
				MutexFactory::i()->enable();
			} else {
				// The external application is not using threading
				MutexFactory::i()->disable();
			}
		} else {
			// We must have all mutex functions
			//CHECK_DEBUG_RETURN(args->CreateMutex == NULL_PTR || args->DestroyMutex == NULL_PTR ||
			//	args->LockMutex == NULL_PTR || args->UnlockMutex == NULL_PTR,
			//	"C_Initialize", "Not all mutex functions are supplied", CKR_ARGUMENTS_BAD);

			MutexFactory::i()->setCreateMutex(args->CreateMutex);
			MutexFactory::i()->setDestroyMutex(args->DestroyMutex);
			MutexFactory::i()->setLockMutex(args->LockMutex);
			MutexFactory::i()->setUnlockMutex(args->UnlockMutex);
			MutexFactory::i()->enable();
		}
	} else {
		// No concurrent access by multiple threads
		MutexFactory::i()->disable();
	}

	softHSM = new SoftHSMInternal();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Initialize", "Coult not allocate memory", CKR_HOST_MEMORY);
	state = std::auto_ptr<SoftHSMInternal>(softHSM);

	//	CK_RV rv = readConfigFile();
	//	if (rv != CKR_OK) {
	//		state.reset(NULL);
	//		//DEBUG_MSG("C_Initialize", "Error in config file");
	//		return rv;
	//	}

	// Init the Botan crypto library
	Botan::LibraryInitializer::initialize("thread_safe=true");

	//DEBUG_MSG("C_Initialize", "OK");
	return CKR_OK;
}

// Finalizes the library. Clears out any memory allocations.

CK_RV C_Finalize(CK_VOID_PTR pReserved) {
	//DEBUG_MSG("C_Finalize", "Calling");

	// Reserved for future use.
	//CHECK_DEBUG_RETURN(pReserved != NULL_PTR, "C_Finalize", "pReserved must be NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	//CHECK_DEBUG_RETURN(state.get() == NULL, "C_Finalize", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	state.reset(NULL);

	// Deinitialize the Botan crypto lib
	Botan::LibraryInitializer::deinitialize();

	//DEBUG_MSG("C_Finalize", "OK");
	return CKR_OK;
}

// Returns general information about SoftHSM.

CK_RV C_GetInfo(CK_INFO_PTR_s pInfo) {
	//DEBUG_MSG("C_GetInfo", "Calling");

	//CHECK_DEBUG_RETURN(state.get() == NULL, "C_GetInfo", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
	//CHECK_DEBUG_RETURN(pInfo == NULL_PTR, "C_GetInfo", "pInfo must not be a NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	pInfo->cryptokiVersion.major = 2;
	pInfo->cryptokiVersion.minor = 20;
	memset(pInfo->manufacturerID, ' ', 32);
	memcpy(pInfo->manufacturerID, "SoftHSM", 7);
	pInfo->flags = 0;
	memset(pInfo->libraryDescription, ' ', 32);
	memcpy(pInfo->libraryDescription, "Implementation of PKCS11", 24);
	//	pInfo->libraryVersion.major = VERSION_MAJOR;
	//	pInfo->libraryVersion.minor = VERSION_MINOR;

	//DEBUG_MSG("C_GetInfo", "OK");
	return CKR_OK;
}

// Returns the function list.

CK_RV C_GetFunctionList(CK_FUNCTION_LIST_PTR_PTR_s ppFunctionList) {
	//DEBUG_MSG("C_GetFunctionList", "Calling");

	//CHECK_DEBUG_RETURN(ppFunctionList == NULL_PTR, "C_GetFunctionList",
	//	"ppFunctionList must not be a NULL_PTR", CKR_ARGUMENTS_BAD);

	*ppFunctionList = &function_list;

	//DEBUG_MSG("C_GetFunctionList", "OK");
	return CKR_OK;
}

// Returns a list of all the slots.
// Only one slot is available, SlotID 1.
// And the token is present.

CK_RV C_GetSlotList_s(CK_BBOOL tokenPresent, CK_SLOT_ID_PTR pSlotList,
		CK_ULONG pulCount)
{
	//DEBUG_MSG("C_GetSlotList", "Calling");

#ifdef SOFTHSM_DB
	LOGI("C_GetSlotList");
#endif
	
	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GetSlotList", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
	//CHECK_DEBUG_RETURN(pulCount == NULL_PTR, "C_GetSlotList", "pulCount must not be a NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	int nrToken = 0;
	int nrTokenPresent = 0;

	// Count the number of slots
	if (softHSM == NULL_PTR)

	SoftSlot* slotToken = softHSM->slots;

//	while (slotToken->getNextSlot() != NULL_PTR) {
//
//		if ((slotToken->slotFlags & CKF_TOKEN_PRESENT) == CKF_TOKEN_PRESENT) {
//			nrTokenPresent++;
//		}
//		nrToken++;
//
//		slotToken = slotToken->getNextSlot();
//	}
	
	// What buffer size should we use?
	unsigned int bufSize = 0;
	if (tokenPresent == CK_TRUE) {
		bufSize = nrTokenPresent;
	} else {
		bufSize = nrToken;
	}

	// The user wants the buffer size
	if (pSlotList == NULL_PTR) {
		pulCount = bufSize;

		//DEBUG_MSG("C_GetSlotList", "OK, returning list length");
		return CKR_OK;
	}
	// Is the given buffer to small?
	if (pulCount < bufSize) {
		pulCount = bufSize;

		//DEBUG_MSG("C_GetSlotList", "The buffer is too small");
		return CKR_BUFFER_TOO_SMALL;
	}
//	slotToken = softHSM->slots;
//	int counter = 0;
//	// Get all slotIDs
//	while (slotToken->getNextSlot() != NULL_PTR) {
//		if (tokenPresent == CK_FALSE
//				|| (slotToken->slotFlags & CKF_TOKEN_PRESENT)
//						== CKF_TOKEN_PRESENT) {
//			pSlotList[counter++] = slotToken->getSlotID();
//			
//		}
//		slotToken = slotToken->getNextSlot();
//	}
	pulCount = bufSize;

	//DEBUG_MSG("C_GetSlotList", "OK, returning list");

#ifdef SOFTHSM_DB
	LOGI(" Label of slotToke 0: slotToken->tokenLabel = %s" , slotToken->tokenLabel);
#endif

	return pSlotList[0];
}

// Returns information about the slot.

CK_RV C_GetSlotInfo(CK_SLOT_ID slotID, CK_SLOT_INFO_PTR_s pInfo) {
	//DEBUG_MSG("C_GetSlotInfo", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GetSlotInfo", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
	//CHECK_DEBUG_RETURN(pInfo == NULL_PTR, "C_GetSlotInfo", "pInfo must not be a NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	SoftSlot *currentSlot = softHSM->slots->getSlot(slotID);

	//CHECK_DEBUG_RETURN(currentSlot == NULL_PTR, "C_GetSlotInfo", "The given slotID does not exist",
	//	CKR_SLOT_ID_INVALID);

	memset(pInfo->slotDescription, ' ', 64);
	memcpy(pInfo->slotDescription, "SoftHSM", 7);
	memset(pInfo->manufacturerID, ' ', 32);
	memcpy(pInfo->manufacturerID, "SoftHSM", 7);

	pInfo->flags = currentSlot->slotFlags;
	pInfo->hardwareVersion.major = VERSION_MAJOR;
	pInfo->hardwareVersion.minor = VERSION_MINOR;
	pInfo->firmwareVersion.major = VERSION_MAJOR;
	pInfo->firmwareVersion.minor = VERSION_MINOR;

	//DEBUG_MSG("C_GetSlotInfo", "OK");
	return CKR_OK;
}

// Returns information about the token.

CK_RV C_GetTokenInfo_s(CK_SLOT_ID slotID, CK_TOKEN_INFO_PTR_s pInfo) {
	//DEBUG_MSG("C_GetTokenInfo", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GetTokenInfo", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
	//CHECK_DEBUG_RETURN(pInfo == NULL_PTR, "C_GetTokenInfo", "pInfo must not be a NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	SoftSlot *currentSlot = softHSM->slots->getSlot(slotID);

	//CHECK_DEBUG_RETURN(currentSlot == NULL_PTR, "C_GetTokenInfo", "The given slotID does not exist",
	//	CKR_SLOT_ID_INVALID);
	//CHECK_DEBUG_RETURN((currentSlot->slotFlags & CKF_TOKEN_PRESENT) == 0, "C_GetTokenInfo",
	//	"The token is not present", CKR_TOKEN_NOT_PRESENT);

	if (currentSlot->tokenLabel == NULL_PTR) {
		memset(pInfo->label, ' ', 32);
	} else {
		memcpy(pInfo->label, currentSlot->tokenLabel, 32);
	}
	memset(pInfo->manufacturerID, ' ', 32);
	memcpy(pInfo->manufacturerID, "SoftHSM", 7);
	memset(pInfo->model, ' ', 16);
	memcpy(pInfo->model, "SoftHSM", 7);
	memset(pInfo->serialNumber, ' ', 16);
	memcpy(pInfo->serialNumber, "1", 1);

	pInfo->flags = currentSlot->tokenFlags;
	pInfo->ulMaxSessionCount = MAX_SESSION_COUNT;
	pInfo->ulSessionCount = softHSM->getSessionCount();
	pInfo->ulMaxRwSessionCount = MAX_SESSION_COUNT;
	pInfo->ulRwSessionCount = softHSM->getSessionCount();
	pInfo->ulMaxPinLen = MAX_PIN_LEN;
	pInfo->ulMinPinLen = MIN_PIN_LEN;
	pInfo->ulTotalPublicMemory = CK_UNAVAILABLE_INFORMATION;
	pInfo->ulFreePublicMemory = CK_UNAVAILABLE_INFORMATION;
	pInfo->ulTotalPrivateMemory = CK_UNAVAILABLE_INFORMATION;
	pInfo->ulFreePrivateMemory = CK_UNAVAILABLE_INFORMATION;
	pInfo->hardwareVersion.major = VERSION_MAJOR;
	pInfo->hardwareVersion.minor = VERSION_MINOR;
	pInfo->firmwareVersion.major = VERSION_MAJOR;
	pInfo->firmwareVersion.minor = VERSION_MINOR;

	time_t rawtime;
	time(&rawtime);
	char dateTime[17];
	strftime(dateTime, 17, "%Y%m%d%H%M%S00", gmtime(&rawtime));
	memcpy(pInfo->utcTime, dateTime, 16);

	//DEBUG_MSG("C_GetTokenInfo", "OK");
	return CKR_OK;
}

// Returns the supported mechanisms.

CK_RV C_GetMechanismList(CK_SLOT_ID slotID,
		CK_MECHANISM_TYPE_PTR pMechanismList, CK_ULONG_PTR pulCount) {
	//DEBUG_MSG("C_GetMechanismList", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GetMechanismList", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
	//CHECK_DEBUG_RETURN(pulCount == NULL_PTR, "C_GetMechanismList", "pulCount must not be a NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	SoftSlot *currentSlot = softHSM->slots->getSlot(slotID);

	//CHECK_DEBUG_RETURN(currentSlot == NULL_PTR, "C_GetMechanismList", "The given slotID does note exist",
	//	CKR_SLOT_ID_INVALID);

	if (pMechanismList == NULL_PTR) {
		*pulCount = NR_SUPPORTED_MECHANISMS;

		//DEBUG_MSG("C_GetMechanismList", "OK, returning list length");
		return CKR_OK;
	}

	if (*pulCount < NR_SUPPORTED_MECHANISMS) {
		*pulCount = NR_SUPPORTED_MECHANISMS;

		//DEBUG_MSG("C_GetMechanismList", "Buffer to small");
		return CKR_BUFFER_TOO_SMALL;
	}

	*pulCount = NR_SUPPORTED_MECHANISMS;

	for (int i = 0; i < NR_SUPPORTED_MECHANISMS; i++) {
		pMechanismList[i] = supportedMechanisms[i];
	}

	//DEBUG_MSG("C_GetMechanismList", "OK, returning list");
	return CKR_OK;
}

// Returns information about a mechanism.

CK_RV C_GetMechanismInfo(CK_SLOT_ID slotID, CK_MECHANISM_TYPE type,
		CK_MECHANISM_INFO_PTR_s pInfo) {
	//DEBUG_MSG("C_GetMechanismInfo", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GetMechanismInfo", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSlot *currentSlot = softHSM->slots->getSlot(slotID);

	//CHECK_DEBUG_RETURN(currentSlot == NULL_PTR, "C_GetMechanismInfo", "The given slotID does not exist",
	//	CKR_SLOT_ID_INVALID);

	return getMechanismInfo(type, pInfo);
}

CK_RV C_InitToken_s(CK_SLOT_ID slotID, CK_UTF8CHAR_PTR pPin, CK_ULONG ulPinLen,
		CK_UTF8CHAR_PTR pLabel, CK_UTF8CHAR_PTR pImei) {
	//DEBUG_MSG("C_InitToken", "Calling");

	if (!state.get()) {
		state = std::auto_ptr<SoftHSMInternal>(new SoftHSMInternal());
	}
	SoftHSMInternal *softHSM = state.get();

	CK_RV rv = softHSM->initToken(slotID, pPin, ulPinLen, pLabel, pImei);

	return rv;
}

CK_RV C_InitPIN_s(CK_SESSION_HANDLE hSession, CK_UTF8CHAR_PTR pPin,
		CK_ULONG ulPinLen) {
	//DEBUG_MSG("C_InitPIN", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_InitPIN", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->initPIN(hSession, pPin, ulPinLen);

	return rv;
}

CK_RV C_SetPIN_s(CK_SESSION_HANDLE hSession, CK_UTF8CHAR_PTR pOldPin,
		CK_ULONG ulOldLen, CK_UTF8CHAR_PTR pNewPin, CK_ULONG ulNewLen) {
	//DEBUG_MSG("C_SetPIN", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_SetPIN", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->setPIN(hSession, pOldPin, ulOldLen, pNewPin, ulNewLen);

	return rv;
}

// Opens a new session.

CK_RV C_OpenSession_s(CK_SLOT_ID slotID, CK_FLAGS flags, CK_VOID_PTR pApplication,
		CK_NOTIFY Notify, CK_SESSION_HANDLE_PTR phSession) {
    
    if (!state.get())
    {
            state = std::auto_ptr<SoftHSMInternal>(new SoftHSMInternal());
    }
	SoftHSMInternal *softHSM = state.get();
	if (softHSM == NULL) {
		return 14;
	}

	CK_RV rv = softHSM->openSession(slotID, flags, pApplication, Notify,
			phSession);

	return rv;
}

// Closes the session with a given handle.

CK_RV C_CloseSession_s(CK_SESSION_HANDLE hSession) {
	//DEBUG_MSG("C_CloseSession", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_CloseSession", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->closeSession(hSession);

	return rv;
}

// Closes all sessions.

CK_RV C_CloseAllSessions_s(CK_SLOT_ID slotID) {
	//DEBUG_MSG("C_CloseAllSessions", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_CloseAllSessions", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->closeAllSessions(slotID);

	return rv;
}

// Returns information about the session.

CK_RV C_GetSessionInfo(CK_SESSION_HANDLE hSession, CK_SESSION_INFO_PTR_s pInfo) {
	//DEBUG_MSG("C_GetSessionInfo", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GetSessionInfo", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->getSessionInfo(hSession, pInfo);

	return rv;
}

CK_RV C_GetOperationState(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG_PTR) {
	//DEBUG_MSG("C_GetOperationState", "Calling");
	//DEBUG_MSG("C_GetOperationState", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_SetOperationState(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG,
		CK_OBJECT_HANDLE, CK_OBJECT_HANDLE) {
	//DEBUG_MSG("C_SetOperationState", "Calling");
	//DEBUG_MSG("C_SetOperationState", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

// Logs a user into the token.
// Only one login is needed, since it is a cross-session login.

CK_RV C_Login_s(CK_SESSION_HANDLE hSession, CK_USER_TYPE userType,
		CK_UTF8CHAR_PTR pPin, CK_ULONG ulPinLen) {
	//DEBUG_MSG("C_Login", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Login", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
    uPIN = (const char*)pPin;
	CK_RV rv = softHSM->login(hSession, userType, pPin, ulPinLen);

	return rv;
}

// Logs out the user from the token.
// Closes all the objects.

CK_RV C_Logout_s(CK_SESSION_HANDLE hSession) {
	//DEBUG_MSG("C_Logout", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Logout", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->logout(hSession);

	return rv;
}

CK_RV C_CreateObject(CK_SESSION_HANDLE hSession, CK_ATTRIBUTE_PTR pTemplate,
		CK_ULONG ulCount, CK_OBJECT_HANDLE_PTR phObject) {
	//DEBUG_MSG("C_CreateObject", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_CreateObject", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->createObject(hSession, pTemplate, ulCount, phObject);

	return rv;
}

CK_RV C_CopyObject(CK_SESSION_HANDLE, CK_OBJECT_HANDLE, CK_ATTRIBUTE_PTR,
		CK_ULONG, CK_OBJECT_HANDLE_PTR) {
	//DEBUG_MSG("C_CopyObject", "Calling");
	//DEBUG_MSG("C_CopyObject", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

// Destroys the object.

CK_RV C_DestroyObject(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject) {
	//DEBUG_MSG("C_DestroyObject", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_DestroyObject", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->destroyObject(hSession, hObject);

	return rv;
}

CK_RV C_GetObjectSize(CK_SESSION_HANDLE, CK_OBJECT_HANDLE, CK_ULONG_PTR) {
	//DEBUG_MSG("C_GetObjectSize", "Calling");
	//DEBUG_MSG("C_GetObjectSize", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

//lấy các thuộc tính của đối tượng
CK_RV C_GetAttributeValue_s(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject,
		CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount) {
	//DEBUG_MSG("C_GetAttributeValue", "Calling");
	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GetAttributeValue", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->getAttributeValue(hSession, hObject, pTemplate,
			ulCount);

	return rv;
}
//thêm hoặc thay đổi các thuộc tính của đối tượng
CK_RV C_SetAttributeValue(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hObject,
		CK_ATTRIBUTE_PTR pTemplate, CK_ULONG ulCount) {
	//DEBUG_MSG("C_SetAttributeValue", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_SetAttributeValue", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->setAttributeValue(hSession, hObject, pTemplate,
			ulCount);

	return rv;
}

//khởi tạo chức năng tìm kiếm đối tượng theo giá trị trong template

CK_RV C_FindObjectsInit_s(CK_SESSION_HANDLE hSession, CK_ATTRIBUTE_PTR pTemplate,
		CK_ULONG ulCount) {
	//DEBUG_MSG("C_FindObjectsInit", "Calling");
	//CK_RV rv = 0;
	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_FindObjectsInit", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	CK_RV rv = softHSM->findObjectsInit(hSession, pTemplate, ulCount);

	return rv;
}

// lấy kết quả tìm kiếm sau khi đã khởi tạo chức năng tìm kiếm

CK_RV C_FindObjects_s(CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE_PTR phObject,
		CK_ULONG ulMaxObjectCount, CK_ULONG_PTR pulObjectCount) {
	//DEBUG_MSG("C_FindObjects", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_FindObjects", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_FindObjects", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->findInitialized) {
		//DEBUG_MSG("C_FindObjects", "Find is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (phObject == NULL_PTR || pulObjectCount == NULL_PTR) {
		//DEBUG_MSG("C_FindObjects", "The arguments must not be NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	CK_ULONG i = 0;

	while (i < ulMaxObjectCount && session->findCurrent->next != NULL_PTR) {
        phObject[i] = session->findCurrent->findObject;
		session->findCurrent = session->findCurrent->next;
		i++;
	}
	*pulObjectCount = i;
    //DEBUG_MSG("C_FindObjects", "OK");
	return CKR_OK;
}

// kết thúc việc tìm kiếm sau khi đã khởi tạo chức năng tìm kiếm.

CK_RV C_FindObjectsFinal_s(CK_SESSION_HANDLE hSession) {
	//DEBUG_MSG("C_FindObjectsFinal", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_FindObjectsFinal", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_FindObjectsFinal", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->findInitialized) {
		//DEBUG_MSG("C_FindObjectsFinal", "Find is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}
	//đặt lại giá trị
	DELETE_PTR(session->findAnchor);
	session->findCurrent = NULL_PTR;
	session->findInitialized = false;

	//DEBUG_MSG("C_FindObjectsFinal", "OK");
	return CKR_OK;
}
//khởi tạo cơ chế mã hóa
CK_RV C_EncryptInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism,
		CK_OBJECT_HANDLE hKey) {
	//DEBUG_MSG("C_EncryptInit", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_EncryptInit", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
	//CHECK_DEBUG_RETURN(pMechanism == NULL_PTR, "C_EncryptInit", "pMechanism must not be NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	SoftSession *session = softHSM->getSession(hSession);
	if (session == NULL_PTR) {
		//DEBUG_MSG("C_EncryptInit", "Cannot find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	// Kiểm tra đã khởi tạo cơ chế mã hóa chưa
	if (session->encryptInitialized) {
		//DEBUG_MSG("C_EncryptInit", "Encrypt is already initialized");
		return CKR_OPERATION_ACTIVE;
	}

	// lấy public key từ hKey
	Botan::Public_Key *cryptoKey = session->getKey(hKey);
	if (cryptoKey == NULL_PTR) {
		//DEBUG_MSG("C_EncryptInit", "The key could not be found");
		return CKR_KEY_HANDLE_INVALID;
	}

	// kiểm tra quyền người dùng
	CK_BBOOL userAuth = userAuthorization(session->getSessionState(),
			session->db->getBooleanAttribute(hKey, CKA_TOKEN, CK_TRUE),
			session->db->getBooleanAttribute(hKey, CKA_PRIVATE, CK_TRUE), 0);
	if (userAuth == CK_FALSE) {
		//DEBUG_MSG("C_EncryptInit", "User is not authorized");
		return CKR_KEY_HANDLE_INVALID;
	}

	// kiểm tra hkey có phải public key của RSA không
	if (session->db->getObjectClass(hKey) != CKO_PUBLIC_KEY
			|| session->db->getKeyType(hKey) != CKK_RSA) {
		//DEBUG_MSG("C_EncryptInit", "Only an RSA public key can be used");
		return CKR_KEY_TYPE_INCONSISTENT;
	}

	// kiểm tra hkey có mã hóa được không
	if (session->db->getBooleanAttribute(hKey, CKA_ENCRYPT, CK_TRUE) == CK_FALSE) {
		//DEBUG_MSG("C_EncryptInit", "This key does not support encryption");
		return CKR_KEY_FUNCTION_NOT_PERMITTED;
	}

	session->encryptSinglePart = false;

#ifdef BOTAN_PRE_1_9_4_FIX
	Botan::EME *eme = NULL_PTR;

	// Selects the correct padding.
	switch(pMechanism->mechanism) {
		case CKM_RSA_PKCS:
		eme = new Botan::EME_PKCS1v15();
		session->encryptSinglePart = true;
		break;
		default:
		//DEBUG_MSG("C_EncryptInit", "The selected mechanism is not supported");
		return CKR_MECHANISM_INVALID;
		break;
	}

	if(eme == NULL_PTR) {
		//DEBUG_MSG("C_EncryptInit", "Could not create the padding");
		return CKR_DEVICE_MEMORY;
	}
#else
	std::string eme;

	// Selects the correct padding.
	switch (pMechanism->mechanism) {
	case CKM_RSA_PKCS:
		eme = "EME-PKCS1-v1_5";
		session->encryptSinglePart = true;
		break;
	default:
		//DEBUG_MSG("C_EncryptInit", "The selected mechanism is not supported");
		return CKR_MECHANISM_INVALID;
		break;
	}
#endif

	// Creates the encryptor with given key and mechanism.
	try {
#ifdef BOTAN_PRE_1_9_4_FIX
		Botan::PK_Encrypting_Key *encryptKey = dynamic_cast<Botan::PK_Encrypting_Key*>(cryptoKey);
		session->encryptSize = (cryptoKey->max_input_bits() + 8) / 8;
		session->pkEncryptor = new Botan::PK_Encryptor_MR_with_EME(*encryptKey, &*eme);
#else
		session->encryptSize = (cryptoKey->max_input_bits() + 8) / 8;
		session->pkEncryptor = new Botan::PK_Encryptor_EME(*cryptoKey, eme);
#endif
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg),"Could not create the encryption function: %s", e.what());
		//ERROR_MSG("C_EncryptInit", errorMsg);
		return CKR_GENERAL_ERROR;
	}

	if (!session->pkEncryptor) {
		//ERROR_MSG("C_EncryptInit", "Could not create the encryption function");
		return CKR_DEVICE_MEMORY;
	}

	session->encryptInitialized = true;

	//DEBUG_MSG("C_EncryptInit", "OK");
	return CKR_OK;
}
//mã hóa sau khi đã khởi tạo
CK_RV C_Encrypt(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData,
		CK_ULONG ulDataLen, CK_BYTE_PTR pEncryptedData,
		CK_ULONG_PTR pulEncryptedDataLen) {
	//DEBUG_MSG("C_Encrypt", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Encrypt", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);
	if (session == NULL_PTR) {
		//DEBUG_MSG("C_Encrypt", "Cannot find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->encryptInitialized) {
		//DEBUG_MSG("C_Encrypt", "Encrypt is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (pulEncryptedDataLen == NULL_PTR) {
		//DEBUG_MSG("C_Encrypt", "pulEncryptedDataLen must not be a NULL_PTR")

		//đặt lại giá trị
		session->encryptSize = 0;
		delete session->pkEncryptor;
		session->pkEncryptor = NULL_PTR;
		session->encryptInitialized = false;

		return CKR_ARGUMENTS_BAD;
	}

	if (pEncryptedData == NULL_PTR) {
		*pulEncryptedDataLen = session->encryptSize;

		//DEBUG_MSG("C_Encrypt", "OK, returning the size of the encrypted data");
		return CKR_OK;
	}

	if (*pulEncryptedDataLen < session->encryptSize) {
		*pulEncryptedDataLen = session->encryptSize;

		//DEBUG_MSG("C_Encrypt", "The given buffer is too small");
		return CKR_BUFFER_TOO_SMALL;
	}

	if (pData == NULL_PTR) {
		//DEBUG_MSG("C_Encrypt", "pData must not be a NULL_PTR");

		//đặt lại giá trị
		session->encryptSize = 0;
		delete session->pkEncryptor;
		session->pkEncryptor = NULL_PTR;
		session->encryptInitialized = false;

		return CKR_ARGUMENTS_BAD;
	}

	// kiểm tra kích thước dữ liệu đầu vào
	if (session->pkEncryptor->maximum_input_size() < ulDataLen) {
		//ERROR_MSG("C_Encrypt", "Input data is too large");

		//đặt lại giá trị
		session->encryptSize = 0;
		delete session->pkEncryptor;
		session->pkEncryptor = NULL_PTR;
		session->encryptInitialized = false;

		return CKR_DATA_LEN_RANGE;
	}

	// mã hóa
	Botan::SecureVector<Botan::byte> encryptResult;
	try {
		encryptResult = session->pkEncryptor->encrypt(pData, ulDataLen,
				*session->rng);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg),"Could not encrypt the data: %s", e.what());
		//ERROR_MSG("C_Encrypt", errorMsg);

		//đặt lại giá trị
		session->encryptSize = 0;
		delete session->pkEncryptor;
		session->pkEncryptor = NULL_PTR;
		session->encryptInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	// trả về kết quả
	memcpy(pEncryptedData, encryptResult.begin(), encryptResult.size());
	*pulEncryptedDataLen = encryptResult.size();

	// đặt lại giá trị
	session->encryptSize = 0;
	delete session->pkEncryptor;
	session->pkEncryptor = NULL_PTR;
	session->encryptInitialized = false;

	//DEBUG_MSG("C_Encrypt", "OK");
	return CKR_OK;
}
//chức năng chưa được hoàn thiện
CK_RV C_EncryptUpdate(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR,
		CK_ULONG_PTR) {
	//DEBUG_MSG("C_EncryptUpdate", "Calling");
	//DEBUG_MSG("C_EncryptUpdate", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}
//chức năng chưa được hoàn thiện
CK_RV C_EncryptFinal(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG_PTR) {
	//DEBUG_MSG("C_EncryptFinal", "Calling");
	//DEBUG_MSG("C_EncryptFinal", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}
//khởi tạo cơ chế giải mã
CK_RV C_DecryptInit_s(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism,
		CK_OBJECT_HANDLE hKey) {
	//DEBUG_MSG("C_DecryptInit", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_DecryptInit", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
	//CHECK_DEBUG_RETURN(pMechanism == NULL_PTR, "C_DecryptInit", "pMechanism must not be NULL_PTR",
	//	CKR_ARGUMENTS_BAD);

	SoftSession *session = softHSM->getSession(hSession);
	if (session == NULL_PTR) {
		//DEBUG_MSG("C_DecryptInit", "Cannot find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	// kiểm tra cơ chế giải mã đã khởi tạo chưa
	if (session->decryptInitialized) {
		//DEBUG_MSG("C_DecryptInit", "Decrypt is already initialized");
		return CKR_OPERATION_ACTIVE;
	}

	// lấy private key
	Botan::Public_Key *cryptoKey = session->getKey(hKey);
	if (cryptoKey == NULL_PTR) {
		//DEBUG_MSG("C_DecryptInit", "The key could not be found");
		return CKR_KEY_HANDLE_INVALID;
	}

	// Kiểm tra quyền người dùng
	CK_BBOOL userAuth = userAuthorization(session->getSessionState(),
			session->db->getBooleanAttribute(hKey, CKA_TOKEN, CK_TRUE),
			session->db->getBooleanAttribute(hKey, CKA_PRIVATE, CK_TRUE), 0);
	if (userAuth == CK_FALSE) {
		//DEBUG_MSG("C_DecryptInit", "User is not authorized");
		return CKR_KEY_HANDLE_INVALID;
	}

	// kiểm tra có phải private key không
	if (session->db->getObjectClass(hKey) != CKO_PRIVATE_KEY
			|| session->db->getKeyType(hKey) != CKK_RSA) {
		//DEBUG_MSG("C_DecryptInit", "Only an RSA private key can be used");
		return CKR_KEY_TYPE_INCONSISTENT;
	}

	// kiểm tra key có khả năng giải mã không ?
//	if (session->db->getBooleanAttribute(hKey, CKA_DECRYPT, CK_TRUE) == CK_FALSE) {
//		//DEBUG_MSG("C_DecryptInit", "This key does not support decryption");
//		return CKR_KEY_FUNCTION_NOT_PERMITTED;
//	}

	session->decryptSinglePart = false;

#ifdef BOTAN_PRE_1_9_4_FIX
	Botan::EME *eme = NULL_PTR;

	// Selects the correct padding.
	switch(pMechanism->mechanism) {
		case CKM_RSA_PKCS:
		eme = new Botan::EME_PKCS1v15();
		session->decryptSinglePart = true;
		break;
		default:
		//DEBUG_MSG("C_DecryptInit", "The selected mechanism is not supported");
		return CKR_MECHANISM_INVALID;
		break;
	}

	if(eme == NULL_PTR) {
		//DEBUG_MSG("C_DecryptInit", "Could not create the padding");
		return CKR_DEVICE_MEMORY;
	}
#else
	std::string eme;

	// Selects the correct padding.
	switch (pMechanism->mechanism) {
	case CKM_RSA_PKCS:
		eme = "EME-PKCS1-v1_5";
		session->decryptSinglePart = true;
		break;
	default:
		//DEBUG_MSG("C_DecryptInit", "The selected mechanism is not supported");
		return CKR_MECHANISM_INVALID;
		break;
	}
#endif

	// Creates the decryptor with given key and mechanism
	try {
#ifdef BOTAN_PRE_1_9_4_FIX
		Botan::PK_Decrypting_Key *decryptKey = dynamic_cast<Botan::PK_Decrypting_Key*>(cryptoKey);
		session->decryptSize = (cryptoKey->max_input_bits() + 8) / 8;
		session->pkDecryptor = new Botan::PK_Decryptor_MR_with_EME(*decryptKey, &*eme);
#else
		session->decryptSize = (cryptoKey->max_input_bits() + 8) / 8;
		session->pkDecryptor = new Botan::PK_Decryptor_EME(
				*dynamic_cast<Botan::Private_Key*>(cryptoKey), eme);
#endif
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not create the decryption function: %s", e.what());
		//ERROR_MSG("C_DecryptInit", errorMsg);
		return CKR_GENERAL_ERROR;
	}

	if (!session->pkDecryptor) {
		//ERROR_MSG("C_DecryptInit", "Could not create the decryption function");
		return CKR_DEVICE_MEMORY;
	}

	session->decryptInitialized = true;

	//DEBUG_MSG("C_DecryptInit", "OK");
	return CKR_OK;
}
//lấy về kết quả giải mã sau khi khởi tạo cơ chế giải mã
CK_RV C_Decrypt_s(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pEncryptedData,
		CK_ULONG ulEncryptedDataLen, CK_BYTE_PTR pData,
		CK_ULONG_PTR pulDataLen) {
	//DEBUG_MSG("C_Decrypt", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Decrypt", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);
	if (session == NULL_PTR) {
		//DEBUG_MSG("C_Decrypt", "Cannot find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->decryptInitialized) {
		//DEBUG_MSG("C_Decrypt", "Decrypt is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (pulDataLen == NULL_PTR) {
		//DEBUG_MSG("C_Decrypt", "pulDataLen must not be a NULL_PTR");

		// đặt lại giá trị
		session->decryptSize = 0;
		delete session->pkDecryptor;
		session->pkDecryptor = NULL_PTR;
		session->decryptInitialized = false;

		return CKR_ARGUMENTS_BAD;
	}

	// PKCS#11: "This number may somewhat exceed the precise number of
	// bytes needed, but should not exceed it by a large amount."
	//
	// We return the maximum output that the RSA key can decrypt.
	// When the data is decrypted, then we know the size.

	if (pData == NULL_PTR) {
		*pulDataLen = session->decryptSize;
		//DEBUG_MSG("C_Decrypt", "OK, returning the size of the decrypted data");
		return CKR_OK;
	}

	if (*pulDataLen < session->decryptSize) {
		*pulDataLen = session->decryptSize;
		//DEBUG_MSG("C_Decrypt", "The given buffer is too small");
		return CKR_BUFFER_TOO_SMALL;
	}

	if (pEncryptedData == NULL_PTR) {
		//DEBUG_MSG("C_Decrypt", "pEncryptedData must not be a NULL_PTR");

		// đặt lại giá trị
		session->decryptSize = 0;
		delete session->pkDecryptor;
		session->pkDecryptor = NULL_PTR;
		session->decryptInitialized = false;

		return CKR_ARGUMENTS_BAD;
	}

	// giải mã
	Botan::SecureVector<Botan::byte> decryptResult;
	try {
		decryptResult = session->pkDecryptor->decrypt(pEncryptedData,
				ulEncryptedDataLen);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg),"Could not decrypt the data: %s", e.what());
		//ERROR_MSG("C_Decrypt", errorMsg);

		// đặt lại giá trị
		session->decryptSize = 0;
		delete session->pkDecryptor;
		session->pkDecryptor = NULL_PTR;
		session->decryptInitialized = false;

		return CKR_ENCRYPTED_DATA_INVALID;
	}

	// trả về kết quả
	memcpy(pData, decryptResult.begin(), decryptResult.size());
	*pulDataLen = decryptResult.size();

	// đặt lại giá trị
	session->decryptSize = 0;
	delete session->pkDecryptor;
	session->pkDecryptor = NULL_PTR;
	session->decryptInitialized = false;

	//DEBUG_MSG("C_Decrypt", "OK");
	return CKR_OK;
}
//chức năng chưa hoàn thiện
CK_RV C_DecryptUpdate(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR,
		CK_ULONG_PTR) {
	//DEBUG_MSG("C_DecryptUpdate", "Calling");
	//DEBUG_MSG("C_DecryptUpdate", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}
//chức năng chưa hoàn thiện
CK_RV C_DecryptFinal(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG_PTR) {
	//DEBUG_MSG("C_DecryptFinal", "Calling");
	//DEBUG_MSG("C_DecryptFinal", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

//khởi tạo chức năng băm dữ liệu
CK_RV C_DigestInit_s(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism) {
	//DEBUG_MSG("C_DigestInit", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_DigestInit", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_DigestInit", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
	//kiểm tra chức năng đã được khởi tạo chưa
	if (session->digestInitialized) {
		//DEBUG_MSG("C_DigestInit", "Digest is already initialized");
		return CKR_OPERATION_ACTIVE;
	}

	if (pMechanism == NULL_PTR) {
		//DEBUG_MSG("C_DigestInit", "pMechanism must not be NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	CK_ULONG mechSize = 0;
	Botan::HashFunction *hashFunc = NULL_PTR;

	// chọn giải thuật băm
	switch (pMechanism->mechanism) {
	case CKM_MD5:
		mechSize = 16;
		hashFunc = new Botan::MD5;
		break;
	case CKM_RIPEMD160:
		mechSize = 20;
		hashFunc = new Botan::RIPEMD_160;
		break;
	case CKM_SHA_1:
		mechSize = 20;
		hashFunc = new Botan::SHA_160;
		break;
	case CKM_SHA256:
		mechSize = 32;
		hashFunc = new Botan::SHA_256;
		break;
	case CKM_SHA384:
		mechSize = 48;
		hashFunc = new Botan::SHA_384;
		break;
	case CKM_SHA512:
		mechSize = 64;
		hashFunc = new Botan::SHA_512;
		break;
	default:
		//DEBUG_MSG("C_DigestInit", "The selected mechanism is not supported");
		return CKR_MECHANISM_INVALID;
		break;
	}

	if (hashFunc == NULL_PTR) {
		//DEBUG_MSG("C_DigestInit", "Could not create the hash function");
		return CKR_DEVICE_MEMORY;
	}

	// tạo giá trị băm theo giải thuật đã chọn
	session->digestSize = mechSize;
	try {
		session->digestPipe = new Botan::Pipe(new Botan::Hash_Filter(hashFunc));
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg),"Could not create the digesting function: %s", e.what());
		//ERROR_MSG("C_DigestInit", errorMsg);
		return CKR_GENERAL_ERROR;
	}

	if (!session->digestPipe) {
		//ERROR_MSG("C_DigestInit", "Could not create the digesting function");
		return CKR_DEVICE_MEMORY;
	}

	session->digestPipe->start_msg();
	session->digestInitialized = true;

	//DEBUG_MSG("C_DigestInit", "OK");
	return CKR_OK;
}

// tạo kết quả băm từ dữ liệu cần băm

CK_RV C_Digest_s(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData,
		CK_ULONG ulDataLen, CK_BYTE_PTR pDigest, CK_ULONG_PTR pulDigestLen) {
	//DEBUG_MSG("C_Digest", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Digest", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_Digest", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
	//kiểm tra hàm băm đã khởi tạo chưa
	if (!session->digestInitialized) {
		//DEBUG_MSG("C_Digest", "Digest is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (pulDigestLen == NULL_PTR) {
		//DEBUG_MSG("C_Digest", "pulDigestLen must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	if (pDigest == NULL_PTR) {
		*pulDigestLen = session->digestSize;
		//DEBUG_MSG("C_Digest", "OK, returning the size of the digest");
		return CKR_OK;
	}

	if (*pulDigestLen < session->digestSize) {
		*pulDigestLen = session->digestSize;
		//DEBUG_MSG("C_Digest", "The given buffer is too small");
		return CKR_BUFFER_TOO_SMALL;
	}

	if (pData == NULL_PTR) {
		//DEBUG_MSG("C_Digest", "pData must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	try {
		// Băm
		session->digestPipe->write(pData, ulDataLen);
		session->digestPipe->end_msg();

		// trả về kết quả
		session->digestPipe->read(pDigest, session->digestSize);
		*pulDigestLen = session->digestSize;
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg),"Could not digest the data: %s", e.what());
		//ERROR_MSG("C_Digest", errorMsg);

		// đặt lại giá trị
		session->digestSize = 0;
		delete session->digestPipe;
		session->digestPipe = NULL_PTR;
		session->digestInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	// đặt lại giá trị
	session->digestSize = 0;
	delete session->digestPipe;
	session->digestPipe = NULL_PTR;
	session->digestInitialized = false;

	//DEBUG_MSG("C_Digest", "OK");
	return CKR_OK;
}

// Thêm dữ liệu cần băm

CK_RV C_DigestUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart,
		CK_ULONG ulPartLen) {
	//DEBUG_MSG("C_DigestUpdate", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_DigestUpdate", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_DigestUpdate", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
	//kiểm tra hàm băm đã khởi tạo chưa
	if (!session->digestInitialized) {
		//DEBUG_MSG("C_DigestUpdate", "Digest is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (pPart == NULL_PTR) {
		//DEBUG_MSG("C_DigestUpdate", "pPart must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	// băm
	try {
		session->digestPipe->write(pPart, ulPartLen);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg),"Could not digest the data: %s", e.what());
		//ERROR_MSG("C_DigestUpdate", errorMsg);

		// đặt lại giá trị
		session->digestSize = 0;
		delete session->digestPipe;
		session->digestPipe = NULL_PTR;
		session->digestInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	//DEBUG_MSG("C_DigestUpdate", "OK");
	return CKR_OK;
}
//chức năng chưa hoàn thiện
CK_RV C_DigestKey(CK_SESSION_HANDLE, CK_OBJECT_HANDLE) {
	//DEBUG_MSG("C_DigestKey", "Calling");
	//DEBUG_MSG("C_DigestKey", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

// lấy dữ liệu băm

CK_RV C_DigestFinal(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pDigest,
		CK_ULONG_PTR pulDigestLen) {
	//DEBUG_MSG("C_DigestFinal", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_DigestFinal", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_DigestFinal", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->digestInitialized) {
		//DEBUG_MSG("C_DigestFinal", "Digest is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (pulDigestLen == NULL_PTR) {
		//DEBUG_MSG("C_DigestFinal", "pulDigestLen must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	if (pDigest == NULL_PTR) {
		*pulDigestLen = session->digestSize;
		//DEBUG_MSG("C_DigestFinal", "OK, returning the size of the digest");
		return CKR_OK;
	}

	if (*pulDigestLen < session->digestSize) {
		*pulDigestLen = session->digestSize;
		//DEBUG_MSG("C_DigestFinal", "The given buffer is too small");
		return CKR_BUFFER_TOO_SMALL;
	}

	try {
		session->digestPipe->end_msg();

		// trả về kết quả
		session->digestPipe->read(pDigest, session->digestSize);
		*pulDigestLen = session->digestSize;
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not digest the data: %s", e.what());
		//ERROR_MSG("C_DigestFinal", errorMsg);

		// đặt lại giá trị
		session->digestSize = 0;
		delete session->digestPipe;
		session->digestPipe = NULL_PTR;
		session->digestInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	// đặt lai giá trị
	session->digestSize = 0;
	delete session->digestPipe;
	session->digestPipe = NULL_PTR;
	session->digestInitialized = false;

	//DEBUG_MSG("C_DigestFinal", "OK");
	return CKR_OK;
}

// khởi tạo chức năng ký

CK_RV C_SignInit_s(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism,
		CK_OBJECT_HANDLE hKey) {
	//DEBUG_MSG("C_SignInit", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_SignInit", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_SignInit", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
	
	// lấy private key
	Botan::Public_Key *cryptoKey = session->getKey(hKey);

	// TODO:
	//   Should also add: session->db->getBooleanAttribute(hKey, CKA_SIGN, CK_TRUE) == CK_FALSE
	//   in the if-statement below. "If this key is allowed to sign data"
	//   Not doing this for now, because you get higher performance.
	//Kiểm tra chữ ký có khả dụng không
	if (cryptoKey == NULL_PTR
			|| session->db->getObjectClass(hKey) != CKO_PRIVATE_KEY
			|| session->db->getKeyType(hKey) != CKK_RSA) {
		//DEBUG_MSG("C_SignInit", "This key can not be used");
		
		return CKR_KEY_HANDLE_INVALID;
	}

	CK_BBOOL userAuth = userAuthorization(session->getSessionState(),
			session->db->getBooleanAttribute(hKey, CKA_TOKEN, CK_TRUE),
			session->db->getBooleanAttribute(hKey, CKA_PRIVATE, CK_TRUE), 0);
	
	//kiểm tra quyền người dùng
	if (userAuth == CK_FALSE) {
		//DEBUG_MSG("C_SignInit", "User is not authorized");
		return CKR_KEY_HANDLE_INVALID;
	}
	//kiểm tra chức năng ký đã khởi tạo chưa
	if (session->signInitialized) {
		//DEBUG_MSG("C_SignInit", "Sign is already initialized");
		return CKR_OPERATION_ACTIVE;
	}

	if (pMechanism == NULL_PTR) {
		//DEBUG_MSG("C_SignInit", "pMechanism must not be NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

#ifndef BOTAN_NO_PK_SIGNER_REUSE
	// kiểm tra có thể dùng lại signer cũ hay ko
	if (!session->pkSigner || session->signMech != pMechanism->mechanism
			|| session->signKey != hKey) {
#endif

		if (session->pkSigner) {
			//xóa signer cũ
			delete session->pkSigner;
			session->pkSigner = NULL;
		}

		session->signSinglePart = false;
#ifdef BOTAN_PRE_1_9_4_FIX
		Botan::EMSA *hashFunc = NULL_PTR;

		// Selects the correct padding and hash algorithm.
		switch(pMechanism->mechanism) {
			case CKM_RSA_PKCS:
			hashFunc = new Botan::EMSA3_Raw();
			session->signSinglePart = true;
			break;
			case CKM_RSA_X_509:
			hashFunc = new Botan::EMSA_Raw();
			session->signSinglePart = true;
			break;
			case CKM_MD5_RSA_PKCS:
			hashFunc = new Botan::EMSA3(new Botan::MD5);
			break;
			case CKM_RIPEMD160_RSA_PKCS:
			hashFunc = new Botan::EMSA3(new Botan::RIPEMD_160);
			break;
			case CKM_SHA1_RSA_PKCS:
			hashFunc = new Botan::EMSA3(new Botan::SHA_160);
			break;
			case CKM_SHA256_RSA_PKCS:
			hashFunc = new Botan::EMSA3(new Botan::SHA_256);
			break;
			case CKM_SHA384_RSA_PKCS:
			hashFunc = new Botan::EMSA3(new Botan::SHA_384);
			break;
			case CKM_SHA512_RSA_PKCS:
			hashFunc = new Botan::EMSA3(new Botan::SHA_512);
			break;
			case CKM_SHA1_RSA_PKCS_PSS:
			if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA_1) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA_1");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA1) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA1");
				return CKR_ARGUMENTS_BAD;
			}
			hashFunc = new Botan::EMSA4(new Botan::SHA_160, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
			break;
			case CKM_SHA256_RSA_PKCS_PSS:
			if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA256) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA256");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA256) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA256");
				return CKR_ARGUMENTS_BAD;
			}
			hashFunc = new Botan::EMSA4(new Botan::SHA_256, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
			break;
			case CKM_SHA384_RSA_PKCS_PSS:
			if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA384) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA384");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA384) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA384");
				return CKR_ARGUMENTS_BAD;
			}
			hashFunc = new Botan::EMSA4(new Botan::SHA_384, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
			break;
			case CKM_SHA512_RSA_PKCS_PSS:
			if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA512) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA512");
				return CKR_ARGUMENTS_BAD;
			}
			if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA512) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA512");
				return CKR_ARGUMENTS_BAD;
			}
			hashFunc = new Botan::EMSA4(new Botan::SHA_512, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
			break;
			default:
			//DEBUG_MSG("C_SignInit", "The selected mechanism is not supported");
			return CKR_MECHANISM_INVALID;
			break;
		}

		if(hashFunc == NULL_PTR) {
			//ERROR_MSG("C_SignInit", "Could not create the hash function");
			return CKR_DEVICE_MEMORY;
		}
#else
		std::string emsa;
		//std::ostringstream request;

		// chọn bộ đệm(padding) và giải thuật băm
		switch (pMechanism->mechanism) {
		case CKM_RSA_PKCS:
			emsa = "EMSA3(Raw)";
			session->signSinglePart = true;
			break;
		case CKM_RSA_X_509:
			emsa = "Raw";
			session->signSinglePart = true;
			break;
		case CKM_MD5_RSA_PKCS:
			emsa = "EMSA3(MD5)";
			break;
		case CKM_RIPEMD160_RSA_PKCS:
			emsa = "EMSA3(RIPEMD-160)";
			break;
		case CKM_SHA1_RSA_PKCS:
			emsa = "EMSA3(SHA-160)";
			break;
		case CKM_SHA256_RSA_PKCS:
			emsa = "EMSA3(SHA-256)";
			break;
		case CKM_SHA384_RSA_PKCS:
			emsa = "EMSA3(SHA-384)";
			break;
		case CKM_SHA512_RSA_PKCS:
			emsa = "EMSA3(SHA-512)";
			break;
		case CKM_SHA1_RSA_PKCS_PSS:
			if (pMechanism->pParameter == NULL_PTR
					|| pMechanism->ulParameterLen
							!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
					!= CKM_SHA_1) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA_1");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
					!= CKG_MGF1_SHA1) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA1");
				return CKR_ARGUMENTS_BAD;
			}
//			request << "EMSA4(SHA-160,MGF1,"
//					<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//					<< ")";
//			emsa = request.str();
			break;
		case CKM_SHA256_RSA_PKCS_PSS:
			if (pMechanism->pParameter == NULL_PTR
					|| pMechanism->ulParameterLen
							!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
					!= CKM_SHA256) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA256");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
					!= CKG_MGF1_SHA256) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA256");
				return CKR_ARGUMENTS_BAD;
			}
//			request << "EMSA4(SHA-256,MGF1,"
//					<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//					<< ")";
//			emsa = request.str();
			break;
		case CKM_SHA384_RSA_PKCS_PSS:
			if (pMechanism->pParameter == NULL_PTR
					|| pMechanism->ulParameterLen
							!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
					!= CKM_SHA384) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA384");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
					!= CKG_MGF1_SHA384) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA384");
				return CKR_ARGUMENTS_BAD;
			}
//			request << "EMSA4(SHA-384,MGF1,"
//					<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//					<< ")";
//			emsa = request.str();
			break;
		case CKM_SHA512_RSA_PKCS_PSS:
			if (pMechanism->pParameter == NULL_PTR
					|| pMechanism->ulParameterLen
							!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
				//DEBUG_MSG("C_SignInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
					!= CKM_SHA512) {
				//DEBUG_MSG("C_SignInit", "hashAlg must be CKM_SHA512");
				return CKR_ARGUMENTS_BAD;
			}
			if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
					!= CKG_MGF1_SHA512) {
				//DEBUG_MSG("C_SignInit", "mgf must be CKG_MGF1_SHA512");
				return CKR_ARGUMENTS_BAD;
			}
//			request << "EMSA4(SHA-512,MGF1,"
//					<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//					<< ")";
//			emsa = request.str();
			break;
		default:
			//DEBUG_MSG("C_SignInit", "The selected mechanism is not supported");
			return CKR_MECHANISM_INVALID;
			break;
		}
#endif
		// tạo signer theo key và cơ chế đã chọn
		try {
#ifdef BOTAN_PRE_1_9_4_FIX
			Botan::PK_Signing_Key *signKey = dynamic_cast<Botan::PK_Signing_Key*>(cryptoKey);
			LOGI("Day");
			session->signSize = (cryptoKey->max_input_bits() + 8) / 8;
			session->pkSigner = new Botan::PK_Signer(*signKey, &*hashFunc);
#else
			session->signSize = (cryptoKey->max_input_bits() + 8) / 8;

			session->pkSigner = new Botan::PK_Signer(
					*dynamic_cast<Botan::Private_Key*>(cryptoKey), emsa);
			//			LOGI("Duoc");
#endif
		} catch (std::exception& e) {
			char errorMsg[1024];
			//snprintf(errorMsg, sizeof(errorMsg), "Could not create the signing function: %s", e.what());
			//ERROR_MSG("C_SignInit", errorMsg);
			return CKR_GENERAL_ERROR;
		}

		if (!session->pkSigner) {
			//ERROR_MSG("C_SignInit", "Could not create the signing function");
			return CKR_DEVICE_MEMORY;
		}

		session->signMech = pMechanism->mechanism;
		session->signKey = hKey;

#ifndef BOTAN_NO_PK_SIGNER_REUSE
	}
#endif

	session->signInitialized = true;

	//DEBUG_MSG("C_SignInit", "OK");
	return CKR_OK;
}

// ký dữ liệu sau khi đã khởi tạo hàm ký và trả về kết quả

CK_RV C_Sign_s(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData, CK_ULONG ulDataLen,
		CK_BYTE_PTR pSignature, CK_ULONG_PTR pulSignatureLen) {
	//DEBUG_MSG("C_Sign", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Sign", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_Sign", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
	//kiểm tra hàm ký đã khởi tạo chưa
	if (!session->signInitialized) {
		//DEBUG_MSG("C_Sign", "Sign is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (pulSignatureLen == NULL_PTR) {
		//DEBUG_MSG("C_Sign", "pulSignatureLen must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	if (pSignature == NULL_PTR) {
		*pulSignatureLen = session->signSize;

		//DEBUG_MSG("C_Sign", "OK, returning the size of the signature");
		return CKR_OK;
	}

	if (*pulSignatureLen < session->signSize) {
		*pulSignatureLen = session->signSize;

		//DEBUG_MSG("C_Sign", "The given buffer is too small");
		return CKR_BUFFER_TOO_SMALL;
	}

	if (pData == NULL_PTR) {
		//DEBUG_MSG("C_Sign", "pData must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	// Ký
	Botan::SecureVector<Botan::byte> signResult;
	try {
		signResult = session->pkSigner->sign_message(pData, ulDataLen,
				*session->rng);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not sign the data: %s", e.what());
		//ERROR_MSG("C_Sign", errorMsg);

		// Đặt lại giá trị
		session->signSize = 0;
		delete session->pkSigner;
		session->pkSigner = NULL_PTR;
		session->signInitialized = false;
		return CKR_GENERAL_ERROR;
	}

	// trả về kết quả
	memcpy(pSignature, signResult.begin(), session->signSize);
	*pulSignatureLen = session->signSize;

	// đặt lại giá trị
	session->signInitialized = false;

	//DEBUG_MSG("C_Sign", "OK");
	return CKR_OK;
}

// lưu dữ liệu vào bộ đệm trước khi kết thúc chức năng ký

CK_RV C_SignUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart,
		CK_ULONG ulPartLen) {
	//DEBUG_MSG("C_SignUpdate", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_SignUpdate", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_SignUpdate", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
	//kiểm tra chức năng ký đã khởi tạo chưa
	if (!session->signInitialized) {
		//DEBUG_MSG("C_SignUpdate", "Sign is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (session->signSinglePart) {
		//DEBUG_MSG("C_SignUpdate", "The mechanism can only sign single part of data");
		return CKR_FUNCTION_NOT_SUPPORTED;
	}

	if (pPart == NULL_PTR) {
		//DEBUG_MSG("C_SignUpdate", "pPart must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	// lưu vào bộ đệm
	try {
		session->pkSigner->update(pPart, ulPartLen);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not buffer the data: %s", e.what());
		//ERROR_MSG("C_SignUpdate", errorMsg);

		// đặt lại giá trị
		session->signSize = 0;
		delete session->pkSigner;
		session->pkSigner = NULL_PTR;
		session->signInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	//DEBUG_MSG("C_SignUpdate", "OK");
	return CKR_OK;
}

// Ký toàn bộ dữ liệu và trả về chữ ký

CK_RV C_SignFinal_s(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSignature,
		CK_ULONG_PTR pulSignatureLen) {
	//DEBUG_MSG("C_SignFinal", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_SignFinal", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_SignFinal", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
	//kiểm tra hàm ký đã khởi tạo chưa
	if (!session->signInitialized) {
		//DEBUG_MSG("C_SignFinal", "Sign is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (session->signSinglePart) {
		//DEBUG_MSG("C_SignFinal", "The mechanism can only sign single part of data");
		return CKR_FUNCTION_NOT_SUPPORTED;
	}

	if (pulSignatureLen == NULL_PTR) {
		//DEBUG_MSG("C_SignFinal", "pulSignatureLen must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	if (pSignature == NULL_PTR) {
		*pulSignatureLen = session->signSize;

		//DEBUG_MSG("C_SignFinal", "OK, returning the size of the signature");
		return CKR_OK;
	}

	if (*pulSignatureLen < session->signSize) {
		*pulSignatureLen = session->signSize;

		//DEBUG_MSG("C_SignFinal", "The given buffer is to small");
		return CKR_BUFFER_TOO_SMALL;
	}

	// Ký
	Botan::SecureVector<Botan::byte> signResult;
	try {
		signResult = session->pkSigner->signature(*session->rng);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not sign the data: %s", e.what());
		//ERROR_MSG("C_SignFinal", errorMsg);

		// đặt lại giá trị
		session->signSize = 0;
		delete session->pkSigner;
		session->pkSigner = NULL_PTR;
		session->signInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	// trả về kết quả
	memcpy(pSignature, signResult.begin(), session->signSize);
	*pulSignatureLen = session->signSize;

	// đặt lại giá trị
	session->signInitialized = false;

	//DEBUG_MSG("C_SignFinal", "OK");
	return CKR_OK;
}

CK_RV C_SignRecoverInit(CK_SESSION_HANDLE, CK_MECHANISM_PTR, CK_OBJECT_HANDLE) {
	//DEBUG_MSG("C_SignRecoverInit", "Calling");
	//DEBUG_MSG("C_SignRecoverInit", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_SignRecover(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR,
		CK_ULONG_PTR) {
	//DEBUG_MSG("C_SignRecover", "Calling");
	//DEBUG_MSG("C_SignRecover", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

// Initialize the verifing functionality.

CK_RV C_VerifyInit(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism,
		CK_OBJECT_HANDLE hKey) {
	//DEBUG_MSG("C_VerifyInit", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_VerifyInit", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_VerifyInit", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	CK_BBOOL hasObject = session->db->hasObject(hKey);
	
	hasObject = CK_TRUE;
	// TODO:
	//   Should also add: session->db->getBooleanAttribute(hKey, CKA_VERIFY, CK_TRUE) == CK_FALSE
	//   in the if-statement below. "If this key is allowed to verify signatures"
	//   Not doing this for now, because you get higher performance.

	if (session->db->getObjectClass(hKey) != CKO_PUBLIC_KEY) {
		
		return CKR_KEY_HANDLE_INVALID;
	} else if (session->db->getKeyType(hKey) != CKK_RSA) {
		
		return CKR_KEY_HANDLE_INVALID;
	} else if (hasObject == CK_FALSE) {
        return CKR_KEY_HANDLE_INVALID;
	}

	//	if (hasObject == CK_FALSE || session->db->getObjectClass(hKey)
	//			!= CKO_PUBLIC_KEY || session->db->getKeyType(hKey) != CKK_RSA) {
	//		return CKR_KEY_HANDLE_INVALID;
	//	}

	CK_BBOOL userAuth = userAuthorization(session->getSessionState(),
			session->db->getBooleanAttribute(hKey, CKA_TOKEN, CK_TRUE),
			session->db->getBooleanAttribute(hKey, CKA_PRIVATE, CK_TRUE), 0);
	if (userAuth == CK_FALSE) {
		//DEBUG_MSG("C_VerifyInit", "User is not authorized");
		return CKR_KEY_HANDLE_INVALID;
	}

	if (session->verifyInitialized) {
		//DEBUG_MSG("C_VerifyInit", "Verify is already initialized");
		return CKR_OPERATION_ACTIVE;
	}

	if (pMechanism == NULL_PTR) {
		//DEBUG_MSG("C_VerifyInit", "pMechanism must not be NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	session->verifySinglePart = false;
#ifdef BOTAN_PRE_1_9_4_FIX
	Botan::EMSA *hashFunc = NULL_PTR;

	// Selects the correct padding and hash algorithm.
	switch(pMechanism->mechanism) {
		case CKM_RSA_PKCS:
		hashFunc = new Botan::EMSA3_Raw();
		session->verifySinglePart = true;
		break;
		case CKM_RSA_X_509:
		hashFunc = new Botan::EMSA_Raw();
		session->verifySinglePart = true;
		break;
		case CKM_MD5_RSA_PKCS:
		hashFunc = new Botan::EMSA3(new Botan::MD5);
		break;
		case CKM_RIPEMD160_RSA_PKCS:
		hashFunc = new Botan::EMSA3(new Botan::RIPEMD_160);
		break;
		case CKM_SHA1_RSA_PKCS:
		hashFunc = new Botan::EMSA3(new Botan::SHA_160);
		break;
		case CKM_SHA256_RSA_PKCS:
		hashFunc = new Botan::EMSA3(new Botan::SHA_256);
		break;
		case CKM_SHA384_RSA_PKCS:
		hashFunc = new Botan::EMSA3(new Botan::SHA_384);
		break;
		case CKM_SHA512_RSA_PKCS:
		hashFunc = new Botan::EMSA3(new Botan::SHA_512);
		break;
		case CKM_SHA1_RSA_PKCS_PSS:
		if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA_1) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA_1");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA1) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA1");
			return CKR_ARGUMENTS_BAD;
		}
		hashFunc = new Botan::EMSA4(new Botan::SHA_160, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
		break;
		case CKM_SHA256_RSA_PKCS_PSS:
		if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA256) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA256");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA256) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA256");
			return CKR_ARGUMENTS_BAD;
		}
		hashFunc = new Botan::EMSA4(new Botan::SHA_256, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
		break;
		case CKM_SHA384_RSA_PKCS_PSS:
		if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA384) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA384");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA384) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA384");
			return CKR_ARGUMENTS_BAD;
		}
		hashFunc = new Botan::EMSA4(new Botan::SHA_384, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
		break;
		case CKM_SHA512_RSA_PKCS_PSS:
		if(pMechanism->pParameter == NULL_PTR || pMechanism->ulParameterLen != sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->hashAlg != CKM_SHA512) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA512");
			return CKR_ARGUMENTS_BAD;
		}
		if(CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->mgf != CKG_MGF1_SHA512) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA512");
			return CKR_ARGUMENTS_BAD;
		}
		hashFunc = new Botan::EMSA4(new Botan::SHA_512, CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen);
		break;
		default:
		//DEBUG_MSG("C_VerifyInit", "The selected mechanism is not supported");
		return CKR_MECHANISM_INVALID;
		break;
	}

	if(hashFunc == NULL_PTR) {
		//DEBUG_MSG("C_VerifyInit", "Could not create the hash function");
		return CKR_DEVICE_MEMORY;
	}
#else
	std::string emsa;
	//std::ostringstream request;

	// Selects the correct padding and hash algorithm.
	switch (pMechanism->mechanism) {
	case CKM_RSA_PKCS:
		emsa = "EMSA3(Raw)";
		session->verifySinglePart = true;
		break;
	case CKM_RSA_X_509:
		emsa = "Raw";
		session->verifySinglePart = true;
		break;
	case CKM_MD5_RSA_PKCS:
		emsa = "EMSA3(MD5)";
		break;
	case CKM_RIPEMD160_RSA_PKCS:
		emsa = "EMSA3(RIPEMD-160)";
		break;
	case CKM_SHA1_RSA_PKCS:
		emsa = "EMSA3(SHA-160)";
		break;
	case CKM_SHA256_RSA_PKCS:
		emsa = "EMSA3(SHA-256)";
		break;
	case CKM_SHA384_RSA_PKCS:
		emsa = "EMSA3(SHA-384)";
		break;
	case CKM_SHA512_RSA_PKCS:
		emsa = "EMSA3(SHA-512)";
		break;
	case CKM_SHA1_RSA_PKCS_PSS:
		if (pMechanism->pParameter == NULL_PTR
				|| pMechanism->ulParameterLen
						!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
				!= CKM_SHA_1) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA_1");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
				!= CKG_MGF1_SHA1) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA1");
			return CKR_ARGUMENTS_BAD;
		}
//		request << "EMSA4(SHA-160,MGF1,"
//				<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//				<< ")";
//		emsa = request.str();
		break;
	case CKM_SHA256_RSA_PKCS_PSS:
		if (pMechanism->pParameter == NULL_PTR
				|| pMechanism->ulParameterLen
						!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
				!= CKM_SHA256) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA256");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
				!= CKG_MGF1_SHA256) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA256");
			return CKR_ARGUMENTS_BAD;
		}
//		request << "EMSA4(SHA-256,MGF1,"
//				<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//				<< ")";
//		emsa = request.str();
		break;
	case CKM_SHA384_RSA_PKCS_PSS:
		if (pMechanism->pParameter == NULL_PTR
				|| pMechanism->ulParameterLen
						!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
				!= CKM_SHA384) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA384");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
				!= CKG_MGF1_SHA384) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA384");
			return CKR_ARGUMENTS_BAD;
		}
//		request << "EMSA4(SHA-384,MGF1,"
//				<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//				<< ")";
//		emsa = request.str();
		break;
	case CKM_SHA512_RSA_PKCS_PSS:
		if (pMechanism->pParameter == NULL_PTR
				|| pMechanism->ulParameterLen
						!= sizeof(CK_RSA_PKCS_PSS_PARAMS_s)) {
			//DEBUG_MSG("C_VerifyInit", "pParameter must be of type CK_RSA_PKCS_PSS_PARAMS");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->hashAlg
				!= CKM_SHA512) {
			//DEBUG_MSG("C_VerifyInit", "hashAlg must be CKM_SHA512");
			return CKR_ARGUMENTS_BAD;
		}
		if (CK_RSA_PKCS_PSS_PARAMS_PTR_s(pMechanism->pParameter)->mgf
				!= CKG_MGF1_SHA512) {
			//DEBUG_MSG("C_VerifyInit", "mgf must be CKG_MGF1_SHA512");
			return CKR_ARGUMENTS_BAD;
		}
//		request << "EMSA4(SHA-512,MGF1,"
//				<< CK_RSA_PKCS_PSS_PARAMS_PTR(pMechanism->pParameter)->sLen
//				<< ")";
//		emsa = request.str();
		break;
	default:
		//DEBUG_MSG("C_VerifyInit", "The selected mechanism is not supported");
		return CKR_MECHANISM_INVALID;
		break;
	}
#endif

	// Get the key from the session key store.
	Botan::Public_Key *cryptoKey = session->getKey(hKey);
	if (cryptoKey == NULL_PTR) {
		//DEBUG_MSG("C_VerifyInit", "Could not load the crypto key");
		return CKR_GENERAL_ERROR;
	}

	// Creates the verifier with given key and mechanism
	try {
#ifdef BOTAN_PRE_1_9_4_FIX
		Botan::PK_Verifying_with_MR_Key *verifyKey = dynamic_cast<Botan::PK_Verifying_with_MR_Key*>(cryptoKey);
		session->verifySize = (cryptoKey->max_input_bits() + 8) / 8;
		session->pkVerifier = new Botan::PK_Verifier_with_MR(*verifyKey, &*hashFunc);
#else
		session->verifySize = (cryptoKey->max_input_bits() + 8) / 8;
		session->pkVerifier = new Botan::PK_Verifier(*cryptoKey, emsa);
#endif
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not create the verifying function: %s", e.what());
		//ERROR_MSG("C_VerifyInit", errorMsg);
		return CKR_GENERAL_ERROR;
	}

	if (!session->pkVerifier) {
		//ERROR_MSG("C_VerifyInit", "Could not create the verifying function");
		return CKR_DEVICE_MEMORY;
	}

	session->verifyInitialized = true;

	//DEBUG_MSG("C_VerifyInit", "OK");
	return CKR_OK;
}

// Verifies if the the signature matches the data

CK_RV C_Verify(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pData,
		CK_ULONG ulDataLen, CK_BYTE_PTR pSignature, CK_ULONG ulSignatureLen) {
	//DEBUG_MSG("C_Verify", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_Verify", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_Verify", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->verifyInitialized) {
		//DEBUG_MSG("C_Verify", "Verify is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (pData == NULL_PTR || pSignature == NULL_PTR) {
		//DEBUG_MSG("C_Verify", "pData and pSignature must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	// Add data
	session->pkVerifier->update(pData, ulDataLen);

	// Check signature length
	if (session->verifySize != ulSignatureLen) {
		// Finalizing
		delete session->pkVerifier;
		session->pkVerifier = NULL_PTR;
		session->verifyInitialized = false;

		//DEBUG_MSG("C_Verify", "The signatures does not have the same length");
		return CKR_SIGNATURE_LEN_RANGE;
	}

	// Verify
	bool verResult;
	try {
		verResult = session->pkVerifier->check_signature(pSignature,
				ulSignatureLen);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not check the signature: %s", e.what());
		//ERROR_MSG("C_Verify", errorMsg);

		// Finalizing
		delete session->pkVerifier;
		session->pkVerifier = NULL_PTR;
		session->verifyInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	// Finalizing
	delete session->pkVerifier;
	session->pkVerifier = NULL_PTR;
	session->verifyInitialized = false;

	// Returns the result
	if (verResult) {
		//DEBUG_MSG("C_Verify", "OK");
		return CKR_OK;
	} else {
		//DEBUG_MSG("C_Verify", "The signature is invalid");
		return CKR_SIGNATURE_INVALID;
	}
}

// Collects the data before the final signature check.

CK_RV C_VerifyUpdate(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pPart,
		CK_ULONG ulPartLen) {
	//DEBUG_MSG("C_VerifyUpdate", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_VerifyUpdate", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_VerifyUpdate", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->verifyInitialized) {
		//DEBUG_MSG("C_VerifyUpdate", "Verify is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (session->verifySinglePart) {
		//DEBUG_MSG("C_VerifyUpdate", "The mechanism can only verify single part of data");
		return CKR_FUNCTION_NOT_SUPPORTED;
	}

	if (pPart == NULL_PTR) {
		//DEBUG_MSG("C_VerifyUpdate", "pPart must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	// Add data
	try {
		session->pkVerifier->update(pPart, ulPartLen);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not buffer the data: %s", e.what());
		//ERROR_MSG("C_VerifyUpdate", errorMsg);

		// Finalizing
		delete session->pkVerifier;
		session->pkVerifier = NULL_PTR;
		session->verifyInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	//DEBUG_MSG("C_VerifyUpdate", "OK");
	return CKR_OK;
}

// Verifies if the signature matches the collected data.

CK_RV C_VerifyFinal(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSignature,
		CK_ULONG ulSignatureLen) {
	//DEBUG_MSG("C_VerifyFinal", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_VerifyFinal", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_VerifyFinal", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (!session->verifyInitialized) {
		//DEBUG_MSG("C_VerifyFinal", "Verify is not initialized");
		return CKR_OPERATION_NOT_INITIALIZED;
	}

	if (session->verifySinglePart) {
		//DEBUG_MSG("C_VerifyFinal", "The mechanism can only verify single part of data");
		return CKR_FUNCTION_NOT_SUPPORTED;
	}

	if (pSignature == NULL_PTR) {
		//DEBUG_MSG("C_VerifyFinal", "pSignature must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	// Check signature length
	if (session->verifySize != ulSignatureLen) {
		// Finalizing
		delete session->pkVerifier;
		session->pkVerifier = NULL_PTR;
		session->verifyInitialized = false;

		//DEBUG_MSG("C_VerifyFinal", "The signatures does not have the same length");
		return CKR_SIGNATURE_LEN_RANGE;
	}

	// Verify
	bool verResult;
	try {
		verResult = session->pkVerifier->check_signature(pSignature,
				ulSignatureLen);
	} catch (std::exception& e) {
		char errorMsg[1024];
		//snprintf(errorMsg, sizeof(errorMsg), "Could not check the signature: %s", e.what());
		//ERROR_MSG("C_VerifyFinal", errorMsg);

		// Finalizing
		delete session->pkVerifier;
		session->pkVerifier = NULL_PTR;
		session->verifyInitialized = false;

		return CKR_GENERAL_ERROR;
	}

	// Finalizing
	delete session->pkVerifier;
	session->pkVerifier = NULL_PTR;
	session->verifyInitialized = false;

	// Returns the result
	if (verResult) {
		//DEBUG_MSG("C_VerifyFinal", "OK");
		return CKR_OK;
	} else {
		//DEBUG_MSG("C_VerifyFinal", "The signature is invalid");
		return CKR_SIGNATURE_INVALID;
	}
}

CK_RV C_VerifyRecoverInit(CK_SESSION_HANDLE, CK_MECHANISM_PTR,
		CK_OBJECT_HANDLE) {
	//DEBUG_MSG("C_VerifyRecoverInit", "Calling");
	//DEBUG_MSG("C_VerifyRecoverInit", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_VerifyRecover(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR,
		CK_ULONG_PTR) {
	//DEBUG_MSG("C_VerifyRecover", "Calling");
	//DEBUG_MSG("C_VerifyRecover", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_DigestEncryptUpdate(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG,
		CK_BYTE_PTR, CK_ULONG_PTR) {
	//DEBUG_MSG("C_DigestEncryptUpdate", "Calling");
	//DEBUG_MSG("C_DigestEncryptUpdate", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_DecryptDigestUpdate(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG,
		CK_BYTE_PTR, CK_ULONG_PTR) {
	//DEBUG_MSG("C_DecryptDigestUpdate", "Calling");
	//DEBUG_MSG("C_DecryptDigestUpdate", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_SignEncryptUpdate(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG, CK_BYTE_PTR,
		CK_ULONG_PTR) {
	//DEBUG_MSG("C_SignEncryptUpdate", "Calling");
	//DEBUG_MSG("C_SignEncryptUpdate", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_DecryptVerifyUpdate(CK_SESSION_HANDLE, CK_BYTE_PTR, CK_ULONG,
		CK_BYTE_PTR, CK_ULONG_PTR) {
	//DEBUG_MSG("C_DecryptVerifyUpdate", "Calling");
	//DEBUG_MSG("C_DecryptVerifyUpdate", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_GenerateKey(CK_SESSION_HANDLE, CK_MECHANISM_PTR, CK_ATTRIBUTE_PTR,
		CK_ULONG, CK_OBJECT_HANDLE_PTR) {
	//DEBUG_MSG("C_GenerateKey", "Calling");
	//DEBUG_MSG("C_GenerateKey", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

// Generates a key pair.
// For now, only RSA is supported.

CK_RV C_GenerateKeyPair_s(CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism,
                        CK_ATTRIBUTE_PTR pPublicKeyTemplate, CK_ULONG ulPublicKeyAttributeCount,
                        CK_ATTRIBUTE_PTR pPrivateKeyTemplate,
                        CK_ULONG ulPrivateKeyAttributeCount, CK_OBJECT_HANDLE_PTR phPublicKey,
                        CK_OBJECT_HANDLE_PTR phPrivateKey) {
	//DEBUG_MSG("C_GenerateKeyPair", "Calling");
    
	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GenerateKeyPair", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);
    
    //	SoftSlot *currentSlot;
    //	currentSlot = new SoftSlot;
    //	//slots = currentSlot;
    
	SoftSession *session = softHSM->getSession(hSession);
    
    
	if (session == NULL_PTR) {
		//DEBUG_MSG("C_GenerateKeyPair", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}
    
	if (pMechanism == NULL_PTR || pPublicKeyTemplate == NULL_PTR
        || pPrivateKeyTemplate == NULL_PTR || phPublicKey == NULL_PTR
        || phPrivateKey == NULL_PTR) {
		//DEBUG_MSG("C_GenerateKeyPair", "The arguments must not be NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}
    
	CK_BBOOL isToken = CK_FALSE;
	CK_BBOOL isPrivate = CK_TRUE;
    
	// Extract object information
	for (CK_ULONG i = 0; i < ulPrivateKeyAttributeCount; i++) {
		switch (pPrivateKeyTemplate[i].type) {
            case CKA_TOKEN:
                if (pPrivateKeyTemplate[i].ulValueLen == sizeof(CK_BBOOL)) {
                    isToken = *(CK_BBOOL*) pPrivateKeyTemplate[i].pValue;
                }
                break;
            case CKA_PRIVATE:
                if (pPrivateKeyTemplate[i].ulValueLen == sizeof(CK_BBOOL)) {
                    isPrivate = *(CK_BBOOL*) pPrivateKeyTemplate[i].pValue;
                }
                break;
            default:
                break;
		}
	}
    
	// Check user credentials
    //	CK_BBOOL userAuth = userAuthorization(session->getSessionState(), isToken,
    //			isPrivate, 1);
    //	if (userAuth == CK_FALSE) {
    //		//DEBUG_MSG("C_GenerateKeyPair", "User is not authorized");
    //		return CKR_USER_NOT_LOGGED_IN;
    //	}
    
	CK_RV rv;
    
	switch (pMechanism->mechanism) {
        case CKM_RSA_PKCS_KEY_PAIR_GEN:
            rv = rsaKeyGen(session, pPublicKeyTemplate, ulPublicKeyAttributeCount,
                           pPrivateKeyTemplate, ulPrivateKeyAttributeCount, phPublicKey,
                           phPrivateKey);
            return rv;
            break;
        default:
            break;
	}
    
	//DEBUG_MSG("C_GenerateKeyPair", "The selected mechanism is not supported");
	return CKR_MECHANISM_INVALID;
}

CK_RV C_WrapKey(CK_SESSION_HANDLE, CK_MECHANISM_PTR, CK_OBJECT_HANDLE,
		CK_OBJECT_HANDLE, CK_BYTE_PTR, CK_ULONG_PTR) {
	//DEBUG_MSG("C_WrapKey", "Calling");
	//DEBUG_MSG("C_WrapKey", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_UnwrapKey(CK_SESSION_HANDLE, CK_MECHANISM_PTR, CK_OBJECT_HANDLE,
		CK_BYTE_PTR, CK_ULONG, CK_ATTRIBUTE_PTR, CK_ULONG,
		CK_OBJECT_HANDLE_PTR) {
	//DEBUG_MSG("C_UnwrapKey", "Calling");
	//DEBUG_MSG("C_UnwrapKey", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

CK_RV C_DeriveKey(CK_SESSION_HANDLE, CK_MECHANISM_PTR, CK_OBJECT_HANDLE,
		CK_ATTRIBUTE_PTR, CK_ULONG, CK_OBJECT_HANDLE_PTR) {
	//DEBUG_MSG("C_DeriveKey", "Calling");
	//DEBUG_MSG("C_DeriveKey", "The function is not implemented.");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

// Reseeds the RNG

CK_RV C_SeedRandom(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSeed,
		CK_ULONG ulSeedLen) {
	//DEBUG_MSG("C_SeedRandom", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_SeedRandom", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_SeedRandom", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (pSeed == NULL_PTR) {
		//DEBUG_MSG("C_SeedRandom", "pSeed must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	session->rng->add_entropy(pSeed, ulSeedLen);
#ifdef BOTAN_RESEED_FIX
	session->rng->reseed(256);
#else
	session->rng->reseed();
#endif

	//DEBUG_MSG("C_SeedRandom", "OK");
	return CKR_OK;
}

// Returns some random data.

CK_RV C_GenerateRandom(CK_SESSION_HANDLE hSession, CK_BYTE_PTR pRandomData,
		CK_ULONG ulRandomLen) {
	//DEBUG_MSG("C_GenerateRandom", "Calling");

	SoftHSMInternal *softHSM = state.get();
	//CHECK_DEBUG_RETURN(softHSM == NULL, "C_GenerateRandom", "Library is not initialized",
	//	CKR_CRYPTOKI_NOT_INITIALIZED);

	SoftSession *session = softHSM->getSession(hSession);

	if (session == NULL_PTR) {
		//DEBUG_MSG("C_GenerateRandom", "Can not find the session");
		return CKR_SESSION_HANDLE_INVALID;
	}

	if (pRandomData == NULL_PTR) {
		//DEBUG_MSG("C_GenerateRandom", "pRandomData must not be a NULL_PTR");
		return CKR_ARGUMENTS_BAD;
	}

	session->rng->randomize(pRandomData, ulRandomLen);

	//DEBUG_MSG("C_GenerateRandom", "OK");
	return CKR_OK;
}

CK_RV C_GetFunctionStatus(CK_SESSION_HANDLE) {
	//DEBUG_MSG("C_GetFunctionStatus", "Calling");
	//DEBUG_MSG("C_GetFunctionStatus", "Just returning. Is a legacy function.");

	return CKR_FUNCTION_NOT_PARALLEL;
}

CK_RV C_CancelFunction(CK_SESSION_HANDLE) {
	//DEBUG_MSG("C_CancelFunction", "Calling");
	//DEBUG_MSG("C_CancelFunction", "Just returning. Is a legacy function.");

	return CKR_FUNCTION_NOT_PARALLEL;
}

CK_RV C_WaitForSlotEvent(CK_FLAGS, CK_SLOT_ID_PTR, CK_VOID_PTR) {
	//DEBUG_MSG("C_WaitForSlotEvent", "Calling");
	//DEBUG_MSG("C_WaitForSlotEvent", "The function is not implemented");

	return CKR_FUNCTION_NOT_SUPPORTED;
}

// Generates a RSA key pair with given templates.

CK_RV rsaKeyGen(SoftSession *session, CK_ATTRIBUTE_PTR pPublicKeyTemplate,
		CK_ULONG ulPublicKeyAttributeCount,
		CK_ATTRIBUTE_PTR pPrivateKeyTemplate,
		CK_ULONG ulPrivateKeyAttributeCount, CK_OBJECT_HANDLE_PTR phPublicKey,
		CK_OBJECT_HANDLE_PTR phPrivateKey) {

	CK_ULONG *modulusBits = NULL_PTR;
	// Defaults to an exponent with e = 65537
	Botan::BigInt *exponent = new Botan::BigInt("65537");
	;

	// Extract desired key information
	for (CK_ULONG i = 0; i < ulPublicKeyAttributeCount; i++) {
		switch (pPublicKeyTemplate[i].type) {
		case CKA_MODULUS_BITS:
			if (pPublicKeyTemplate[i].ulValueLen != sizeof(CK_ULONG)) {
				delete exponent;

				return CKR_TEMPLATE_INCOMPLETE;
			}
			modulusBits = (CK_ULONG*) pPublicKeyTemplate[i].pValue;
			break;
		case CKA_PUBLIC_EXPONENT:
			delete exponent;
			exponent = new Botan::BigInt(
					(Botan::byte*) pPublicKeyTemplate[i].pValue,
					(Botan::u32bit) pPublicKeyTemplate[i].ulValueLen);
			break;
		default:
			break;
		}
	}

	// CKA_MODULUS_BITS must be specified to be able to generate a key pair.
	if (modulusBits == NULL_PTR) {
		delete exponent;
		//DEBUG_MSG("C_GenerateKeyPair", "Missing CKA_MODULUS_BITS in pPublicKeyTemplate");
		return CKR_TEMPLATE_INCOMPLETE;
	}

	// Generate the key
	Botan::RSA_PrivateKey *rsaKey = NULL_PTR;
	try {

		//		LOGI("start");
		rsaKey = new Botan::RSA_PrivateKey(*session->rng,
				(Botan::u32bit) *modulusBits,
				BotanCompat::to_u32bit(*exponent));
		//		LOGI("end");
		delete exponent;
	} catch (...) {
		delete exponent;
		//ERROR_MSG("C_GenerateKeyPair", "Could not generate key pair");
		return CKR_GENERAL_ERROR;
	}

	// Add the private key to the database.
    of = fopen("Users/ducvm/Documents/encrypt.log", "w+");
	CK_OBJECT_HANDLE privRef = session->db->addRSAKeyPriv(
			session->getSessionState(), rsaKey, pPrivateKeyTemplate,
			ulPrivateKeyAttributeCount);

	if (privRef == 0) {
		delete rsaKey;
		//DEBUG_MSG("C_GenerateKeyPair", "Could not save private key in DB");
		return CKR_GENERAL_ERROR;
	}

	// Add the public key to the database.
	CK_OBJECT_HANDLE pubRef = session->db->addRSAKeyPub(
			session->getSessionState(), rsaKey, pPublicKeyTemplate,
			ulPublicKeyAttributeCount);

	if (pubRef == 0) {
		delete rsaKey;
		session->db->deleteObject(privRef);

		//DEBUG_MSG("C_GenerateKeyPair", "Could not save public key in DB");
		return CKR_GENERAL_ERROR;
	}
    fclose(of);
	// Returns the object handles to the application.
	*phPublicKey = pubRef;
	*phPrivateKey = privRef;

	//		INFO_MSG("C_GenerateKeyPair", "Key pair generated");
	//DEBUG_MSG("C_GenerateKeyPair", "OK");
	return CKR_OK;
}

long initToken(char *slot, char *label, char *soPIN, char *userPIN) {
	// Keep a copy of the PINs because getpass/getpassphrase will overwrite the previous PIN.
	char so_pin_copy[MAX_PIN_LEN + 1];
	char user_pin_copy[MAX_PIN_LEN + 1];

	if (slot == NULL) {
		//		fprintf(stderr, "Error: A slot number must be supplied. Use --slot <number>\n");
		return 1;
	}

	if (label == NULL) {
		//		fprintf(stderr, "Error: A label for the token must be supplied. Use --label <text>\n");
		return 1;
	}

	if (strlen(label) > 32) {
		//		fprintf(stderr, "Error: The token label must not have a length greater than 32 chars.\n");
		return 1;
	}

	if (soPIN == NULL) {
		//		printf("The SO PIN must have a length between %i and %i characters.\n", MIN_PIN_LEN, MAX_PIN_LEN);
	}

	int soLength = 0;
	soLength = strlen(soPIN);
	while (soLength < MIN_PIN_LEN || soLength > MAX_PIN_LEN) {
		//		printf("Wrong size! The SO PIN must have a length between %i and %i characters.\n", MIN_PIN_LEN, MAX_PIN_LEN);
		soLength = strlen(soPIN);
	}
	strcpy(so_pin_copy, soPIN);

	if (userPIN == NULL) {
		//		printf("The user PIN must have a length between %i and %i characters.\n", MIN_PIN_LEN, MAX_PIN_LEN);
	}

	int userLength = strlen(userPIN);
	while (userLength < MIN_PIN_LEN || userLength > MAX_PIN_LEN) {
		//		printf("Wrong size! The user PIN must have a length between %i and %i characters.\n", MIN_PIN_LEN, MAX_PIN_LEN);
	}

	strcpy(user_pin_copy, userPIN);

	//	// Load the variables
	CK_SLOT_ID slotID = atoi(slot);
	CK_UTF8CHAR paddedLabel[32];
	memset(paddedLabel, ' ', sizeof(paddedLabel));
	memcpy(paddedLabel, label, strlen(label));
	CK_UTF8CHAR_PTR _sopin = (CK_UTF8CHAR_PTR) so_pin_copy;

	//CK_RV rv = C_InitToken(slotID, _sopin, soLength, paddedLabel);
	CK_RV rv;
	rv = C_CloseAllSessions_s(slotID);

	//
//	CK_SESSION_HANDLE hSession;
//	rv = C_OpenSession(slotID, CKF_SERIAL_SESSION | CKF_RW_SESSION, NULL_PTR,
//			NULL_PTR, &hSession);
	//	if (rv != CKR_OK) {
	//		//		fprintf(stderr, "Error: Could not open a session with the library.\n");
	//		return 1;
	//	}

	//	rv = C_Login(hSession, CKU_SO, (CK_UTF8CHAR_PTR) so_pin_copy, soLength);
	//	if (rv != CKR_OK) {
	//		//		fprintf(stderr, "Error: Could not log in on the token.\n");
	//		return 1;
	//	}

	//	rv = C_InitPIN(hSession, (CK_UTF8CHAR_PTR) user_pin_copy, userLength);
	//	if (rv != CKR_OK) {
	//		//		fprintf(stderr, "Error: Could not initialize the user PIN.\n");
	//		return 1;
	//	}
	//	rv = C_CloseSession(hSession);
	//	//	printf("The token has been initialized.\n");

	return rv;
}

CK_RV generateRsaKeyPair_s(CK_SESSION_HANDLE hSession, CK_BBOOL bTokenPuk,
                         CK_BBOOL bPrivatePuk, CK_BBOOL bTokenPrk, CK_BBOOL bPrivatePrk,
                         CK_OBJECT_HANDLE &hPuk, CK_OBJECT_HANDLE &hPrk, CK_ULONG keyLength, char*  cid) {
	CK_MECHANISM mechanism = { CKM_RSA_PKCS_KEY_PAIR_GEN, NULL_PTR, 0 };
	CK_ULONG bits = keyLength;
	CK_BYTE pubExp[] = { 0x01, 0x00, 0x01 };
	CK_BYTE subject[] = { 0x12, 0x34 }; // tam thoi the
	//CK_BYTE id[] = { 123 }; // tam thoi the
    //   int id = 10;
	CK_BBOOL bFalse = CK_FALSE;
	CK_BBOOL bTrue = CK_TRUE;
	char* key = "DCBA";
	//char* keyLabel = "VNPT";
    char* prikeyLabel ="PRIV";
    char* pubkeyLabel ="PUBL";
    CK_OBJECT_CLASS opriKey = CKO_PRIVATE_KEY;
    CK_OBJECT_CLASS opubKey = CKO_PUBLIC_KEY;
	CK_ATTRIBUTE pukAttribs[] = {{CKA_LABEL, pubkeyLabel, sizeof(pubkeyLabel)}, {CKA_CLASS, &opubKey, sizeof(opubKey)}, { CKA_LOCAL, &bTrue, sizeof(bTrue) }, {
        CKA_TOKEN, &bTokenPuk, sizeof(bTokenPuk) }, { CKA_PRIVATE,
			&bPrivatePuk, sizeof(bPrivatePuk) }, { CKA_ENCRYPT, &bFalse,
                sizeof(bFalse) }, { CKA_ID, cid, 1 }, { CKA_VERIFY, &bTrue, sizeof(bTrue) }, { CKA_WRAP,
                    &bFalse, sizeof(bFalse) },
        { CKA_MODULUS_BITS, &bits, sizeof(bits) }, { CKA_PUBLIC_EXPONENT,
            &pubExp[0], sizeof(pubExp) } };
    
	CK_ATTRIBUTE prkAttribs[] = {{CKA_LABEL, prikeyLabel, sizeof(prikeyLabel)}, {CKA_CLASS, &opriKey, sizeof(opriKey)}, { CKA_LOCAL, &bTrue, sizeof(bTrue) },
        { CKA_TOKEN, &bTokenPrk, sizeof(bTokenPrk) }, { CKA_PRIVATE,
			&bPrivatePrk, sizeof(bPrivatePrk) }, { CKA_SUBJECT, &subject[0],
                sizeof(subject) }, { CKA_ID, cid, 1 }, { CKA_SENSITIVE,
                    &bTrue, sizeof(bTrue) }, { CKA_DECRYPT, &bFalse, sizeof(bFalse) }, {
                        CKA_SIGN, &bTrue, sizeof(bTrue) }, { CKA_UNWRAP, &bFalse,
                            sizeof(bFalse) } };
	hPuk = CK_INVALID_HANDLE;
	hPrk = CK_INVALID_HANDLE;
	CK_RV rv = C_GenerateKeyPair_s(hSession, &mechanism, pukAttribs,
                                 sizeof(pukAttribs) / sizeof(CK_ATTRIBUTE), prkAttribs,
                                 sizeof(prkAttribs) / sizeof(CK_ATTRIBUTE), &hPuk, &hPrk);
	return rv;
}

void rsaPkcsSignVerify(CK_MECHANISM_TYPE mechanismType,
		CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hPublicKey,
		CK_OBJECT_HANDLE hPrivateKey) {
	CK_RV rv;
	CK_MECHANISM mechanism = { mechanismType, NULL_PTR, 0 };
	CK_BYTE data[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
			0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0F };
	CK_BYTE signature[256];
	CK_ULONG ulSignatureLen = 0;

	rv = C_SignInit_s(hSession, &mechanism, hPrivateKey);

	ulSignatureLen = sizeof(signature);
	rv = C_Sign_s(hSession, data, sizeof(data), signature, &ulSignatureLen);
	rv = C_VerifyInit(hSession, &mechanism, hPublicKey);
    rv = C_Verify(hSession, data, sizeof(data), signature, ulSignatureLen);
}

//long rsaPkcsSign(CK_MECHANISM mechanism, CK_SESSION_HANDLE hSession,
//		CK_OBJECT_HANDLE hPrivateKey) {
//	CK_RV rv;
//
//	CK_BYTE signature[256];
//	CK_ULONG ulSignatureLen = 0;
//
//	rv = C_SignInit(hSession, &mechanism, hPrivateKey);
//
//	ulSignatureLen = sizeof(signature);
//	rv = C_Sign(hSession, data, sizeof(data), signature, &ulSignatureLen);
//	return rv;
//}

//long rsaPkcsVerify(CK_MECHANISM mechanism, CK_SESSION_HANDLE hSession,
//		CK_OBJECT_HANDLE hPublicKey, CK_BYTE signature[]) {
//	CK_RV rv;
//
//	CK_ULONG ulSignatureLen = 0;
//
//	ulSignatureLen = sizeof(signature);
//
//	rv = C_VerifyInit(hSession, &mechanism, hPublicKey);
//
//	rv = C_Verify(hSession, data, sizeof(data), signature, ulSignatureLen);
//
//	return rv;
//}

void digestRsaPkcsSignVerify(CK_MECHANISM_TYPE mechanismType,
		CK_SESSION_HANDLE hSession, CK_OBJECT_HANDLE hPublicKey,
		CK_OBJECT_HANDLE hPrivateKey) {
	CK_RV rv;
	CK_MECHANISM mechanism = { mechanismType, NULL_PTR, 0 };
	CK_BYTE data[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
			0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0F };
	CK_BYTE signature[256];
	CK_ULONG ulSignatureLen = 0;

	rv = C_SignInit_s(hSession, &mechanism, hPrivateKey);

	rv = C_SignUpdate(hSession, data, sizeof(data));

	ulSignatureLen = sizeof(signature);
	rv = C_SignFinal_s(hSession, signature, &ulSignatureLen);

	rv = C_VerifyInit(hSession, &mechanism, hPublicKey);

	rv = C_VerifyUpdate(hSession, data, sizeof(data));

	rv = C_VerifyFinal(hSession, signature, ulSignatureLen);

	// verify again, but now change the input that is being signed.
	rv = C_VerifyInit(hSession, &mechanism, hPublicKey);

	data[0] = 0xff;
	rv = C_VerifyUpdate(hSession, data, sizeof(data));

	rv = C_VerifyFinal(hSession, signature, ulSignatureLen);
}


/*
 *  Generate key pair
 */
CK_ULONG genRSAKeyPair(CK_ULONG c_hSession, CK_ULONG slotInitToken,
		CK_UTF8CHAR userPin[], CK_ULONG oPuk, CK_ULONG oPrk, CK_ULONG keyLength,char* id)
{
	CK_RV rv = -1;

#ifdef SOFTHSM_DB
	LOGI("The current slot id: %d", slotInitToken);
	LOGI("The current session id: %d", c_hSession);
#endif

	// Login USER into the sessions so we can create a private objects
	CK_ULONG pinLength = strlen((char*) userPin);
	CK_ULONG ukeyLength = (CK_ULONG) keyLength;
	rv = C_Login_s(c_hSession, CKU_USER, userPin, pinLength);

	const CK_BBOOL ckTrue = CK_TRUE;
	const CK_BBOOL ckFalse = CK_FALSE;
//	rv = generateRsaKeyPair(c_hSession, IN_SESSION, IS_PUBLIC, IN_SESSION,
//			IS_PRIVATE, oPuk, oPrk, ukeyLength);
   // char* id = (char*) malloc(sizeof(char) * 2);
   // memcpy(id, id)
	rv = generateRsaKeyPair_s(c_hSession, ckFalse, ckFalse, ckFalse,
			ckTrue, oPuk, oPrk, ukeyLength, id);
	return oPrk;
}

// Sinh PKCS#10 Request
//long genPKCS10Request(long slotInitToken, CK_UTF8CHAR userPin[])
//{
//	CK_RV rv = 0;
//	LOGI("mSessionRW: %d", mSessionRW);
//	rv = C_OpenSession(slotInitToken, CKF_SERIAL_SESSION, NULL_PTR, NULL_PTR,
//			&mSessionRW);
//
//	// Login USER into the sessions so we can create a private objects
//	CK_ULONG pinLength = sizeof(userPin) - 1;
//	rv = C_Login(mSessionRW, CKU_USER, userPin, pinLength);
//
//	//
//	SoftHSMInternal *softHSM = state.get();
//	SoftSession *session = softHSM->getSession(mSessionRW);
//	Botan::X509_Cert_Options opts("Hoang Test/VN/VNPT/VN");
//	Botan::Public_Key *cryptoKey = session->getKey(mPrk);
//
//	if (cryptoKey == NULL_PTR) {
//#ifdef SOFTHSM_DEBUG
//		LOGI("Error when getting private key");
//#endif
//		return CKR_KEY_HANDLE_INVALID;
//	}
//
//	LOGI("cryptoKey is not NULL");
//	Botan::Private_Key* prkey = dynamic_cast<Botan::Private_Key*>(cryptoKey);
//
//	if(prkey != NULL_PTR)
//	LOGI("prkey is not null pointer");
//
//	Botan::RandomNumberGenerator* rng = session->rng;
//	const std::string hash_fn = "SHA-160";
//	LOGI("Bat dau gen PKCS10");
//
//	Botan::PKCS10_Request req = Botan::X509::create_cert_req(opts,
//			*dynamic_cast<const Botan::Private_Key*>(cryptoKey), "SHA-160",
//			*session->rng);
////	Botan::PKCS10_Request req = Botan::X509::create_cert_req(opts,
////				*prkey, "SHA-160",
////				*session->rng);
//	LOGI("PKCS10 OK");
//
//	// Create cert.pem file
//	FILE* file = fopen("/data/data/vnpt.example.testsofthsm/request.pem", "w+");
//	if (!file) {
//		printf("Error when opening file cert.pem");
//	} else {
//		std::string pemStr = req.PEM_encode();
//		fprintf(file, pemStr.c_str());
//	}
//	LOGI("Finished creat certificate file!");
//	fclose(file);
//
//	return CKR_OK;
//
//}

long genPKCS10Request_s(CK_SESSION_HANDLE sessionID, CK_SLOT_ID slotInitToken,
                      CK_UTF8CHAR userPin[], CK_ULONG handleKey) {
	CK_RV rv;
    
	// rv = C_OpenSession(slotInitToken, CKF_SERIAL_SESSION, NULL_PTR, NULL_PTR, &sessionID);
    
	// Login USER into the sessions so we can create a private objects
	CK_ULONG pinLength = strlen((const char*)userPin);
	rv = C_Login_s(sessionID, CKU_USER, userPin, pinLength);
    
	//
	SoftHSMInternal *softHSM = state.get();
	SoftSession *session = softHSM->getSession(sessionID);
	Botan::X509_Cert_Options opts("Hoang Test/VN/VNPT/VN");
    //	session->db->
    
	//mPrk = 1;
    //	if(session == NULL) LOGI("session NULL");
    //	LOGI("mPrk = %d", mPrk);
    //	CK_ATTRIBUTE_PTR attrs = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
    //	attrs->type = CKA_LABEL;
    //	char* key =  "VNPT";
    //	attrs->pValue = (void*)  key;
    //	// find Key
    //	rv = C_FindObjectsInit(sessionID, attrs, 1);
    //	LOGI("The value after find objects init = %d", rv);
    //	CK_OBJECT_HANDLE_PTR phandleObject = (CK_OBJECT_HANDLE_PTR) malloc(10 * sizeof(CK_OBJECT_HANDLE));
    //	CK_ULONG_PTR ulCount = NULL;
    //	rv = C_FindObjects(sessionID, phandleObject, 100, ulCount );
    //	LOGI("The value after find objects init = %d", rv);
    //	CK_ULONG oHandleKey = phandleObject[0];
    //	LOGI("oHandleKey = %d", oHandleKey);
    
	Botan::Public_Key *cryptoKey = session->getKey(handleKey);
    
	Botan::MemoryVector<unsigned char> bVect = cryptoKey->x509_subject_public_key();
	//LOGI("Length = %d", bVect.pinLength);
    
#ifdef SOFTHSM_DB
	LOGI("Object handle of private key: mPrk =  %d", mPrk);
#endif
    
	if (cryptoKey == NULL_PTR) {
		return CKR_KEY_HANDLE_INVALID;
	}
	//	LOGI("",cryptoKey->);
	Botan::Private_Key* prkey = dynamic_cast<Botan::Private_Key*>(cryptoKey);
	Botan::RandomNumberGenerator* rng = session->rng;
	const std::string hash_fn = "SHA-160";
    
	// Alice
	//Botan::RSA_PrivateKey priv_rsa(rng, 1024 /* bits */);
    
#ifdef SOFTHSM_DB
	LOGI("Starting to gen PKCS10 Request");
#endif
    
	Botan::PKCS10_Request req = Botan::X509::create_cert_req(opts, *prkey,
                                                             "SHA-160", *(session->rng));
	
    //	LOGI("PKCS10 OK");
	//C_CloseSession(mSessionRW);
    
    
	// Create cert.pem file
	std::string str = getenv("HOME");
    str += "/Documents/request.pem";
    char * path = new char[str.size() + 1];
    std::copy(str.begin(), str.end(), path);
    path[str.size()] = '\0';
    FILE* file = fopen(path, "w+");
	if (!file) {
		printf("Error when opening file cert.pem");
	} else {
		std::string pemStr = req.PEM_encode();
        fprintf(file, "%s", pemStr.c_str());
	}
	
	fclose(file);
    
	return CKR_OK;
    
}

#include "botan/base64.h"

void getPublicKeyValue(long hsession, long handle) {
    SoftHSMInternal *softHSM = state.get();
    SoftSession *session = softHSM->getSession((CK_ULONG)hsession);
    Botan::Public_Key *cryptoKey = session->getKey((CK_ULONG)handle);
    
    Botan::MemoryVector<unsigned char> bVect = cryptoKey->x509_subject_public_key();
    CK_ULONG uLen = bVect.size();
    
    unsigned char temp[uLen];
    for(int i = 0; i < uLen; i++) {
        temp[i] = bVect[i];
    }
    
    //    unsigned char *re = &temp[0];
    
    std::string b64 = Botan::base64_encode(bVect);
    
    //    re = (unsigned char*) b64.c_str();
    
    //    std::string str_;
    //    str_.append(reinterpret_cast<const char*>(re));
    
    //Write to file
    std::string str = getenv("HOME");
    str += "/tmp/pubkey.txt";
    char * path = new char[str.size() + 1];
    std::copy(str.begin(), str.end(), path);
    path[str.size()] = '\0';
    
    FILE* file = fopen(path, "w+");
	if (!file) {
		printf("Error when opening file pubkey.txt");
	} else {
        fprintf(file,"%s", b64.c_str());
	}
	
	fclose(file);
}


long testRsaSignVerify() {
	CK_RV rv = 1;
	CK_UTF8CHAR pin[] = SLOT_0_USER1_PIN;
	CK_ULONG pinLength = sizeof(pin) - 1;
	CK_UTF8CHAR sopin[] = SLOT_0_SO1_PIN;
	CK_ULONG sopinLength = sizeof(sopin) - 1;
	CK_SESSION_HANDLE hSessionRO;
	CK_SESSION_HANDLE hSessionRW;
	CK_C_INITIALIZE_ARGS_s cinit_args;
	CK_UTF8CHAR label[32];

	memset(label, ' ', 32);
	memcpy(label, "token1", strlen("token1"));

	memset(&cinit_args, 0x0, sizeof(cinit_args));
	cinit_args.flags = CKF_OS_LOCKING_OK;

	//rv = C_InitToken(SLOT_INIT_TOKEN, pin, pinLength, label);

	// Just make sure that we finalize any previous tests
	//C_Finalize(NULL_PTR);

	// Initialize the library and start the test.
	/*rv = C_Initialize(&cinit_args);
	 if(rv != CKR_OK) {
	 return;
	 }*/

	//	// Open read-only session on when the token is not initialized should fail
	//	rv = C_OpenSession(SLOT_INIT_TOKEN, CKF_SERIAL_SESSION, NULL_PTR, NULL_PTR, &hSessionRO);
	//	if (rv != CKR_OK) {
	//		return 1;
	//	}
	//	// Open read-only session
	//	rv = C_OpenSession(SLOT_INIT_TOKEN, CKF_SERIAL_SESSION, NULL_PTR, NULL_PTR,
	//			&hSessionRO);
	//	if (rv != CKR_OK) {
	//		return 2;
	//	}
	//
	//	// Open read-write session
	//	rv = C_OpenSession(SLOT_INIT_TOKEN, CKF_SERIAL_SESSION | CKF_RW_SESSION,
	//			NULL_PTR, NULL_PTR, &hSessionRW);
	//	if (rv != CKR_OK) {
	//		return 3;
	//	}
	//
	//	// Login USER into the sessions so we can create a private objects
	//	rv = C_Login(hSessionRO, CKU_USER, pin, pinLength);
	//	if (rv != CKR_OK) {
	//		return 4;
	//	}
	//	//
	//	CK_OBJECT_HANDLE hPuk = CK_INVALID_HANDLE;
	//	CK_OBJECT_HANDLE hPrk = CK_INVALID_HANDLE;
//	CK_ULONG length = 2048;

	// Hoang test
	//rv = genRSAKeyPair(mSessionRW, SLOT_INIT_TOKEN, mPuk, mPrk,  pin, length);
//	rv = genPKCS10Request(mSessionRW, SLOT_INIT_TOKEN, pin);
	/*	// Public Session keys
	 //	rv = generateRsaKeyPair(hSessionRW, IN_SESSION, IS_PUBLIC, IN_SESSION,
	 //			IS_PUBLIC, hPuk, hPrk, length);

	 //	if (rv != CKR_OK) {
	 //		return 5;
	 //	}
	 //		rsaPkcsSignVerify(CKM_RSA_PKCS, hSessionRO, hPuk, hPrk);
	 //	rsaPkcsSignVerify(CKM_RSA_X_509, hSessionRO, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_MD5_RSA_PKCS, hSessionRO, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA1_RSA_PKCS, hSessionRO, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA256_RSA_PKCS, hSessionRO, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA512_RSA_PKCS, hSessionRO, hPuk, hPrk);

	 // Private Session Keys
	 //	rv = generateRsaKeyPair(hSessionRW, IN_SESSION, IS_PRIVATE, IN_SESSION,
	 //			IS_PRIVATE, hPuk, hPrk);
	 //	if (rv != CKR_OK) {
	 //		return 6;
	 //	}
	 //	rsaPkcsSignVerify(CKM_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	rsaPkcsSignVerify(CKM_RSA_X_509, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_MD5_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA1_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA256_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA512_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //
	 //	// Public Token Keys
	 //	rv = generateRsaKeyPair(hSessionRW, ON_TOKEN, IS_PUBLIC, ON_TOKEN,
	 //			IS_PUBLIC, hPuk, hPrk);
	 //	if (rv != CKR_OK) {
	 //		return 7;
	 //	}
	 //	rsaPkcsSignVerify(CKM_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	rsaPkcsSignVerify(CKM_RSA_X_509, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_MD5_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA1_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA256_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA512_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //
	 //	// Private Token Keys
	 //	rv = generateRsaKeyPair(hSessionRW, ON_TOKEN, IS_PRIVATE, ON_TOKEN,
	 //			IS_PRIVATE, hPuk, hPrk);
	 //
	 //	rsaPkcsSignVerify(CKM_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	rsaPkcsSignVerify(CKM_RSA_X_509, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_MD5_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA1_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA256_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 //	digestRsaPkcsSignVerify(CKM_SHA512_RSA_PKCS, hSessionRW, hPuk, hPrk);
	 */
	return rv;
}

//CK_OBJECT_HANDLE c_hPuk;
//CK_OBJECT_HANDLE c_hPrk;
//CK_MECHANISM c_mechanism;
//
//extern "C" {
////JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_test(
////		JNIEnv * env, jobject obj);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_gethPuk(
//		JNIEnv * env, jobject obj);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_gethPrk(
//		JNIEnv * env, jobject obj);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_testInitToken(
//		JNIEnv * env, jobject obj);
//JNIEXPORT jbyteArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_rsaPkcsSign(
//		JNIEnv * env, jobject obj, jbyteArray jdata, jlong dataLen,
//		jlong mechanismType, jlong hSession, jlong hPrivateKey);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_rsaPkcsVerify(
//		JNIEnv * env, jobject obj, jlong mechanismType, jlong hSession,
//		jlong hPublicKey, jbyteArray jdata, jbyteArray signature);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_testSignAndVerify(
//		JNIEnv * env, jobject obj);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Initialize(
//		JNIEnv * env, jobject obj, jobject joInitArgs);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Finalize(
//		JNIEnv * env, jobject obj, jobject pReserved);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetInfo(
//		JNIEnv * env, jobject obj, jobject joInfo);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetSlotList(
//		JNIEnv * env, jobject obj, jlong pulCount);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetSlotInfo(
//		JNIEnv * env, jobject obj, jlong jslotID, jobject jobj);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetTokenInfo(
//		JNIEnv * env, jobject obj, jlong jslotID, jobject jobj);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetMechanismList(
//		JNIEnv * env, jobject obj, jlong jslotID, jlongArray jaMechanismList,
//		jlong julCount);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetMechanismInfo(
//		JNIEnv * env, jobject obj, jlong jslotID, jlong jtype,
//		jobject joMechanismInfo);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_InitToken(
//		JNIEnv * env, jobject obj, jlong slotID, jstring pPin, jlong ulPinLen,
//		jstring pLabel);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_InitPIN(
//		JNIEnv * env, jobject obj, jlong hSession, jstring pPin,
//		jlong ulPinLen);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SetPIN(
//		JNIEnv * env, jobject obj, jlong hSession, jstring jOldPin,
//		jlong julOldLen, jstring jNewPin, jlong julNewLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_OpenSessionInit(
//		JNIEnv * env, jobject obj, jlong slotID, jlong flags,
//		jobjectArray pApplication, jlong phSession);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_OpenSession(
//		JNIEnv * env, jobject obj, jlong slotID, jlong flags,
//		jobjectArray pApplication, jlong phSession);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_CloseSession(
//		JNIEnv * env, jobject obj, jlong hSession);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_CloseAllSessions(
//		JNIEnv * env, jobject obj, jlong slotID);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetSessionInfo(
//		JNIEnv * env, jobject obj, jlong jhSession, jobject joSessionInfo);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DestroyObject(
//		JNIEnv * env, jobject obj, jlong jhSession, jlong jhObject);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Login(
//		JNIEnv * env, jobject obj, jlong hSession, jlong userType, jstring pPin,
//		jlong ulPinLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_LoginSO(
//		JNIEnv * env, jobject obj, jlong hSession);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Logout(
//		JNIEnv * env, jobject obj, jlong jhSession);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_CreateObject(
//		JNIEnv * env, jobject obj, jlong jhSession, jobject joAtribute,
//		jlong julCount, jlong jphObject);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetAttributeValue(
//		JNIEnv * env, jobject obj, jlong jhSession, jlong jhObject,
//		jobject joAttribute, jlong julCount);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SetAttributeValue(
//		JNIEnv * env, jobject obj, jlong jhSession, jlong jhObject,
//		jobjectArray joAttribute, jlong julCount);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindObjectsInit(
//		JNIEnv * env, jobject obj, jlong hSession, jobjectArray pTemplate,
//		jlong ulCount);
//JNIEXPORT jlongArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindObjects(
//		JNIEnv * env, jobject obj, jlong jhSession, jlongArray jphObject,
//		jlong julMaxObjectCount, jlongArray jpulObjectCount);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindObjectsFinal(
//		JNIEnv * env, jobject obj, jlong jhSession);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_EncryptInit(
//		JNIEnv * env, jobject obj, jlong jhSession, jobject joMechanism,
//		jlong jhKey);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Encrypt(
//		JNIEnv * env, jobject obj, jlong hSession, jstring jData,
//		jlong ulDataLen, jstring jEncryptedData, jlong jpulEncryptedDataLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DecryptInit(
//		JNIEnv * env, jobject obj, jlong jhSession, jobject joMechanism,
//		jlong jhKey);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Decrypt(
//		JNIEnv * env, jobject obj, jlong hSession, jstring jEncryptedData,
//		jlong julEncryptedDataLen, jstring jData, jlong julDataLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DigestInit(
//		JNIEnv* env, jobject jobj, jlong jhSession, jobject joMechanism);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Digest(
//		JNIEnv* env, jobject jobj, jlong jhSession, jstring jData,
//		jlong julDataLen, jstring jDigest, jlong julDigestLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DigestUpdate(
//		JNIEnv * env, jobject obj, jlong jhSession, jbyteArray jpPart,
//		jlong julPartLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DigestFinal(
//		JNIEnv * env, jobject obj, jlong hSession, jbyteArray jpDigest,
//		jlong jpulDigestLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetFunctionList(
//		JNIEnv * env, jobject obj, CK_FUNCTION_LIST_PTR_PTR ppFunctionList);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignInit(
//		JNIEnv * env, jobject obj, jlong hSession, jlong pMechanism,
//		jlong hKey);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Sign(JNIEnv* env,
//		jobject jobj, jlong jhSession, jbyteArray jaData, jlong julDataLen,
//		jbyteArray jaSignature, jlong jpulSignatureLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignUpdate(
//		JNIEnv*env, jobject jobj, jlong jhSession, jbyteArray jpPart,
//		jlong julPartLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignFinal(
//		JNIEnv*env, jobject jobj, jlong jhSession, jbyteArray jpSignature,
//		jlong jpulSignatureLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_VerifyFinal(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpSignature,
//		jlong julSignatureLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_VerifyUpdate(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpPart,
//		jlong julPartLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Verify(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpData,
//		jlong julDataLen, jbyteArray jpSignature, jlong julSignatureLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_VerifyInit(
//		JNIEnv* env, jobject jobj, jlong jhSession, jobject joMechanism,
//		jlong jhKey);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GenerateKeyPair(
//		CK_SESSION_HANDLE hSession, CK_MECHANISM_PTR pMechanism,
//		CK_ATTRIBUTE_PTR pPublicKeyTemplate, CK_ULONG ulPublicKeyAttributeCount,
//		CK_ATTRIBUTE_PTR pPrivateKeyTemplate,
//		CK_ULONG ulPrivateKeyAttributeCount, CK_OBJECT_HANDLE_PTR phPublicKey,
//		CK_OBJECT_HANDLE_PTR phPrivateKey);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SeedRandom(
//		CK_SESSION_HANDLE hSession, CK_BYTE_PTR pSeed, CK_ULONG ulSeedLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_C_GenerateRandom(
//		JNIEnv * env, jobject obj, CK_SESSION_HANDLE hSession,
//		CK_BYTE_PTR pRandomData, CK_ULONG ulRandomLen);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GenerateRsaKeyPair(
//		JNIEnv * env, jobject obj, jlong hSession, jlong jslotID, jlong hPuk,
//		jlong hPrk, jlong keyLength);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GeneratePKCS10Request(
//		JNIEnv * env, jobject obj, jlong jsessionID, jlong jslotInitToken,
//		jstring juserPin, jlong jhandleKey);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_ImportPublicCert(
//		JNIEnv* env, jobject jobj, jlong jSlotID, jstring jpath);
//JNIEXPORT jobjectArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_ReadPublicCert(
//		JNIEnv * env, jobject obj, jlong jsessionID, jlong jHandle,
//		jstring jpath, jlong jattributeLen);
//JNIEXPORT jobjectArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_TestImportPublicCert(
//		JNIEnv* env, jobject jobj, jlong jSlotID, jstring jpath);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_BuildCertX509(
//		JNIEnv * env, jobject obj, jlong jsessionID, jlong jHandle,
//		jlong jattLength);
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetPrivateKey();
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignData(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jaData,
//		jlong julDataLen, jbyteArray jaSignature, jlong jpulSignatureLen);
//
//JNIEXPORT jbyteArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetID(
//		JNIEnv* env, jobject jobj, jlong jsessionID, jlong jhandle,
//		jlong jlength);
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindSignatureKey(
//		JNIEnv* env, jobject jobj, jlong jsessionID, jbyteArray jobjectID, jlong jsignatureKeyHandle);
//
//};
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_testInitToken(
//		JNIEnv * env, jobject obj) {
//	char* slot = (char*) "0";
//	char* label = (char*) "testSoftHSM_vnptcaHSM";
//	char* sopin = (char*) "12345678";
//	char* c_userpin = (char*) "12345678";
//	long re = initToken(slot, label, sopin, c_userpin);
//	return (jlong) re;
//}
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_testSignAndVerify(
//		JNIEnv * env, jobject obj) {
//	long re = testRsaSignVerify();
//	return (jlong) re;
//}
//
//// init Pin
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_InitPIN(
//		JNIEnv * env, jobject obj, jlong hSession, jstring pPin,
//		jlong ulPinLen) {
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	const char *pin = env->GetStringUTFChars(pPin, 0);
//	CK_UTF8CHAR_PTR c_pPin = (CK_UTF8CHAR_PTR) pin;
//	CK_ULONG c_ulPinLen = (CK_ULONG) ulPinLen;
//	long re = C_InitPIN(c_hSession, c_pPin, c_ulPinLen);
//	env->ReleaseStringUTFChars(pPin, pin);
//	return re;
//}
//
//// init Token
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_InitToken(
//		JNIEnv * env, jobject obj, jlong slotID, jstring pPin, jlong ulPinLen,
//		jstring pLabel) {
//	CK_SLOT_ID c_slotID = (CK_SLOT_ID) slotID;
//	CK_ULONG c_ulPinLen = (CK_ULONG) ulPinLen;
//
//	// Xử lý jString label -> char*
//	const char *label = env->GetStringUTFChars(pLabel, 0);
//
//	CK_UTF8CHAR paddedLabel[32];
//	memset(paddedLabel, ' ', sizeof(paddedLabel));
//	memcpy(paddedLabel, label, strlen(label));
//	//	std::string str(label, std::find(label, label + 10, '\0'));
//
//	// Xử lý jString pPin -> char*
//	const char *pin = env->GetStringUTFChars(pPin, 0);
//
//	CK_UTF8CHAR_PTR c_pPin = (CK_UTF8CHAR_PTR) pin;
//
//	long re = C_InitToken(c_slotID, c_pPin, c_ulPinLen, paddedLabel);
//	env->ReleaseStringUTFChars(pPin, pin);
//	env->ReleaseStringUTFChars(pLabel, label);
//	return re;
//}
//
////Close all sessions
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_CloseAllSessions(
//		JNIEnv * env, jobject obj, jlong slotID) {
//	CK_SLOT_ID c_slotID = (CK_SLOT_ID) slotID;
//	long re = C_CloseAllSessions(c_slotID);
//	return re;
//}
//
////open session
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_OpenSessionInit(
//		JNIEnv * env, jobject obj, jlong slotID, jlong flags,
//		jobjectArray pApplication, jlong phSession) {
//
//	CK_SLOT_ID c_slotID = (CK_SLOT_ID) slotID;
//	CK_FLAGS c_flags = (CK_FLAGS) flags;
//	CK_VOID_PTR c_pApplication = (CK_VOID_PTR) pApplication;
//	CK_SESSION_HANDLE c_phSession = (CK_SESSION_HANDLE) phSession;
//	LOGI("phSession %d", phSession);
//	long re = C_OpenSession(c_slotID, c_flags, c_pApplication, NULL_PTR,
//			&c_phSession);
//	LOGI("re %d", re);
//	LOGI("c_phSession %d", c_phSession);
//	return (jlong) c_phSession;
//}
//
////open session
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_OpenSession(
//		JNIEnv * env, jobject obj, jlong slotID, jlong flags,
//		jobjectArray pApplication, jlong phSession) {
//	if (!state.get()) {
//		state = std::auto_ptr<SoftHSMInternal>(new SoftHSMInternal());
//	}
//	CK_SLOT_ID c_slotID = (CK_SLOT_ID) slotID;
//	CK_FLAGS c_flags = (CK_FLAGS) flags;
//	CK_VOID_PTR c_pApplication = (CK_VOID_PTR) pApplication;
//	CK_SESSION_HANDLE c_phSession = (CK_SESSION_HANDLE) phSession;
//	LOGI("phSession %d", phSession);
//	long re = C_OpenSession(c_slotID, c_flags, c_pApplication, NULL_PTR,
//			&c_phSession);
//	LOGI("re %d", re);
//	LOGI("c_phSession %d", c_phSession);
//	return (jlong) c_phSession;
//}
//// login token
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Login(
//		JNIEnv * env, jobject obj, jlong hSession, jlong userType, jstring pPin,
//		jlong ulPinLen) {
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_USER_TYPE c_userType = (CK_USER_TYPE) userType;
//	CK_ULONG c_ulPinLen = (CK_ULONG) ulPinLen;
//
//	// jstring pPin -> char*
//	const char *pin = env->GetStringUTFChars(pPin, 0);
//
//	CK_UTF8CHAR_PTR c_pPin = (CK_UTF8CHAR_PTR) pin;
//
//	long re = C_Login(c_hSession, c_userType, c_pPin, c_ulPinLen);
//	env->ReleaseStringUTFChars(pPin, pin);
//	return re;
//}
//
///*
// * Wrapper for Login SO
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_LoginSO(
//		JNIEnv * env, jobject obj, jlong hSession)
//{
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_ULONG c_userType = CKU_SO;
//	CK_UTF8CHAR soPin[] = SLOT_0_SO1_PIN;
//	CK_ULONG c_ulCount = strlen((char*)soPin);
//	CK_ULONG re = C_Login(c_hSession, c_userType, soPin, c_ulCount);
//	return re;
//}
//
///*
// * Wrapper for Login SO
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_CloseSession(
//		JNIEnv * env, jobject obj, jlong hSession) {
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	long re = C_CloseSession(c_hSession);
//	return re;
//}
//
///*
// * Wrapper for generate RSA key pair
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GenerateRsaKeyPair(
//		JNIEnv * env, jobject obj, jlong hSession, jlong jslotID, jlong hPuk,
//		jlong hPrk, jlong keyLength) {
//
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_SLOT_ID c_slotID = (CK_SLOT_ID) jslotID;
//	CK_OBJECT_HANDLE oPrk = (CK_OBJECT_HANDLE) hPrk;
//	CK_OBJECT_HANDLE oPuk = (CK_OBJECT_HANDLE) hPuk;
//
//	CK_ULONG c_keyLength = (CK_ULONG) keyLength;
//	CK_ULONG length = 2048;
//	CK_UTF8CHAR pin[] = SLOT_0_USER1_PIN;
//
//	long re = genRSAKeyPair(c_hSession, c_slotID, pin, oPuk, oPrk, length);
////	long re = generateRsaKeyPair(mSessionRW, IN_SESSION, IS_PUBLIC, IN_SESSION,
////			IS_PRIVATE, mPuk, mPrk, c_keyLength);
//	if (re != 0) {
//		LOGI("Generate RSA key pair is sucessful!");
//	}
//	LOGI("Object handle of private key %d", re);
//	return (jlong) re;
//}
//
////get slots
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetSlotList(
//		JNIEnv * env, jobject obj, jlong pulCount) {
//
//	if (!state.get()) {
//			state = std::auto_ptr<SoftHSMInternal>(new SoftHSMInternal());
//		}
//
//	CK_ULONG c_pulCount = (CK_ULONG) pulCount;
//	CK_SLOT_ID_PTR c_pSlotList = NULL ;
//	CK_BBOOL tokenPresent = CK_FALSE;
//
//
//	long re = C_GetSlotList(tokenPresent, c_pSlotList, c_pulCount);
//
//	return (jlong) re;
//}
//
///*
// * Wrapper for GetSlotList
// */
//
////JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetSlotList(
////		JNIEnv * env, jobject obj, jlongArray jpSlotList, jlong jpulCount) {
////	CK_RV rv;
////	CK_BBOOL tokenPresent = CK_FALSE;
////	CK_SLOT_ID_PTR c_pSlotList;
////	CK_ULONG_PTR c_ulCount = (CK_ULONG_PTR) &jpulCount;
////	Converter* convert = new Converter();
////	convert->jLongArrayToCKULongArray(env, jpSlotList, &c_pSlotList, c_ulCount);
////	rv = C_GetSlotList(tokenPresent, c_pSlotList, *c_ulCount);
////	return rv;
////}
//
//
////find object init
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindObjectsInit(
//		JNIEnv * env, jobject obj, jlong hSession, jobjectArray joAttribute,
//		jlong ulCount) {
//	CK_RV rv = 0;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_ULONG c_ulCount = (CK_ULONG) ulCount;
//	CK_ATTRIBUTE_PTR pAttribute = NULL;
//	pAttribute = (CK_ATTRIBUTE_PTR) malloc(c_ulCount * sizeof(CK_ATTRIBUTE));
//	// Convert JObject ( class CK_ATTRIBUTE in java) to CK_ATTRIBUTE in c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	convert->JObjectToCKAttribute(env, obj, joAttribute, c_ulCount, pAttribute);
////	LOGI("%d ", *(CK_ULONG*)pAttribute->pValue);
////	assert( pAttribute != 0);
//	rv = C_FindObjectsInit(c_hSession, pAttribute, c_ulCount);
//	//free(pAttribute);
//	return rv;
//}
//
//// Cac ham ky
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_gethPuk(
//		JNIEnv * env, jobject obj) {
//	return (jlong) c_hPuk;
//}
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_gethPrk(
//		JNIEnv * env, jobject obj) {
//	return (jlong) mPrk;
//}
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignInit(
//		JNIEnv * env, jobject obj, jlong hSession, jlong pMechanism,
//		jlong hKey) {
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_MECHANISM_PTR c_pMechanism = (CK_MECHANISM_PTR) pMechanism;
//	CK_OBJECT_HANDLE c_hKey = (CK_OBJECT_HANDLE) hKey;
//	long re = C_SignInit(c_hSession, c_pMechanism, c_hKey);
//	return re;
//}
//
///*
// *  Wrapper for rsaPkcsSign
// */
//
//JNIEXPORT jbyteArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_rsaPkcsSign(
//		JNIEnv * env, jobject obj, jbyteArray jdata, jlong dataLen,
//		jlong mechanismType, jlong hSession, jlong hPrivateKey) {
//
//	CK_RV rv;
//	CK_BYTE_PTR ckpData = NULL_PTR;
//	CK_BYTE_PTR ckpSignature;
//	CK_ULONG ckDataLength;
//	CK_ULONG ckSignatureLength = 0;
//	jbyteArray jSignature;
//
//	CK_MECHANISM_TYPE c_mechanismType = (CK_MECHANISM_TYPE) mechanismType;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_OBJECT_HANDLE c_hPrivateKey = (CK_OBJECT_HANDLE) hPrivateKey;
//
//	Converter* convert = new Converter();
//	convert->jByteArrayToCKByteArray(env, jdata, &ckpData, &ckDataLength);
//
//	c_mechanism = (CK_MECHANISM) {c_mechanismType, NULL_PTR, 0};
//
//	rv = C_SignInit(c_hSession, &c_mechanism, c_hPrivateKey);
//	/* first determine the length of the signature */
//	LOGI("%d", rv);
//	rv = C_Sign(c_hSession, ckpData, ckDataLength, NULL_PTR,
//			&ckSignatureLength);
//	LOGI("%d", rv);
//	ckpSignature = (CK_BYTE_PTR) malloc(ckSignatureLength * sizeof(CK_BYTE));
//
//	rv = C_Sign(c_hSession, ckpData, ckDataLength, ckpSignature,
//			&ckSignatureLength);
//	LOGI("%d", rv);
//	// return jbyteArray
//	jSignature = convert->ckByteArrayToJByteArray(env, ckpSignature,
//			ckSignatureLength);
//	free(ckpData);
//	free(ckpSignature);
//	LOGI("Finished rsaPkcsSign!");
//	return jSignature;
//}
//


//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_rsaPkcsVerify(
//		JNIEnv * env, jobject obj, jlong mechanismType, jlong hSession,
//		jlong hPublicKey, jbyteArray jdata, jbyteArray jsignature) {
//
//	CK_RV rv;
//	CK_BYTE_PTR ckpData = NULL_PTR;
//	CK_BYTE_PTR ckpSignature = NULL_PTR;
//	CK_ULONG ckDataLength;
//	CK_ULONG ckSignatureLength;
//
//	CK_MECHANISM_TYPE c_mechanismType = (CK_MECHANISM_TYPE) mechanismType;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_OBJECT_HANDLE c_hPublicKey = (CK_OBJECT_HANDLE) hPublicKey;
//
//	rv = C_VerifyInit(c_hSession, &c_mechanism, c_hPublicKey);
//
//	//	Converter* convert = new Converter();
//	//	convert->jByteArrayToCKByteArray(env, jdata, &ckpData, &ckDataLength);
//	//	convert->jByteArrayToCKByteArray(env, jsignature, &ckpSignature,
//	//			&ckSignatureLength);
//	//
//	//	rv = C_Verify(c_hSession, ckpData, ckDataLength, ckpSignature,
//	//			ckSignatureLength);
//
//	return rv;
//}

/*
 *  Wrapper for rsaPkcsVerify
 */
//long VerifyRSA(int mechanismType, sessionID,
//		int hPublicKey, CK_BYTE_PTR datap, CK_BYTE_PTR signaturep) {
//
//	CK_RV rv;
//	CK_BYTE_PTR ckpData = NULL_PTR;
//	CK_BYTE_PTR ckpSignature = NULL_PTR;
//	CK_ULONG ckDataLength;
//	CK_ULONG ckSignatureLength;
//
//   // rv = C_VErify
//	rv = C_VerifyInit(sessionID, &c_mechanism, c_hPublicKey);

	//	Converter* convert = new Converter();
	//	convert->jByteArrayToCKByteArray(env, jdata, &ckpData, &ckDataLength);
	//	convert->jByteArrayToCKByteArray(env, jsignature, &ckpSignature,
	//			&ckSignatureLength);
	//
	//	rv = C_Verify(c_hSession, ckpData, ckDataLength, ckpSignature,
	//			ckSignatureLength);

//	return rv;
//}
//
///*
// *  Wrapper for C_Initialize
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Initialize(
//		JNIEnv * env, jobject obj, jobject joInitArgs) {
//	CK_RV rv;
//	CK_VOID_PTR pInitArgs = (CK_VOID_PTR) joInitArgs;
//	rv = C_Initialize(pInitArgs);
//	return rv;
//
//}
//
///*
// *  Wrapper for C_Finalize
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Finalize(
//		JNIEnv * env, jobject obj, jobject joReserved) {
//	//Convert from jobject to void * pointer
//	CK_VOID_PTR pReserved = (CK_VOID_PTR) joReserved;
//	// Call core function
//	CK_RV rv = C_Finalize(pReserved);
//	return rv;
//}
//
///*
// *  Wrapper for C_GetSlotInfo
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetSlotInfo(
//		JNIEnv * env, jobject obj, jlong jslotID, jobject jobj) {
//	CK_SLOT_INFO_PTR slotp;
//	CK_SLOT_ID slotID = (CK_SLOT_ID) jslotID;
//	Converter* convert = new Converter();
//	// Give empty jobject to
//	slotp = convert->JObjectToCKSlotInfo(env, jobj);
//	CK_RV rv = C_GetSlotInfo(slotID, slotp);
//	delete convert;
//	return rv;
//
//}
//
///*
// *  Wrapper for C_GetTokenInfo
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetTokenInfo(
//		JNIEnv * env, jobject obj, jlong jslotID, jobject jobj) {
//	CK_RV rv;
//	CK_TOKEN_INFO_PTR tokenp;
//	CK_SLOT_ID slotID = (CK_SLOT_ID) jslotID;
//	Converter* convert = new Converter();
//	// Give empty jobject to
//	tokenp = convert->JObjectToCKTokenInfo(env, jobj);
//	rv = C_GetTokenInfo(slotID, tokenp);
//	delete convert;
//	return rv;
//
//}
//
///*
// *  Wrapper for C_GetSessionInfo
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetSessionInfo(
//		JNIEnv * env, jobject obj, jlong jhSession, jobject joSessionInfo) {
//	CK_RV rv;
//	CK_SESSION_INFO_PTR sessionp;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	// Create a converter
//	Converter* convert = new Converter();
//	sessionp = convert->JObjectToCKSessionInfo(env, joSessionInfo);
//	rv = C_GetSessionInfo(c_hSession, sessionp);
//
//	// Realease memory
//	delete convert;
//	return rv;
//}
//
///*
// *  Wrapper for C_GetMechanismList
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetMechanismList(
//		JNIEnv * env, jobject obj, jlong jslotID, jlongArray jaMechanismList,
//		CK_ULONG_PTR julCount) {
//	CK_RV rv;
//	CK_SLOT_ID c_slotID = (CK_SLOT_ID) jslotID;
//	CK_ULONG_PTR c_pulCount = (CK_ULONG_PTR) &julCount;
//	// Create a converter
//	Converter* convert = new Converter();
//	// Convert jlongArray to long array of c/c++
//	CK_MECHANISM_TYPE_PTR pMechanismList;
//	convert->jLongArrayToCKULongArray(env, jaMechanismList,
//			(CK_ULONG_PTR*) &pMechanismList, c_pulCount);
//
//	rv = C_GetMechanismList(c_slotID, pMechanismList, c_pulCount);
//	delete convert;
//	return rv;
//}
//
///*
// *  Wrapper for C_GetMechanismInfo
// */JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetMechanismInfo(
//		JNIEnv * env, jobject obj, jlong jslotID, jlong jtype,
//		jobject joMechanismInfo) {
//	CK_RV rv;
//	CK_SLOT_ID c_slotID = (CK_SLOT_ID) jslotID;
//	CK_MECHANISM_TYPE c_type = (CK_MECHANISM_TYPE) &jtype;
//
//	// Convert jobject (clas CK_MECHANISM_INFO) to struct
//	Converter* convert = new Converter();
//	// Convert jlongArray to long array of c/c++
//	CK_MECHANISM_INFO_PTR pMechanismInfo = NULL;
//	pMechanismInfo = convert->JObjectToCKMechanismInfo(env, joMechanismInfo);
//	assert(pMechanismInfo != NULL);
//	rv = C_GetMechanismInfo(c_slotID, c_type, pMechanismInfo);
//}
//
///*
// *  Wrapper for C_GetInfo
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetInfo(
//		JNIEnv * env, jobject obj, jobject joInfo) {
//	// Convert jobject (clas CK_INFO_PTR) to struct
//	Converter* convert = new Converter();
//	CK_INFO_PTR pInfo = NULL;
//	pInfo = convert->JObjectToCKInfo(env, joInfo);
//	assert(pInfo != NULL);
//	CK_RV rv = C_GetInfo(pInfo);
//	return rv;
//
//}
//
///*
// *  Wrapper for C_CreateObject
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_CreateObject(
//		JNIEnv * env, jobject obj, jlong jhSession, jobjectArray joAttribute,
//		jlong julCount, jlong jphObject) {
//	CK_RV rv;
//	jobject jobj;
//	// Find the length of object array
//	CK_ULONG ulLength = (CK_ULONG) env->GetArrayLength(joAttribute);
//	// Allocate for CK_ATTRIBUTE
//	CK_ATTRIBUTE_PTR pAttribute = new CK_ATTRIBUTE[ulLength + 1];
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_ulCount = (CK_ULONG) julCount;
//	CK_ULONG_PTR c_phObject = (CK_ULONG_PTR) &jphObject;
//
//	// Convert JObject ( class CK_ATTRIBUTE in java) to CK_ATTRIBUTE in c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	// Get length of object array
//	CK_ATTRIBUTE_PTR cAttribute = new CK_ATTRIBUTE;
//
//	for (CK_ULONG i = 0; i < ulLength && i < c_ulCount; ++i) {
//		convert->JObjectToCKAttribute(env, obj, joAttribute, c_ulCount,
//				cAttribute);
//		jobj = convert->ckAttributePtrToJAttribute(env, cAttribute, c_ulCount);
//	}
//
//	rv = C_CreateObject(c_hSession, pAttribute, c_ulCount, c_phObject);
//
//	// Convert pAttribute to jobjectArray
//	for (int i = 0; i < ulLength && i < c_ulCount; ++i) {
//		//jobj = 	env->GetObjectArrayElement(joAttribute,i);
//
//	}
//
//	// Return
//	return rv;
//}
//
///*
// *  Wrapper for C_DestroyObject
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DestroyObject(
//		JNIEnv * env, jobject obj, jlong jhSession, jlong jhObject) {
//	CK_RV rv = -1;
//	if (!state.get()) {
//			state = std::auto_ptr<SoftHSMInternal>(new SoftHSMInternal());
//		}
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_OBJECT_HANDLE c_hObject = (CK_OBJECT_HANDLE) jhObject;
//	rv = C_DestroyObject(c_hSession, c_hObject);
//	return rv;
//}
//
///*
// *  Wrapper for C_GetAttributeValue
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetAttributeValue(
//		JNIEnv * env, jobject obj, jlong jhSession, jlong jhObject,
//		jobjectArray joAttribute, jlong julCount) {
//	CK_RV rv;
//
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_OBJECT_HANDLE c_hObject = (CK_OBJECT_HANDLE) jhObject;
//	CK_ULONG c_ulCount = (CK_ULONG) julCount;
//	CK_ATTRIBUTE_PTR pAttribute = NULL;
//
//	// Convert JObject ( class CK_ATTRIBUTE in java) to CK_ATTRIBUTE in c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	convert->JObjectToCKAttribute(env, obj, joAttribute, c_ulCount, pAttribute);
//	assert( pAttribute != 0);
//	rv = C_GetAttributeValue(c_hSession, c_hObject, pAttribute, c_ulCount);
//	// Return about byte array including information
//	jobjectArray jAttributeObject;
//	jAttributeObject = convert->ckAttributePtrToJAttribute(env, pAttribute,
//			c_ulCount);
//	// Return
//	return rv;
//}
//
///*
// *  Wrapper for C_SetAttributeValue
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SetAttributeValue(
//		JNIEnv * env, jobject jobj, jlong jhSession, jlong jhObject,
//		jobjectArray joAttribute, jlong julCount) {
//	LOGI("0");
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_OBJECT_HANDLE c_hObject = (CK_OBJECT_HANDLE) jhObject;
//	CK_ULONG c_ulCount = (CK_ULONG) julCount;
//	CK_ATTRIBUTE_PTR pAttribute = new CK_ATTRIBUTE[c_ulCount];
//	assert( pAttribute != 0);
//	LOGI("1");
//	// Convert JObject ( class CK_ATTRIBUTE in java) to CK_ATTRIBUTE in c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	convert->JObjectToCKAttribute(env, jobj, joAttribute, c_ulCount,
//			pAttribute);
//	LOGI("pValue :%d", pAttribute[0].pValue);
//	LOGI("pValue :%s", pAttribute[1].pValue);
//	rv = C_SetAttributeValue(c_hSession, c_hObject, pAttribute, c_ulCount);
//	LOGI("return rv : %d", rv);
//	LOGI("2");
//	// Convert from c/c++ to java class
//	// Return about byte array including information
////	jobjectArray jAttributeObject;
////	jAttributeObject = convert->ckAttributePtrToJAttribute(env, pAttribute,
////			c_ulCount);
//	LOGI("3");
//	delete[] pAttribute;
//	return rv;
//}
//
///*
// *  Wrapper for C_SetPIN
// */JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SetPIN(
//		JNIEnv * env, jobject obj, jlong hSession, jstring jOldPin,
//		jlong julOldLen, jstring jNewPin, jlong julNewLen) {
//	// Convert from jstring to const char* and CK_UTF8_CHAR
//	// Using functions GetStringUTFChars
//	const char* pOldPin = env->GetStringUTFChars(jOldPin, 0);
//	const char* pNewPin = env->GetStringUTFChars(jNewPin, 0);
//	// Casting it
//	// Transform from jlong to CK_ULONG by casting directly
//	CK_ULONG c_ulOldLen = (CK_ULONG) julOldLen;
//	CK_ULONG c_ulNewLen = (CK_ULONG) julNewLen;
//	// Casting remain variables
//	CK_UTF8CHAR_PTR c_pOldPin = (CK_UTF8CHAR_PTR) pOldPin;
//	CK_UTF8CHAR_PTR c_pNewPin = (CK_UTF8CHAR_PTR) pNewPin;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	//Call core funtion
//	CK_RV rv = C_SetPIN(c_hSession, c_pOldPin, c_ulOldLen, c_pNewPin,
//			c_ulNewLen);
//	env->ReleaseStringUTFChars(jOldPin, pOldPin);
//	env->ReleaseStringUTFChars(jNewPin, pNewPin);
//	return rv;
//}
//
///*
// *  Wrapper for C_FindObjecs
// */
//
//JNIEXPORT jlongArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindObjects(
//		JNIEnv* env, jobject obj, jlong jhSession, jlongArray jphObject,
//		jlong julMaxObjectCount, jlongArray jpulObjectCount) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//
//	CK_ULONG c_ulMaxObjectCount = (CK_ULONG) julMaxObjectCount;
//
//	CK_ULONG c_ulCount1 = (env)->GetArrayLength(jphObject);
//	CK_ULONG c_ulCount2 = (env)->GetArrayLength(jpulObjectCount);
//	LOGI("1 = %d, 2 = %d",c_ulCount1, c_ulCount2);
//
//	CK_OBJECT_HANDLE_PTR c_phObject  = (CK_ULONG_PTR) malloc(c_ulCount1 * sizeof(CK_ULONG));
//	CK_ULONG_PTR c_pulObjectCount  = (CK_ULONG_PTR) malloc(c_ulCount2 * sizeof(CK_ULONG));
//	LOGI("1");
//	Converter* convert = new Converter();
//	convert->jLongArrayToCKULongArray(env, jphObject, &c_phObject, &c_ulCount1);
//	convert->jLongArrayToCKULongArray(env, jpulObjectCount, &c_pulObjectCount, &c_ulCount2);
//	LOGI("2");
//	for(int i = 0 ; i < 10 ; i++){
//			LOGI("c_phObject1 = %x", *(c_phObject+i));
//			c_phObject++;
//		}
//	rv = C_FindObjects(c_hSession, c_phObject, c_ulMaxObjectCount,
//			c_pulObjectCount);
//	LOGI("3");
//	//CK_ULONG len = 100;
//	for(int i = 0 ; i < 10 ; i++){
//			LOGI("c_phObject = %x", c_phObject[i]);
//		}
//	// Convert to array of long
//	jphObject = convert->ckULongArrayToJLongArray(env, (CK_ULONG_PTR)c_phObject, *c_pulObjectCount);
//	//free(c_phObject);
//	return jphObject;
//
//}
///*
// *  Wrapper for C_FindObjecFinal
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindObjectsFinal(
//		JNIEnv * env, jobject obj, jlong jhSession) {
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	// Call FindObjectFinal function
//	CK_RV rv = C_FindObjectsFinal(c_hSession);
//	return rv;
//}
//
///*
// *  Wrapper for C_Sign function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Sign(JNIEnv* env,
//		jobject jobj, jlong jhSession, jbyteArray jaData, jlong julDataLen,
//		jbyteArray jaSignature, jlong jpulSignatureLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_ulDataLen = (CK_ULONG) julDataLen;
//	CK_ULONG_PTR c_pulSignatureLen = (CK_ULONG_PTR) &jpulSignatureLen;
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pData = NULL;
//	CK_BYTE_PTR pSignature = NULL;
//	convert->jByteArrayToCKByteArray(env, jaData, &pData, &c_ulDataLen);
//	convert->jByteArrayToCKByteArray(env, jaSignature, &pSignature,
//			c_pulSignatureLen);
//
//	rv = C_Sign(c_hSession, pData, c_ulDataLen, pSignature, c_pulSignatureLen);
//	return rv;
//
//}
//
///*
// *  Wrapper for C_SignUpdate function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignUpdate(
//		JNIEnv*env, jobject jobj, jlong jhSession, jbyteArray jpPart,
//		jlong julPartLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_pulPartLen = (CK_ULONG) julPartLen;
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pPart = NULL;
//	convert->jByteArrayToCKByteArray(env, jpPart, &pPart, &c_pulPartLen);
//
//	rv = C_SignUpdate(c_hSession, pPart, c_pulPartLen);
//
//}
//
///*
// *  Wrapper for C_SignFinal function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignFinal(
//		JNIEnv*env, jobject jobj, jlong jhSession, jbyteArray jpSignature,
//		jlong jpulSignatureLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_pulSignatureLen = (CK_ULONG) jpulSignatureLen;
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pSignature = NULL;
//	convert->jByteArrayToCKByteArray(env, jpSignature, &pSignature,
//			&c_pulSignatureLen);
//
//	rv = C_SignUpdate(c_hSession, pSignature, c_pulSignatureLen);
//	return rv;
//
//}
//
///*
// *  Wrapper for C_Encypt function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_EncryptInit(
//		JNIEnv * env, jobject obj, jlong jhSession, jobject joMechanism,
//		jlong jhKey) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_OBJECT_HANDLE c_hKey = (CK_OBJECT_HANDLE) jhKey;
//	// Convert jobject (CK_MECHANISM of java) to struct in c/c++
//	Converter* convert = new Converter();
//	CK_MECHANISM_PTR pMechanism = NULL;
//	pMechanism = convert->JObjectToCKMechanism(env, joMechanism);
//
//	rv = C_EncryptInit(c_hSession, pMechanism, c_hKey);
//	return rv;
//
//}
//
///*
// *  Wrapper for C_Encypt function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Encrypt(
//		JNIEnv * env, jobject obj, jlong jhSession, jstring jData,
//		jlong ulDataLen, jstring jEncryptedData, jlong jpulEncryptedDataLen) {
//	//Casting variables
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_ulDataLen = (CK_ULONG) ulDataLen;
//	// From jstring to CK_BYTE_PTR (usigned char*)
//	// Convert to const char*
//	const char* pData = env->GetStringUTFChars(jData, 0);
//	const char* pEncryptedData = env->GetStringUTFChars(jEncryptedData, 0);
//	CK_BYTE_PTR c_pData = (CK_BYTE_PTR) pData;
//	CK_BYTE_PTR c_pEncryptedData = (CK_BYTE_PTR) pEncryptedData;
//	// From jlongArray to CK_ULONG_PTR
//	// Create a converter object
//	Converter* convert = new Converter();
//	//CK_ULONG_PTR c_pulEncryptedDataLen = NULL_PTR;
//	//CK_ULONG c_Length = 1;
//	//convert->jLongArrayToCKULongArray(env,jpulEncryptedDataLen,&c_pulEncryptedDataLen,&c_Length);
//	CK_ULONG_PTR c_pulEncryptedDataLen = (CK_ULONG_PTR) &jpulEncryptedDataLen;
//
//	CK_RV rv = C_Encrypt(c_hSession, c_pData, c_ulDataLen, c_pEncryptedData,
//			c_pulEncryptedDataLen);
//	env->ReleaseStringUTFChars(jData, pData);
//	env->ReleaseStringUTFChars(jEncryptedData, pEncryptedData);
//	return rv;
//}
//
///*
// *  Wrapper for C_Decrypt function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Decrypt(
//		JNIEnv* env, jobject jobj, jlong jhSession, jstring jEncryptedData,
//		jlong julEncryptedDataLen, jstring jData, jlong julDataLen) {
//	// Casting variable
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_ulEncryptedDataLen = (CK_ULONG) julEncryptedDataLen;
//	// From jstring to CK_BYTE_PTR (usigned char*)
//	// Convert to const char*
//	const char* pEncryptedData = env->GetStringUTFChars(jEncryptedData, 0);
//	const char* pData = env->GetStringUTFChars(jData, 0);
//	CK_BYTE_PTR c_pEncryptedData = (CK_BYTE_PTR) pEncryptedData;
//	CK_BYTE_PTR c_pData = (CK_BYTE_PTR) pData;
//	//
//	CK_ULONG_PTR c_ulDataLen = (CK_ULONG_PTR) &julDataLen;
//	CK_RV rv = C_Decrypt(c_hSession, c_pEncryptedData, c_ulEncryptedDataLen,
//			c_pData, c_ulDataLen);
//
//	env->ReleaseStringUTFChars(jEncryptedData, pEncryptedData);
//	env->ReleaseStringUTFChars(jData, pData);
//	return rv;
//}
//
///*
// *  Wrapper for C_DecryptInit function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DecryptInit(
//		JNIEnv* env, jobject jobj, jlong jhSession, jobject joMechanism,
//		jlong jhKey) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_OBJECT_HANDLE c_hKey = (CK_OBJECT_HANDLE) jhKey;
//	// Convert jobject (CK_MECHANISM of java) to struct in c/c++
//	Converter* convert = new Converter();
//	CK_MECHANISM_PTR pMechanism = NULL;
//	pMechanism = convert->JObjectToCKMechanism(env, joMechanism);
//
//	rv = C_DecryptInit(c_hSession, pMechanism, c_hKey);
//	return rv;
//}
//
///*
// *  Wrapper for C_DigestInit
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DigestInit(
//		JNIEnv* env, jobject jobj, jlong jhSession, jobject joMechanism) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	// Convert jobject (CK_MECHANISM of java) to struct in c/c++
//	Converter* convert = new Converter();
//	CK_MECHANISM_PTR pMechanism = NULL;
//	pMechanism = convert->JObjectToCKMechanism(env, joMechanism);
//
//	rv = C_DigestInit(c_hSession, pMechanism);
//	return rv;
//}
//
///*
// * Wrapper for C_Digest function
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Digest(
//		JNIEnv* env, jobject jobj, jlong jhSession, jstring jData,
//		jlong julDataLen, jstring jDigest, jlong julDigestLen) {
//	// Casting variable
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_ulDataLen = (CK_ULONG) julDataLen;
//	// From jstring to CK_BYTE_PTR (usigned char*)
//	// Convert to const char*
//	const char* pData = env->GetStringUTFChars(jData, 0);
//	const char* pDigest = env->GetStringUTFChars(jDigest, 0);
//	CK_BYTE_PTR c_pData = (CK_BYTE_PTR) pData;
//	CK_BYTE_PTR c_pDigest = (CK_BYTE_PTR) pDigest;
//	// Declare unsigned long poniter
//	CK_ULONG_PTR c_ulDigestLen = (CK_ULONG_PTR) &julDigestLen;
//	CK_RV rv = C_Digest(c_hSession, c_pData, c_ulDataLen, c_pDigest,
//			c_ulDigestLen);
//	env->ReleaseStringUTFChars(jDigest, pDigest);
//	env->ReleaseStringUTFChars(jData, pData);
//	return rv;
//}
//
///*
// *  Wrapper for C_DigestUpdatei
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DigestUpdate(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpPart,
//		jlong julPartLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_ulPartLen = (CK_ULONG) julPartLen;
//	// Convert jbyteArray to CK_BYTE_PTR of c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pPart = NULL;
//	convert->jByteArrayToCKByteArray(env, jpPart, &pPart, &c_ulPartLen);
//	assert(pPart != NULL);
//	// Call core function
//	rv = C_DigestUpdate(c_hSession, pPart, julPartLen);
//	return rv;
//}
//
///*
// *  Wrapper for C_DigestFinal
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_DigestFinal(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpDigest,
//		jlong jpulDigestLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG_PTR c_pulDigestLen = (CK_ULONG_PTR) &jpulDigestLen;
//	// Convert jbyteArray to CK_BYTE_PTR of c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pDigest = NULL;
//	convert->jByteArrayToCKByteArray(env, jpDigest, &pDigest, c_pulDigestLen);
//	assert(pDigest != NULL);
//	// Call core function
//	rv = C_DigestFinal(c_hSession, pDigest, c_pulDigestLen);
//	return rv;
//}
//
///*
// *  Wrapper for C_VerifyInit
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_VerifyInit(
//		JNIEnv* env, jobject jobj, jlong jhSession, jobject joMechanism,
//		jlong jhKey) {
//
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_OBJECT_HANDLE c_hKey = (CK_OBJECT_HANDLE) jhKey;
//	// Convert jobject (CK_MECHANISM of java) to struct in c/c++
//	Converter* convert = new Converter();
//	CK_MECHANISM_PTR pMechanism = NULL;
//	pMechanism = convert->JObjectToCKMechanism(env, joMechanism);
//
//	rv = C_VerifyInit(c_hSession, pMechanism, c_hKey);
//	return rv;
//}
//
///*
// *  Wrapper for C_Verify
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Verify(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpData,
//		jlong julDataLen, jbyteArray jpSignature, jlong julSignatureLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG c_ulDataLen = (CK_ULONG) julDataLen;
//	CK_ULONG c_ulSignatureLen = (CK_ULONG) julSignatureLen;
//	// Convert jbyteArray to CK_BYTE_PTR of c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pData = NULL;
//	CK_BYTE_PTR pSignature = NULL;
//	convert->jByteArrayToCKByteArray(env, jpData, &pData, &c_ulDataLen);
//	assert(pData != 0);
//	convert->jByteArrayToCKByteArray(env, jpSignature, &pSignature,
//			&c_ulSignatureLen);
//	assert(pSignature != 0);
//
//	rv = C_Verify(c_hSession, pData, c_ulDataLen, pSignature, c_ulSignatureLen);
//	return rv;
//
//}
//
///*
// *  Wrapper for C_VerifyUpdate
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_VerifyUpdate(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpPart,
//		jlong julPartLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG_PTR c_ulPartLen = (CK_ULONG_PTR) &julPartLen;
//	// Convert jbyteArray to CK_BYTE_PTR of c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pPart = NULL;
//	convert->jByteArrayToCKByteArray(env, jpPart, &pPart, c_ulPartLen);
//	assert(pPart != 0);
//
//	rv = C_VerifyUpdate(c_hSession, pPart, *c_ulPartLen);
//	return rv;
//}
//
///*
// *  Wrapper for C_VerifyFinal
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_VerifyFinal(
//		JNIEnv* env, jobject jobj, jlong jhSession, jbyteArray jpSignature,
//		jlong julSignatureLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	CK_ULONG_PTR c_pulSignatureLen = (CK_ULONG_PTR) &julSignatureLen;
//	// Convert jbyteArray to CK_BYTE_PTR of c/c++
//	// Create a converter
//	Converter* convert = new Converter();
//	CK_BYTE_PTR pSignature = NULL;
//	convert->jByteArrayToCKByteArray(env, jpSignature, &pSignature,
//			c_pulSignatureLen);
//	assert(pSignature != 0);
//
//	rv = C_VerifyFinal(c_hSession, pSignature, *c_pulSignatureLen);
//	return rv;
//}
//
///*
// *  Wrapper for C_Logout
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_Logout(
//		JNIEnv* env, jobject obj, jlong jhSession) {
//	CK_RV rv;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) jhSession;
//	rv = C_Logout(c_hSession);
//	return rv;
//}
//


/*
 *  Get information in certificate
 *
 */
CK_ULONG MakeCKAttribute(const Botan::X509_Certificate* cert,
		CK_ATTRIBUTE_PTR pAttribute, const char* s)
{

	// Get information provider
	Botan::X509_DN issuer_dn = cert->issuer_dn();
	// Get information who is provider certificate
	Botan::X509_DN subject_dn = cert->subject_dn();
	// Get serial
	// Counter to caculate the number attribute to be created
	CK_ULONG count = 0;
	// Type of certificate
	pAttribute[count].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
	pAttribute[count].type = CKA_CERTIFICATE_TYPE;
	CK_CERTIFICATE_TYPE certType = CKC_X_509;
	pAttribute[count].pValue = &certType;
	pAttribute[count].ulValueLen = sizeof(certType);
	count++;
    
	// Create CKA_CLASS
	pAttribute[count].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
	pAttribute[count].type = CKA_CLASS;
	const char* oClass = "CERT";
	pAttribute[count].pValue = (void*)oClass;
	pAttribute[count].ulValueLen = sizeof(oClass);
	count++;

	// Create CKA_TOKEN
	pAttribute[count].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
	pAttribute[count].type = CKA_TOKEN;
	CK_BBOOL isToken = 1;
	pAttribute[count].pValue = (void*)&isToken;
	pAttribute[count].ulValueLen = sizeof(isToken);
	count++;
    
	// Get serial number
	Botan::MemoryVector<unsigned char> serVector = cert->serial_number();
	int sizeVector = serVector.size();

	// Create a string to save pValue
	std::string serialStr("");
	CK_BYTE_PTR pSerial = (CK_BYTE_PTR) malloc(16 * sizeof(CK_BYTE));
	for (int i = 0; i < sizeVector; ++i) {
		// Convert pValue to string
		pSerial[i] = serVector[i];
	}

	pAttribute[count].pValue = (CK_VOID_PTR) malloc(16 * sizeof(CK_CHAR));
	pAttribute[count].type = CKA_SERIAL_NUMBER;
	pAttribute[count].pValue = (void*) pSerial;
	pAttribute[count].ulValueLen = 16 * sizeof(CK_CHAR);
	count++;
    
    // CKA_ID
	//const char* s = "ABCD";
	pAttribute[count].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
	pAttribute[count].type = CKA_ID;
	pAttribute[count].pValue = (void*)s;
	pAttribute[count].ulValueLen = 4 * sizeof(CK_CHAR);
	count++;

	// Create attribute CKA_VALUE
	// Get byte which includes information certificate
	Botan::MemoryVector<unsigned char> vectCert = cert->BER_encode();
	pAttribute[count].pValue = (CK_VOID_PTR) malloc(vectCert.size() * sizeof(CK_CHAR));
	pAttribute[count].type = CKA_VALUE;

	char* valueStr  = (char*) malloc(vectCert.size() * sizeof(CK_CHAR));
	for(int i = 0 ; i < vectCert.size() ;  ++i )
	{
		valueStr[i] = vectCert[i];
	}
	pAttribute[count].pValue = (void*) valueStr;
	pAttribute[count].ulValueLen = vectCert.size() * sizeof(CK_CHAR);
	count++;

	// Create CKA_LABEL
	pAttribute[count].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
	pAttribute[count].type = CKA_LABEL;
	const char* label = "CERT";
	pAttribute[count].pValue = (void*)label;
	pAttribute[count].ulValueLen = sizeof(label);
	count++;

	return count;
}


//	// Convert jstring to const char*
//	//	const char* pPath = env->GetStringUTFChars(jpath,false);
//	CK_SESSION_HANDLE sessionID = (CK_SESSION_HANDLE) jsessionID;
//	// Read certificate
//	const Botan::X509_Certificate* cert = new Botan::X509_Certificate(
//			"/mnt/sdcard/TestCert.pem");
//	assert(cert != 0);
//
//	// Get fields in certificate
//	// Create ck_attribute
//
//	CK_ATTRIBUTE_PTR pAttribute = (CK_ATTRIBUTE_PTR) malloc(
//			7 * sizeof(CK_ATTRIBUTE));
//
//#ifdef SOFTHSM_DB
//	if(pAttribute == 0)
//	{
//		LOGI("ERROR when create attribute pointer");
//	}
//#endif
//
//	CK_ULONG attributeLen = 0;
//	attributeLen = MakeCKAttribute(cert, pAttribute);
//    LOGI("Type = %d, CKA_TOKEN = %d", pAttribute[5].type, *(CK_CHAR*)pAttribute[2].pValue);
//
//#ifdef SOFTHSM_DB
//	if(attributeLen > 5)
//	{
//		LOGI("pAttribute[5].type: %d", pAttribute[5].type);
//		LOGI("The first value of  pAttribute[5].type: %x", *((CK_CHAR*)pAttribute[5].pValue));
//		//LOGI("pAttribute[5].pValue: %s", *(CK_CHAR*)pAttribute[5].pValue);
//	}
//#endif
//
//	// Import certificate to database
//	// Get SoftHSM
//	SoftHSMInternal *softHSM = state.get();
//	assert( softHSM != 0);
//
//	SoftSession* softSession = softHSM->getSession(sessionID);
//	assert( softSession != 0);
//
//#ifdef SOFTHSM_DB
//	LOGI("Current session id : %d", sessionID );
//#endif
//
//	CK_OBJECT_HANDLE oHandle = softSession->db->importPublicCert(pAttribute,
//			attributeLen);
//
//#ifdef SOFTHSM_DB
//	LOGI("oHandle : %d", oHandle );
//#endif
//	return oHandle;
////	if(oHandle != 0 )
////	return CKR_OK;
////	else return 1;
//
////	LOGI("Handle : %d", oHandle);
////	//Read certificate to test
////	CK_ATTRIBUTE_PTR pAtt = (CK_ATTRIBUTE_PTR) malloc(4 * sizeof(CK_ATTRIBUTE));
////	pAtt[0].type = CKA_CERTIFICATE_TYPE;
////	pAtt[0].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
////	pAtt[0].ulValueLen = sizeof(CK_OBJECT_CLASS);
////	pAtt[1].type = CKA_CLASS;
////	pAtt[1].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
////	CK_OBJECT_CLASS Handle = CKO_CERTIFICATE;
////	pAtt[1].ulValueLen = sizeof(CK_OBJECT_CLASS);
////	pAtt[1].pValue = (void*) &Handle;
////
////	pAtt[2].type = CKA_TOKEN;
////	pAtt[2].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
////
////	pAtt[2].ulValueLen = sizeof(CK_BBOOL);
////	pAtt[3].type = CKA_SERIAL_NUMBER;
////	pAtt[3].pValue = (CK_VOID_PTR) malloc(16 * sizeof(CK_CHAR));
////	pAtt[3].ulValueLen = 32 * sizeof(CK_CHAR);
////	for (int i = 0; i < attributeLen; ++i) {
////		LOGI("Before type : %d", pAtt[i].type);
////		//CK_VOID_PTR p = (CK_VOID_PTR) pAtt[i].pValue;
////		//assert(p != 0);
////	}
////	LOGI("Begin getAttributeValue");
////	rv = softHSM->getAttributeValue(sessionID, oHandle, pAtt, attributeLen);
////	LOGI("%d", rv);
////	LOGI("%d", attributeLen);
////	for (int i = 0; i < attributeLen; ++i) {
////		LOGI("After type : %d", pAtt[i].type);
////		//CK_VOID_PTR p = (CK_VOID_PTR) pAtt[i].pValue;
////		assert(pAtt[i].pValue != NULL_PTR);
////	}
////	LOGI("%d", pAtt[1].pValue);
////	LOGI("9");
////	Converter* convert = new Converter();
////	jobjectArray obj = convert->ckAttributePtrToJAttribute(env, pAtt,
////			attributeLen);
////	LOGI("10");
////
////	//Release memory
//////	for(int i = 0 ; i < attributeLen ; ++i )
//////	{
//////		free(pAtt[i].pValue);
//////	}
////	free(pAttribute);
////	free(pAtt);
////
////	return obj;
//}
//
//
//void CheckPublicKey(CK_SESSION_HANDLE sessionID, CK_OBJECT_HANDLE mPrk)
//{
//	SoftHSMInternal *softHSM = state.get();
//	SoftSession *session = softHSM->getSession(sessionID);
//	//Botan::X509_Cert_Options opts("Hoang Test/VN/VNPT/VN");
//	//	session->db->
//	Botan::Public_Key *cryptoKey = session->getKey(mPrk);
//
//	Botan::MemoryVector<unsigned char> bVect = cryptoKey->x509_subject_public_key();
//		//LOGI("Length = %d", bVect.pinLength);
//	for(int i = 0 ; i < 30; i++)
//		{
//		  LOGI("Value ------------ = %x", bVect[i]);
//		}
//}


// Wrapper for import cert function for iOS

CK_RV importCert(CK_SESSION_HANDLE sessionID, const char* str, const char* s)
{
    //CK_RV rv ;
    
    // Step 1:
    // Read certificate
    const Botan::X509_Certificate* cert = new Botan::X509_Certificate(str);
    assert(cert != 0);
    
    // Step 2:
    // Make attributes
    int size = 7;
    CK_ATTRIBUTE_PTR pAttributes = (CK_ATTRIBUTE_PTR) malloc( size * sizeof(CK_ATTRIBUTE));
    
    int attributeLen = MakeCKAttribute(cert, pAttributes, s);
    
    // Step 3:
    // Import certificate to database
    
    // Get SoftHSM
    SoftHSMInternal *softHSM = state.get();
    assert( softHSM != 0);
    // Get session 
    SoftSession* softSession = softHSM->getSession(sessionID);
    assert( softSession != 0);
    
    //Import
    CK_OBJECT_HANDLE oHandle = softSession->db->importPublicCert(pAttributes, attributeLen);
    return (CK_RV) oHandle;
}

/*
 * Change Data
 */
CK_RV ChangeData(int sessionId, int handleKey, const char* oldPin, const char* newPin)
{
    
    // Step 1: Get BigInt
    if (!state.get()) {
        state = std::auto_ptr < SoftHSMInternal > (new SoftHSMInternal());
    }
    
    SoftHSMInternal *softHSM = state.get();
    
    SoftSession* mSession = softHSM->getSession((CK_ULONG) sessionId);
    
    assert(mSession != NULL);
    
    // Step 3: Get BigNumber
    Botan::BigInt bigN = mSession->db->getBigInt((CK_ULONG) handleKey, CKA_MODULUS);
    Botan::BigInt bigE = mSession->db->getBigInt((CK_ULONG) handleKey,
                                                 CKA_PUBLIC_EXPONENT);
    Botan::BigInt bigD = mSession->db->getBigInt((CK_ULONG) handleKey,
                                                 CKA_PRIVATE_EXPONENT);
    Botan::BigInt bigP = mSession->db->getBigInt((CK_ULONG) handleKey, CKA_PRIME_1);
    Botan::BigInt bigQ = mSession->db->getBigInt((CK_ULONG) handleKey, CKA_PRIME_2);
    
    if(bigN.is_zero () || bigE.is_zero() || bigD.is_zero() || bigP.is_zero() || bigQ.is_zero()) {
        return -1;
    }
    
    // Step 4: Backup database
    
    int result = mSession->db->backupBigInt((CK_ULONG) handleKey, CKA_MODULUS,
                                            &bigN);
    mSession->db->backupBigInt((CK_ULONG) handleKey, CKA_PUBLIC_EXPONENT, &bigE);
    mSession->db->backupBigInt((CK_ULONG) handleKey, CKA_PRIVATE_EXPONENT, &bigD);
    mSession->db->backupBigInt((CK_ULONG) handleKey, CKA_PRIME_1, &bigP);
    mSession->db->backupBigInt((CK_ULONG) handleKey, CKA_PRIME_2, &bigQ);
    
    // Step 4: Decrypt with old pin
    Botan::BigInt bigN1 = mSession->db->decrypt((unsigned char*) oldPin,
                                                bigN);
    Botan::BigInt bigE1 = mSession->db->decrypt((unsigned char*) oldPin,
                                                bigE);
    Botan::BigInt bigD1 = mSession->db->decrypt((unsigned char*) oldPin,
                                                bigD);
    Botan::BigInt bigP1 = mSession->db->decrypt((unsigned char*) oldPin,
                                                bigP);
    Botan::BigInt bigQ1 = mSession->db->decrypt((unsigned char*) oldPin,
                                                bigQ);
    
    if(bigN1.is_zero () || bigE1.is_zero() || bigD1.is_zero() || bigP1.is_zero() || bigQ1.is_zero()) {
        return -1;
    }
    // Step 5: Encrypt with new pin
    
    Botan::BigInt bigN2 = mSession->db->encrypt((unsigned char*) newPin,
                                                bigN1);
    Botan::BigInt bigE2 = mSession->db->encrypt((unsigned char*) newPin,
                                                bigE1);
    Botan::BigInt bigD2 = mSession->db->encrypt((unsigned char*) newPin,
                                                bigD1);
    Botan::BigInt bigP2 = mSession->db->encrypt((unsigned char*) newPin,
                                                bigP1);
    Botan::BigInt bigQ2 = mSession->db->encrypt((unsigned char*) newPin,
                                                bigQ1);
    
    // Step 6: Save to database private
    mSession->db->saveAttributeBigInt((CK_ULONG) handleKey, CKA_MODULUS, &bigN2);
    mSession->db->saveAttributeBigInt((CK_ULONG) handleKey, CKA_PUBLIC_EXPONENT,
                                      &bigE2);
    mSession->db->saveAttributeBigInt((CK_ULONG) handleKey, CKA_PRIVATE_EXPONENT,
                                      &bigD2);
    mSession->db->saveAttributeBigInt((CK_ULONG) handleKey, CKA_PRIME_1, &bigP2);
    mSession->db->saveAttributeBigInt((CK_ULONG) handleKey, CKA_PRIME_2, &bigQ2);
    
    // Step 7: Save to database for public key
    mSession->db->saveAttributeBigInt((CK_ULONG) handleKey + 1, CKA_MODULUS,
                                      &bigN2);
    mSession->db->saveAttributeBigInt((CK_ULONG) handleKey + 1, CKA_PUBLIC_EXPONENT,
                                      &bigE2);
    
    fclose(of);
    
    return 0;
    
}//
///*
// *  Wrapper for functions which used to import public certificate to database
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_ImportPublicCert(
//		JNIEnv* env, jobject jobj, jlong jsessionID, jstring jpath) {
//
//	// Convert jstring to const char*
//	//	const char* pPath = env->GetStringUTFChars(jpath,false);
//	CK_SESSION_HANDLE sessionID = (CK_SESSION_HANDLE) jsessionID;
//	// Read certificate
//	const Botan::X509_Certificate* cert = new Botan::X509_Certificate(
//			"/mnt/sdcard/TestCert.pem");
//	assert(cert != 0);
//
//	// Get fields in certificate
//	// Create ck_attribute
//
//	CK_ATTRIBUTE_PTR pAttribute = (CK_ATTRIBUTE_PTR) malloc(
//			7 * sizeof(CK_ATTRIBUTE));
//
//#ifdef SOFTHSM_DB
//	if(pAttribute == 0)
//	{
//		LOGI("ERROR when create attribute pointer");
//	}
//#endif
//
//	CK_ULONG attributeLen = 0;
//	attributeLen = MakeCKAttribute(cert, pAttribute);
//    LOGI("Type = %d, CKA_TOKEN = %d", pAttribute[5].type, *(CK_CHAR*)pAttribute[2].pValue);
//
//#ifdef SOFTHSM_DB
//	if(attributeLen > 5)
//	{
//		LOGI("pAttribute[5].type: %d", pAttribute[5].type);
//		LOGI("The first value of  pAttribute[5].type: %x", *((CK_CHAR*)pAttribute[5].pValue));
//		//LOGI("pAttribute[5].pValue: %s", *(CK_CHAR*)pAttribute[5].pValue);
//	}
//#endif
//
//	// Import certificate to database
//	// Get SoftHSM
//	SoftHSMInternal *softHSM = state.get();
//	assert( softHSM != 0);
//
//	SoftSession* softSession = softHSM->getSession(sessionID);
//	assert( softSession != 0);
//
//#ifdef SOFTHSM_DB
//	LOGI("Current session id : %d", sessionID );
//#endif
//
//	CK_OBJECT_HANDLE oHandle = softSession->db->importPublicCert(pAttribute,
//			attributeLen);
//
//#ifdef SOFTHSM_DB
//	LOGI("oHandle : %d", oHandle );
//#endif
//	return oHandle;
////	if(oHandle != 0 )
////	return CKR_OK;
////	else return 1;
//
////	LOGI("Handle : %d", oHandle);
////	//Read certificate to test
////	CK_ATTRIBUTE_PTR pAtt = (CK_ATTRIBUTE_PTR) malloc(4 * sizeof(CK_ATTRIBUTE));
////	pAtt[0].type = CKA_CERTIFICATE_TYPE;
////	pAtt[0].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
////	pAtt[0].ulValueLen = sizeof(CK_OBJECT_CLASS);
////	pAtt[1].type = CKA_CLASS;
////	pAtt[1].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
////	CK_OBJECT_CLASS Handle = CKO_CERTIFICATE;
////	pAtt[1].ulValueLen = sizeof(CK_OBJECT_CLASS);
////	pAtt[1].pValue = (void*) &Handle;
////
////	pAtt[2].type = CKA_TOKEN;
////	pAtt[2].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
////
////	pAtt[2].ulValueLen = sizeof(CK_BBOOL);
////	pAtt[3].type = CKA_SERIAL_NUMBER;
////	pAtt[3].pValue = (CK_VOID_PTR) malloc(16 * sizeof(CK_CHAR));
////	pAtt[3].ulValueLen = 32 * sizeof(CK_CHAR);
////	for (int i = 0; i < attributeLen; ++i) {
////		LOGI("Before type : %d", pAtt[i].type);
////		//CK_VOID_PTR p = (CK_VOID_PTR) pAtt[i].pValue;
////		//assert(p != 0);
////	}
////	LOGI("Begin getAttributeValue");
////	rv = softHSM->getAttributeValue(sessionID, oHandle, pAtt, attributeLen);
////	LOGI("%d", rv);
////	LOGI("%d", attributeLen);
////	for (int i = 0; i < attributeLen; ++i) {
////		LOGI("After type : %d", pAtt[i].type);
////		//CK_VOID_PTR p = (CK_VOID_PTR) pAtt[i].pValue;
////		assert(pAtt[i].pValue != NULL_PTR);
////	}
////	LOGI("%d", pAtt[1].pValue);
////	LOGI("9");
////	Converter* convert = new Converter();
////	jobjectArray obj = convert->ckAttributePtrToJAttribute(env, pAtt,
////			attributeLen);
////	LOGI("10");
////
////	//Release memory
//////	for(int i = 0 ; i < attributeLen ; ++i )
//////	{
//////		free(pAtt[i].pValue);
//////	}
////	free(pAttribute);
////	free(pAtt);
////
////	return obj;
//}
//
//
//void CheckPublicKey(CK_SESSION_HANDLE sessionID, CK_OBJECT_HANDLE mPrk)
//{
//	SoftHSMInternal *softHSM = state.get();
//	SoftSession *session = softHSM->getSession(sessionID);
//	//Botan::X509_Cert_Options opts("Hoang Test/VN/VNPT/VN");
//	//	session->db->
//	Botan::Public_Key *cryptoKey = session->getKey(mPrk);
//
//	Botan::MemoryVector<unsigned char> bVect = cryptoKey->x509_subject_public_key();
//		//LOGI("Length = %d", bVect.pinLength);
//	for(int i = 0 ; i < 30; i++)
//		{
//		  LOGI("Value ------------ = %x", bVect[i]);
//		}
//}
//
///*
// * Wrapper ReadPublicCert
// */
//JNIEXPORT jobjectArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_ReadPublicCert(
//		JNIEnv * env, jobject obj, jlong jsessionID, jlong jHandle,
//		jstring jpath, jlong jattributeLen) {
//	CK_RV rv;
//	CK_SESSION_HANDLE sessionID = (CK_SESSION_HANDLE) jsessionID;
//	CK_OBJECT_HANDLE oHandle = (CK_SESSION_HANDLE) jHandle;
//	CK_ULONG attributeLen = (CK_ULONG) jattributeLen;
//
//	//Read certificate to test
//	CK_ATTRIBUTE_PTR pAtt = (CK_ATTRIBUTE_PTR) malloc(4 * sizeof(CK_ATTRIBUTE));
//
//#ifdef SOFTHSM_DB
//	if(pAtt == 0)
//	LOGI("pAtt is null pointer!");
//#endif
//
//	assert(pAtt != 0);
//	pAtt[0].type = CKA_CERTIFICATE_TYPE;
//	pAtt[0].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
//	pAtt[0].ulValueLen = sizeof(CK_OBJECT_CLASS);
//
//	pAtt[1].type = CKA_CLASS;
//	pAtt[1].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
//	CK_OBJECT_CLASS Handle = CKO_CERTIFICATE;
//	pAtt[1].ulValueLen = sizeof(CK_OBJECT_CLASS);
//	pAtt[1].pValue = (void*) &Handle;
//
//	pAtt[2].type = CKA_TOKEN;
//	pAtt[2].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
//	pAtt[2].ulValueLen = sizeof(CK_BBOOL);
//
//	pAtt[3].type = CKA_SERIAL_NUMBER;
//	pAtt[3].pValue = (CK_VOID_PTR) malloc(16 * sizeof(CK_CHAR));
//	pAtt[3].ulValueLen = 32 * sizeof(CK_CHAR);
//
//	// Attribute to read the bytes of certificate
//	pAtt[4].type = CKA_VALUE;
//	pAtt[4].pValue = (CK_VOID_PTR) malloc(2048 * sizeof(CK_CHAR));
//	pAtt[4].ulValueLen = 2048 * sizeof(CK_CHAR);
//
//	pAtt[5].type = CKA_ID;
//	pAtt[5].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
//	pAtt[5].ulValueLen = 4 * sizeof(CK_CHAR);
//
//#ifdef SOFTHSM_DB
//	for (int i = 0; i < attributeLen; ++i) {
//		LOGI("Before type : %d", pAtt[i].type);
//	}
//#endif
//
//	// Get SoftHSM
//	SoftHSMInternal *softHSM = state.get();
//	assert( softHSM != 0);
//	rv = softHSM->getAttributeValue(sessionID, oHandle, pAtt, attributeLen);
//
//	for (int i = 0; i < attributeLen; ++i) {
//#ifdef SOFTHSM_DB
//		LOGI("After pAtt[i].type : %d", pAtt[i].type);
//#endif
//		//CK_VOID_PTR p = (CK_VOID_PTR) pAtt[i].pValue;
//		assert(pAtt[i].pValue != NULL_PTR);
//	}
//
//#ifdef SOFTHSM_DB
//	LOGI("rv: %d", rv);
//	LOGI("attributeLen: %d", attributeLen);
//	LOGI("pAtt[4].pValue:%x", *((CK_CHAR*)pAtt[4].pValue));
//#endif
//
//	Converter* convert = new Converter();
//	jobjectArray jobjArray = convert->ckAttributePtrToJAttribute(env, pAtt,
//			attributeLen);
////	free(pAtt);
//	CheckPublicKey(sessionID, 1);
//	return jobjArray;
//}
//
///*
// *  Wrapper TestImportPublicCert
// */
//
//JNIEXPORT jobjectArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_TestImportPublicCert(
//		JNIEnv* env, jobject jobj, jlong jsessionID, jstring jpath) {
//	CK_RV rv = 1;
//	// jpath stores the path to certificate needed import
//	LOGI("1");
//	//Convert jstring to const char*
//	//	const char* pPath = env->GetStringUTFChars(jpath,false);
//	CK_SESSION_HANDLE sessionID = (CK_SESSION_HANDLE) jsessionID;
//	// Read certificate
//	LOGI("2");
//	Botan::X509_Certificate* cert = new Botan::X509_Certificate(
//			"/data/data/vnpt.example.testsofthsm/TestCert.pem");
//	LOGI("3");
//	assert(cert != 0);
//
//	// Get fields in certificate
//	// Create ck_attribute
//	CK_ATTRIBUTE_PTR pAttribute = (CK_ATTRIBUTE_PTR) malloc(
//			4 * sizeof(CK_ATTRIBUTE));
//	LOGI("4");
//	CK_ULONG count = 0;
//	CK_ULONG attributeLen = 0;
//	assert( cert != 0);
//	LOGI("5");
//	attributeLen = MakeCKAttribute(cert, pAttribute);
//	LOGI("6");
//	LOGI("pAttribute[0].pValue: %d", *(CK_ULONG*)pAttribute[0].pValue);
//	LOGI("pAttribute[1].pValue: %d", *(CK_ULONG*)pAttribute[1].pValue);
//	LOGI("pAttribute[2].pValue: %d", *(CK_ULONG*)pAttribute[2].pValue);
//	// Import certificate to database
//	// Get SoftHSM
//	SoftHSMInternal *softHSM = state.get();
//	assert( softHSM != 0);
//	LOGI("7");
//	LOGI("Session: %d ", sessionID);
//	SoftSession* softSession = softHSM->getSession(sessionID);
//	assert( softSession != 0);
//	LOGI("8");
//	LOGI("Length of attribue: %d", attributeLen);
//	LOGI("pAttribute[0].pValue: %d", *(CK_ULONG*)pAttribute[0].pValue);
//	LOGI("pAttribute[1].pValue: %d", *(CK_ULONG*)pAttribute[1].pValue);
//	LOGI("pAttribute[2].pValue: %d", *(CK_ULONG*)pAttribute[2].pValue);
//	CK_OBJECT_HANDLE oHandle = softSession->db->importPublicCert(pAttribute,
//			attributeLen);
//	if (oHandle != 0)
//		return CKR_OK;
//	LOGI("Handle : %d", oHandle);
//	//Read certificate to test
//	CK_ATTRIBUTE_PTR pAtt = (CK_ATTRIBUTE_PTR) malloc(4 * sizeof(CK_ATTRIBUTE));
//	pAtt[0].type = CKA_CERTIFICATE_TYPE;
//	pAtt[0].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
//	pAtt[0].ulValueLen = sizeof(CK_OBJECT_CLASS);
//	pAtt[1].type = CKA_CLASS;
//	pAtt[1].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
//	CK_OBJECT_CLASS Handle = CKO_CERTIFICATE;
//	pAtt[1].ulValueLen = sizeof(CK_OBJECT_CLASS);
//	pAtt[1].pValue = (void*) &Handle;
//
//	pAtt[2].type = CKA_TOKEN;
//	pAtt[2].pValue = (CK_VOID_PTR) malloc(4 * sizeof(CK_CHAR));
//
//	pAtt[2].ulValueLen = sizeof(CK_BBOOL);
//	pAtt[3].type = CKA_SERIAL_NUMBER;
//	pAtt[3].pValue = (CK_VOID_PTR) malloc(16 * sizeof(CK_CHAR));
//	pAtt[3].ulValueLen = 32 * sizeof(CK_CHAR);
//	for (int i = 0; i < attributeLen; ++i) {
//		LOGI("Before type : %d", pAtt[i].type);
//		//CK_VOID_PTR p = (CK_VOID_PTR) pAtt[i].pValue;
//		//assert(p != 0);
//	}
//	LOGI("Begin getAttributeValue");
//	rv = softHSM->getAttributeValue(sessionID, oHandle, pAtt, attributeLen);
//	LOGI("%d", rv);
//	LOGI("%d", attributeLen);
//	for (int i = 0; i < attributeLen; ++i) {
//		LOGI("After type : %d", pAtt[i].type);
//		//CK_VOID_PTR p = (CK_VOID_PTR) pAtt[i].pValue;
//		assert(pAtt[i].pValue != NULL_PTR);
//	}
//	LOGI("%d", pAtt[1].pValue);
//	LOGI("9");
//	Converter* convert = new Converter();
//	jobjectArray obj = convert->ckAttributePtrToJAttribute(env, pAtt,
//			attributeLen);
//	LOGI("10");
//
//	free(pAttribute);
//	free(pAtt);
//
//	return obj;
//}
///*
// * Wrapper for generate PKCS#10 Request
// */JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GeneratePKCS10Request(
//		JNIEnv * env, jobject obj, jlong jsessionID, jlong jslotInitToken,
//		jstring juserPin, jlong jhandleKey) {
//	CK_RV rv;
//	CK_ULONG c_slotInitToken = (CK_ULONG) jslotInitToken;
//	// Convert to const char*
//	const char* puserPin = env->GetStringUTFChars(juserPin, 0);
//	CK_CHAR_PTR c_puserPin = (CK_CHAR_PTR) puserPin;
//	CK_ULONG handleKey = (CK_ULONG) jhandleKey;
//	// Assign session for globale variable mSessionRW
//	CK_ULONG c_sessionID = (CK_SESSION_HANDLE) jsessionID;
//	rv = genPKCS10Request(c_sessionID, c_slotInitToken, c_puserPin, handleKey);
//	env->ReleaseStringUTFChars(juserPin, puserPin);
//
//	return rv;
//}
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_TestGenKeyAndPKCS10Request(
//		JNIEnv * env, jobject obj) {
//	//jlong hSession, jlong hPuk, jlong hPrk, jlong keyLength
//}
//
///*
// * Wrapper for build certificate x509
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_BuildCertX509(
//		JNIEnv * env, jobject obj, jlong jsessionID, jlong jHandle,
//		jlong jattLength) {
//	CK_RV rv;
//	CK_SESSION_HANDLE sessionID = (CK_SESSION_HANDLE) jsessionID;
//	CK_OBJECT_HANDLE handle = (CK_OBJECT_HANDLE) jHandle;
//	CK_ULONG attLength = (CK_ULONG) jattLength;
//	// Create attribute to get certificate
//	CK_ATTRIBUTE_PTR att = (CK_ATTRIBUTE_PTR) malloc(
//			attLength * sizeof(CK_ATTRIBUTE));
//	att->type = CKA_VALUE;
//	att->pValue = (CK_VOID_PTR) malloc(2048 * sizeof(CK_CHAR));
//	att->ulValueLen = 2048;
//	// Load Certificate X509
//	rv = C_GetAttributeValue(sessionID, handle, att, attLength);
//	if (rv != 0) {
//		LOGI("Error when loading certificate ");
//	}
//	// Get array byte
//	// Firstly, make a array char to store
//	char* certValue = (char*) malloc(2048 * sizeof(CK_CHAR));
//	certValue = (char*) att->pValue;
//
//#ifdef SOFTHSM_DB
//	for (int i = 0; i < strlen(certValue); ++i)
//	{
//		LOGI("Value : %x", *(certValue + i));
//	}
//#endif
//
//	return rv;
//}
//
///*
// * Wrapper for get private key from certificate
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetPrivateKey(
//		JNIEnv * env, jobject obj, jlong jsessionID, jstring jPath) {
//
//	Botan::DataSource_Stream file(
//			"/data/data/vnpt.example.testsofthsm/softHSMTest.pem");
//	const std::string str = "Test";
//	SoftHSMInternal *softHSM = state.get();
//	SoftSession *session = softHSM->getSession((CK_ULONG) jsessionID);
//	Botan::PKCS8_PrivateKey* key1 = Botan::PKCS8::load_key(file, *session->rng,
//			str);
//	// Dynamic cast
//
//#ifdef SOFTHSM_DB
//	Botan::X509_PublicKey *publicKey1 = Botan::X509::load_key(file);
//	// Botan::X509_PrivateKey* key2 = dynamic<Botan::Private_Key*> (publicKey1);
//#endif
//
//	return 0;
//}
//
///*
// * Wrapper for get private key from certificate
// */
//
//JNIEXPORT jbyteArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_SignData(
//		JNIEnv* env, jobject jobj, jlong hSession, jbyteArray jdata,
//		jlong dataLen, jlong mechanismType, jlong hPrivateKey) {
//
//	CK_RV rv;
//	CK_BYTE_PTR ckpData = NULL_PTR;
//	CK_BYTE_PTR ckpSignature;
//	CK_ULONG ckDataLength;
//	CK_ULONG ckSignatureLength = 0;
//	jbyteArray jSignature;
//	CK_MECHANISM_TYPE c_mechanismType = (CK_MECHANISM_TYPE) mechanismType;
//	CK_SESSION_HANDLE c_hSession = (CK_SESSION_HANDLE) hSession;
//	CK_OBJECT_HANDLE c_hPrivateKey = (CK_OBJECT_HANDLE) hPrivateKey;
//
//	Converter* convert = new Converter();
//	convert->jByteArrayToCKByteArray(env, jdata, &ckpData, &ckDataLength);
//
//	c_mechanism = (CK_MECHANISM) {c_mechanismType, NULL_PTR, 0};
//
//	rv = C_SignInit(c_hSession, &c_mechanism, c_hPrivateKey);
//	/* first determine the length of the signature */
//
//	rv = C_Sign(c_hSession, ckpData, ckDataLength, NULL_PTR,
//			&ckSignatureLength);
//
//	ckpSignature = (CK_BYTE_PTR) malloc(ckSignatureLength * sizeof(CK_BYTE));
//
//	rv = C_Sign(c_hSession, ckpData, ckDataLength, ckpSignature,
//			&ckSignatureLength);
//
//	// return jbyteArray
//	jSignature = convert->ckByteArrayToJByteArray(env, ckpSignature,
//			ckSignatureLength);
//	free(ckpData);
//	free(ckpSignature);
//
//	return jSignature;
//}
//
//std::string VNPT_CA_GetID(CK_ULONG sessionID, CK_ULONG handle,
//		CK_ULONG length) {
//#ifdef SOFHTSM_DB
//	LOGI("Begin VNPT_CA_GetID");
//#endif
//
//	CK_ATTRIBUTE_PTR att = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
//	att->type = CKA_ID;
//	att->pValue = (CK_VOID_PTR) malloc(length * sizeof(CK_CHAR));
//	CK_ULONG attLen = 1;
//	CK_RV rv = C_GetAttributeValue(sessionID, handle, att, attLen);
//
//#ifdef SOFHTSM_DB
//	LOGI("Value return of C_GetAttributeValue: %d", rv);
//	assert(rv == 0);
//#endif
//
//	char* s = (char*) malloc(4 * sizeof(CK_CHAR));
//
//	if (att[0].pValue != NULL) {
//		// Return pValue
//		printf("attr[0].pValue = %s", att[0].pValue);
//		strcpy(s, (char*) att[0].pValue);
//	}
//	std::string idStr(s);
//	free(att->pValue);
//	free(att);
//
//	return idStr;
//}
//
///*
// * Wrapper for Get Object ID
// */
//
//JNIEXPORT jbyteArray JNICALL Java_vnpt_example_testsofthsm_SoftHSM_GetID(
//		JNIEnv* env, jobject jobj, jlong jsessionID, jlong jhandle,
//		jlong jlength) {
//	CK_SESSION_HANDLE sessionID = (CK_SESSION_HANDLE) jsessionID;
//	CK_OBJECT_HANDLE handle = (CK_OBJECT_HANDLE) jhandle;
//
//	//std::string str = VNPT_CA_GetID(sessionID, handle, (CK_ULONG) jlength);
//	CK_ATTRIBUTE_PTR att = (CK_ATTRIBUTE_PTR) malloc(sizeof(CK_ATTRIBUTE));
//	att->type = CKA_ID;
//	att->pValue = (CK_VOID_PTR) malloc((CK_ULONG) jlength * sizeof(CK_CHAR));
//	CK_ULONG attLen = 1;
//	CK_RV rv = C_GetAttributeValue(sessionID, handle, att, attLen);
//	LOGI("rv = %d", rv);
//
//	LOGI("pValue: = %x", att->pValue);
//	// Convert str to byte array
//	Converter* convert = new Converter();
//	jbyteArray jarrayID = convert->ckByteArrayToJByteArray(env, (CK_BYTE_PTR) att->pValue,
//			(CK_ULONG) jlength);
//	return jarrayID;
//}
//
//
///*
// * Wrapper for Get Object ID
// */
//
//JNIEXPORT jlong JNICALL Java_vnpt_example_testsofthsm_SoftHSM_FindSignatureKey(
//		JNIEnv* env, jobject jobj, jlong jsessionID, jbyteArray jobjectID, jlong jsignatureKeyHandle)
//{
//	CK_SESSION_HANDLE sessionID = (CK_SESSION_HANDLE) jsessionID;
//	CK_ULONG length = 3;
//	CK_BYTE_PTR objectID = (CK_BYTE_PTR) malloc(length * sizeof(CK_BYTE));
//	Converter* convert = new Converter();
//	convert->jByteArrayToCKByteArray(env, jobjectID, &objectID, &length);
//	bool bBool = CK_TRUE;
//	jbyteArray sigKey;
//	CK_ATTRIBUTE_PTR attributeTemplateList = (CK_ATTRIBUTE_PTR) malloc(2* sizeof(CK_ATTRIBUTE));
//	LOGI("%x", objectID[0]);
//	attributeTemplateList[0].type = CKA_ID;
//	attributeTemplateList[0].pValue = (CK_VOID_PTR) malloc(length * sizeof(CK_BYTE));
//	attributeTemplateList[0].pValue = objectID;
//
//	attributeTemplateList[1].type = CKA_SIGN;
//	attributeTemplateList[1].pValue = &bBool;
//	LOGI("Before Find Object Init");
////	CK_ULONG rv;
//	CK_ULONG rv = C_FindObjectsInit(sessionID, attributeTemplateList, 1);
//	LOGI("After Find Object Init");
////	CK_ULONG [] availableSignatureKeys = C_FindObjects(sessionID, 100); //maximum of 100 at once
////	if (availableSignatureKeys.length == 0)
////	{
////		return sigKey;
////	}
////	else
////	{
////		for (int i = 0; i < availableSignatureKeys.length; i++)
////		{
////			if (i == 0)
////			{ // the first we find, we take as our signature key
////				signatureKeyHandle = availableSignatureKeys[i];
////			}
////		}
////	}
////	C_FindObjectsFinal(sessionID);
//	return rv;
//
////}
//
//}
//
//
//void show_key_info(CK_SESSION_HANDLE session, CK_OBJECT_HANDLE key)
//{
//     CK_RV rv;
//     CK_UTF8CHAR *label = (CK_UTF8CHAR *) malloc(80);
//     CK_BYTE *id = (CK_BYTE *) malloc(10);
//     size_t label_len;
//     char *label_str;
//
//     memset(id, 0, 10);
//
//     CK_ATTRIBUTE template1[] = {
//          {CKA_LABEL, label, 80},
//          {CKA_ID, id, 1}
//     };
//
//     rv = C_GetAttributeValue(session, key, template1, 2);
//   //  check_return_value(rv, "get attribute value");
//
//     fprintf(stdout, "Found a key:\n");
//     //label_len = template[0].ulValueLen;
//     if (label_len > 0) {
//       //   label_str = malloc(label_len + 1);
//          memcpy(label_str, label, label_len);
//          label_str[label_len] = '\0';
//          fprintf(stdout, "\tKey label: %s\n", label_str);
//          free(label_str);
//     } else {
//          fprintf(stdout, "\tKey label too large, or not found\n");
//     }
//     if (template1[1].ulValueLen > 0) {
//          fprintf(stdout, "\tKey ID: %02x\n", id[0]);
//     } else {
//          fprintf(stdout, "\tKey id too large, or not found\n");
//     }
//
//     free(label);
//     free(id);
//}
