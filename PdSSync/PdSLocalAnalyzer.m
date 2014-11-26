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
 *  @param dataBlock if you define this block it will be used to extract the data from the file
 *  @param progressBlock the progress block
 *  @param completionBlock the completion block.
 *
 */
- (void)createHashMapFromLocalFolderURL:(NSURL*)folderURL
                              dataBlock:(NSData* (^)(NSString*path, NSUInteger index))dataBlock
                          progressBlock:(void(^)(NSUInteger hash,NSString*path, NSUInteger index))progressBlock
                     andCompletionBlock:(void(^)(HashMap*hashMap))completionBlock{
    
    NSString *folderPath=[folderURL path];
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
        NSString *pathExtension=file.pathExtension;
        if([exclusion indexOfObject:[file lastPathComponent]]==NSNotFound && ![pathExtension isEqualToString:kPdSSyncHashFileExtension]){
            @autoreleasepool {
                NSData *data=nil;
                NSString*hashfile=[filePath stringByAppendingFormat:@".%@",kPdSSyncHashFileExtension];
                NSString *relativePath=[filePath stringByReplacingOccurrencesOfString:[folderPath stringByAppendingString:@"/"] withString:@""];
                // we check if there is a file.extension.kPdSSyncHashFileExtension
                if(!self.recomputeHash && [fileManager fileExistsAtPath:hashfile] ){
                    NSError*crc32ReadingError=nil;
                    NSString*crc32String=[NSString stringWithContentsOfFile:filePath
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:&crc32ReadingError];
                    if(!crc32ReadingError){
                        long long crc32=[crc32String longLongValue];
                        progressBlock((unsigned int)crc32,relativePath,i);
                    }else{
                        NSLog(@"ERROR when reading crc32 from %@ %@",filePath,[crc32ReadingError localizedDescription]);
                    }
                }else{
                    if (dataBlock) {
                        data=dataBlock(filePath,i);
                    }else{
                        data=[NSData dataWithContentsOfFile:filePath];
                    }
                }
                unsigned long crc32=(unsigned long)[data crc32];
                if(crc32!=0){// 0 for folders
                    progressBlock(crc32,relativePath,i);
                    [hashMap setHash:[NSString stringWithFormat:@"%lu",(unsigned long)crc32] forPath:relativePath];
                    [treeDictionary setObject:[NSString stringWithFormat:@"%lu",(unsigned long)crc32] forKey:relativePath];
                    i++;
                    if(self.saveHashInAFile){
                        [self _writeCrc32:crc32 toFileWithPath:filePath];
                    }
                }
            }
        }
        
        if(!self.saveHashInAFile && [pathExtension isEqualToString:kPdSSyncHashFileExtension]){
            NSError*removeFile=nil;
            [fileManager removeItemAtPath:filePath error:&removeFile];
        }
    }
    
    // We gonna create the hashmap folder
    NSString*hashMapFileP=[[folderURL absoluteString] stringByAppendingFormat:@"%@%@.%@",kPdSSyncMetadataFolder,kPdSSyncHashMashMapFileName,kPdSSyncHashFileExtension];
    [fileManager createRecursivelyRequiredFolderForPath:hashMapFileP];
    
    // Let s write the serialized HashMap file
    NSDictionary*dictionaryHashMap=[hashMap dictionaryRepresentation];
    NSString*json=[self _encodetoJson:dictionaryHashMap];
    NSError*error;
    hashMapFileP=[hashMapFileP stringByReplacingOccurrencesOfString:@"file:///" withString:@"/"];
    [json writeToFile:hashMapFileP
           atomically:YES
             encoding:NSUTF8StringEncoding
                error:&error];
    if(error){
        NSLog(@"ERROR when writing hashmap to %@ %@", [error description],hashMapFileP);
        
    }
    completionBlock(hashMap);
}



#pragma mark - private


- (BOOL)_writeCrc32:(unsigned long)crc32 toFileWithPath:(NSString*)path{
    NSError *crc32WritingError=nil;
    NSString *crc32Path=[path stringByAppendingFormat:@".%@",kPdSSyncHashFileExtension];
    NSString *crc32String=[NSString stringWithFormat:@"%lu",crc32];
    
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


- (NSString*)_encodetoJson:(id)object{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData) {
        return [error localizedDescription];
    } else {
        return [[NSString alloc]initWithBytes:[jsonData bytes]
                                       length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
}





@end

