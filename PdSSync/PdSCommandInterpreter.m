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
    }
    return self;
}


- (PdSSyncMode)_mode{
    return nil;
}





//-(void)interpretBunchOfCommand($treeId, $syncIdentifier, array $bunchOfCommand,  $finalHashMap);

// _finalize($treeId, $syncIdentifier,$finalHashMap

// _decodeAndRunCommand($syncIdentifier, array $cmd , $treeId)





@end
