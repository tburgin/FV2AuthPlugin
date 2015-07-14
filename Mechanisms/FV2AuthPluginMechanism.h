//
//  FV2AuthPluginMechanism.h
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 5/7/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AuthorizationPlugin.h"
#include <dlfcn.h>

@interface FV2AuthPluginMechanism : NSObject
/**
 *  Mechanism for adding users to FV2
 *
 *  @param mechanism MechanismRecord
 *
 *  @return OSStatus
 */
+ (OSStatus) runMechanism:(MechanismRecord*)mechanism;

@end
