//
//  PdSAnalyzer.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 26/11/2013.
//  Copyright (c) 2013 Pereira da Silva. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _PdSSyncOperation {
    PdSCopy      = 0,
    PdSMove      = 1,
    PdSDelete    = 2
} PdSSyncOperation;

typedef enum _PdSSyncOperationParams {
    PdSSource      = 0,
    PdSDestination = 1
} PdSSyncOperationParams;

@interface PdSAnalyzer : NSObject

@property (nonatomic,readonly)NSURL*masterURL;
@property (nonatomic,readonly)NSURL*slaveURL;

/**
 *  Dedicated initializer.
 *
 *  @param masterURL the master URL
 *  @param slaveURL  the slave URL
 *
 *  @return the instance.
 */
- (instancetype)initWithMasterURL:(NSURL*)masterURL andSlaveURL:(NSURL*)slaveURL;

/**
 *  Creates a dictionary with  relative paths as key and  CRC32 as value
 *
 *  @param url   the
 *  @param progressBlock the progress block
 *  @param completionBlock the completion block.
 */
- (void)createFileDescriptorFromFolderURL:(NSURL*)folderURL
                        withProgressBlock:(void(^)(uint32_t crc32,NSString*relativePath, NSUInteger index))progressBlock
              andCompletionBlock:(void(^)(NSMutableDictionary*treeDictionary))completionBlock;


/**
 *  Compute the delta and generates an operation descriptor
 *
 *  @param completionBlock the completion block
 */
- (void)computeDeltaWithCompletionBlock:(void(^)(NSMutableDictionary*operationDictionary))completionBlock;


@end
