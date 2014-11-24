//
//  PdSCommandInterpreter.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 11/03/2014.
//
//

// Current implementation relies on http://cocoadocs.org/docsets/AFNetworking/2.2.0/

#import "AFNetworking.h"
#import "PdSCommandInterpreter.h"


// We have removed a fix inspired https://github.com/AFNetworking/AFNetworking/issues/1398
// Some servers responds a 411 status when there is no content length
// We donnot  want to patch as it is related to an Apple related bug.
// Fix the issue server side



typedef void(^ProgressBlock_type)(uint taskIndex,float progress);
typedef void(^CompletionBlock_type)(BOOL success,NSString*message);

@interface PdSCommandInterpreter (){
    CompletionBlock_type             _completionBlock;
    ProgressBlock_type               _progressBlock;
    PdSFileManager                   *__weak _fileManager;
    AFHTTPSessionManager            *_HTTPsessionManager;
    
}
@property (nonatomic,strong)NSOperationQueue *queue;
@end

@implementation PdSCommandInterpreter

@synthesize bunchOfCommand  = _bunchOfCommand;
@synthesize context         = _context;

/**
 *
 *
 *  @param bunchOfCommand  the bunch of command
 *  @param context         the interpreter context
 *  @param progressBlock   the progress block
 *  @param completionBlock te completion block
 *
 *  @return the interpreter
 */
+ (PdSCommandInterpreter*)interpreterWithBunchOfCommand:(NSArray*)bunchOfCommand
                                                context:(PdSSyncContext*)context
                                          progressBlock:(void(^)(uint taskIndex,float progress))progressBlock
                                     andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock{
    return [[PdSCommandInterpreter alloc] initWithBunchOfCommand:bunchOfCommand
                                                         context:context
                                                   progressBlock:progressBlock
                                              andCompletionBlock:completionBlock];
}

/**
 *   The dedicated initializer.
 *
 *  @param bunchOfCommand  the bunch of command
 *  @param context         the interpreter context
 *  @param progressBlock   the progress block
 *  @param completionBlock te completion block
 *
 *  @return the interpreter
 */
- (instancetype)initWithBunchOfCommand:(NSArray*)bunchOfCommand
                               context:(PdSSyncContext*)context
                         progressBlock:(void(^)(uint taskIndex,float progress))progressBlock
                    andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock;{
    if(self){
        self->_bunchOfCommand=[bunchOfCommand copy];
        self->_context=context;
        self->_progressBlock=progressBlock?[progressBlock copy]:nil;
        self->_completionBlock=completionBlock?[completionBlock copy]:nil;
        self->_fileManager=[PdSFileManager sharedInstance];
        [self->_fileManager setDelegate:self];
        self->_progressCounter=0;
        if(self->_context.mode==SourceIsDistantDestinationIsDistant ){
            [NSException raise:@"TemporaryException" format:@"SourceIsDistantDestinationIsDistant is currently not supported"];
        }
        if(self->_context.mode==SourceIsLocalDestinationIsLocal ){
            [NSException raise:@"TemporaryException" format:@"SourceIsLocalDestinationIsLocal is currently not supported"];
        }
        if([context isValid] && _bunchOfCommand){
            _queue=[[NSOperationQueue alloc] init];
            _queue.name=[NSString stringWithFormat:@"com.pereira-da-silva.PdSSync.CommandInterpreter.%i",[self hash]];
            [_queue setMaxConcurrentOperationCount:1];// Sequential
            [self _setUpManager];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _run];
            });
        }else{
            if(self->_completionBlock){
                _completionBlock(NO,@"sourceUrl && destinationUrl && bunchOfCommand && finalHashMap are required");
            }
        }
    }
    return self;
}


+(id)encodeCreateOrUpdate:(NSString*)source destination:(NSString*)destination{
    if(source && destination){
        return [NSString stringWithFormat:@"[%i,\"%@\",\"%@\"]", PdSCreateOrUpdate,destination,source];
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
            dispatch_sync(dispatch_get_main_queue(), ^{
                _completionBlock(YES,nil);
            });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        _progressCounter++;
        [_queue setSuspended:NO];
    });
}




