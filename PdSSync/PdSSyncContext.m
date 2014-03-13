//
//  PdSSyncContext.m
//  Pods
//
//  Created by Benoit Pereira da Silva on 13/03/2014.
//
//

#import "PdSSyncContext.h"


@implementation PdSSyncContext{
    NSURL*_sourceUrl;
    NSURL*_destinationUrl;

}

@synthesize finalHashMap = _finalHashMap;

-(instancetype)initWithFinalHashMap:(HashMap*)finalHashMap
                          sourceURL:(NSURL*)sourceUrl
                  andDestinationUrl:(NSURL*)destinationUrl{
    self=[super init];
    if(self){
        self->_sourceUrl=[sourceUrl copy];
        self->_destinationUrl=[destinationUrl copy];
        self->_finalHashMap=finalHashMap;
        self->_sourceTreeId=[self _treeIDFromUrl:sourceUrl];
        self->_destinationTreeId=[self _treeIDFromUrl:destinationUrl];
    }
    return self;
}

- (BOOL)isValid{
    return (_sourceUrl && _destinationUrl && _finalHashMap);
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
        return nil;
    }
}

- (PdSSyncMode)mode{
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

@end
