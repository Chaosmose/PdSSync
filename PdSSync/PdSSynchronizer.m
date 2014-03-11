//
//  PdSSynchronizer.m
//  PdSSyncCL
//
//  Created by Benoit Pereira da Silva on 26/11/2013.
//  Copyright (c) 2013 Pereira da Silva. All rights reserved.
//

#import "PdSSynchronizer.h"
#import "NSData+CRC.h"

@interface PdSSynchronizer(){
#if TARGET_OS_IPHONE
    NSString *_applicationDocumentsDirectory;
#endif
}
@property (nonatomic,weak)NSFileManager*fileManager;
@end


@implementation PdSSynchronizer

@synthesize masterURL = _masterURL;
@synthesize slaveURL = _slaveURL;


/**
 *  Dedicated initializer.
 *
 *  @param masterURL the master URL
 *  @param slaveURL  the slave URL
 *
 *  @return the instance.
 */
- (instancetype)initWithMasterURL:(NSURL*)masterURL andSlaveURL:(NSURL*)slaveURL{
    self=[super init];
    if (self){
        self->_masterURL=masterURL;
        self->_slaveURL=slaveURL;
        self->_fileManager=[NSFileManager defaultManager];
    }
    return self;
}

/**
 *  Creates a dictionary with MD5 keys and relative paths
 *
 *  @param url   the
 *  @param progressBlock the progress block
 *  @param completionBlock the completion block.
 */
- (void)createFileDescriptorFromFolderURL:(NSURL*)folderURL
                        withProgressBlock:(void(^)(uint32_t crc32,NSString*relativePath, NSUInteger index))progressBlock
                       andCompletionBlock:(void(^)(NSMutableDictionary*treeDictionary))completionBlock{
    // Local
    BOOL exists=[_fileManager fileExistsAtPath:folderURL.absoluteString];
    NSArray*exclusion=@[@".DS_Store"];
    if (exists){
        NSMutableDictionary*treeDictionary=[NSMutableDictionary dictionary];
        NSDirectoryEnumerator *dirEnum =[_fileManager enumeratorAtPath:folderURL.absoluteString];
        NSString *file;
        int i=0;
        while ((file = [dirEnum nextObject])) {
            if([exclusion indexOfObject:[file lastPathComponent]]==NSNotFound){
                NSString *fp=[folderURL.absoluteString stringByAppendingFormat:@"/%@",file];
                @autoreleasepool {
                    NSData *data=[NSData dataWithContentsOfFile:fp];
                    uint32_t crc32=[data crc32];
                    if(crc32!=0){// 0 for folders
                        NSString *relativePath=file;
                        progressBlock(crc32,relativePath,i);
                        [treeDictionary setObject:[NSString stringWithFormat:@"%i",crc32] forKey:relativePath];
                        i++;
                    }
                    
                }
            }
            
        }
        completionBlock(treeDictionary);
    }else{
        NSLog(@"%@ is not a file reference",folderURL);
        completionBlock(nil);
    }
}




#pragma mark - IOS Only
#if TARGET_OS_IPHONE


- (NSString *) applicationDocumentsDirectory{
    if(!_applicationDocumentsDirectory){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        _applicationDocumentsDirectory=[basePath stringByAppendingString:@"/"];
    }
    return _applicationDocumentsDirectory;
}


#endif

#pragma mark - private

- (NSMutableDictionary*)_deltaOperationsMaster:(NSMutableDictionary*)masterDescriptor
                                       toSlave:(NSMutableDictionary*)slaveDescriptor{
    NSMutableDictionary *deltaOperations=[NSMutableDictionary dictionary];
    return deltaOperations;
}

-(BOOL)_createRecursivelyRequiredFolderForPath:(NSString*)path{
#if TARGET_OS_IPHONE
    if([path rangeOfString:[self applicationDocumentsDirectory]].location==NSNotFound){
        return NO;
    }
#endif
    if(![[path substringFromIndex:path.length-1] isEqualToString:@"/"])
        path=[path stringByDeletingLastPathComponent];
    
    if(![self.fileManager fileExistsAtPath:path]){
        NSError *error=nil;
        [self.fileManager createDirectoryAtPath:path
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error];
        if(error){
            return NO;
        }
    }
    return YES;
}



-(uint32_t)crc32FromData:(NSData *)data{
    return [data crc32];
}

- (uint32_t)crc32FromDictionary:(NSDictionary*)dictionary{
    NSMutableData *data = [[NSMutableData alloc]init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:dictionary forKey:@"k"];
    [archiver finishEncoding];
    return [data crc32];
}


@end

