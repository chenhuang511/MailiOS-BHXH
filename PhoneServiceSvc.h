#import <Foundation/Foundation.h>
#import "USAdditions.h"
#import <libxml/tree.h>
#import "USGlobals.h"
@class PhoneServiceSvc_DeleteMail;
@class PhoneServiceSvc_DeleteMailResponse;
@class PhoneServiceSvc_DeletePhone;
@class PhoneServiceSvc_DeletePhoneResponse;
@class PhoneServiceSvc_GetContact;
@class PhoneServiceSvc_GetContactResponse;
@class PhoneServiceSvc_GetKeyMail;
@class PhoneServiceSvc_GetKeyMailResponse;
@class PhoneServiceSvc_SaveMail;
@class PhoneServiceSvc_SaveMailResponse;
@class PhoneServiceSvc_SavePhone;
@class PhoneServiceSvc_SavePhoneResponse;
@interface PhoneServiceSvc_DeleteMail : NSObject {
	
/* elements */
	NSString * MailAddress;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_DeleteMail *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * MailAddress;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_DeleteMailResponse : NSObject {
	
/* elements */
	NSNumber * return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_DeleteMailResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_DeletePhone : NSObject {
	
/* elements */
	NSString * PhoneNumber;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_DeletePhone *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * PhoneNumber;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_DeletePhoneResponse : NSObject {
	
/* elements */
	NSNumber * return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_DeletePhoneResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_GetContact : NSObject {
	
/* elements */
	NSString * ListContact;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_GetContact *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * ListContact;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_GetContactResponse : NSObject {
	
/* elements */
	NSString * return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_GetContactResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_GetKeyMail : NSObject {
	
/* elements */
	NSString * MailAddress;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_GetKeyMail *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * MailAddress;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_GetKeyMailResponse : NSObject {
	
/* elements */
	NSString * return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_GetKeyMailResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_SaveMail : NSObject {
	
/* elements */
	NSString * MailAddress;
	NSString * PublicKey;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_SaveMail *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * MailAddress;
@property (retain) NSString * PublicKey;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_SaveMailResponse : NSObject {
	
/* elements */
	NSNumber * return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_SaveMailResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_SavePhone : NSObject {
	
/* elements */
	NSString * PhoneNumber;
	NSString * Certificate;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_SavePhone *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSString * PhoneNumber;
@property (retain) NSString * Certificate;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface PhoneServiceSvc_SavePhoneResponse : NSObject {
	
/* elements */
	NSNumber * return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (PhoneServiceSvc_SavePhoneResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
/* elements */
@property (retain) NSNumber * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
/* Cookies handling provided by http://en.wikibooks.org/wiki/Programming:WebObjects/Web_Services/Web_Service_Provider */
#import <libxml/parser.h>
#import "xs.h"
#import "PhoneServiceSvc.h"
@class PhoneServicePortBinding;
@interface PhoneServiceSvc : NSObject {
	
}
+ (PhoneServicePortBinding *)PhoneServicePortBinding;
@end
@class PhoneServicePortBindingResponse;
@class PhoneServicePortBindingOperation;
@protocol PhoneServicePortBindingResponseDelegate <NSObject>
- (void) operation:(PhoneServicePortBindingOperation *)operation completedWithResponse:(PhoneServicePortBindingResponse *)response;
@end
@interface PhoneServicePortBinding : NSObject <PhoneServicePortBindingResponseDelegate> {
	NSURL *address;
	NSTimeInterval defaultTimeout;
	NSMutableArray *cookies;
	BOOL logXMLInOut;
	BOOL synchronousOperationComplete;
	NSString *authUsername;
	NSString *authPassword;
}
@property (copy) NSURL *address;
@property (assign) BOOL logXMLInOut;
@property (assign) NSTimeInterval defaultTimeout;
@property (nonatomic, retain) NSMutableArray *cookies;
@property (nonatomic, retain) NSString *authUsername;
@property (nonatomic, retain) NSString *authPassword;
- (id)initWithAddress:(NSString *)anAddress;
- (void)sendHTTPCallUsingBody:(NSString *)body soapAction:(NSString *)soapAction forOperation:(PhoneServicePortBindingOperation *)operation;
- (void)addCookie:(NSHTTPCookie *)toAdd;
- (PhoneServicePortBindingResponse *)SavePhoneUsingParameters:(PhoneServiceSvc_SavePhone *)aParameters ;
- (void)SavePhoneAsyncUsingParameters:(PhoneServiceSvc_SavePhone *)aParameters  delegate:(id<PhoneServicePortBindingResponseDelegate>)responseDelegate;
- (PhoneServicePortBindingResponse *)DeletePhoneUsingParameters:(PhoneServiceSvc_DeletePhone *)aParameters ;
- (void)DeletePhoneAsyncUsingParameters:(PhoneServiceSvc_DeletePhone *)aParameters  delegate:(id<PhoneServicePortBindingResponseDelegate>)responseDelegate;
- (PhoneServicePortBindingResponse *)GetContactUsingParameters:(PhoneServiceSvc_GetContact *)aParameters ;
- (void)GetContactAsyncUsingParameters:(PhoneServiceSvc_GetContact *)aParameters  delegate:(id<PhoneServicePortBindingResponseDelegate>)responseDelegate;
- (PhoneServicePortBindingResponse *)SaveMailUsingParameters:(PhoneServiceSvc_SaveMail *)aParameters ;
- (void)SaveMailAsyncUsingParameters:(PhoneServiceSvc_SaveMail *)aParameters  delegate:(id<PhoneServicePortBindingResponseDelegate>)responseDelegate;
- (PhoneServicePortBindingResponse *)GetKeyMailUsingParameters:(PhoneServiceSvc_GetKeyMail *)aParameters ;
- (void)GetKeyMailAsyncUsingParameters:(PhoneServiceSvc_GetKeyMail *)aParameters  delegate:(id<PhoneServicePortBindingResponseDelegate>)responseDelegate;
- (PhoneServicePortBindingResponse *)DeleteMailUsingParameters:(PhoneServiceSvc_DeleteMail *)aParameters ;
- (void)DeleteMailAsyncUsingParameters:(PhoneServiceSvc_DeleteMail *)aParameters  delegate:(id<PhoneServicePortBindingResponseDelegate>)responseDelegate;
@end
@interface PhoneServicePortBindingOperation : NSOperation {
	PhoneServicePortBinding *binding;
	PhoneServicePortBindingResponse *response;
	id<PhoneServicePortBindingResponseDelegate> delegate;
	NSMutableData *responseData;
	NSURLConnection *urlConnection;
}
@property (retain) PhoneServicePortBinding *binding;
@property (readonly) PhoneServicePortBindingResponse *response;
@property (nonatomic, assign) id<PhoneServicePortBindingResponseDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate;
@end
@interface PhoneServicePortBinding_SavePhone : PhoneServicePortBindingOperation {
	PhoneServiceSvc_SavePhone * parameters;
}
@property (retain) PhoneServiceSvc_SavePhone * parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate
	parameters:(PhoneServiceSvc_SavePhone *)aParameters
;
@end
@interface PhoneServicePortBinding_DeletePhone : PhoneServicePortBindingOperation {
	PhoneServiceSvc_DeletePhone * parameters;
}
@property (retain) PhoneServiceSvc_DeletePhone * parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate
	parameters:(PhoneServiceSvc_DeletePhone *)aParameters
;
@end
@interface PhoneServicePortBinding_GetContact : PhoneServicePortBindingOperation {
	PhoneServiceSvc_GetContact * parameters;
}
@property (retain) PhoneServiceSvc_GetContact * parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate
	parameters:(PhoneServiceSvc_GetContact *)aParameters
;
@end
@interface PhoneServicePortBinding_SaveMail : PhoneServicePortBindingOperation {
	PhoneServiceSvc_SaveMail * parameters;
}
@property (retain) PhoneServiceSvc_SaveMail * parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate
	parameters:(PhoneServiceSvc_SaveMail *)aParameters
;
@end
@interface PhoneServicePortBinding_GetKeyMail : PhoneServicePortBindingOperation {
	PhoneServiceSvc_GetKeyMail * parameters;
}
@property (retain) PhoneServiceSvc_GetKeyMail * parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate
	parameters:(PhoneServiceSvc_GetKeyMail *)aParameters
;
@end
@interface PhoneServicePortBinding_DeleteMail : PhoneServicePortBindingOperation {
	PhoneServiceSvc_DeleteMail * parameters;
}
@property (retain) PhoneServiceSvc_DeleteMail * parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate
	parameters:(PhoneServiceSvc_DeleteMail *)aParameters
;
@end
@interface PhoneServicePortBinding_envelope : NSObject {
}
+ (PhoneServicePortBinding_envelope *)sharedInstance;
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements;
@end
@interface PhoneServicePortBindingResponse : NSObject {
	NSArray *headers;
	NSArray *bodyParts;
	NSError *error;
}
@property (retain) NSArray *headers;
@property (retain) NSArray *bodyParts;
@property (retain) NSError *error;
@end
