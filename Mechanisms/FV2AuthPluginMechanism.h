//
//  FV2AuthPluginMechanism.h
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 5/7/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthorizationPlugin.h"
#import "MechanismHelper.h"
#include <dlfcn.h>

@interface FV2AuthPluginMechanism : NSObject

@property (strong) NSString *username;
@property (strong) NSString *password;
@property (strong) NSString *smartCardKeychain;
@property account_t accountType;
@property uid_t UID;

@property MechanismRecord *mechanism;
@property void *libcsfde_handle;
@property void *libodfde_handle;

- (id)initWithMechanism:(MechanismRecord*)inMechanism;

/**
 *  Mechanism for adding users to FV2
 *
 *  @param mechanism MechanismRecord
 *
 *  @return OSStatus
 */
- (OSStatus) runMechanism;

@end
