
#include "config.h"
#include "MutexFactory.h"
#include "osmutex.h"
#include <memory>


/*****************************************************************************
 Mutex implementation
 *****************************************************************************/

// Constructor
Mutex::Mutex()
{
	isValid = (MutexFactory::i()->createMutex(&handle) == CKR_OK);	
}

// Destructor
Mutex::~Mutex()
{
	if (isValid)
	{
		MutexFactory::i()->destroyMutex(handle);
	}
}

// Lock the mutex
bool Mutex::lock()
{
	return (isValid && (MutexFactory::i()->lockMutex(handle) == CKR_OK));
}
	 
// Unlock the mutex
void Mutex::unlock()
{
	if (isValid) 
	{
		MutexFactory::i()->unlockMutex(handle);
	}
}

/*****************************************************************************
 MutexLocker implementation
 *****************************************************************************/

// Constructor
MutexLocker::MutexLocker(Mutex* mutex)
{
	this->mutex = mutex;

	if (this->mutex != NULL) this->mutex->lock();
}

// Destructor
MutexLocker::~MutexLocker()
{
	if (this->mutex != NULL) this->mutex->unlock();
}

/*****************************************************************************
 MutexFactory implementation
 *****************************************************************************/

// Initialise the one-and-only instance
MutexFactory* MutexFactory::instance = NULL;

// Constructor
MutexFactory::MutexFactory()
{
	createMutex = OSCreateMutex;
	destroyMutex = OSDestroyMutex;
	lockMutex = OSLockMutex;
	unlockMutex = OSUnlockMutex;

	enabled = true;
}

// Destructor
MutexFactory::~MutexFactory()
{
}

// Return the one-and-only instance
MutexFactory* MutexFactory::i()
{
	if (instance == NULL)
	{
		instance = new MutexFactory();
	}

	return instance;
}

// Destroy the one-and-only instance
void MutexFactory::destroy()
{
	if (instance != NULL)
	{
		delete instance;
		instance = NULL;
	}
}

// Get a mutex instance
Mutex* MutexFactory::getMutex()
{
	return new Mutex();
}

// Recycle a mutex instance
void MutexFactory::recycleMutex(Mutex* mutex)
{
	if (mutex != NULL) delete mutex;
}

// Set the function pointers
void MutexFactory::setCreateMutex(CK_CREATEMUTEX createMutex)
{
	this->createMutex = createMutex;
}

void MutexFactory::setDestroyMutex(CK_DESTROYMUTEX destroyMutex)
{
	this->destroyMutex = destroyMutex;
}

void MutexFactory::setLockMutex(CK_LOCKMUTEX lockMutex)
{
	this->lockMutex = lockMutex;
}

void MutexFactory::setUnlockMutex(CK_UNLOCKMUTEX unlockMutex)
{
	this->unlockMutex = unlockMutex;
}

void MutexFactory::enable()
{
	enabled = true;
}

void MutexFactory::disable()
{
	enabled = false;
}

CK_RV MutexFactory::CreateMutex(CK_VOID_PTR_PTR newMutex)
{
	if (!enabled) return CKR_OK;

	return (this->createMutex)(newMutex);
}

CK_RV MutexFactory::DestroyMutex(CK_VOID_PTR mutex)
{
	if (!enabled) return CKR_OK;

	return (this->destroyMutex)(mutex);
}

CK_RV MutexFactory::LockMutex(CK_VOID_PTR mutex)
{
	if (!enabled) return CKR_OK;

	return (this->lockMutex)(mutex);
}

CK_RV MutexFactory::UnlockMutex(CK_VOID_PTR mutex)
{
	if (!enabled) return CKR_OK;

	return (this->unlockMutex)(mutex);
}

