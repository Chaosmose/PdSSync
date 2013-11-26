//
//  main.m
//  PdSDeltaSync
//
//  Created by Benoit Pereira da Silva on 26/11/2013.
//  Copyright (c) 2013 Pereira da Silva. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PdSAnalyzer.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSURL *m=[NSURL URLWithString:@"/Users/bpds/Entrepot/Git/Public-projects/PdSSync/Repository/Default/Master"];
        NSURL *s=[NSURL URLWithString:@"/Users/bpds/Entrepot/Git/Public-projects/PdSSync/Repository/Default/Slave"];
        
        PdSAnalyzer*a=[[PdSAnalyzer alloc] initWithMasterURL:m
                                                 andSlaveURL:s];
        [a computeDeltaWithCompletionBlock:^(NSMutableDictionary *operationDictionary) {
            NSLog(@"\n%@",operationDictionary);
        }];
        
    }
    return 0;
}

