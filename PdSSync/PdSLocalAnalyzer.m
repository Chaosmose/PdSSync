//
//  PdSSynchronizer.m
//  PdSSyncCL
//
//  Created by Benoit Pereira da Silva on 26/11/2013.
//  Copyright (c) 2013 Pereira da Silva. All rights reserved.
//

#import "PdSLocalAnalyzer.h"


@interface PdSLocalAnalyzer(){
}
@end


@implementation PdSLocalAnalyzer

-(id)init{
    self=[super init];
    if(self){
        self.recomputeHash=NO;
        self.saveHashInAFile=YES;
    }
    return self;
}



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
- (void)createHashMapFromLocalFolderURL:(NSURL*)folderURL
                              dataBlock:(NSData* (^)(NSString*path, NSUInteger index))dataBlock
                          progressBlock:(void(^)(uint32_t crc32,NSString*path, NSUInteger index))progressBlock
                     andCompletionBlock:(void(^)(HashMap*hashMap))completionBlock{
    
    PdSFileManager*fileManager=[PdSFileManager sharedInstance] ;
    // Local
    NSArray*exclusion=@[@".DS_Store"];
    NSMutableDictionary*treeDictionary=[NSMutableDictionary dictionary];
    NSArray *keys = [NSArray arrayWithObject:NSURLIsDirectoryKey];
    NSDirectoryEnumerator *dirEnum =[fileManager enumeratorAtURL:folderURL
                                       includingPropertiesForKeys:keys
                                                          options:0
                                                     errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                         NSLog(@"ERROR when enumerating  %@ %@",url, [error localizedDescription]);
                                                         return YES;
                                                     }];

    HashMap*hashMap=[[HashMap alloc]init];
    
    NSURL *file;
    int i=0;
    while ((file = [dirEnum nextObject])) {
        NSString *filePath=[NSString filteredFilePathFrom:[file absoluteString]];
        if([exclusion indexOfObject:[file lastPathComponent]]==NSNotFound || [file.pathExtension isEqualToString:kPdSSyncHashFileExtension]){
            @autoreleasepool {
                NSData *data=nil;
                NSString*hashfile=[filePath stringByAppendingString:kPdSSyncHashFileExtension];
                // we check if there is a file.extension.kPdSSyncHashFileExtension
                if(!self.recomputeHash && [fileManager fileExistsAtPath:hashfile] ){
                    NSError*crc32ReadingError=nil;
                    NSString*crc32String=[NSString stringWithContentsOfFile:filePath
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:&crc32ReadingError];
                    if(!crc32ReadingError){
                        uint32_t crc32=[crc32String integerValue];
                        NSString *relativePath=file;
                        progressBlock(crc32,relativePath,i);
                        
                    }else{
                        NSLog(@"ERROR when reading crc32 from %@ %@",filePath,[crc32ReadingError localizedDescription]);
                    }
                }else{
                    if (dataBlock) {
                        data=dataBlock(file,i);
                    }else{
                        data=[NSData dataWithContentsOfFile:filePath];
                    }
                }
                uint32_t crc32=[data crc32];
                if(crc32!=0){// 0 for folders
                    NSString *relativePath=filePath;
#warning relative PATH 
                    
                    progressBlock(crc32,relativePath,i);
                    [hashMap setHash:[NSString stringWithFormat:@"%i",crc32] forPath:relativePath ];
                    [treeDictionary setObject:[NSString stringWithFormat:@"%i",crc32] forKey:relativePath];
                    i++;
                    if(self.saveHashInAFile ){
                        [self _writeCrc32:crc32 toFileWithPath:hashfile];
                    }
                }
                
                
                
            }
        }
        
    }
    completionBlock(hashMap);
    
}



#pragma mark - private


- (BOOL)_writeCrc32:(uint32_t)crc32 toFileWithPath:(NSString*)path{
    NSError *crc32WritingError=nil;
    NSString *crc32Path=[path stringByAppendingString:kPdSSyncHashFileExtension];
    NSString *crc32String=[NSString stringWithFormat:@"%@",@(crc32)];
    
    [crc32String writeToFile:crc32Path
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:&crc32WritingError];
    if(crc32WritingError){
        return NO;
    }else{
        return YES;
    }
}






@end

