//
//  PdSSynchronizer.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 26/11/2013.
//  Copyright (c) 2013 Pereira da Silva. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HashMap.h"
#import "DeltaPathMap.h"

typedef NS_ENUM (NSUInteger,
                 PdSSyncMode) {
    MasterIsLocalSlaveIsDistant   = 0 ,
    MasterIsDistantSlaveIsLocal   = 1 ,
    MasterIsLocalSlaveIsLocal     = 2 ,
    MasterIsDistantSlaveIsDistant = 3 // Currently not supported ?

} ;


@interface PdSSynchronizer : NSObject

@property (nonatomic,readonly)NSURL*masterURL;
@property (nonatomic,readonly)NSURL*slaveURL;
@property (nonatomic,readonly)PdSSyncMode mode;

/**
 *  Dedicated initializer.
 *
 *  @param masterURL the master URL
 *
 *  @param slaveURL  the slave URL
 *
 *  @return the instance.
 */
- (instancetype)initWithMasterURL:(NSURL*)masterURL andSlaveURL:(NSURL*)slaveURL;

/**
 *  Creates a dictionary with  relative paths as key and  CRC32 as value
 *
 *  @param url the folder url
 *
 *  @param dataBlock if you define this block it will be used to extract the data from the file
 *
 *  @param progressBlock the progress block
 *
 *  @param completionBlock the completion block.
 *
 */
- (void)createFileDescriptorFromLocalFolderURL:(NSURL*)folderURL
                                dataBlock:(NSData* (^)(NSString*relativePath, NSUInteger index))dataBlock
                        progressBlock:(void(^)(uint32_t crc32,NSString*relativePath, NSUInteger index))progressBlock
              andCompletionBlock:(void(^)(HashMap*hashMap))completionBlock;



/**
 *  Computes a crc32 from NSData
 *
 *  @param data the data
 *
 *  @return the hash
 */
- (uint32_t)crc32FromData:(NSData*)data;

/**
 *  Computes a crc32 from a NSDictionary
 *
 *  @param data the data
 *
 *  @return the hash
 */
- (uint32_t)crc32FromDictionary:(NSDictionary*)dictionary;



@end
