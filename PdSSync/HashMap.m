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
        // NB : this section could be refined a little bit by preserving already valid path.
        // But this optimization will only reduce move commands that are generally not intensive on local operation.
        NSMutableArray*pathsOnDestination=[[destination->_hashToPaths objectForKey:hash] mutableCopy];
        NSMutableArray*pathsOnSources=[[source->_hashToPaths objectForKey:hash] mutableCopy];
        
        NSUInteger nbOfOccurencesOnDestination=[pathsOnDestination count];
        NSUInteger nbOfOccurencesOnSource=[pathsOnSources count];
        
        if(nbOfOccurencesOnSource==0){
            // We gonna delete all the files.
            for (NSString*toBeDeletedPath in pathsOnDestination) {
                [delta.deletedPaths addObject:[toBeDeletedPath copy]];
            }
        }else if(nbOfOccurencesOnSource<nbOfOccurencesOnDestination){
            // There are more occurences on destination than on source.
            // We gonna delete some files
            NSUInteger numberOfOccurenceToDelete=(nbOfOccurencesOnDestination-nbOfOccurencesOnSource);
            for (NSUInteger i=0; i<numberOfOccurenceToDelete; i++) {
                NSString *toBeDeletedPath=[pathsOnDestination objectAtIndex:i];
                [delta.deletedPaths addObject:[toBeDeletedPath copy]];
            }
            // Then move the preserved files to remap.
            NSUInteger indexInSource=0;
            for (NSUInteger i=numberOfOccurenceToDelete;i<nbOfOccurencesOnDestination; i++) {
                NSString *toBeMovedOriginalPath=[pathsOnDestination objectAtIndex:i];
                NSString *toBeMovedFinalPath=[pathsOnSources objectAtIndex:indexInSource];
                // Move only if necessary.
                if(![toBeMovedFinalPath isEqualToString:toBeMovedFinalPath]){
                    NSArray*movedArray=@[toBeMovedFinalPath,toBeMovedOriginalPath];
                    [delta.movedPaths addObject:movedArray];
                }
                indexInSource++;
            }
        }else if(nbOfOccurencesOnSource>nbOfOccurencesOnDestination){
            // There are more occurences on source than on destination.
            // We move some files then copy the others.
            
            // Move
            NSUInteger numberOfOccurenceToMove=nbOfOccurencesOnDestination;
            NSString*toBeMovedFinalPath=nil;
            for (NSUInteger i=0;i<numberOfOccurenceToMove; i++) {
                NSString *toBeMovedOriginalPath=[pathsOnDestination objectAtIndex:i];
                toBeMovedFinalPath=[pathsOnSources objectAtIndex:i];
                // Move only if necessary.
                if(![toBeMovedFinalPath isEqualToString:toBeMovedFinalPath]){
                    NSArray*movedArray=@[toBeMovedFinalPath,toBeMovedOriginalPath];
                    [delta.movedPaths addObject:movedArray];
                }
            }
            // Copy
            NSString*toBeCopiedOriginalPath=toBeMovedFinalPath;
            for (NSUInteger i=numberOfOccurenceToMove;i<nbOfOccurencesOnSource; i++) {
                NSString *toBeCopiedFinalPath=[pathsOnSources objectAtIndex:i];
                if(![toBeCopiedFinalPath isEqualToString:toBeCopiedOriginalPath]){
                    NSArray*copiedArray=@[toBeCopiedFinalPath,toBeCopiedOriginalPath];
                    [delta.copiedPaths addObject:copiedArray];
                }
            }
        }
    }
    
    // #2# scan the source.
    // To Update and create paths.
    for (NSString *hash in source->_hashToPaths) {
        NSMutableArray*pathsOnDestination=[[destination->_hashToPaths objectForKey:hash] mutableCopy];
        NSMutableArray*pathsOnSources=[[source->_hashToPaths objectForKey:hash] mutableCopy];
        NSString*toBeCopiedOriginalPath=[pathsOnSources objectAtIndex:0];
        if (pathsOnDestination && [pathsOnDestination count]>0) {
            // Update?
            BOOL hasBeenUpdated=NO;
            for (NSString*path in pathsOnSources) {
                NSString*destinationHash=[destination->_pathToHash objectForKey:path];
                if(![destinationHash isEqualToString:hash]){
                    if(!hasBeenUpdated){
                        // update one
                        [delta.updatedPaths addObject:[path copy]];
                        hasBeenUpdated=YES;
                    }else{
                        // Copy the others occurences.
                        NSArray*copiedArray=@[path,toBeCopiedOriginalPath];
                        [delta.copiedPaths addObject:copiedArray];
                    }
                }
            }
        }else{
            // Create.
            BOOL hasBeenCreated=NO;
            for (NSString*path in pathsOnSources) {
                if(!hasBeenCreated){
                    // update one
                    [delta.createdPaths addObject:[path copy]];
                    hasBeenCreated=YES;
                }else{
                    // Copy the others occurences.
                    NSArray*copiedArray=@[path,toBeCopiedOriginalPath];
                    [delta.copiedPaths addObject:copiedArray];
                    
                }
            }
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
    return [_hashToPaths count];
}

@end