//
//  PdSSynchronizer.m
//  PdSSyncCL
//
//  Created by Benoit Pereira da Silva on 26/11/2013.
//  Copyright (c) 2013 Pereira da Silva. All rights reserved.
//

#import "PdSLocalAnalyzer.h"
#import "NSData+CRC.h"

@interface PdSLocalAnalyzer(){
#if TARGET_OS_IPHONE
    NSString *_applicationDocumentsDirectory;
#endif
}
@property (nonatomic,weak)NSFileManager*fileManager;
@end


@implementation PdSLocalAnalyzer


/*
typedef NS_ENUM (NSUInteger,
                 PdSSyncMode) {
    MasterIsLocalSlaveIsDistant   = 0 ,
    MasterIsDistantSlaveIsLocal   = 1 ,
    MasterIsLocalSlaveIsLocal     = 2 ,
    MasterIsDistantSlaveIsDistant = 3 // Currently not supported ?
    
} ;
*/


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
                            andCompletionBlock:(void(^)(HashMap*hashMap))completionBlock{
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
                    NSData *data=nil;
                    if (dataBlock) {
                        data=dataBlock(fp,i);
                    }else{
                        data=[NSData dataWithContentsOfFile:fp];
                    }
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

