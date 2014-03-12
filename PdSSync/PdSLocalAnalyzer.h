//
//  PdSSynchronizer.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 26/11/2013.
//  Copyright (c) 2013 Pereira da Silva. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PdSSync.h"




@interface PdSLocalAnalyzer : NSObject


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
                                dataBlock:(NSData* (^)(NSString*path, NSUInteger index))dataBlock
                        progressBlock:(void(^)(uint32_t crc32,NSString*path, NSUInteger index))progressBlock
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
