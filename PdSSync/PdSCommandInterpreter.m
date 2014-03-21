//
//  PdSCommandInterpreter.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 11/03/2014.
//
//

// Current implementation relies on http://cocoadocs.org/docsets/AFNetworking/2.2.0/

#import "AFNetworking.h"
#import "JSONResponseSerializerWithData.h"
#import "PdSCommandInterpreter.h"


typedef void(^CompletionBlock_type)(BOOL success,NSString*message);

@interface PdSCommandInterpreter (){
    CompletionBlock_type             _completionBlock;
    NSFileManager                   *_fileManager;
    AFHTTPSessionManager            *_HTTPsessionManager;
    
    NSProgress*__autoreleasing * _unitaryCommandProgress;
    
}
@property (nonatomic,strong)NSOperationQueue *queue;
@end

@implementation PdSCommandInterpreter

@synthesize bunchOfCommand  = _bunchOfCommand;
@synthesize context         = _context;

/**
 *   The dedicated initializer.
 *
 *  @param bunchOfCommand  the bunch of command
 *  @param context         the interpreter context
 *  @param completionBlock te completion block
 *
 *  @return the interpreter
 */
- (instancetype)initWithBunchOfCommand:(NSArray*)bunchOfCommand
                               context:(PdSSyncContext*)context
                    andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock{
    if(self){
        self->_bunchOfCommand=[bunchOfCommand copy];
        self->_context=context;
        self->_completionBlock=[completionBlock copy];
        self->_fileManager=[NSFileManager alloc];
        [self->_fileManager setDelegate:self];
        if(self->_context.mode==SourceIsDistantDestinationIsDistant ){
            [NSException raise:@"TemporaryException" format:@"SourceIsDistantDestinationIsDistant is currently not supported"];
        }
        if(self->_context.mode==SourceIsLocalDestinationIsLocal ){
            [NSException raise:@"TemporaryException" format:@"SourceIsLocalDestinationIsLocal is currently not supported"];
        }
        if([context isValid] && _bunchOfCommand){
            self->_queue=[[NSOperationQueue alloc] init];
            _queue.name=[NSString stringWithFormat:@"com.pereira-da-silva.PdSSync.CommandInterpreter.%i",[self hash]];
            [_queue setMaxConcurrentOperationCount:1];// Sequential
            [self _setUpManager];
            [self _run];
            
        }else{
            if(self->_completionBlock){
                _completionBlock(NO,@"sourceUrl && destinationUrl && bunchOfCommand && finalHashMap are required");
            }
        }
    }
    return self;
}


+(id)encodeCreateOrUpdate:(NSString*)destination{
    if(destination){
        return [NSString stringWithFormat:@"[%i,\"%@\"]", PdSCreateOrUpdate,destination];
    }
    return nil;
}

+(id)encodeCopy:(NSString*)source destination:(NSString*)destination{
    if(source && destination){
        return [NSString stringWithFormat:@"[%i,\"%@\",\"%@\"]", PdSCopy,destination,source];
    }else{
        return nil;
    }
}

+(id)encodeMove:(NSString*)source destination:(NSString*)destination{
    if(source && destination){
        return [NSString stringWithFormat:@"[%i,\"%@\",\"%@\"]", PdSMove,destination,source];
    }else{
        return nil;
    }
}

+(id)encodeRemove:(NSString*)destination{
    if(destination){
        return [NSString stringWithFormat:@"[%i,\"%@\"]", PdSDelete,destination];
    }else{
        return nil;
    }
}

+(id)encodeSanitize:(NSString*)destination{
    if(destination){
        return [NSString stringWithFormat:@"[%i,\"%@\"]", PdsSanitize,destination];
    }else{
        return nil;
    }
}

+(id)encodeChmode:(NSString*)destination mode:(int)mode{
    if(destination && (0<=mode && mode<777)){
        return [NSString stringWithFormat:@"[%i,\"%@\",\"%i\"]", PdSChmod,destination,mode];
    }else{
        return nil;
    }
}

+(id)encodeForget:(NSString*)destination{
    if(destination){
        return [NSString stringWithFormat:@"[%i,\"%@\"]", PdSForget,destination];
    }else{
        return nil;
    }
}