#pragma  mark - command runtime


-(void)_runCreateOrUpdate:(NSString*)source destination:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        
        // UPLOAD
        //_context.destinationBaseUrl;
        
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
        
        
        
        NSProgress* progress=nil;
        NSURLSessionUploadTask *uploadTask = [_HTTPsessionManager uploadTaskWithStreamedRequest:request
                                                                                       progress:&progress
                                                                              completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                                                  [progress removeObserver:weakSelf
                                                                                                forKeyPath:@"fractionCompleted"
                                                                                                   context:NULL];
                                                                                  if ([(NSHTTPURLResponse*)response statusCode]!=201 && error) {
                                                                                      NSString *msg=[NSString stringWithFormat:@"Error when uploading %@",[weakSelf _stringFromError:error]];
                                                                                      [weakSelf _interruptOnFault:msg];
                                                                                  } else {
                                                                                      NSString *s=[[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                                                                                      NSLog(@"%@ %@", response, s);
                                                                                      [weakSelf _nextCommand];
                                                                                  }
                                                                              }];
        
        [uploadTask resume];
        
        [progress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        
        
        
        
        
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal){
        
        PdSCommandInterpreter *__weak weakSelf=self;
        
        // DOWNLOAD
        NSString*treeId=_context.sourceTreeId;
        // Decompose in a GET for the URI then a download task
        
        NSString *URLString =[[_context.sourceBaseUrl absoluteString] stringByAppendingFormat:@"file/tree/%@/",treeId];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        NSDictionary *parameters = @{
                                     @"path": [source copy],
                                     @"redirect":@"false",
                                     @"returnValue":@"false"
                                    };

        [_HTTPsessionManager GET:URLString
                      parameters:parameters
                         success:^(NSURLSessionDataTask *task, id responseObject) {
                             NSDictionary*d=(NSDictionary*)responseObject;
                             NSString*uriString=[d objectForKey:@"uri"];
                             if(uriString && [uriString isKindOfClass:[NSString class]]){
                                 NSURLRequest *fileRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:uriString]];
                                 NSProgress* progress=nil;
                                 NSURLSessionDownloadTask *downloadTask = [_HTTPsessionManager downloadTaskWithRequest:fileRequest
                                                                                                              progress:&progress
                                                                                                           destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                                                                                               [progress removeObserver:weakSelf
                                                                                                                             forKeyPath:@"fractionCompleted"
                                                                                                                                context:NULL];
                                                                                                               NSString*p=[weakSelf _absoluteLocalPathFromRelativePath:destination toLocalUrl:_context.destinationBaseUrl];
                                                                                                               [_fileManager createRecursivelyRequiredFolderForPath:p];
                                                                                                               if([_fileManager fileExistsAtPath:[NSString filteredFilePathFrom:p]]){
                                                                                                                   NSError*error=nil;
                                                                                                                   [_fileManager removeItemAtPath:[NSString filteredFilePathFrom:p] error:&error];
                                                                                                                   if(error){
                                                                                                                       NSString *msg=[NSString stringWithFormat:@"Error when removing %@ %@",p,[self _stringFromError:error]];
                                                                                                                       [weakSelf _interruptOnFault:msg];
                                                                                                                 
                                                                                                                   }
                                                                                                               }
                                                                                                               return [NSURL URLWithString:p];
                                                                                                           } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                                                                                                               [progress removeObserver:weakSelf
                                                                                                                             forKeyPath:@"fractionCompleted"
                                                                                                                                context:NULL];
                                                                                                               if(error){                                                                                                                   [weakSelf _interruptOnFault:[self _stringFromError:error]];

                                                                                                               }else{
                                                                                                                   NSLog(@"File downloaded to: %@", filePath);
                                                                                                                   
                                                                                                                   [weakSelf _nextCommand];
                                                                                                               }
                                                                                                               
                                                                                                           }];
                                 [downloadTask resume];
                                 
                                 [progress addObserver:self
                                            forKeyPath:@"fractionCompleted"
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
                                 
                             }else{
                                 [weakSelf _interruptOnFault:[NSString stringWithFormat:@"Missing url in response of %@",task.currentRequest.URL.absoluteString]];
                             }
                         } failure:^(NSURLSessionDataTask *task, NSError *error) {
                             NSLog(@"%@",[weakSelf _stringFromError:error]);
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
        // Write the Hashmap to a file
        // @todo could be crypted.
        
        NSString* hashMapTempFilename = [NSString stringWithFormat:@"%f.hashmap", [NSDate timeIntervalSinceReferenceDate]];
        NSURL* hashMapTempFileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:hashMapTempFilename]];
        [[_context.finalHashMap dictionaryRepresentation] writeToURL:hashMapTempFileUrl atomically:YES];
        
        PdSCommandInterpreter *__weak weakSelf=self;
        
        
        
        NSString *URLString =[[_context.destinationBaseUrl absoluteString] stringByAppendingFormat:@"finalizeTransactionIn/tree/%@/",_context.destinationTreeId];
        NSDictionary *parameters = @{
                                     @"syncIdentifier": _context.syncID,
                                     @"commands":[self  _encodetoJson:creativeCommands]
                                     };
        
        NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST"
                                                                                                  URLString:URLString
                                                                                                 parameters:parameters
                                                                                  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                                                      [formData appendPartWithFileURL:hashMapTempFileUrl
                                                                                                                 name:@"hashmap"
                                                                                                             fileName:[hashMapTempFileUrl lastPathComponent]
                                                                                                             mimeType:@"application/octet-stream"
                                                                                                                error:nil];
                                                                                      
                                                                                      
                                                                                  } error:nil];
        
        NSProgress* progress=nil;
        NSURLSessionUploadTask *uploadTask = [_HTTPsessionManager uploadTaskWithStreamedRequest:request
                                                                                       progress:&progress
                                                                              completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
                                                                                  [progress removeObserver:weakSelf
                                                                                                forKeyPath:@"fractionCompleted"
                                                                                                   context:NULL];
                                                                                   if ([(NSHTTPURLResponse*)response statusCode]!=200 && error) {
                                                                                      NSString *msg=[NSString stringWithFormat:@"Error when finalizing %@ ",[self _stringFromError:error]];
                                                                                      [self _interruptOnFault:msg];
                                                                                  } else {
                                                                                      NSString *s=[[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding];
                                                                                      NSLog(@"%@ %@", response, s);
                                                                                     [weakSelf _nextCommand];
                                                                                  }
                                                                              }];
        [uploadTask resume];
        
        [progress addObserver:self
                   forKeyPath:@"fractionCompleted"
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
        
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // NEED TO QUALIFY IF THE FINALIZATION IS USEFULL
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
    
}


- (NSString*)_stringFromError:(NSError*)error{
    NSMutableString*result=[NSMutableString string];
    NSData *d=[[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseDataErrorKey];
    if(d && [d length]>0){
         [result appendFormat:@" JSONResponseSerializerWithDataKey : %@",[[NSString alloc] initWithBytes:[d bytes]
                                    length:[d length]
                                  encoding:NSUTF8StringEncoding]];

    }
        if([error localizedDescription]){
            [result appendFormat:@" debugDescription : %@",[error localizedDescription]];
        }
        if([error debugDescription]){
            [result appendFormat:@" debugDescription : %@",[error debugDescription]];
        }

        return result;
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




#pragma mark - KVO


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"fractionCompleted"]) {
        NSProgress *progress = (NSProgress *)object;
        if(_progressBlock){
            float f=progress.fractionCompleted;
            dispatch_sync(dispatch_get_main_queue(), ^{
                _progressBlock(_progressCounter,f);
            });
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
            _HTTPsessionManager.responseSerializer = [[AFJSONResponseSerializer alloc]init];
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