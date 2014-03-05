//
//  PdSSync.h
//   PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//

// UNIX like permissions
// Permission applies to a tree

// A tree    ==     "trunk" [ branch :  [ leaf , branch : [ leaf, leaf ] ];
// 1 trunk   =      1 hashmap
// 1 trunk   =      1 owner (the creator)
// 1 owner  <->     N groups

// Each leaf can historizized [ state : [ [ doer , undoer ] , ... ]
// we use for history : state, .PdSync/<relativepath>/counter , .PdSync/<relativepath>/history/0000000001.doer,000000001.undoer


// Encoding

typedef NS_ENUM (NSUInteger,
                  PdSSyncCommand) {
    PdSCreateOrUpdate   = 0 , // W destination or source
    PdSCopy             = 1 , // R source W destination
    PdSMove             = 2 , // R source W destination
    PdSDelete           = 3 , // W source
} ;

typedef NS_ENUM(NSUInteger,
                PdSSyncCMDParam) {
    PdSDestination = 0,
    PdSSource      = 1
} ;


typedef NS_ENUM (NSUInteger,
                 PdSAdminCommand) {
    PdsSanitize    = 4 , // X on tree
    PdSChmod       = 5 , // X on tree
    PdSForget      = 6 , // X on tree
} ;

typedef NS_ENUM(NSUInteger,
                PdSAdminCMDParam) {
    PdSPoi         = 0,
    PdSDepth       = 1,
    PdSValue       = 2
} ;


typedef NS_ENUM(NSUInteger,
                PdSSyncPrivilege) {
    R_OWNER     = 400 ,
    W_OWNER     = 200 ,
    X_OWNER     = 100 ,
    R_GROUP     =  40 ,
    W_GROUP     =  20 ,
    X_GROUP     =  10 ,
    R_OTHER     =   4 ,
    W_OTHER     =   2 ,
    X_OTHER     =   1
} ;



#import "HashMap.h"
#import "DeltaPathMap.h"
#import "PdSAnalyzer.h"