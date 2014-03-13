//
//  PdSSyncContext.h
//  Pods
//
//  Created by Benoit Pereira da Silva on 13/03/2014.
//
//

#import <Foundation/Foundation.h>
#import "PdSSync.h"

@interface PdSSyncContext : NSObject


@property (nonatomic,readonly)HashMap *finalHashMap;

// Treeid are extracted from the distant url only.
@property (nonatomic,readonly)NSString*sourceTreeId;
@property (nonatomic,readonly)NSString*destinationTreeId;

// Informational properties

@property (nonatomic)int numberOfCompletedCommands;
@property (nonatomic)int numberOfCommands;


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
 *  for example     : http://PdsSync.api.local/api/v1/tree/unique-public-id-1293
 *  or              : file://localfilepathToTheFileTreeFolder/
 *
 *  If the url is distant we extract the tree id.
 *
 *
 *  @param finalHashMap   finalHashMap description
 *  @param sourceUrl      sourceUrl description
 *  @param destinationUrl destinationUrl description
 *
 *  @return returns the context
 */
-(instancetype)initWithFinalHashMap:(HashMap*)finalHashMap
                          sourceURL:(NSURL*)sourceUrl
                  andDestinationUrl:(NSURL*)destinationUrl;


- (BOOL)isValid;

- (PdSSyncMode)mode;


@end