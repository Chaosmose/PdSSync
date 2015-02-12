//
//  PdSCommandInterpreter.h
//  PdSSync
//
//  Created by Benoit Pereira da Silva on 11/03/2014.
//
//

#import <Foundation/Foundation.h>
#import "PdSSync.h"

@class PdSSyncContext;
@class PdSCommandInterpreter;

@protocol PdSSyncFinalizationDelegate <NSObject>
-(void)readyForFinalization:(PdSCommandInterpreter*)reference;
-(void)progressMessage:(NSString*)message;
@end




extern NSString * const PdSSyncInterpreterWillFinalize;// Notification
extern NSString * const PdSSyncInterpreterHasFinalized;// Notification

@interface PdSCommandInterpreter : NSObject


@property (nonatomic)id<PdSSyncFinalizationDelegate>finalizationDelegate;

/**
 *  The current bunch of command.
 */
@property (nonatomic,readonly)NSArray*bunchOfCommand;

/**
 *  The context
 */
@property (nonatomic,readonly)PdSSyncContext *context;

/**
 *  The progress counter in percent.
 * ( Total command number / executed command ) + proportionnal progress on the current command
 */
@property (nonatomic,readonly)uint progressCounter;



/**
 *
 *
 *  @param bunchOfCommand  the bunch of command
 *  @param context         the interpreter context
 *  @param progressBlock   the progress block
 *  @param completionBlock te completion block
 *
 *  @return the interpreter
 */
+ (PdSCommandInterpreter*)interpreterWithBunchOfCommand:(NSArray*)bunchOfCommand
                                                context:(PdSSyncContext*)context
                                    progressBlock:(void(^)(uint taskIndex,float progress))progressBlock
                                     andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock;

/**
 *   The dedicated initializer.
 *
 *  @param bunchOfCommand  the bunch of command
 *  @param context         the interpreter context
 *  @param progressBlock   the progress block
 *  @param completionBlock te completion block
 *
 *  @return the interpreter
 */
- (instancetype)initWithBunchOfCommand:(NSArray*)bunchOfCommand
                               context:(PdSSyncContext*)context
                         progressBlock:(void(^)(uint taskIndex,float progress))progressBlock
                    andCompletionBlock:(void(^)(BOOL success,NSString*message))completionBlock;

/**
 * Called by the delegate to conclude the sequence of commands.
 */
- (void)finalize;


// Commands encoding returns the encoded command in the relevant format.
// Currently we use JSON, MsgPack could be supported soon.

+(id)encodeCreate:(NSString*)source destination:(NSString*)destination;
+(id)encodeUpdate:(NSString*)source destination:(NSString*)destination;
+(id)encodeCopy:(NSString*)source destination:(NSString*)destination;
+(id)encodeMove:(NSString*)source destination:(NSString*)destination;
+(id)encodeRemove:(NSString*)destination;

+ (NSMutableArray*)commandsFromDeltaPathMap:(DeltaPathMap*)deltaPathMap;


@end