//
//  HashMap.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//

#import "HashMap.h"

NSString*const pathToHashKey=@"pathToHash";
NSString*const hashToPathKey=@"hashToPathKey";


@implementation HashMap {
    NSMutableDictionary *_pathToHash; // Path is the key
    NSMutableDictionary *_hashToPath; // Hash is the key
}
/**
 *  A dictionary encoded factory constructor
 *
 *  @param dictionary the dictionary
 *
 *  @return tha HashMap
 */
+(instancetype)fromDictionary:(NSDictionary*)dictionary{
    if([dictionary objectForKey:pathToHashKey] && [dictionary objectForKey:hashToPathKey]){
        HashMap *hashMap=[[HashMap alloc] init];
        hashMap->_hashToPath=[[dictionary objectForKey:hashToPathKey]copy];
        hashMap->_pathToHash=[[dictionary objectForKey:pathToHashKey]copy];
        return hashMap;
    }else{
        return nil;
    }
    
}

/**
 *  Returns a dictionary representation of the HashMap
 *
 *  @return the dictionary
 */
- (NSDictionary*)dictionaryRepresentation{
    return @{pathToHashKey:[_pathToHash copy], hashToPathKey:[_hashToPath copy]};
}

/**
 *  Sets the hash of a given path
 *
 *  @param hash the hash
 @  @param path the path
 */
- (void)setHash:(NSString*)hash forPath:(NSString*)path{
    if(!_pathToHash){
        _pathToHash=[NSMutableDictionary dictionary];
        _hashToPath=[NSMutableDictionary dictionary];
    }
    _pathToHash[[path copy]]=[hash copy];
    _hashToPath[[hash copy]]=[path copy];
}

/**
 *  Returns the hash of a given path or nil if not found
 *<(
 *  @param path
 *
 *  @return the path
 */
- (NSString*)hashForPath:(NSString*)path{
    return [_pathToHash objectForKey:path];
}


/**
 *  Returns the path of a given hash or nil if not found
 *
 *  @param path
 *
 *  @return the path
 */
- (NSString*)pathFromHash:(NSString*)path{
    return [_hashToPath objectForKey:path];;
}


/**
 *  Computes the delta hash Map form a master to a slave.
 *
 *  @param master the master hashMap
 *  @param slave  the slave hashMap
 *
 *  @return the DeltaHashMap
 */
- (DeltaPathMap*)deltaHashMapWithMaster:(HashMap*)master andSlave:(HashMap*)slave{
    DeltaPathMap*delta=[DeltaPathMap deltaHasMap];
    for (NSDictionary*path in master->_hashToPath) {
        if ([slave hashForPath:path]) {
            if([[master hashForPath:path] isEqualToString:[slave hashForPath:path]]){
                [delta.similarPaths addObject:[path copy]];
            }else{
                [delta.updatedPaths addObject:[path copy]];
            }
        }else{
            // There is no hash in the slave.
            [delta.createdPaths addObject:[path copy]];
        }
    }
    for (NSDictionary*path in slave->_hashToPath) {
         if (![master hashForPath:path]) {
              [delta.deletedPaths addObject:[path copy]];
         }
    }
    return delta;
}




@end
