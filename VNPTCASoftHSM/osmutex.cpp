
#include "config.h"
//#include "log.h"
#include "osmutex.h"

//#ifdef HAVE_PTHREAD_H

#include <stdlib.h>
#include <pthread.h>

CK_RV OSCreateMutex(CK_VOID_PTR_PTR newMutex)
{
	unsigned long rv;

	/* Allocate memory */
	pthread_mutex_t* pthreadMutex = (pthread_mutex_t*) malloc(sizeof(pthread_mutex_t));

	if (pthreadMutex == NULL)
	{
		//ERROR_MSG("OSCreateMutex", "Failed to allocate memory for a new mutex");

		return CKR_HOST_MEMORY;
	}

	/* Initialise the mutex */
	/*if ((rv = pthread_mutex_init(pthreadMutex, NULL)) != 0)
	{
		free(pthreadMutex);

		//ERROR_MSG("OSCreateMutex", "Failed to initialise POSIX mutex");

		return CKR_GENERAL_ERROR;
	}*/

	*newMutex = pthreadMutex;

	return CKR_OK;
}

CK_RV OSDestroyMutex(CK_VOID_PTR mutex)
{
	unsigned long rv;
	pthread_mutex_t* pthreadMutex = (pthread_mutex_t*) mutex;

	if (pthreadMutex == NULL)
	{
		//ERROR_MSG("OSDestroyMutex", "Cannot destroy NULL mutex");

		return CKR_ARGUMENTS_BAD;
	}

	/*if ((rv = pthread_mutex_destroy(pthreadMutex)) != 0)
	{
		//ERROR_MSG("OSDestroyMutex", "Failed to destroy POSIX mutex");

		return CKR_GENERAL_ERROR;
	}*/

	free(pthreadMutex);

	return CKR_OK;
}

CK_RV OSLockMutex(CK_VOID_PTR mutex)
{
	unsigned long rv;
	pthread_mutex_t* pthreadMutex = (pthread_mutex_t*) mutex;

	if (pthreadMutex == NULL)
	{
		//ERROR_MSG("OSLockMutex", "Cannot lock NULL mutex");

		return CKR_ARGUMENTS_BAD;
	}

	/*if ((rv = pthread_mutex_lock(pthreadMutex)) != 0)
	{
		//ERROR_MSG("OSLockMutex", "Failed to lock POSIX mutex");

		return CKR_GENERAL_ERROR;
	}*/

	return CKR_OK;
}

CK_RV OSUnlockMutex(CK_VOID_PTR mutex)
{
	unsigned long rv;
	pthread_mutex_t* pthreadMutex = (pthread_mutex_t*) mutex;

	if (pthreadMutex == NULL)
	{
		//ERROR_MSG("OSUnlockMutex", "Cannot unlock NULL mutex");

		return CKR_ARGUMENTS_BAD;
	}

	/*if ((rv = pthread_mutex_unlock(pthreadMutex)) != 0)
	{
		//ERROR_MSG("OSUnlockMutex", "Failed to unlock POSIX mutex");

		return CKR_GENERAL_ERROR;
	}*/

	return CKR_OK;
}

//#else
//#error "There are no mutex implementations for your operating system yet"
//#endif

