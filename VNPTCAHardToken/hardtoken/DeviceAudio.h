//
//  device.h
//  AudioToken
//
//  Created by Pham Xuan Khanh on 2/20/11.
//  Copyright 2011 Minh Thong Card Solutions Co. LTD. All rights reserved.
//

#ifndef AudioToken_device_h
#define AudioToken_device_h
#include <CoreFoundation/CoreFoundation.h>
//#include "es_types.h"


extern int testFile_index;
extern int output_index;
extern int testing;
extern BOOL g_isDevicePresent;

//void* g_device=0;

//int transmit_type = 0;

#define ES_U1 unsigned char

typedef void(NOTIFY_HANDLER)(ES_U1 is_inserted,void* user_data);

#ifdef __cplusplus
extern "C"
{
#endif
    
void esaudio_registNotify(NOTIFY_HANDLER* notify,void* user_data);
void esaudio_unregistNotify(NOTIFY_HANDLER* notify,void* user_data);
                         
ES_U1 esaudio_init(void** session);
ES_U1 esaudio_final(void* session);

//ES_U1 esaudio_send(void* session,CFDataRef dataSend);
ES_U1 esaudio_recv(void* session,CFMutableDataRef dataRecv);
ES_U1 esaudio_cleanup(void *session);
ES_U1 esaudio_cancel(void* session);
ES_U1 esaudio_resetstate(void *session);

#ifdef __cplusplus
}
#endif
#endif