#pragma mark - private methods

- (void)_run{
    if([_bunchOfCommand count]>0){
        PdSCommandInterpreter * __weak weakSelf=self;
        NSMutableArray*creativeCommands=[NSMutableArray array];
        NSMutableArray*unCreativeCommands=[NSMutableArray array];
        // First pass we dicriminate creative for un creative commands
        // Creative commands requires for example download or an upload.
        // Copy is "not creative" as we copy a existing resource
        for (id encodedCommand in _bunchOfCommand) {
            NSArray*cmdAsAnArray=[self _encodedCommandToArray:encodedCommand];
            if(cmdAsAnArray){
                if([[cmdAsAnArray objectAtIndex:0] intValue]==PdSCreateOrUpdate){
                    [creativeCommands addObject:cmdAsAnArray];
                }else{
                    [unCreativeCommands addObject:cmdAsAnArray];
                }
            }
            if([encodedCommand isKindOfClass:[NSString class]]){
                
            }else{
                [self _interruptOnFault:[NSString stringWithFormat:@"Illegal command %@",encodedCommand]];
            }
        }
        for (NSArray*cmd in creativeCommands) {
            [self->_queue addOperationWithBlock:^{
                [weakSelf _runCommandFromArrayOfArgs:cmd];
            }];
        }
        for (NSArray*cmd in unCreativeCommands) {
            [self->_queue addOperationWithBlock:^{
                [weakSelf _runCommandFromArrayOfArgs:cmd];
            }];
        }
        [_queue addOperationWithBlock:^{
            [self _finalizeWithCreativeCommands:creativeCommands];
        }];
        
        
        // Finaly we add the completion block
        [self->_queue addOperationWithBlock:^{
            _completionBlock(YES,nil);
        }];
        
    }else{
        _completionBlock(YES,@"There was no command to execute");
    }
}



- (void)_interruptOnFault:(NSString*)faultMessage{
    // This method is never called on reachability issues.
    [self->_queue cancelAllOperations];
    self->_completionBlock(NO,faultMessage);
}


