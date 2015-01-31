//
//  HashMap.m
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//

#import "HashMap.h"

NSString*const pathToHashKey=@"pthToH";
NSString*const hashToPathsKey=@"hToPths";

@interface HashMap (){
}
@property (nonatomic)NSMutableDictionary *pathToHash; // Path is the key
@property (nonatomic)NSMutableDictionary *hashToPaths; // Hash is the key each entry is an array of Paths
@end

@implementation HashMap {
}

-(instancetype)init{
    self=[super init];
    if (self) {
        self.pathToHash=[NSMutableDictionary dictionary];
        self.hashToPaths=[NSMutableDictionary dictionary];
        _useCompactSerialization=YES;
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
    if([dictionary objectForKey:pathToHashKey] && [dictionary objectForKey:hashToPathsKey]){
        // Not compact deserialization mode
        HashMap *hashMap=[[HashMap alloc] init];
        hashMap.pathToHash=[dictionary objectForKey:pathToHashKey];
        hashMap.hashToPaths=[dictionary objectForKey:hashToPathsKey];
        return hashMap;
    }else if ([dictionary objectForKey:pathToHashKey]) {
        // compact deserialization mode
        HashMap *hashMap=[[HashMap alloc] init];
        NSDictionary*pathToHash=[dictionary objectForKey:pathToHashKey];
        for (NSString*pathKey in pathToHash) {
            [hashMap setHash:[pathToHash objectForKey:pathKey]
                     forPath:pathKey];
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
    if(_useCompactSerialization){
        // We store only pathToHash because
        // paths are unique, but you can find to files with the same hash (if they are binary copies)
        return @{pathToHashKey:[_pathToHash copy]};
    }else{
        return @{pathToHashKey:[_pathToHash copy],
                 hashToPathsKey:[_hashToPaths copy]};
    }
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
        _hashToPaths=[NSMutableDictionary dictionary];
    }
    NSString*h=[hash copy];
    NSString*p=[path copy];
    _pathToHash[p]=h;
    if(![_hashToPaths objectForKey:h]){
        _hashToPaths[h]=[NSMutableArray arrayWithObjects:p, nil];
    }else{
        [(NSMutableArray*)_hashToPaths[h] addObject:p];
    }
}

/**
 *  Returns the hash of a given path or nil if not found
 *<(
 *  @param path
 *
 *  @return the path
 */
- (NSString*)_hashForPath:(NSString*)path{
    return [_pathToHash objectForKey:path];
}


/**
 *  Returns the paths for given hash or nil if not found
 *
 *  @param path
 *
 *  @return the path
 */
- (NSArray*)_pathsFromHash:(NSString*)path{
    return [_hashToPaths objectForKey:path];;
}

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
- (DeltaPathMap*)deltaHashMapWithSource:(HashMap*)source andDestination:(HashMap*)destination{
    if(!source || !destination){
        return nil;
    }
    DeltaPathMap*delta=[DeltaPathMap instance];
    
    // #1# scan the destination.
    // Check deleted or moved paths from the source
    // that have still one occurence present in the destination
    
    for (NSString*hash in destination->_hashToPaths) {
        
        NSMutableArray*pathsOnDestination=[[destination->_hashToPaths objectForKey:hash] mutableCopy];
        NSMutableArray*pathsOnSources=[[source->_hashToPaths objectForKey:hash] mutableCopy];
        
        NSUInteger nbOfOccurencesOnDestination=[pathsOnDestination count];
        NSUInteger nbOfOccurencesOnSource=[pathsOnSources count];
        
        if(nbOfOccurencesOnSource==0){
            // We gonna delete all the files.
            for (NSString*toBeDeletedPath in pathsOnDestination) {
                // If the path exist on the destination and the source
                // and the hash is different it is an Update not delete
                if([[source->_pathToHash allKeys] indexOfObject:toBeDeletedPath]==NSNotFound){
                    [self _addPathOrOperation:[toBeDeletedPath copy]
                                       to:delta.deletedPaths];
                }
            }
        }else if(nbOfOccurencesOnSource<nbOfOccurencesOnDestination){
            // There are more occurences on destination than on source.
            // We gonna delete some files
            NSUInteger numberOfOccurenceToDelete=(nbOfOccurencesOnDestination-nbOfOccurencesOnSource);
            for (NSUInteger i=0; i<numberOfOccurenceToDelete; i++) {
                NSString *toBeDeletedPath=[pathsOnDestination objectAtIndex:i];
                // If the path exist on the destination and the source
                // and the hash is different it is an Update not delete
                if([[source->_pathToHash allKeys] indexOfObject:toBeDeletedPath]==NSNotFound){
                    [self _addPathOrOperation:[toBeDeletedPath copy]
                                       to:delta.deletedPaths];
                }
            }
            // Then move the preserved files to remap.
            NSUInteger indexInSource=0;
            for (NSUInteger i=numberOfOccurenceToDelete;i<nbOfOccurencesOnDestination; i++) {
                NSString *toBeMovedOriginalPath=[pathsOnDestination objectAtIndex:i];
                NSString *toBeMovedFinalPath=[pathsOnSources objectAtIndex:indexInSource];
                // Move only if necessary.
                if([self _shouldProceedToMoveOrCopyFrom:toBeMovedOriginalPath
                                                     to:toBeMovedFinalPath
                                        forOriginalHash:hash
                                  destinationPathToHash:destination->_pathToHash]){
                    NSArray*movedArray=@[toBeMovedFinalPath,toBeMovedOriginalPath];
                    [self _addPathOrOperation:movedArray
                                           to:delta.movedPaths];
                }
                indexInSource++;
            }
        }else if(nbOfOccurencesOnSource>=nbOfOccurencesOnDestination){
            // There are more occurences on source than on destination.
            // We move some files then copy the others.
            // Move
            NSUInteger numberOfOccurenceToMove=nbOfOccurencesOnDestination;
            NSString*toBeMovedFinalPath=nil;
            for (NSUInteger i=0;i<numberOfOccurenceToMove; i++) {
                NSString *toBeMovedOriginalPath=[pathsOnDestination objectAtIndex:i];
                toBeMovedFinalPath=[pathsOnSources objectAtIndex:i];
                // Move only if necessary.
                if([self _shouldProceedToMoveOrCopyFrom:toBeMovedOriginalPath
                                                     to:toBeMovedFinalPath
                                        forOriginalHash:hash
                                  destinationPathToHash:destination->_pathToHash]){
                    NSArray*movedArray=@[toBeMovedFinalPath,toBeMovedOriginalPath];
                    [delta.movedPaths addObject:movedArray];
                    [self _addPathOrOperation:movedArray
                                           to:delta.movedPaths];
                }
            }
            // Copy
            NSString*toBeCopiedOriginalPath=toBeMovedFinalPath;
            for (NSUInteger i=numberOfOccurenceToMove;i<nbOfOccurencesOnSource; i++) {
                NSString *toBeCopiedFinalPath=[pathsOnSources objectAtIndex:i];
                if([self _shouldProceedToMoveOrCopyFrom:toBeCopiedOriginalPath
                                                     to:toBeCopiedFinalPath
                                        forOriginalHash:hash
                                  destinationPathToHash:destination->_pathToHash]){
                    NSArray*copiedArray=@[toBeCopiedFinalPath,toBeCopiedOriginalPath];
                    [self _addPathOrOperation:copiedArray
                                           to:delta.copiedPaths];
                }
            }
        }
    }
    
    // #2# scan the source.
    // To Update and create paths.
    for (NSString *hash in source->_hashToPaths) {
        NSMutableArray*pathsOnDestination=[[destination->_hashToPaths objectForKey:hash] mutableCopy];
        NSMutableArray*pathsOnSources=[[source->_hashToPaths objectForKey:hash] mutableCopy];
        NSString*originalPath=[pathsOnSources objectAtIndex:0];
        
        if (pathsOnDestination && [pathsOnDestination count]>0) {
            BOOL hasBeenMoved=NO;
            for (NSString*path in pathsOnSources) {
                if(!hasBeenMoved){
                    // Move one
                    if([self _shouldProceedToMoveOrCopyFrom:originalPath
                                                         to:path
                                            forOriginalHash:hash
                                      destinationPathToHash:destination->_pathToHash]){
                        NSArray*movedArray=@[path,originalPath];
                        [self _addPathOrOperation:movedArray
                                               to:delta.movedPaths];
                    }
                    hasBeenMoved=YES;
                }else{
                    if([self _shouldProceedToMoveOrCopyFrom:originalPath
                                                         to:path
                                            forOriginalHash:hash
                                      destinationPathToHash:destination->_pathToHash]){
                        // Copy the others occurences.
                        NSArray*copiedArray=@[path,originalPath];
                        [self _addPathOrOperation:copiedArray
                                               to:delta.copiedPaths];
                    }
                }
            }
        }else{
            // Create.
            BOOL hasBeenProcessed=NO;
            for (NSString*path in pathsOnSources) {
                if(!hasBeenProcessed){
                    
                    // If the path exist on the destination an the source
                    // and the hash is different it is an Update
                    // Else it is a created path
                    if(![[destination->_pathToHash allKeys] containsObject:pathsOnSources]){
                        // update one
                        [self _addPathOrOperation:[path copy]
                                               to:delta.updatedPaths];
                    }else{
                        // create one
                        [self _addPathOrOperation:[path copy]
                                           to:delta.createdPaths];
                    }
                    hasBeenProcessed=YES;
                }else{
                    if([self _shouldProceedToMoveOrCopyFrom:originalPath
                                                         to:path
                                            forOriginalHash:hash
                                      destinationPathToHash:destination->_pathToHash]){
                        // Copy the others occurences.
                        NSArray*copiedArray=@[path,originalPath];
                        [self _addPathOrOperation:copiedArray
                                               to:delta.copiedPaths];
                    }
                }
            }
        }
    }
    return delta;
}

- (BOOL)_shouldProceedToMoveOrCopyFrom:(NSString*)originalPath
                                    to:(NSString*)finalPath
                       forOriginalHash:(NSString*)hash
                 destinationPathToHash:(NSMutableDictionary*)pathToHash{
    if([originalPath isEqualToString:finalPath]){
        // That's a neutral operation
        return NO;
    }

    if([[pathToHash objectForKey:finalPath] isEqualToString:hash]){
        // The hash on the destination is already Correct
        return NO;
    }
    return YES;
}


// Prevent from possible double entries.
- (BOOL)_addPathOrOperation:(NSObject*)op
                         to:(NSMutableArray*)container{
    BOOL __block shouldBeAdded=YES;
    [container enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([op isKindOfClass:[NSArray class]]) {
            // It is a move or a copy
            NSArray*pair=(NSArray*)op;
            NSArray*pair2=(NSArray*)obj;
            if([pair count]==2 && [pair2 count]==2){
                if([[pair objectAtIndex:0] isEqualToString:[pair2 objectAtIndex:0]]
                   && [[pair objectAtIndex:1] isEqualToString:[pair2 objectAtIndex:1]] ){
                    // This op already exists.
                    shouldBeAdded=NO;
                    *stop=YES;
                }else{
                    // Invalid op
                    shouldBeAdded=NO;
                    *stop=YES;
                }
            }
        }else if([op isKindOfClass:[NSString class]]){
            // It is a simple path to be created, deleted or updated
            if([(NSString*)obj isEqualToString:(NSString *)op]){
                // This path already exists
                shouldBeAdded=NO;
                *stop=YES;
            }
        }
    }];
    if(shouldBeAdded) {
        // Add the path or operation
        [container addObject:op];
    }else{
        NSLog(@"***");
    }
    return shouldBeAdded;
}


/**
 *  Returns the number of paths in hash path
 *
 *  @return the count;
 */
- (NSUInteger)count{
    return [_hashToPaths count];
}

@end