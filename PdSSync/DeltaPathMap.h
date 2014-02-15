//
//  DeltaHashMap.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//

#import <Foundation/Foundation.h>

extern NSString*createdPathsKey;
extern NSString*deletedPathsKey;
extern NSString*updatedPathsKey;

@interface DeltaPathMap : NSObject


@property (strong,nonatomic)NSMutableArray*similarPaths;
@property (strong,nonatomic)NSMutableArray*createdPaths;
@property (strong,nonatomic)NSMutableArray*deletedPaths;
@property (strong,nonatomic)NSMutableArray*updatedPaths;

/**
 *  Returns a new instance of a deltaHashMap;
 *
 *  @return a deltaHashMap instance
 */
+(DeltaPathMap*)deltaHasMap;

/**
 *  Returns a dictionary representation of the DeltaPathMap
 *
 *  @return the dictionary
 */
- (NSDictionary*)dictionaryRepresentation;


@end
