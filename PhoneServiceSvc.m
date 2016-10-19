#import "PhoneServiceSvc.h"
#import <libxml/xmlstring.h>
#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#endif
@implementation PhoneServiceSvc_DeleteMail

- (id)init {
  if ((self = [super init])) {
    MailAddress = 0;
  }

  return self;
}
- (void)dealloc {
  if (MailAddress != nil)
    [MailAddress release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.MailAddress != 0) {
    xmlAddChild(node, [self.MailAddress xmlNodeForDoc:node->doc
                                          elementName:@"MailAddress"
                                      elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize MailAddress;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_DeleteMail *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_DeleteMail *newObject =
      [[PhoneServiceSvc_DeleteMail new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"MailAddress")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.MailAddress = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_DeleteMailResponse
- (id)init {
  if ((self = [super init])) {
    return_ = 0;
  }

  return self;
}
- (void)dealloc {
  if (return_ != nil)
    [return_ release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.return_ != 0) {
    xmlAddChild(node, [self.return_ xmlNodeForDoc:node->doc
                                      elementName:@"return"
                                  elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize return_;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_DeleteMailResponse *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_DeleteMailResponse *newObject =
      [[PhoneServiceSvc_DeleteMailResponse new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"return")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSNumber class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.return_ = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_DeletePhone
- (id)init {
  if ((self = [super init])) {
    PhoneNumber = 0;
  }

  return self;
}
- (void)dealloc {
  if (PhoneNumber != nil)
    [PhoneNumber release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.PhoneNumber != 0) {
    xmlAddChild(node, [self.PhoneNumber xmlNodeForDoc:node->doc
                                          elementName:@"PhoneNumber"
                                      elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize PhoneNumber;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_DeletePhone *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_DeletePhone *newObject =
      [[PhoneServiceSvc_DeletePhone new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"PhoneNumber")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.PhoneNumber = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_DeletePhoneResponse
- (id)init {
  if ((self = [super init])) {
    return_ = 0;
  }

  return self;
}
- (void)dealloc {
  if (return_ != nil)
    [return_ release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.return_ != 0) {
    xmlAddChild(node, [self.return_ xmlNodeForDoc:node->doc
                                      elementName:@"return"
                                  elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize return_;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_DeletePhoneResponse *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_DeletePhoneResponse *newObject =
      [[PhoneServiceSvc_DeletePhoneResponse new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"return")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSNumber class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.return_ = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_GetContact
- (id)init {
  if ((self = [super init])) {
    ListContact = 0;
  }

  return self;
}
- (void)dealloc {
  if (ListContact != nil)
    [ListContact release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.ListContact != 0) {
    xmlAddChild(node, [self.ListContact xmlNodeForDoc:node->doc
                                          elementName:@"ListContact"
                                      elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize ListContact;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_GetContact *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_GetContact *newObject =
      [[PhoneServiceSvc_GetContact new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"ListContact")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.ListContact = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_GetContactResponse
- (id)init {
  if ((self = [super init])) {
    return_ = 0;
  }

  return self;
}
- (void)dealloc {
  if (return_ != nil)
    [return_ release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.return_ != 0) {
    xmlAddChild(node, [self.return_ xmlNodeForDoc:node->doc
                                      elementName:@"return"
                                  elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize return_;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_GetContactResponse *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_GetContactResponse *newObject =
      [[PhoneServiceSvc_GetContactResponse new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"return")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.return_ = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_GetKeyMail
- (id)init {
  if ((self = [super init])) {
    MailAddress = 0;
  }

  return self;
}
- (void)dealloc {
  if (MailAddress != nil)
    [MailAddress release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.MailAddress != 0) {
    xmlAddChild(node, [self.MailAddress xmlNodeForDoc:node->doc
                                          elementName:@"MailAddress"
                                      elementNSPrefix:nil]);
  }
}
/* elements */
@synthesize MailAddress;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_GetKeyMail *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_GetKeyMail *newObject =
      [[PhoneServiceSvc_GetKeyMail new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"MailAddress")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.MailAddress = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_GetKeyMailResponse
- (id)init {
  if ((self = [super init])) {
    return_ = 0;
  }

  return self;
}
- (void)dealloc {
  if (return_ != nil)
    [return_ release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.return_ != 0) {
    xmlAddChild(node, [self.return_ xmlNodeForDoc:node->doc
                                      elementName:@"return"
                                  elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize return_;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_GetKeyMailResponse *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_GetKeyMailResponse *newObject =
      [[PhoneServiceSvc_GetKeyMailResponse new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"return")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.return_ = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_SaveMail
- (id)init {
  if ((self = [super init])) {
    MailAddress = 0;
    PublicKey = 0;
  }

  return self;
}
- (void)dealloc {
  if (MailAddress != nil)
    [MailAddress release];
  if (PublicKey != nil)
    [PublicKey release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.MailAddress != 0) {
    xmlAddChild(node, [self.MailAddress xmlNodeForDoc:node->doc
                                          elementName:@"MailAddress"
                                      elementNSPrefix:nil]);
  }
  if (self.PublicKey != 0) {
    xmlAddChild(node, [self.PublicKey xmlNodeForDoc:node->doc
                                        elementName:@"PublicKey"
                                    elementNSPrefix:nil]);
  }
}
/* elements */
@synthesize MailAddress;
@synthesize PublicKey;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_SaveMail *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_SaveMail *newObject =
      [[PhoneServiceSvc_SaveMail new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"MailAddress")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.MailAddress = newChild;
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"PublicKey")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.PublicKey = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_SaveMailResponse
- (id)init {
  if ((self = [super init])) {
    return_ = 0;
  }

  return self;
}
- (void)dealloc {
  if (return_ != nil)
    [return_ release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.return_ != 0) {
    xmlAddChild(node, [self.return_ xmlNodeForDoc:node->doc
                                      elementName:@"return"
                                  elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize return_;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_SaveMailResponse *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_SaveMailResponse *newObject =
      [[PhoneServiceSvc_SaveMailResponse new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"return")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSNumber class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.return_ = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_SavePhone
- (id)init {
  if ((self = [super init])) {
    PhoneNumber = 0;
    Certificate = 0;
  }

  return self;
}
- (void)dealloc {
  if (PhoneNumber != nil)
    [PhoneNumber release];
  if (Certificate != nil)
    [Certificate release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.PhoneNumber != 0) {
    xmlAddChild(node, [self.PhoneNumber xmlNodeForDoc:node->doc
                                          elementName:@"PhoneNumber"
                                      elementNSPrefix:@"PhoneServiceSvc"]);
  }
  if (self.Certificate != 0) {
    xmlAddChild(node, [self.Certificate xmlNodeForDoc:node->doc
                                          elementName:@"Certificate"
                                      elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize PhoneNumber;
@synthesize Certificate;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_SavePhone *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_SavePhone *newObject =
      [[PhoneServiceSvc_SavePhone new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"PhoneNumber")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.PhoneNumber = newChild;
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"Certificate")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSString class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.Certificate = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc_SavePhoneResponse
- (id)init {
  if ((self = [super init])) {
    return_ = 0;
  }

  return self;
}
- (void)dealloc {
  if (return_ != nil)
    [return_ release];

  [super dealloc];
}
- (NSString *)nsPrefix {
  return @"PhoneServiceSvc";
}
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc
                elementName:(NSString *)elName
            elementNSPrefix:(NSString *)elNSPrefix {
  NSString *nodeName = nil;
  if (elNSPrefix != nil && [elNSPrefix length] > 0) {
    nodeName = [NSString stringWithFormat:@"%@:%@", elNSPrefix, elName];
  } else {
    nodeName = [NSString stringWithFormat:@"%@:%@", @"PhoneServiceSvc", elName];
  }

  xmlNodePtr node = xmlNewDocNode(doc, NULL, [nodeName xmlString], NULL);

  [self addAttributesToNode:node];

  [self addElementsToNode:node];

  return node;
}
- (void)addAttributesToNode:(xmlNodePtr)node {
}
- (void)addElementsToNode:(xmlNodePtr)node {

  if (self.return_ != 0) {
    xmlAddChild(node, [self.return_ xmlNodeForDoc:node->doc
                                      elementName:@"return"
                                  elementNSPrefix:@"PhoneServiceSvc"]);
  }
}
/* elements */
@synthesize return_;
/* attributes */
- (NSDictionary *)attributes {
  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

  return attributes;
}
+ (PhoneServiceSvc_SavePhoneResponse *)deserializeNode:(xmlNodePtr)cur {
  PhoneServiceSvc_SavePhoneResponse *newObject =
      [[PhoneServiceSvc_SavePhoneResponse new] autorelease];

  [newObject deserializeAttributesFromNode:cur];
  [newObject deserializeElementsFromNode:cur];

  return newObject;
}
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur {
}
- (void)deserializeElementsFromNode:(xmlNodePtr)cur {

  for (cur = cur->children; cur != NULL; cur = cur->next) {
    if (cur->type == XML_ELEMENT_NODE) {
      xmlChar *elementText = xmlNodeListGetString(cur->doc, cur->children, 1);
      NSString *elementString = nil;

      if (elementText != NULL) {
        elementString = [NSString stringWithCString:(char *)elementText
                                           encoding:NSUTF8StringEncoding];
        [elementString self]; // avoid compiler warning for unused var
        xmlFree(elementText);
      }
      if (xmlStrEqual(cur->name, (const xmlChar *)"return")) {

        Class elementClass = nil;
        xmlChar *instanceType = xmlGetNsProp(
            cur, (const xmlChar *)"type",
            (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance");
        if (instanceType == NULL) {
          elementClass = [NSNumber class];
        } else {
          NSString *elementTypeString =
              [NSString stringWithCString:(char *)instanceType
                                 encoding:NSUTF8StringEncoding];

          NSArray *elementTypeArray =
              [elementTypeString componentsSeparatedByString:@":"];

          NSString *elementClassString = nil;
          if ([elementTypeArray count] > 1) {
            NSString *prefix = [elementTypeArray objectAtIndex:0];
            NSString *localName = [elementTypeArray objectAtIndex:1];

            xmlNsPtr elementNamespace =
                xmlSearchNs(cur->doc, cur, [prefix xmlString]);

            NSString *standardPrefix = [[USGlobals sharedInstance]
                                            .wsdlStandardNamespaces
                objectForKey:
                    [NSString stringWithCString:(char *)elementNamespace->href
                                       encoding:NSUTF8StringEncoding]];

            elementClassString =
                [NSString stringWithFormat:@"%@_%@", standardPrefix, localName];
          } else {
            elementClassString = [elementTypeString
                stringByReplacingOccurrencesOfString:@":"
                                          withString:@"_"
                                             options:0
                                               range:NSMakeRange(
                                                         0, [elementTypeString
                                                                    length])];
          }

          elementClass = NSClassFromString(elementClassString);
          xmlFree(instanceType);
        }

        id newChild = [elementClass deserializeNode:cur];

        self.return_ = newChild;
      }
    }
  }
}
@end
@implementation PhoneServiceSvc
+ (void)initialize {
  [[USGlobals sharedInstance]
          .wsdlStandardNamespaces
      setObject:@"xs"
         forKey:@"http://www.w3.org/2001/XMLSchema"];
  [[USGlobals sharedInstance]
          .wsdlStandardNamespaces setObject:@"PhoneServiceSvc"
                                     forKey:@"http://ws.vdcca.org/"];
}
+ (PhoneServicePortBinding *)PhoneServicePortBinding {
  return [[[PhoneServicePortBinding alloc]
      initWithAddress:@"http://123.30.60.210:6015/AndroidService/PhoneService?wsdl"] autorelease];
}
@end
@implementation PhoneServicePortBinding
@synthesize address;
@synthesize defaultTimeout;
@synthesize logXMLInOut;
@synthesize cookies;
@synthesize authUsername;
@synthesize authPassword;

- (id)init {
  if ((self = [super init])) {
    address = nil;
    cookies = nil;
    defaultTimeout = 5; // seconds
    logXMLInOut = YES;
    synchronousOperationComplete = NO;
  }

  return self;
}
- (id)initWithAddress:(NSString *)anAddress {
  if ((self = [self init])) {
    self.address = [NSURL URLWithString:anAddress];
  }

  return self;
}
- (void)addCookie:(NSHTTPCookie *)toAdd {
  if (toAdd != nil) {
    if (cookies == nil)
      cookies = [[NSMutableArray alloc] init];
    [cookies addObject:toAdd];
  }
}
- (PhoneServicePortBindingResponse *)performSynchronousOperation:
    (PhoneServicePortBindingOperation *)operation {
  synchronousOperationComplete = NO;
  [operation start];

  // Now wait for response
  NSRunLoop *theRL = [NSRunLoop currentRunLoop];

  while (!synchronousOperationComplete &&
         [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]])
    ;
  return operation.response;
}
- (void)performAsynchronousOperation:
    (PhoneServicePortBindingOperation *)operation {
  [operation start];
}
- (void)operation:(PhoneServicePortBindingOperation *)operation
    completedWithResponse:(PhoneServicePortBindingResponse *)response {
  synchronousOperationComplete = YES;
}
- (PhoneServicePortBindingResponse *)SavePhoneUsingParameters:
    (PhoneServiceSvc_SavePhone *)aParameters {
  return [self performSynchronousOperation:
                   [[(PhoneServicePortBinding_SavePhone *)
                           [PhoneServicePortBinding_SavePhone alloc]
                       initWithBinding:self
                              delegate:self
                            parameters:aParameters] autorelease]];
}
- (void)SavePhoneAsyncUsingParameters:(PhoneServiceSvc_SavePhone *)aParameters
                             delegate:
                                 (id<PhoneServicePortBindingResponseDelegate>)
                                     responseDelegate {
  [self performAsynchronousOperation:
            [[(PhoneServicePortBinding_SavePhone *)
                    [PhoneServicePortBinding_SavePhone alloc]
                initWithBinding:self
                       delegate:responseDelegate
                     parameters:aParameters] autorelease]];
}
- (PhoneServicePortBindingResponse *)DeletePhoneUsingParameters:
    (PhoneServiceSvc_DeletePhone *)aParameters {
  return [self performSynchronousOperation:
                   [[(PhoneServicePortBinding_DeletePhone *)
                           [PhoneServicePortBinding_DeletePhone alloc]
                       initWithBinding:self
                              delegate:self
                            parameters:aParameters] autorelease]];
}
- (void)
DeletePhoneAsyncUsingParameters:(PhoneServiceSvc_DeletePhone *)aParameters
                       delegate:(id<PhoneServicePortBindingResponseDelegate>)
                                    responseDelegate {
  [self performAsynchronousOperation:
            [[(PhoneServicePortBinding_DeletePhone *)
                    [PhoneServicePortBinding_DeletePhone alloc]
                initWithBinding:self
                       delegate:responseDelegate
                     parameters:aParameters] autorelease]];
}
- (PhoneServicePortBindingResponse *)GetContactUsingParameters:
    (PhoneServiceSvc_GetContact *)aParameters {
  return [self performSynchronousOperation:
                   [[(PhoneServicePortBinding_GetContact *)
                           [PhoneServicePortBinding_GetContact alloc]
                       initWithBinding:self
                              delegate:self
                            parameters:aParameters] autorelease]];
}
- (void)GetContactAsyncUsingParameters:(PhoneServiceSvc_GetContact *)aParameters
                              delegate:
                                  (id<PhoneServicePortBindingResponseDelegate>)
                                      responseDelegate {
  [self performAsynchronousOperation:
            [[(PhoneServicePortBinding_GetContact *)
                    [PhoneServicePortBinding_GetContact alloc]
                initWithBinding:self
                       delegate:responseDelegate
                     parameters:aParameters] autorelease]];
}
- (PhoneServicePortBindingResponse *)SaveMailUsingParameters:
    (PhoneServiceSvc_SaveMail *)aParameters {
  return [self performSynchronousOperation:
                   [[(PhoneServicePortBinding_SaveMail *)
                           [PhoneServicePortBinding_SaveMail alloc]
                       initWithBinding:self
                              delegate:self
                            parameters:aParameters] autorelease]];
}
- (void)SaveMailAsyncUsingParameters:(PhoneServiceSvc_SaveMail *)aParameters
                            delegate:
                                (id<PhoneServicePortBindingResponseDelegate>)
                                    responseDelegate {
  [self performAsynchronousOperation:
            [[(PhoneServicePortBinding_SaveMail *)
                    [PhoneServicePortBinding_SaveMail alloc]
                initWithBinding:self
                       delegate:responseDelegate
                     parameters:aParameters] autorelease]];
}
- (PhoneServicePortBindingResponse *)GetKeyMailUsingParameters:
    (PhoneServiceSvc_GetKeyMail *)aParameters {
  return [self performSynchronousOperation:
                   [[(PhoneServicePortBinding_GetKeyMail *)
                           [PhoneServicePortBinding_GetKeyMail alloc]
                       initWithBinding:self
                              delegate:self
                            parameters:aParameters] autorelease]];
}
- (void)GetKeyMailAsyncUsingParameters:(PhoneServiceSvc_GetKeyMail *)aParameters
                              delegate:
                                  (id<PhoneServicePortBindingResponseDelegate>)
                                      responseDelegate {
  [self performAsynchronousOperation:
            [[(PhoneServicePortBinding_GetKeyMail *)
                    [PhoneServicePortBinding_GetKeyMail alloc]
                initWithBinding:self
                       delegate:responseDelegate
                     parameters:aParameters] autorelease]];
}
- (PhoneServicePortBindingResponse *)DeleteMailUsingParameters:
    (PhoneServiceSvc_DeleteMail *)aParameters {
  return [self performSynchronousOperation:
                   [[(PhoneServicePortBinding_DeleteMail *)
                           [PhoneServicePortBinding_DeleteMail alloc]
                       initWithBinding:self
                              delegate:self
                            parameters:aParameters] autorelease]];
}
- (void)DeleteMailAsyncUsingParameters:(PhoneServiceSvc_DeleteMail *)aParameters
                              delegate:
                                  (id<PhoneServicePortBindingResponseDelegate>)
                                      responseDelegate {
  [self performAsynchronousOperation:
            [[(PhoneServicePortBinding_DeleteMail *)
                    [PhoneServicePortBinding_DeleteMail alloc]
                initWithBinding:self
                       delegate:responseDelegate
                     parameters:aParameters] autorelease]];
}
- (void)sendHTTPCallUsingBody:(NSString *)outputBody
                   soapAction:(NSString *)soapAction
                 forOperation:(PhoneServicePortBindingOperation *)operation {
  NSMutableURLRequest *request = [NSMutableURLRequest
       requestWithURL:self.address
          cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
      timeoutInterval:self.defaultTimeout];
  NSData *bodyData = [outputBody dataUsingEncoding:NSUTF8StringEncoding];

  if (cookies != nil) {
    [request
        setAllHTTPHeaderFields:[NSHTTPCookie
                                   requestHeaderFieldsWithCookies:cookies]];
  }
  [request setValue:@"wsdl2objc" forHTTPHeaderField:@"User-Agent"];
  [request setValue:soapAction forHTTPHeaderField:@"SOAPAction"];
  [request setValue:@"text/xml; charset=utf-8"
      forHTTPHeaderField:@"Content-Type"];
  [request setValue:[NSString stringWithFormat:@"%u", [bodyData length]]
      forHTTPHeaderField:@"Content-Length"];
  [request setValue:self.address.host forHTTPHeaderField:@"Host"];
  [request setHTTPMethod:@"POST"];
  // set version 1.1 - how?
  [request setHTTPBody:bodyData];

  if (self.logXMLInOut) {
    NSLog(@"OutputHeaders:\n%@", [request allHTTPHeaderFields]);
    NSLog(@"OutputBody:\n%@", outputBody);
  }

  NSURLConnection *connection =
      [[NSURLConnection alloc] initWithRequest:request delegate:operation];

  operation.urlConnection = connection;
  [connection release];
}
- (void)dealloc {
  [address release];
  [cookies release];
  [super dealloc];
}
@end
@implementation PhoneServicePortBindingOperation
@synthesize binding;
@synthesize response;
@synthesize delegate;
@synthesize responseData;
@synthesize urlConnection;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding
             delegate:(id<PhoneServicePortBindingResponseDelegate>)aDelegate {
  if ((self = [super init])) {
    self.binding = aBinding;
    response = nil;
    self.delegate = aDelegate;
    self.responseData = nil;
    self.urlConnection = nil;
  }

  return self;
}
- (void)connection:(NSURLConnection *)connection
    didReceiveAuthenticationChallenge:
        (NSURLAuthenticationChallenge *)challenge {
  if ([challenge previousFailureCount] == 0) {
    NSURLCredential *newCredential;
    newCredential = [NSURLCredential
        credentialWithUser:self.binding.authUsername
                  password:self.binding.authPassword
               persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:newCredential
           forAuthenticationChallenge:challenge];
  } else {
    [[challenge sender] cancelAuthenticationChallenge:challenge];
    NSDictionary *userInfo =
        [NSDictionary dictionaryWithObject:@"Authentication Error"
                                    forKey:NSLocalizedDescriptionKey];
    NSError *authError = [NSError errorWithDomain:@"Connection Authentication"
                                             code:0
                                         userInfo:userInfo];
    [self connection:connection didFailWithError:authError];
  }
}
- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)urlResponse {
  NSHTTPURLResponse *httpResponse;
  if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
    httpResponse = (NSHTTPURLResponse *)urlResponse;
  } else {
    httpResponse = nil;
  }

  if (binding.logXMLInOut) {
    NSLog(@"ResponseStatus: %u\n", [httpResponse statusCode]);
    NSLog(@"ResponseHeaders:\n%@", [httpResponse allHeaderFields]);
  }

  NSMutableArray *cookies = [[NSHTTPCookie
      cookiesWithResponseHeaderFields:[httpResponse allHeaderFields]
                               forURL:binding.address] mutableCopy];

  binding.cookies = cookies;
  [cookies release];
  if ([urlResponse.MIMEType rangeOfString:@"text/xml"].length == 0) {
    NSError *error = nil;
    [connection cancel];
    if ([httpResponse statusCode] >= 400) {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:[NSHTTPURLResponse localizedStringForStatusCode:
                                                      [httpResponse statusCode]]
                        forKey:NSLocalizedDescriptionKey];

      error = [NSError errorWithDomain:@"PhoneServicePortBindingResponseHTTP"
                                  code:[httpResponse statusCode]
                              userInfo:userInfo];
    } else {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:
              [NSString stringWithFormat:
                            @"Unexpected response MIME type to SOAP call:%@",
                            urlResponse.MIMEType]
                        forKey:NSLocalizedDescriptionKey];
      error = [NSError errorWithDomain:@"PhoneServicePortBindingResponseHTTP"
                                  code:1
                              userInfo:userInfo];
    }

    [self connection:connection didFailWithError:error];
  }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
  if (responseData == nil) {
    responseData = [data mutableCopy];
  } else {
    [responseData appendData:data];
  }
}
- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
  if (binding.logXMLInOut) {
    NSLog(@"ResponseError:\n%@", error);
  }
  response.error = error;
  [delegate operation:self completedWithResponse:response];
}
- (void)dealloc {
  [binding release];
  //[response release];
  delegate = nil;
  [responseData release];
  [urlConnection release];

  [super dealloc];
}
@end
@implementation PhoneServicePortBinding_SavePhone
@synthesize parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding
             delegate:
                 (id<PhoneServicePortBindingResponseDelegate>)responseDelegate
           parameters:(PhoneServiceSvc_SavePhone *)aParameters {
  if ((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
    self.parameters = aParameters;
  }

  return self;
}
- (void)dealloc {
  if (parameters != nil)
    [parameters release];

  [super dealloc];
}
- (void)main {
  [response autorelease];
  response = [PhoneServicePortBindingResponse new];

  PhoneServicePortBinding_envelope *envelope =
      [PhoneServicePortBinding_envelope sharedInstance];

  NSMutableDictionary *headerElements = nil;
  headerElements = [NSMutableDictionary dictionary];

  NSMutableDictionary *bodyElements = nil;
  bodyElements = [NSMutableDictionary dictionary];
  if (parameters != nil)
    [bodyElements setObject:parameters forKey:@"SavePhone"];

  NSString *operationXMLString =
      [envelope serializedFormUsingHeaderElements:headerElements
                                     bodyElements:bodyElements];

  [binding sendHTTPCallUsingBody:operationXMLString
                      soapAction:@"http://ws.vdcca.org/SavePhone"
                    forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (responseData != nil && delegate != nil) {
    xmlDocPtr doc;
    xmlNodePtr cur;

    if (binding.logXMLInOut) {
      NSLog(@"ResponseBody:\n%@",
            [[[NSString alloc] initWithData:responseData
                                   encoding:NSUTF8StringEncoding] autorelease]);
    }

    doc = xmlParseMemory([responseData bytes], [responseData length]);

    if (doc == NULL) {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:@"Errors while parsing returned XML"
                        forKey:NSLocalizedDescriptionKey];

      response.error =
          [NSError errorWithDomain:@"PhoneServicePortBindingResponseXML"
                              code:1
                          userInfo:userInfo];
      [delegate operation:self completedWithResponse:response];
    } else {
      cur = xmlDocGetRootElement(doc);
      cur = cur->children;

      for (; cur != NULL; cur = cur->next) {
        if (cur->type == XML_ELEMENT_NODE) {

          if (xmlStrEqual(cur->name, (const xmlChar *)"Body")) {
            NSMutableArray *responseBodyParts = [NSMutableArray array];

            xmlNodePtr bodyNode;
            for (bodyNode = cur->children; bodyNode != NULL;
                 bodyNode = bodyNode->next) {
              if (cur->type == XML_ELEMENT_NODE) {
                if (xmlStrEqual(bodyNode->name,
                                (const xmlChar *)"SavePhoneResponse")) {
                  PhoneServiceSvc_SavePhoneResponse *bodyObject =
                      [PhoneServiceSvc_SavePhoneResponse
                          deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
                if (xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix) &&
                    xmlStrEqual(bodyNode->name, (const xmlChar *)"Fault")) {
                  SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
              }
            }

            response.bodyParts = responseBodyParts;
          }
        }
      }

      xmlFreeDoc(doc);
    }

    xmlCleanupParser();
    [delegate operation:self completedWithResponse:response];
  }
}
@end
@implementation PhoneServicePortBinding_DeletePhone
@synthesize parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding
             delegate:
                 (id<PhoneServicePortBindingResponseDelegate>)responseDelegate
           parameters:(PhoneServiceSvc_DeletePhone *)aParameters {
  if ((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
    self.parameters = aParameters;
  }

  return self;
}
- (void)dealloc {
  if (parameters != nil)
    [parameters release];

  [super dealloc];
}
- (void)main {
  [response autorelease];
  response = [PhoneServicePortBindingResponse new];

  PhoneServicePortBinding_envelope *envelope =
      [PhoneServicePortBinding_envelope sharedInstance];

  NSMutableDictionary *headerElements = nil;
  headerElements = [NSMutableDictionary dictionary];

  NSMutableDictionary *bodyElements = nil;
  bodyElements = [NSMutableDictionary dictionary];
  if (parameters != nil)
    [bodyElements setObject:parameters forKey:@"DeletePhone"];

  NSString *operationXMLString =
      [envelope serializedFormUsingHeaderElements:headerElements
                                     bodyElements:bodyElements];

  [binding sendHTTPCallUsingBody:operationXMLString
                      soapAction:@"http://ws.vdcca.org/DeletePhone"
                    forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (responseData != nil && delegate != nil) {
    xmlDocPtr doc;
    xmlNodePtr cur;

    if (binding.logXMLInOut) {
      NSLog(@"ResponseBody:\n%@",
            [[[NSString alloc] initWithData:responseData
                                   encoding:NSUTF8StringEncoding] autorelease]);
    }

    doc = xmlParseMemory([responseData bytes], [responseData length]);

    if (doc == NULL) {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:@"Errors while parsing returned XML"
                        forKey:NSLocalizedDescriptionKey];

      response.error =
          [NSError errorWithDomain:@"PhoneServicePortBindingResponseXML"
                              code:1
                          userInfo:userInfo];
      [delegate operation:self completedWithResponse:response];
    } else {
      cur = xmlDocGetRootElement(doc);
      cur = cur->children;

      for (; cur != NULL; cur = cur->next) {
        if (cur->type == XML_ELEMENT_NODE) {

          if (xmlStrEqual(cur->name, (const xmlChar *)"Body")) {
            NSMutableArray *responseBodyParts = [NSMutableArray array];

            xmlNodePtr bodyNode;
            for (bodyNode = cur->children; bodyNode != NULL;
                 bodyNode = bodyNode->next) {
              if (cur->type == XML_ELEMENT_NODE) {
                if (xmlStrEqual(bodyNode->name,
                                (const xmlChar *)"DeletePhoneResponse")) {
                  PhoneServiceSvc_DeletePhoneResponse *bodyObject =
                      [PhoneServiceSvc_DeletePhoneResponse
                          deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
                if (xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix) &&
                    xmlStrEqual(bodyNode->name, (const xmlChar *)"Fault")) {
                  SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
              }
            }

            response.bodyParts = responseBodyParts;
          }
        }
      }

      xmlFreeDoc(doc);
    }

    xmlCleanupParser();
    [delegate operation:self completedWithResponse:response];
  }
}
@end
@implementation PhoneServicePortBinding_GetContact
@synthesize parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding
             delegate:
                 (id<PhoneServicePortBindingResponseDelegate>)responseDelegate
           parameters:(PhoneServiceSvc_GetContact *)aParameters {
  if ((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
    self.parameters = aParameters;
  }

  return self;
}
- (void)dealloc {
  if (parameters != nil)
    [parameters release];

  [super dealloc];
}
- (void)main {
  [response autorelease];
  response = [PhoneServicePortBindingResponse new];

  PhoneServicePortBinding_envelope *envelope =
      [PhoneServicePortBinding_envelope sharedInstance];

  NSMutableDictionary *headerElements = nil;
  headerElements = [NSMutableDictionary dictionary];

  NSMutableDictionary *bodyElements = nil;
  bodyElements = [NSMutableDictionary dictionary];
  if (parameters != nil)
    [bodyElements setObject:parameters forKey:@"GetContact"];

  NSString *operationXMLString =
      [envelope serializedFormUsingHeaderElements:headerElements
                                     bodyElements:bodyElements];

  [binding sendHTTPCallUsingBody:operationXMLString
                      soapAction:@"http://ws.vdcca.org/GetContact"
                    forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (responseData != nil && delegate != nil) {
    xmlDocPtr doc;
    xmlNodePtr cur;

    if (binding.logXMLInOut) {
      NSLog(@"ResponseBody:\n%@",
            [[[NSString alloc] initWithData:responseData
                                   encoding:NSUTF8StringEncoding] autorelease]);
    }

    doc = xmlParseMemory([responseData bytes], [responseData length]);

    if (doc == NULL) {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:@"Errors while parsing returned XML"
                        forKey:NSLocalizedDescriptionKey];

      response.error =
          [NSError errorWithDomain:@"PhoneServicePortBindingResponseXML"
                              code:1
                          userInfo:userInfo];
      [delegate operation:self completedWithResponse:response];
    } else {
      cur = xmlDocGetRootElement(doc);
      cur = cur->children;

      for (; cur != NULL; cur = cur->next) {
        if (cur->type == XML_ELEMENT_NODE) {

          if (xmlStrEqual(cur->name, (const xmlChar *)"Body")) {
            NSMutableArray *responseBodyParts = [NSMutableArray array];

            xmlNodePtr bodyNode;
            for (bodyNode = cur->children; bodyNode != NULL;
                 bodyNode = bodyNode->next) {
              if (cur->type == XML_ELEMENT_NODE) {
                if (xmlStrEqual(bodyNode->name,
                                (const xmlChar *)"GetContactResponse")) {
                  PhoneServiceSvc_GetContactResponse *bodyObject =
                      [PhoneServiceSvc_GetContactResponse
                          deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
                if (xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix) &&
                    xmlStrEqual(bodyNode->name, (const xmlChar *)"Fault")) {
                  SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
              }
            }

            response.bodyParts = responseBodyParts;
          }
        }
      }

      xmlFreeDoc(doc);
    }

    xmlCleanupParser();
    [delegate operation:self completedWithResponse:response];
  }
}
@end
@implementation PhoneServicePortBinding_SaveMail
@synthesize parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding
             delegate:
                 (id<PhoneServicePortBindingResponseDelegate>)responseDelegate
           parameters:(PhoneServiceSvc_SaveMail *)aParameters {
  if ((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
    self.parameters = aParameters;
  }

  return self;
}
- (void)dealloc {
  if (parameters != nil)
    [parameters release];

  [super dealloc];
}
- (void)main {
  [response autorelease];
  response = [PhoneServicePortBindingResponse new];

  PhoneServicePortBinding_envelope *envelope =
      [PhoneServicePortBinding_envelope sharedInstance];

  NSMutableDictionary *headerElements = nil;
  headerElements = [NSMutableDictionary dictionary];

  NSMutableDictionary *bodyElements = nil;
  bodyElements = [NSMutableDictionary dictionary];
  if (parameters != nil)
    [bodyElements setObject:parameters forKey:@"SaveMail"];

  NSString *operationXMLString =
      [envelope serializedFormUsingHeaderElements:headerElements
                                     bodyElements:bodyElements];

  [binding sendHTTPCallUsingBody:operationXMLString
                      soapAction:@"http://ws.vdcca.org/SaveMail"
                    forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (responseData != nil && delegate != nil) {
    xmlDocPtr doc;
    xmlNodePtr cur;

    if (binding.logXMLInOut) {
      NSLog(@"ResponseBody:\n%@",
            [[[NSString alloc] initWithData:responseData
                                   encoding:NSUTF8StringEncoding] autorelease]);
    }

    doc = xmlParseMemory([responseData bytes], [responseData length]);

    if (doc == NULL) {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:@"Errors while parsing returned XML"
                        forKey:NSLocalizedDescriptionKey];

      response.error =
          [NSError errorWithDomain:@"PhoneServicePortBindingResponseXML"
                              code:1
                          userInfo:userInfo];
      [delegate operation:self completedWithResponse:response];
    } else {
      cur = xmlDocGetRootElement(doc);
      cur = cur->children;

      for (; cur != NULL; cur = cur->next) {
        if (cur->type == XML_ELEMENT_NODE) {

          if (xmlStrEqual(cur->name, (const xmlChar *)"Body")) {
            NSMutableArray *responseBodyParts = [NSMutableArray array];

            xmlNodePtr bodyNode;
            for (bodyNode = cur->children; bodyNode != NULL;
                 bodyNode = bodyNode->next) {
              if (cur->type == XML_ELEMENT_NODE) {
                if (xmlStrEqual(bodyNode->name,
                                (const xmlChar *)"SaveMailResponse")) {
                  PhoneServiceSvc_SaveMailResponse *bodyObject =
                      [PhoneServiceSvc_SaveMailResponse
                          deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
                if (xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix) &&
                    xmlStrEqual(bodyNode->name, (const xmlChar *)"Fault")) {
                  SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
              }
            }

            response.bodyParts = responseBodyParts;
          }
        }
      }

      xmlFreeDoc(doc);
    }

    xmlCleanupParser();
    [delegate operation:self completedWithResponse:response];
  }
}
@end
@implementation PhoneServicePortBinding_GetKeyMail
@synthesize parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding
             delegate:
                 (id<PhoneServicePortBindingResponseDelegate>)responseDelegate
           parameters:(PhoneServiceSvc_GetKeyMail *)aParameters {
  if ((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
    self.parameters = aParameters;
  }

  return self;
}
- (void)dealloc {
  if (parameters != nil)
    [parameters release];

  [super dealloc];
}
- (void)main {
  [response autorelease];
  response = [PhoneServicePortBindingResponse new];

  PhoneServicePortBinding_envelope *envelope =
      [PhoneServicePortBinding_envelope sharedInstance];

  NSMutableDictionary *headerElements = nil;
  headerElements = [NSMutableDictionary dictionary];

  NSMutableDictionary *bodyElements = nil;
  bodyElements = [NSMutableDictionary dictionary];
  if (parameters != nil)
    [bodyElements setObject:parameters forKey:@"GetKeyMail"];

  NSString *operationXMLString =
      [envelope serializedFormUsingHeaderElements:headerElements
                                     bodyElements:bodyElements];

  [binding sendHTTPCallUsingBody:operationXMLString
                      soapAction:@"http://ws.vdcca.org/GetKeyMail"
                    forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (responseData != nil && delegate != nil) {
    xmlDocPtr doc;
    xmlNodePtr cur;

    if (binding.logXMLInOut) {
      NSLog(@"ResponseBody:\n%@",
            [[[NSString alloc] initWithData:responseData
                                   encoding:NSUTF8StringEncoding] autorelease]);
    }

    doc = xmlParseMemory([responseData bytes], [responseData length]);

    if (doc == NULL) {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:@"Errors while parsing returned XML"
                        forKey:NSLocalizedDescriptionKey];

      response.error =
          [NSError errorWithDomain:@"PhoneServicePortBindingResponseXML"
                              code:1
                          userInfo:userInfo];
      [delegate operation:self completedWithResponse:response];
    } else {
      cur = xmlDocGetRootElement(doc);
      cur = cur->children;

      for (; cur != NULL; cur = cur->next) {
        if (cur->type == XML_ELEMENT_NODE) {

          if (xmlStrEqual(cur->name, (const xmlChar *)"Body")) {
            NSMutableArray *responseBodyParts = [NSMutableArray array];

            xmlNodePtr bodyNode;
            for (bodyNode = cur->children; bodyNode != NULL;
                 bodyNode = bodyNode->next) {
              if (cur->type == XML_ELEMENT_NODE) {
                if (xmlStrEqual(bodyNode->name,
                                (const xmlChar *)"GetKeyMailResponse")) {
                  PhoneServiceSvc_GetKeyMailResponse *bodyObject =
                      [PhoneServiceSvc_GetKeyMailResponse
                          deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
                if (xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix) &&
                    xmlStrEqual(bodyNode->name, (const xmlChar *)"Fault")) {
                  SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
              }
            }

            response.bodyParts = responseBodyParts;
          }
        }
      }

      xmlFreeDoc(doc);
    }

    xmlCleanupParser();
    [delegate operation:self completedWithResponse:response];
  }
}
@end
@implementation PhoneServicePortBinding_DeleteMail
@synthesize parameters;
- (id)initWithBinding:(PhoneServicePortBinding *)aBinding
             delegate:
                 (id<PhoneServicePortBindingResponseDelegate>)responseDelegate
           parameters:(PhoneServiceSvc_DeleteMail *)aParameters {
  if ((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
    self.parameters = aParameters;
  }

  return self;
}
- (void)dealloc {
  if (parameters != nil)
    [parameters release];

  [super dealloc];
}
- (void)main {
  [response autorelease];
  response = [PhoneServicePortBindingResponse new];

  PhoneServicePortBinding_envelope *envelope =
      [PhoneServicePortBinding_envelope sharedInstance];

  NSMutableDictionary *headerElements = nil;
  headerElements = [NSMutableDictionary dictionary];

  NSMutableDictionary *bodyElements = nil;
  bodyElements = [NSMutableDictionary dictionary];
  if (parameters != nil)
    [bodyElements setObject:parameters forKey:@"DeleteMail"];

  NSString *operationXMLString =
      [envelope serializedFormUsingHeaderElements:headerElements
                                     bodyElements:bodyElements];

  [binding sendHTTPCallUsingBody:operationXMLString
                      soapAction:@"http://ws.vdcca.org/DeleteMail"
                    forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
  if (responseData != nil && delegate != nil) {
    xmlDocPtr doc;
    xmlNodePtr cur;

    if (binding.logXMLInOut) {
      NSLog(@"ResponseBody:\n%@",
            [[[NSString alloc] initWithData:responseData
                                   encoding:NSUTF8StringEncoding] autorelease]);
    }

    doc = xmlParseMemory([responseData bytes], [responseData length]);

    if (doc == NULL) {
      NSDictionary *userInfo = [NSDictionary
          dictionaryWithObject:@"Errors while parsing returned XML"
                        forKey:NSLocalizedDescriptionKey];

      response.error =
          [NSError errorWithDomain:@"PhoneServicePortBindingResponseXML"
                              code:1
                          userInfo:userInfo];
      [delegate operation:self completedWithResponse:response];
    } else {
      cur = xmlDocGetRootElement(doc);
      cur = cur->children;

      for (; cur != NULL; cur = cur->next) {
        if (cur->type == XML_ELEMENT_NODE) {

          if (xmlStrEqual(cur->name, (const xmlChar *)"Body")) {
            NSMutableArray *responseBodyParts = [NSMutableArray array];

            xmlNodePtr bodyNode;
            for (bodyNode = cur->children; bodyNode != NULL;
                 bodyNode = bodyNode->next) {
              if (cur->type == XML_ELEMENT_NODE) {
                if (xmlStrEqual(bodyNode->name,
                                (const xmlChar *)"DeleteMailResponse")) {
                  PhoneServiceSvc_DeleteMailResponse *bodyObject =
                      [PhoneServiceSvc_DeleteMailResponse
                          deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
                if (xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix) &&
                    xmlStrEqual(bodyNode->name, (const xmlChar *)"Fault")) {
                  SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode];
                  // NSAssert1(bodyObject != nil, @"Errors while parsing body
                  // %s", bodyNode->name);
                  if (bodyObject != nil)
                    [responseBodyParts addObject:bodyObject];
                }
              }
            }

            response.bodyParts = responseBodyParts;
          }
        }
      }

      xmlFreeDoc(doc);
    }

    xmlCleanupParser();
    [delegate operation:self completedWithResponse:response];
  }
}
@end
static PhoneServicePortBinding_envelope
    *PhoneServicePortBindingSharedEnvelopeInstance = nil;
@implementation PhoneServicePortBinding_envelope
+ (PhoneServicePortBinding_envelope *)sharedInstance {
  if (PhoneServicePortBindingSharedEnvelopeInstance == nil) {
    PhoneServicePortBindingSharedEnvelopeInstance =
        [PhoneServicePortBinding_envelope new];
  }

  return PhoneServicePortBindingSharedEnvelopeInstance;
}
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements
                                   bodyElements:(NSDictionary *)bodyElements {
  xmlDocPtr doc;

  doc = xmlNewDoc((const xmlChar *)XML_DEFAULT_VERSION);
  if (doc == NULL) {
    NSLog(@"Error creating the xml document tree");
    return @"";
  }

  xmlNodePtr root = xmlNewDocNode(doc, NULL, (const xmlChar *)"Envelope", NULL);
  xmlDocSetRootElement(doc, root);

  xmlNsPtr soapEnvelopeNs = xmlNewNs(
      root, (const xmlChar *)"http://schemas.xmlsoap.org/soap/envelope/",
      (const xmlChar *)"soap");
  xmlSetNs(root, soapEnvelopeNs);

  xmlNsPtr xslNs =
      xmlNewNs(root, (const xmlChar *)"http://www.w3.org/1999/XSL/Transform",
               (const xmlChar *)"xsl");
  xmlNewNs(root, (const xmlChar *)"http://www.w3.org/2001/XMLSchema-instance",
           (const xmlChar *)"xsi");

  xmlNewNsProp(root, xslNs, (const xmlChar *)"version", (const xmlChar *)"1.0");

  xmlNewNs(root, (const xmlChar *)"http://www.w3.org/2001/XMLSchema",
           (const xmlChar *)"xs");
  xmlNewNs(root, (const xmlChar *)"http://ws.vdcca.org/",
           (const xmlChar *)"PhoneServiceSvc");

  if ((headerElements != nil) && ([headerElements count] > 0)) {
    xmlNodePtr headerNode =
        xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar *)"Header", NULL);
    xmlAddChild(root, headerNode);

    for (NSString *key in [headerElements allKeys]) {
      id header = [headerElements objectForKey:key];
      xmlAddChild(
          headerNode,
          [header xmlNodeForDoc:doc elementName:key elementNSPrefix:nil]);
    }
  }

  if ((bodyElements != nil) && ([bodyElements count] > 0)) {
    xmlNodePtr bodyNode =
        xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar *)"Body", NULL);
    xmlAddChild(root, bodyNode);

    for (NSString *key in [bodyElements allKeys]) {
      id body = [bodyElements objectForKey:key];
      xmlAddChild(bodyNode,
                  [body xmlNodeForDoc:doc elementName:key elementNSPrefix:nil]);
    }
  }

  xmlChar *buf;
  int size;
  xmlDocDumpFormatMemory(doc, &buf, &size, 1);

  NSString *serializedForm = [NSString stringWithCString:(const char *)buf
                                                encoding:NSUTF8StringEncoding];
  xmlFree(buf);

  xmlFreeDoc(doc);
  return serializedForm;
}
@end
@implementation PhoneServicePortBindingResponse
@synthesize headers;
@synthesize bodyParts;
@synthesize error;
- (id)init {
  if ((self = [super init])) {
    headers = nil;
    bodyParts = nil;
    error = nil;
  }

  return self;
}
- (void)dealloc {
  // self.headers = nil;
  // self.bodyParts = nil;
  self.error = nil;
  [super dealloc];
}
@end
