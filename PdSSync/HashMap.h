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
extern NSString* const hashToPathKey;

@interface HashMap : NSObject


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
 *  Returns the hash of a given path or nil if not found
 *
 *  @param path
 *
 *  @return the path
 */
- (NSString*)hashForPath:(NSString*)path;


/**
 *  Returns the path of a given hash or nil if not found
 *
 *  @param path
 *
 *  @return the path
 */
- (NSString*)pathFromHash:(NSString*)path;



/**
 *  Computes the delta path map form a master to a slave.
 *
 *  @param master the master hashMap
 *  @param slave  the slave hashMap
 *
 *  @return the DeltaHashMap
 */
- (DeltaPathMap*)deltaHashMapWithMaster:(HashMap*)master andSlave:(HashMap*)slave;

@end