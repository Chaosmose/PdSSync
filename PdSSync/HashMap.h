//
//  HashMap.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//

#import <Foundation/Foundation.h>

#import "DeltaPathMap.h"

extern NSString* const pathToHashKey;
extern NSString* const hashToPathsKey;

@interface HashMap : NSObject

/**
 *  Default YES
 */
@property (nonatomic)BOOL useCompactSerialization;

/**
 *  A dictionary encoded factory constructor
 *
 *  @param dictionary the dictionary
 *
 *  @return tha HashMap
 */
+(instancetype)fromDictionary:(NSDictionary*)dictionary;


/**
 *  Returns a dictionary representation of the HashMap
 *
 *  @return the dictionary
 */
- (NSDictionary*)dictionaryRepresentation;


/**
 *  Sets the hash of a given path
 *
 *  @param hash the hash
 @  @param path the path
 */
- (void)setHash:(NSString*)hash forPath:(NSString*)path;


/**
 *  Computes an optimized delta path map from a source to a destination.
 *  We try to reduce the operation and to perform the more efficient operation.
 *  For example : we can perform a move command instead of (delete + create)
 *  When delta is used for a distant  synchronization this may be highly critical.
 *
 *  @param source the source hashMap
 *  @param destination  the destination hashMap
 *
 *  @return the DeltaHashMap
 */
- (DeltaPathMap*)deltaHashMapWithSource:(HashMap*)source andDestination:(HashMap*)destination;


/**
 *  Returns the number of paths in hash path
 *
 *  @return the count;
 */
- (NSUInteger)count;

@end