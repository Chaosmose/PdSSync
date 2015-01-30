//
//  PdSSyncAdmin.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 12/11/2014.
//
//

#import <Foundation/Foundation.h>
#import "PdSSync.h"

@class PdSSyncContext;
@protocol PdSSyncFinalizationDelegate;

typedef NS_ENUM(NSInteger,
                PdSSyncExtentedStatusError) {
    PdSStatusErrorHashMapDeserializationTypeMissMatch=1000
} ;


/**
 *  Administration interface.
 */
@interface PdSSyncAdmin : NSObject

/**
 *
 */
@property (nonatomic,readonly)PdSSyncContext*syncContext;

@property (nonatomic)id<PdSSyncFinalizationDelegate>finalizationDelegate;


/**
 *  Initialize the admin facade with a contzext
 *
 *  @param context the context
 *
 *  @return the admin instance
 */
- (instancetype)initWithContext:(PdSSyncContext*)context;



#pragma mark - Synchronization

/**
 *  Synchronizes the source to the destination
 *
 *  @param progressBlock   the progress block
 *  @param completionBlock the completionBlock
 */
-(void)synchronizeWithprogressBlock:(void(^)(uint taskIndex,float progress,NSString*message))progressBlock
                 andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock;



#pragma mark - Advanced actions

/**
 *  Proceed to installation of the Repository
 *
 *  @param context the context
 *  @param block   the completion block
 */
- (void)installWithCompletionBlock:(void (^)(BOOL success, NSInteger statusCode))block;

/**
 *  Creates a tree
 *  @param block      the completion block
 */
- (void)createTreesWithCompletionBlock:(void (^)(BOOL success, NSInteger statusCode))block;

/**
 *  Touches the trees (changes the public ID )
 *
 *  @param block      the completion block
 */
- (void)touchTreesWithCompletionBlock:(void (^)(BOOL success, NSInteger statusCode))block;

/**
 *  Returns the source and destination hashMaps for a given tree
 *
 *  @param block      the result block 
 */
-(void)hashMapsForTreesWithCompletionBlock:(void (^)(HashMap*sourceHashMap,HashMap*destinationHashMap,NSInteger statusCode))block;





@end
