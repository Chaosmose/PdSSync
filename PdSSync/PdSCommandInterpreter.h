//
//  PdSCommandInterpreter.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 11/03/2014.
//
//

#import <Foundation/Foundation.h>
#import "PdSSync.h"

@interface PdSCommandInterpreter : NSObject


/**
 *  The source url
 */
@property( nonatomic,readonly)NSURL*sourceUrl;

/**
 *  The destination url
 */
@property (nonatomic,readonly)NSURL*destinationUrl;


/**
 *  The optionnal tree id
 */
@property (nonatomic,readonly) NSString*treeId;


/**
 *  The current bunch of command.
 */
@property (nonatomic,readonly)NSArray*bunchOfCommand;


/**
 *  The final hashmap
 */
@property (nonatomic,readonly) HashMap*finalHashMap;


/**
 *  The synchronization mode
 */
@property (nonatomic,readonly)PdSSyncMode*syncMode;


/**
 *  The progress counter in percent.
 * ( Total command number / executed command ) + proportionnal progress on the current command
 */
@property (nonatomic,readonly)NSUInteger*progressCounter;



/**
 *  The dedicated initializer.
 *
 *  @param sourceUrl      the source url
 *  @param destinationUrl       the destination - url
 *  @param treeId         the optionnal tree id
 *  @param bunchOfCommand the bunch of command
 *  @param finalHashMap   the final hash map 
 *  @param completionBlock the completion block
 *  @return the instance.
 */
- (instancetype)initWithSourceUrl:(NSURL*)sourceUrl
                         destinationUrl:(NSURL*)destinationUrl
                           treeId:(NSString*)treeId
                        bunchOfCommand:(NSArray*)bunchOfCommand
                     finalHashMap:(HashMap*)finalHashMap
               andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock;


@end
