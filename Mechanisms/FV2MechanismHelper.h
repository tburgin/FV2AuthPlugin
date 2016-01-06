/*
 
    FV2AuthPlugin
    Copyright © NIH. All rights reserved.
    Republication or redistribution of NIH content is prohibited without the 
    prior written consent of NIH.
    Created by Burgin, Thomas (NIH/NIMH) [C]

*/

#import <Foundation/Foundation.h>
#import <DirectoryService/DirectoryService.h>
#import "FV2AuthorizationPlugin.h"

@interface FV2MechanismHelper : NSObject
/**
 *  Checks to make sure the Mechanism is valid
 *
 *  @param mechanism MechanismRecord
 *
 *  @return BOOL
 */
+ (BOOL)MechanismValid:(const MechanismRecord *)mechanism;

/**
 *  Gets the authenticating account type
 *
 *  @param inMechanism AuthorizationMechanismRef
 *
 *  @return account_t
 */
+ (account_t)getAccountType:(AuthorizationMechanismRef)inMechanism;

/**
 *  Gets the authenticating username
 *
 *  @param inMechanism AuthorizationMechanismRef
 *
 *  @return NSString
 */
+ (NSString *)getUserName:(AuthorizationMechanismRef)inMechanism;

/**
 *  Gets the authenticating user's password
 *
 *  @param inMechanism AuthorizationMechanismRef
 *
 *  @return NSString
 */
+ (NSString *)getPassword:(AuthorizationMechanismRef)inMechanism;

/**
 *  Gets the authenticating TokenName (SmartCard Keychain Name)
 *
 *  @param inMechanism AuthorizationMechanismRef
 *
 *  @return NSString
 */
+ (NSString *)getTokenName:(AuthorizationMechanismRef) inMechanism;

/**
 *  Gets the authenticating UID
 *
 *  @param inMechanism AuthorizationMechanismRef
 *
 *  @return uid_t
 */
+ (uid_t)getUID:(AuthorizationMechanismRef) inMechanism;

/**
 *  Gets the authenticating GID
 *
 *  @param inMechanism AuthorizationMechanismRef
 *
 *  @return gid_t
 */
+ (gid_t)getGID:(AuthorizationMechanismRef) inMechanism;

@end
