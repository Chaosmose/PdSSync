//
//  PdSSync.h
//   PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//
//


typedef enum PdSSyncOperations {
    PdSCopy      = 0,
    PdSMove      = 1,
    PdSDelete    = 2
} PdSSyncOperation;

typedef enum PdSSyncOperationParams {
    PdSSource      = 0,
    PdSDestination = 1
} PdSSyncOperationParam;

#import "HashMap.h"
#import "DeltaPathMap.h"
#import "PdSAnalyzer.h"

