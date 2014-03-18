//
//  JSONResponseSerializerWithData.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 18/03/2014.
//
//  Extracted from http://blog.gregfiumara.com/archives/239
//  Uses NSError userInfo to pass the response data in JSONResponseSerializerWithDataKey

#import "AFURLResponseSerialization.h"

/// NSError userInfo key that will contain response data
static NSString * const JSONResponseSerializerWithDataKey = @"JSONResponseSerializerWithDataKey";

@interface JSONResponseSerializerWithData : AFJSONResponseSerializer

@end
