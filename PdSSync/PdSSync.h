//
//  PdSSync.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 15/02/2014.
//

// VERSION 1.0 Of the ObjC & PHP version

// IDEAS FOR THE NEXT VERSIONS

// 0- Currently the sync is oriented : source -> destination
// Support unoriented sync ?

// 1- Support SourceIsDistantDestinationIsDistant

// 2- Homologuous P2P sync

typedef NS_ENUM (NSUInteger,
                  PdSSyncCommand) {
    PdSCreateOrUpdate   = 0 , // W destination and source
    PdSCopy             = 1 , // R source W destination
    PdSMove             = 2 , // R source W destination
    PdSDelete           = 3 , // W source
} ;


typedef NS_ENUM(NSUInteger,
                PdSSyncCMDParamRank) {
    PdSCommand     = 0,
    PdSDestination = 1,
    PdSSource      = 2
} ;


typedef NS_ENUM (NSUInteger,
                 PdSSyncMode) {
    SourceIsLocalDestinationIsDistant   = 0 ,
    SourceIsDistantDestinationIsLocal   = 1 ,
    SourceIsLocalDestinationIsLocal     = 2 ,
    SourceIsDistantDestinationIsDistant = 3 // currently not supported 
};

#define kPdSSyncModeStrings @[\
                                @("SourceIsLocalDestinationIsDistant"),\
                                @("SourceIsDistantDestinationIsLocal"),\
                                @("SourceIsLocalDestinationIsLocal"),\
                                @("SourceIsDistantDestinationIsDistant")\
                            ]


// The extension for a single file hash
#define kPdSSyncHashFileExtension @("hash")

// The global hash map name
#define kPdSSyncHashMashMapFileName @("hashMap")

// The metadata folder
#define kPdSSyncMetadataFolder @(".PdSSync/")

// A prefix used to identify easyly a prefixed file.
#define kPdSSyncPrefixSignature @(".PdSSync")

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


