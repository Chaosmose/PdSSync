//
//  PdSSyncAdmin.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 12/11/2014.
//
//

#import "PdSSyncAdmin.h"

@implementation PdSSyncAdmin

/**
 *  Initialize the admin facade with a contzext
 *
 *  @param context the context
 *
 *  @return the admin instance
 */
- (instancetype)initWithContext:(PdSSyncContext*)context{
    self=[super init];
    if(self){
        self->_syncContext=context;
    }
    return self;
}

/**
 *  Proceed to installation of the Repository
 *
 *  @param context the context
 *  @param block   the completion block
 */
- (void)installWithCompletionBlock:(void (^)(BOOL success, NSInteger statusCode))block{
    
}

/**
 *  Creates a tree
 *
 *  @param identifier with the given identifier
 *  @param block      the completion block
 */
- (void)createTreeWithId:(NSString*)identifier
     withCompletionBlock:(void (^)(BOOL success, NSInteger statusCode))block{
    
}

/**
 *  Touches the tree (changes the public ID )
 *
 *  @param identifier the tree to be touched
 *  @param block      the completion block
 */
- (void)touchTreeWithId:(NSString*)identifier
    withCompletionBlock:(void (^)(BOOL success, NSInteger statusCode))block{
    
    
}

/**
 *  Returns the source and destination hashMaps for a given tree
 *
 *  @param identifier the tree identifier
 *  @param block      the result block
 */
-(void)hashMapsForTreeWithId:(NSString*)identifier
         withCompletionBlock:(void (^)(HashMap*sourceHashMap,HashMap*destinationHashMap,NSInteger statusCode))block{
    
}


/**
 *  Synchronizes the source to the destination
 *
 *  @param progressBlock   the progress block
 *  @param completionBlock the completionBlock
 */
-(void)synchronizeWithprogressBlock:(void(^)(uint taskIndex,float progress))progressBlock
                 andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock{
    
}




@end
