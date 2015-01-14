//
//  PdSSyncContext.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 13/03/2014.
//
//

#import <Foundation/Foundation.h>
#import "PdSSync.h"

@interface PdSSyncContext : NSObject


@property (nonatomic,strong)FilesHashMap *finalHashMap;


@property (nonatomic,readonly)NSString*sourceTreeId;
@property (nonatomic,readonly)NSString*destinationTreeId;

@property (nonatomic,readonly)NSURL*sourceBaseUrl;
@property (nonatomic,readonly)NSURL*destinationBaseUrl;

// A unique sync identifier
@property (nonatomic,readonly)NSString*syncID;

// Informational properties

@property (nonatomic)int numberOfCompletedCommands;
@property (nonatomic)int numberOfCommands;


@property (nonatomic)BOOL autoCreateTrees;

// Additional properties
// Usable for acl and credentials and security

@property (nonatomic,copy)NSString*name;
@property (nonatomic,copy)NSString*token;
@property (nonatomic,copy)NSString*creationKey;
@property (nonatomic)int groupID;
@property (nonatomic)int userID;


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
                  andDestinationUrl:(NSURL*)destinationUrl;


- (BOOL)isValid;

- (PdSSyncMode)mode;


@end