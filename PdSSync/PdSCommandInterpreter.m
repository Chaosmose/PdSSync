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


typedef void(^CompletionBlock_type)(BOOL success,NSString*message);

@interface PdSCommandInterpreter (){
    CompletionBlock_type _completionBlock;
    NSFileManager *_fileManager;
}
@property (nonatomic,strong)NSOperationQueue *queue;
@end

@implementation PdSCommandInterpreter

@synthesize bunchOfCommand = _bunchOfCommand;
@synthesize context = _context;

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
        self->_context=[context copy];
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
            [self _run];

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
        // Finaly we add the completion block
        [self->_queue addOperationWithBlock:^{
            _completionBlock(YES,nil);
        }];
        
    }else{
        _completionBlock(YES,@"There was no command to execute");
    }
}


- (void)_interruptOnFault:(NSString*)faultMessage{
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
    if(cmd && [cmd isKindOfClass:[NSArray class]] && [cmd length]>0){
        return cmd;
    }else{
        [self _interruptOnFault:[NSString stringWithFormat:@"Invalid command : %@",encoded]];
    }
    return nil;
}


-(void)_runCommandFromArrayOfArgs:(NSArray*)cmd{
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


#pragma  mark - command runtime 


-(void)_runCreateOrUpdate:(NSString*)source destination:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // UPLOAD
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal){
        // DOWNLOAD
    }else if (self->_context.mode==SourceIsLocalDestinationIsLocal){
        // It is a copy
        [self _runCopy:source destination:destination];
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
    }
}

-(void)_runCopy:(NSString*)source destination:(NSString*)destination{
    if((self->_context.mode==SourceIsLocalDestinationIsDistant)){
        // CALL the PdSync Service
    }else if (self->_context.mode==SourceIsDistantDestinationIsLocal||
              self->_context.mode==SourceIsLocalDestinationIsLocal){
        // COPY LOCALLY
    }else if (self->_context.mode==SourceIsDistantDestinationIsDistant){
        // CURRENTLY NOT SUPPORTED
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
        // CALL the PdSync Service
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


@end