//
//  DeltaPathMap.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//

#import <Foundation/Foundation.h>

extern NSString* const createdPathsKey;
extern NSString* const deletedPathsKey;
extern NSString* const updatedPathsKey;

@interface DeltaPathMap : NSObject


@property (strong,nonatomic)NSMutableArray*createdPaths;
@property (strong,nonatomic)NSMutableArray*deletedPaths;
@property (strong,nonatomic)NSMutableArray*updatedPaths;

/**
 *  Returns a new instance of a deltaHashMap;
 *
 *  @return a DeltaPathMap instance
 */
+(DeltaPathMap*)instance;

/**
 *  Returns a dictionary representation of the DeltaPathMap
 *
 *  @return the dictionary
 */
- (NSDictionary*)dictionaryRepresentation;

@end