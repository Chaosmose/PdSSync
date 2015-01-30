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
 *  Default is NO
 *  If set to NO the dataBlock or the standard hash method will be ignored.
 */
@property (nonatomic)BOOL recomputeHash;

/**
 * Default is YES
 * When the hash is computed it is save to file.extension.kPdSSyncHashFileExtension
 * Else any file file with kPdSSyncHashFileExtension will be removed.
 */
@property (nonatomic)BOOL saveHashInAFile;



/**
 *  Creates a dictionary with  relative paths as key and  CRC32 as value
 *
 *  @param url the folder ur
 *  @param dataBlock if you define this block it will be used to extract the data from the file
 *  @param progressBlock the progress block
 *  @param completionBlock the completion block.
 *
 */
- (void)createHashMapFromLocalFolderURL:(NSURL*)folderURL
                                dataBlock:(NSData* (^)(NSString*path, NSUInteger index))dataBlock
                        progressBlock:(void(^)(NSUInteger hash,NSString*path, NSUInteger index))progressBlock
              andCompletionBlock:(void(^)(HashMap*hashMap))completionBlock;

@end