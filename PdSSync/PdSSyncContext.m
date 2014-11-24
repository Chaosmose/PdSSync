//
//  PdSSyncContext.m
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 13/03/2014.
//
//

#import "PdSSyncContext.h"


@implementation PdSSyncContext{

}

@synthesize syncID = _syncID;
@synthesize sourceBaseUrl = _sourceBaseUrl;
@synthesize destinationBaseUrl = _destinationBaseUrl;
@synthesize finalHashMap = _finalHashMap;

/**
 * The url are considerated as the repository root
 *
 *  for example     : @"http://PdsSync.api.local/api/v1/tree/unique-public-id-1293"
 *  or              : @"~/Entrepot/Git/Public-projects/PdSSync/PdSSyncPhp/Repository/"
 *
 *  If the url is distant we extract the tree id.
 *
 *
 *  @param sourceUrl      sourceUrl description
 *  @param destinationUrl destinationUrl description
 *
 *  @return returns the context
 */
-(instancetype)initWithSourceURL:(NSURL*)sourceUrl
               andDestinationUrl:(NSURL*)destinationUrl{
    self=[super init];
    if(self){
        self->_sourceBaseUrl=[self _baseUrlFromUrl:sourceUrl];
        self->_destinationBaseUrl=[self _baseUrlFromUrl:destinationUrl];
        self->_sourceTreeId=[self _treeIDFromUrl:sourceUrl];
        self->_destinationTreeId=[self _treeIDFromUrl:destinationUrl];
        self->_syncID=[self _getNewSyncID];
    }
    return self;
}

- (BOOL)isValid{
    return (_sourceBaseUrl && _destinationBaseUrl);
}


- (PdSSyncMode)mode{
    if([[_sourceBaseUrl absoluteString] rangeOfString:@"http"].location==0){
        if([[_destinationBaseUrl absoluteString] rangeOfString:@"http"].location==0){
            return SourceIsDistantDestinationIsDistant;
        }else{
            return SourceIsDistantDestinationIsLocal;
        }
    }else{
        if([[_destinationBaseUrl absoluteString] rangeOfString:@"http"].location==0){
            return SourceIsLocalDestinationIsDistant;
        }else{
            return SourceIsLocalDestinationIsLocal;
        }
    }
    return nil;
}


- (NSString*)_treeIDFromUrl:(NSURL*)url{
    if([[url absoluteString] rangeOfString:@"http"].location==0){
        NSArray* components=url.pathComponents;
        if([components indexOfObject:@"tree"]){
            int tIdx=[components indexOfObject:@"tree"];
            if([components count]>tIdx+1){
                return [components objectAtIndex:tIdx+1];
            }
        }
        return nil;
    }else{
        NSArray* components=url.pathComponents;
        return (NSString*)[components lastObject];
    }
}


- (NSURL*)_baseUrlFromUrl:(NSURL*)url{
    if([[url absoluteString] rangeOfString:@"http"].location==0){
        NSArray* components=url.pathComponents;
        if([components indexOfObject:@"tree"]){
            int tIdx=[components indexOfObject:@"tree"];
            if(tIdx >2 && tIdx!=NSNotFound){
                NSMutableString*stringUrl=[NSMutableString stringWithFormat:@"%@://%@",[url scheme],[url host]];
                for (int i=0; i<tIdx; i++) {
                    [stringUrl appendFormat:@"%@%@",[components objectAtIndex:i],(i==0)?@"":@"/"];
                }
                return [NSURL URLWithString:stringUrl];
            }
        }
    }
    if(url){
        return [url copy];
    }
    return nil;
}


-(NSString *)_getNewSyncID{
    // Returns a UUID
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return uuidStr;
}

@end
