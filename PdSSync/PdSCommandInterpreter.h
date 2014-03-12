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
 *  The master url
 */
@property( nonatomic,readonly)NSURL*masterUrl;

/**
 *  The slave url
 */
@property (nonatomic,readonly)NSURL*slaveUrl;


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
 *  @param masterUrl      the master url
 *  @param slaveUrl       the slave url
 *  @param treeId         the optionnal tree id
 *  @param bunchOfCommand the bunch of command
 *  @param finalHashMap   the final hash map 
 *  @param completionBlock the completion block
 *  @return the instance.
 */
- (instancetype)initWithMasterUrl:(NSURL*)masterUrl
                         slaveUrl:(NSURL*)slaveUrl
                           treeId:(NSString*)treeId
                        bunchOfCommand:(NSArray*)bunchOfCommand
                     finalHashMap:(HashMap*)finalHashMap
               andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock;


@end
