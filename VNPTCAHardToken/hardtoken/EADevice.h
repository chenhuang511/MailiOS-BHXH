#ifndef EA_DEVICE_H
#define EA_DEVICE_H

typedef enum es_device_event_e
{
    DEVICE_REMOVED  = 0,
    DEVICE_INSERTED = 1,
}ES_DEVICE_EVENT;

typedef void (*ES_DEVICE_NOTIFY_CALLBACK)(void* device,ES_DEVICE_EVENT event,void* userdata);

#ifdef __cplusplus
extern "C"
{
#endif
int es_register_device_notify(ES_DEVICE_NOTIFY_CALLBACK device_notify,void* userdata);
int es_unregister_device_notify(ES_DEVICE_NOTIFY_CALLBACK device_notify,void* userdata);

int es_send(void* device,unsigned char const* send,unsigned int send_len,unsigned char * recv,unsigned int* recv_len);
    
void InitializeP11Again();
    
#ifdef __cplusplus
}
#endif

#endif//EA_DEVICE_H