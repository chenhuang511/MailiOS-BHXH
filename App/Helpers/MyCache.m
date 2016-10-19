//
//  MyCache.m
//  iMail
//
//  Created by Chen on 8/22/14.
//  Copyright (c) 2014 com.inkmobility. All rights reserved.
//

#import "MyCache.h"

@implementation MyCache
- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:message forKey:@"cachedMessage"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        message = [decoder decodeObjectForKey:@"cachedMessage"];
    }
    return self;
}

-(NSArray *)getMessage{
    return message;
}
@end