- (NSArray*)_encodedCommandToArray:(NSString*)encoded{
    NSData *data = [encoded dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    id cmd = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(error && !encoded){
        // We stop the process on any error
        [self _interruptOnFault:[NSString stringWithFormat:@"Cmd deserialization failed %@ : %@",encoded,[error localizedDescription]]];
    }
    if(cmd && [cmd isKindOfClass:[NSArray class]] && [cmd count]>0){
        return cmd;
    }else{
        [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %@",encoded]];
    }
    return nil;
}

-(void)_runCommandFromArrayOfArgs:(NSArray*)cmd{
    [self _commandInProgress];
    if(cmd && [cmd isKindOfClass:[NSArray class]] && [cmd count]>0){
        int cmdName=[[cmd objectAtIndex:0] intValue];
        NSString*arg1= [cmd count]>1?[cmd objectAtIndex:1]:nil;
        NSString*arg2=[cmd count]>2?[cmd objectAtIndex:2]:nil;
        switch (cmdName) {
            case (PdSCreateOrUpdate):{
                if(arg1 && arg2){
                    [self _runCreateOrUpdate:arg2 destination:arg1];
                }else{
                    [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %i arg1:%@ arg2:%@",cmdName,arg1?arg1:@"nil",arg2?arg2:@"nil"]];
                }
                break;
            }
            case (PdSCopy):{
                if(arg1 && arg2){
                    [self _runCopy:arg2 destination:arg1];
                }else{
                    [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %i arg1:%@ arg2:%@",cmdName,arg1?arg1:@"nil",arg2?arg2:@"nil"]];
                }
                break;
            }
            case (PdSMove):{
                if(arg1 && arg2){
                    [self _runMove:arg2 destination:arg1];
                }else{
                    [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %i arg1:%@ arg2:%@",cmdName,arg1?arg1:@"nil",arg2?arg2:@"nil"]];
                }
                break;
            }
            case (PdSDelete):{
                if(arg1){
                    [self _runDelete:arg1];
                }else{
                    [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %i arg1:%@ ",cmdName,arg1?arg1:@"nil"]];
                }
                break;
            }
            case (PdsSanitize):{
                if(arg1){
                    [self _runSanitize:arg1];
                }else{
                    [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %i arg1:%@ ",cmdName,arg1?arg1:@"nil"]];
                }
                break;
            }
            case (PdSChmod):{
                if(arg1 && arg2){
                    [self _runChmod:arg1 mode:[arg2 intValue]];
                }else{
                    [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %i arg1:%@ arg2:%@",cmdName,arg1?arg1:@"nil",arg2?arg2:@"nil"]];
                }
                break;
            }
            case (PdSForget):{
                if(arg1 && arg2){
                    [self _runForget:arg1];
                }else{
                    [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %i arg1:%@ arg2:%@",cmdName,arg1?arg1:@"nil",arg2?arg2:@"nil"]];
                }
                break;
            }
            default:
                [self _interruptOnFault:[NSString stringWithFormat:@"The command %i is currently not supported",cmdName]];
                break;
        }
    }else{
        [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command %@",cmd?cmd:@"nil"]];
    }
}


- (void)_commandInProgress{
    [_queue setSuspended:YES];
}

- (void)_nextCommand{
    [_queue setSuspended:NO];
}




#pragma  mark - command runtime


-(void)_runCreateOrUpdate:(NSString*)source destination:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        
        // UPLOAD
        //_context.destinationBaseUrl;
        
        // http -v -f POST PdsSync.api.local/api/v1/uploadFileTo/tree/unique-public-id-1293/
        // destination='a/file1.txt' syncIdentifier='your-syncID_' source@~/Documents/Samples/text1.txt doers='' undoers=''
        
        PdSCommandInterpreter *__weak weakSelf=self;
        NSString *URLString =[[_context.destinationBaseUrl absoluteString] stringByAppendingFormat:@"uploadFileTo/tree/%@/",_context.destinationTreeId];
        NSDictionary *parameters = @{
                                     @"syncIdentifier": _context.syncID,
                                     @"destination":destination,
                                     @"doers":@"",
                                     @"undoers":@""};// @todo find a solution for doers / undoers if possible
        
        
        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                                                                                                  URLString:URLString
                                                                                                 parameters:parameters
                                                                                  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                                      [formData appendPartWithFileURL:[NSURL fileURLWithPath:source]
                                                                                                                 name:@"source"
                                                                                                             fileName:[destination lastPathComponent]
                                                                                                             mimeType:@"application/octet-stream"
                                                                                                                error:nil];
                                                                                      
                                                                                  } error:nil];
        
        _unitaryCommandProgress = nil;
        NSURLSessionUploadTask *uploadTask = [_HTTPsessionManager uploadTaskWithStreamedRequest:request
                                                                                       progress:&_unitaryCommandProgress
                                                                              completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                                                  if (error) {
                                                                                      NSLog(@"Error: %@", error);
                                                                                  } else {
                                                                                      NSString *s=[[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                                                                                      NSLog(@"%@ %@", response, s);
                                                                                      [weakSelf _nextCommand];
                                                                                  }
                                                                              }];
        
        [uploadTask resume];
        
        
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal){
        
          PdSCommandInterpreter *__weak weakSelf=self;
        
        // DOWNLOAD
        //_context.sourceBaseUrl;
        
        // http://pdssync.api.local/api/v1/file/tree/unique-public-id-1293/?path=txt/test/a.txt&redirect=false&returnValue=false
        
        NSString*treeId=_context.destinationTreeId;
        
        // Decompose in a GET for the URI then a download task
        
        NSString *URLString =[[_context.sourceBaseUrl absoluteString] stringByAppendingFormat:@"file/tree/%@/?path=%@&redirect=false&returnValue=false",treeId,source];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        [_HTTPsessionManager GET:URLString parameters:nil
                         success:^(NSURLSessionDataTask *task, id responseObject) {
                             NSDictionary*d=(NSDictionary*)responseObject;
                             NSString*uriString=[d objectForKey:@"uri"];
                             if(uriString){
                                 NSURLRequest *fileRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:uriString]];
                                 _unitaryCommandProgress = nil;
                                 NSURLSessionDownloadTask *downloadTask = [_HTTPsessionManager downloadTaskWithRequest:fileRequest
                                                                                                              progress:&_unitaryCommandProgress
                                                                                                           destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                                                                               NSString*p=[weakSelf _absoluteLocalPathFromRelativePath:destination toLocalUrl:_context.destinationBaseUrl];
                                                                                                               [weakSelf _createRecursivelyRequiredFolderForPath:p];
                                                                                                               if([_fileManager fileExistsAtPath:[weakSelf _filter:p]]){
                                                                                                                   NSError*error=nil;
                                                                                                                  [_fileManager removeItemAtPath:[weakSelf _filter:p] error:&error];
                                                                                                                   if(error){
                                                                                                                       NSString *msg=[NSString stringWithFormat:@"Error when removing %@ %@",p,[error localizedDescription]];
                                                                                                                       [weakSelf _interruptOnFault:msg];
                                                                                                                   }
                                                                                                               }
                                                                                                               return [NSURL URLWithString:p];
                                                                                                           } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                                                                               NSLog(@"File downloaded to: %@", filePath);
                                                                                                               [weakSelf _nextCommand];
                                                                                                           }];
                                 [downloadTask resume];
                             }else{
                                 [weakSelf _interruptOnFault:[NSString stringWithFormat:@"Missing url in response of %@",task.currentRequest.URL.absoluteString]];
                             }
                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                             NSLog(@"%@",[self _stringFromError:error]);
                             [weakSelf _interruptOnFault:[weakSelf _stringFromError:error]];
                         }];
        
        
        
        
        
        
    }else if (self->_context.mode==SourceIsLocalDestinationIsLocal){
        // It is a copy
        [self _runCopy:source destination:destination];
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
}



- (void)_finalizeWithCreativeCommands:(NSArray*)creativeCommands{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Service
        
        //http -v  POST PdsSync.api.local/api/v1/finalizeTransactionIn/tree/unique-public-id-1293/ commands:='[ [   0 ,"a/file1.txt" ]]' syncIdentifier='your-syncID_' hashMap='[]'
        NSString *URLString =[NSString stringWithFormat:@"finalizeTransactionIn/file/tree/%@/%@",_context.destinationTreeId,@""];//@"?start_debug=1&debug_host=127.0.0.1&debug_port=10137"
        NSDictionary *parameters = @{
                                     @"syncIdentifier": _context.syncID,
                                     @"commands":creativeCommands,
                                     @"hashMap":[_context.finalHashMap dictionaryRepresentation]
                                     };
        
        
        [_HTTPsessionManager POST:URLString
                       parameters:parameters
                          success:^(NSURLSessionDataTask *task, id responseObject) {
                              [self _nextCommand];
                          } failure:^(NSURLSessionDataTask *task, NSError *error) {
                              NSLog(@"\n%@\n%@",[task.currentRequest.URL absoluteString],[self _stringFromError:error]);
                              [self _interruptOnFault:[error localizedDescription]];
                          }];
        
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // NEED TO QUALIFY IF THE FINALIZATION IS USEFULL
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
    
}


- (NSString*)_stringFromError:(NSError*)error{
    NSData *d=[[error userInfo] objectForKey:JSONResponseSerializerWithDataKey];
    return [[NSString alloc] initWithBytes:[d bytes]
                                    length:[d length]
                                  encoding:NSUTF8StringEncoding];
}


-(void)_runCopy:(NSString*)source destination:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Service
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // COPY LOCALLY
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTEDa
    }
}


-(void)_runMove:(NSString*)source destination:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Service
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // MOVE LOCALLY
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
}

-(void)_runDelete:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Service
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // DELETE LOCALLY
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
}

