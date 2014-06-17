//
//  HashMap.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//

#import "HashMap.h"

NSString*const pathToHashKey=@"pthToH";
NSString*const hashToPathKey=@"hToPth";


@implementation HashMap {
    NSMutableDictionary *_pathToHash; // Path is the key
    NSMutableDictionary *_hashToPath; // Hash is the key
}


-(instancetype)init{
    self=[super init];
    if (self) {
        self->_pathToHash=[NSMutableDictionary dictionary];
        self->_hashToPath=[NSMutableDictionary dictionary];
    }
    return self;
}

/**
 *  A dictionary encoded factory constructor
 *
 *  @param dictionary the dictionary
 *
 *  @return tha HashMap
 */
+(instancetype)fromDictionary:(NSDictionary*)dictionary{
    if([dictionary objectForKey:hashToPathKey]){
        HashMap *hashMap=[[HashMap alloc] init];
        hashMap->_hashToPath=[[dictionary objectForKey:hashToPathKey]copy];
        if([dictionary objectForKey:pathToHashKey]){
            hashMap->_pathToHash=[[dictionary objectForKey:pathToHashKey]copy];
        }else{
            // It is a compact mode we regenerate the homologous map
            hashMap->_hashToPath=[NSMutableDictionary dictionary];
            for (NSString*path in hashMap->_pathToHash) {
                NSString*hash=[hashMap->_hashToPath valueForKey:path];
                hashMap->_hashToPath[[hash copy]]=[path copy];
            }
        }
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
    return @{hashToPathKey:[_hashToPath copy]};
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
 *  Computes the delta path map form a source to a destination.
 *
 *  @param source the source hashMap
 *  @param destination  the destination hashMap
 *
 *  @return the DeltaHashMap
 */
- (DeltaPathMap*)deltaHashMapWithSource:(HashMap*)source andDestination:(HashMap*)destination{
    DeltaPathMap*delta=[DeltaPathMap instance];
    for (NSDictionary*path in source->_hashToPath) {
        if ([destination hashForPath:path]) {
            if(![[source hashForPath:path] isEqualToString:[destination hashForPath:path]]){
                [delta.updatedPaths addObject:[path copy]];
            }
        }else{
            // There is no hash in the destination.
            [delta.createdPaths addObject:[path copy]];
        }
    }
    for (NSDictionary*path in destination->_hashToPath) {
         if (![source hashForPath:path]) {
              [delta.deletedPaths addObject:[path copy]];
         }
    }
    return delta;
}


/**
 *  Returns the number of paths in hash path
 *
 *  @return the count;
 */
- (NSUInteger)count{
    return [_hashToPath count];
}

@end