//
//  DeltaHashMap.m
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//

#import "DeltaPathMap.h"

static NSString*createdPathsKey=@"createdPaths";
static NSString*deletedPathsKey=@"deletedPaths";
static NSString*updatedPathsKey=@"updatedPaths";

@implementation DeltaPathMap

/**
 *  Returns a new instance of a deltaHashMap;
 *
 *  @return a deltaHashMap instance
 */
+(DeltaPathMap*)deltaHasMap{
    DeltaPathMap*instance=[[DeltaPathMap alloc]init];
    instance.createdPaths=[NSMutableArray array];
    instance.updatedPaths=[NSMutableArray array];
    instance.deletedPaths=[NSMutableArray array];
    return instance;
}




/**
 *  Returns a dictionary representation of the DeltaPathMap
 *
 *  @return the dictionary
 */
- (NSDictionary*)dictionaryRepresentation{
    NSMutableDictionary*dictionary=[NSMutableDictionary dictionary];
    [dictionary setObject:[[self createdPaths] copy] forKey:createdPathsKey];
    [dictionary setObject:[[self updatedPaths] copy] forKey:deletedPathsKey];
    [dictionary setObject:[[self deletedPaths] copy] forKey:updatedPathsKey];
    return dictionary;
}





@end
