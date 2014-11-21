//
//  PdSSync.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//


// VERSION 1.0 Of the ObjC & PHP version

// ROAD MAP FOR THE VERSION 2.0

// 1- UNIX like permissions
// Permission applies to a tree

// A tree    ==     "trunk" [ branch :  [ leaf , branch : [ leaf, leaf ] ];
// 1 trunk   =      1 hashmap
// 1 trunk   =      1 owner (the creator)
// 1 owner  <->     N groups


// 2- Gonna support server sent events :
// http://en.wikipedia.org/wiki/Server-sent_events
// http://nshipster.com/afnetworking-2/ real time http://rocket.github.io
// Check : https://github.com/licson0729/libSSE-php
// Check : http://stackoverflow.com/questions/14564903/server-sent-events-and-php-what-triggers-events-on-the-server


// 3- Discreet doer, undoer

// Each leaf can historizized [ state : [ [ doer , undoer ] , ... ]
// we use for history : state, .PdSync/<relativepath>/counter , .PdSync/<relativepath>/history/0000000001.doer,000000001.undoer


// 4-SourceIsDistantDestinationIsDistant


// 5- Message pack


// Encoding

typedef NS_ENUM (NSUInteger,
                  PdSSyncCommand) {
    PdSCreateOrUpdate   = 0 , // W destination and source
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

typedef NS_ENUM (NSUInteger,
                 PdSSyncMode) {
    SourceIsLocalDestinationIsDistant   = 0 ,
    SourceIsDistantDestinationIsLocal   = 1 ,
    SourceIsLocalDestinationIsLocal     = 2 ,
    SourceIsDistantDestinationIsDistant = 3 // currently not supported 
};


// The extension for a single file hash
#define kPdSSyncHashFileExtension @("hash")

// The global hash map name
#define kPdSSyncHashMashMapFileName @("hashMap")

// The metadata folder
#define kPdSSyncMetadataFolder @(".PdSSync/")

#import "PdSFileManager.h"
#import "HashMap.h"
#import "DeltaPathMap.h"
#import "PdSCommandInterpreter.h"
#import "PdSLocalAnalyzer.h"
#import "PdSSyncContext.h"
#import "PdSSyncAdmin.h"

// PdSCommons 
#import "NSData+CRC.h"
#import "NSString+PdSFacilities.h"