-(void)_runSanitize:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Service
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // SANITIZE LOCALLY
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
}

-(void)_runChmod:(NSString*)destination mode:(int)mode{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Servicepas
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // CHMOD LOCALLY
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
}

-(void)_runForget:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Service
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // FORGET LOCALLY
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
}


- (NSString*)_absoluteLocalPathFromRelativePath:(NSString*)relativePath toLocalUrl:(NSURL*)localUrl{
    return [NSString stringWithFormat:@"%@%@",[localUrl absoluteString],relativePath];
}


#pragma mark - NSFileManagerDelegate


- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath{
    if ([error code] == NSFileWriteFileExistsError)
        return YES;
    else
        return NO;
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL{
    if ([error code] == NSFileWriteFileExistsError)
        return YES;
    else
        return NO;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath{
    if ([error code] == NSFileWriteFileExistsError)
        return YES;
    else
        return NO;
    
}
- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL{
    if ([error code] == NSFileWriteFileExistsError)
        return YES;
    else
        return NO;
    
}

#pragma mark - File manager selectors

-(BOOL)_createRecursivelyRequiredFolderForPath:(NSString*)path{
    NSString*filteredPath=[self _filter:path];
#if TARGET_OS_IPHONE
    if([path rangeOfString:[self _applicationDocumentsDirectory]].location==NSNotFound){
        return NO;
#endif
    if(![[filteredPath substringFromIndex:filteredPath.length-1] isEqualToString:@"/"])
        filteredPath=[filteredPath stringByDeletingLastPathComponent];
    
    if(![_fileManager fileExistsAtPath:filteredPath]){
        NSError *error=nil;
        [_fileManager createDirectoryAtPath:filteredPath
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:&error];
        if(error){
            return NO;
        }
    }
    return YES;
}

- (NSString*)_filter:(NSString*)path{
    if(!path)
        return path;
    // Those filtering operations may be necessary sometimes when manipulating IOS FS.
    NSString *filtered=[[path copy] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    filtered=[filtered stringByReplacingOccurrencesOfString:@"file:///private" withString:@""];
    filtered=[filtered stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    return filtered;
}



- (NSString *)_applicationDocumentsDirectory{
#if TARGET_OS_IPHONE
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        _applicationDocumentsDirectory=[self _filter:[basePath stringByAppendingString:@"/"]];
#else
        // If the absolute path was nil
        // We create automatically a data folder
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath=[paths lastObject];
        return basePath;
#endif
}



#pragma mark - AFNetworking


// We currently support ONE MANAGER ONLY
// @todo SourceIsDistantDestinationIsDistant

- (BOOL)_setUpManager{
    if(self->_context.mode!=SourceIsLocalDestinationIsLocal &&
       self->_context.mode!=SourceIsDistantDestinationIsDistant){
        //_SessionManager
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        if(self->_context.mode==SourceIsLocalDestinationIsDistant ){
            _HTTPsessionManager=[[AFHTTPSessionManager alloc]initWithBaseURL:_context.destinationBaseUrl sessionConfiguration:configuration];
        }else if(self->_context.mode==SourceIsDistantDestinationIsLocal){
            _HTTPsessionManager=[[AFHTTPSessionManager alloc]initWithBaseURL:_context.sourceBaseUrl sessionConfiguration:configuration];
        }
        if(_HTTPsessionManager){
            AFJSONRequestSerializer*r=[AFJSONRequestSerializer serializer];
            [_HTTPsessionManager setRequestSerializer:r];
            _HTTPsessionManager.responseSerializer = [[JSONResponseSerializerWithData alloc]init];
            NSSet*acceptable= [NSSet setWithArray:@[@"application/json",@"text/html"]];
            [_HTTPsessionManager.responseSerializer setAcceptableContentTypes:acceptable];
            // REACHABILITY SUPPORT
            NSOperationQueue *operationQueue = _HTTPsessionManager.operationQueue;
            [_HTTPsessionManager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                switch (status) {
                    case AFNetworkReachabilityStatusReachableViaWWAN:
                    case AFNetworkReachabilityStatusReachableViaWiFi:
                        [operationQueue setSuspended:NO];
                        break;
                    case AFNetworkReachabilityStatusNotReachable:
                    default:
                        [operationQueue setSuspended:YES];
                        break;
                }
            }];
            
            return YES;
        }
    }
    return NO;
}

- (NSString*)_encodetoJson:(id)object{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:0
                                                         error:&error];
    
    if (!jsonData) {
        return [error localizedDescription];
    } else {
        return [[NSString alloc]initWithBytes:[jsonData bytes]
                                       length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
}




@end