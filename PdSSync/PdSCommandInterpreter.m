//
//  PdSCommandInterpreter.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 11/03/2014.
//
//

#import "PdSCommandInterpreter.h"


typedef void(^CompletionBlock_type)(BOOL success,NSString*message);

@interface PdSCommandInterpreter (){
    CompletionBlock_type _completionBlock;
    
}

@end

@implementation PdSCommandInterpreter

@synthesize sourceUrl = _sourceUrl;
@synthesize destinationUrl = _destinationUrl;
@synthesize treeId = _treeId;
@synthesize finalHashMap = _finalHashMap;
@synthesize bunchOfCommand = _bunchOfCommand;
@synthesize syncMode = _syncMode;


/**
 *  The dedicated initializer.
 *
 *  @param sourceUrl      the source url
 *  @param destinationUrl the destination url
 *  @param treeId         the optionnal tree id
 *  @param bunchOfCommand the bunch of command
 *  @param finalHashMap   the final hash map
 *  @param completionBlock the completion block
 *  @return the instance.
 */
- (instancetype)initWithSourceUrl:(NSURL*)sourceUrl
                         destinationUrl:(NSURL*)destinationUrl
                           treeId:(NSString*)treeId
                   bunchOfCommand:(NSArray*)bunchOfCommand
                     finalHashMap:(HashMap*)finalHashMap
               andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock{
    self=[super init];
    if(self){
        self->_finalHashMap=[finalHashMap copy];
        self->_bunchOfCommand=[bunchOfCommand copy];
        self->_syncMode=[self _mode];
        self->_completionBlock=[completionBlock copy];
        
        if(self->_syncMode==SourceIsDistantDestinationIsDistant ){
            [NSException raise:@"TemporaryException" format:@"SourceIsDistantDestinationIsDistant is currently not supported"];
        }
        if(self->_syncMode==SourceIsLocalDestinationIsLocal ){
            [NSException raise:@"TemporaryException" format:@"SourceIsLocalDestinationIsLocal is currently not supported"];
        }
        if(sourceUrl && destinationUrl && bunchOfCommand && finalHashMap){
            PdSCommandInterpreter * __weak weakSelf=self;
            dispatch_async(dispatch_queue_create("com.pereira-da-silva.PdSSync.CmdInterpreter", NULL), ^{
                [weakSelf _run];
            });
        }else{
            if(self->_completionBlock){
                _completionBlock(NO,@"sourceUrl && destinationUrl && bunchOfCommand && finalHashMap are required");
            }
        }
    }
    return self;
}


- (PdSSyncMode)_mode{
    if([[_sourceUrl absoluteString] rangeOfString:@"http"].location==0){
        if([[_destinationUrl absoluteString] rangeOfString:@"http"].location==0){
            return SourceIsDistantDestinationIsDistant;
        }else{
            return SourceIsDistantDestinationIsLocal;
        }
    }else{
        if([[_destinationUrl absoluteString] rangeOfString:@"http"].location==0){
            return SourceIsLocalDestinationIsDistant;
        }else{
            return SourceIsLocalDestinationIsLocal;
        }
    }
    return nil;
}


- (void)_run{
    
}


//-(void)interpretBunchOfCommand($treeId, $syncIdentifier, array $bunchOfCommand,  $finalHashMap);

// _finalize($treeId, $syncIdentifier,$finalHashMap

// _decodeAndRunCommand($syncIdentifier, array $cmd , $treeId)


/*
 
 typedef NS_ENUM (NSUInteger,
 PdSSyncCommand) {
 PdSCreateOrUpdate   = 0 , // W destination or source
 PdSCopy             = 1 , // R source W destination
 PdSMove             = 2 , // R source W destination
 PdSDelete           = 3 , // W source
 } ;
 
 typedef NS_ENUM(NSUInteger,
 PdSSyncCMDParamRank) {
 PdSDestination = 1,
 PdSSource      = 2
 } ;
 
 
 typedef NS_ENUM (NSUInteger,
 PdSAdminCommand) {
 PdsSanitize    = 4 , // X on tree
 PdSChmod       = 5 , // X on tree
 PdSForget      = 6 , // X on tree
 } ;
 
 */

-(NSString*)encodeCreateOrUpdate:(NSString*)source destination:(NSString*)destination{
    return [NSString stringWithFormat:@"[%i,\"%@\",\"%@\"]", PdSCreateOrUpdate,destination,source];
}
-(NSString*)encodeCopy:(NSString*)source destination:(NSString*)destination{
    return [NSString stringWithFormat:@"[%i,\"%@\",\"%@\"]", PdSCopy,destination,source];;
}
-(NSString*)encodeMove:(NSString*)source destination:(NSString*)destination{
    return [NSString stringWithFormat:@"[%i,\"%@\",\"%@\"]", PdSMove,destination,source];;
}
-(NSString*)encodeRemove:(NSString*)destination{
    return [NSString stringWithFormat:@"[%i,\"%@\"]", PdSDelete,destination];;
}


-(void)_runCommand:(NSString*)encoded{
// NSArray *cmd=[NSJSONSerialization d]
    
}


-(void)runCreateOrUpdate:(NSString*)encoded{
    
}
-(void)runCopy:(NSString*)encoded{
    
}
-(void)runMove:(NSString*)encoded{
    
}
-(void)runRemove:(NSString*)encoded{
    
}




@end
