//
//  JSONResponseSerializerWithData.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 18/03/2014.
//
//

#import "JSONResponseSerializerWithData.h"

@implementation JSONResponseSerializerWithData


- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error{
	id JSONObject = [super responseObjectForResponse:response data:data error:error];
	if (*error != nil) {
		NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
		if (data == nil) {
			userInfo[JSONResponseSerializerWithDataKey] = [NSData data];
		} else {
			userInfo[JSONResponseSerializerWithDataKey] = data;
		}
		NSError *newError = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:userInfo];
		(*error) = newError;
	}
	return (JSONObject);
}

@end
