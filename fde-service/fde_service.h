//
//  fde_service.h
//  fde-service
//
//  Created by Burgin, Thomas (NIH/CIT) [C] on 10/9/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "fde_serviceProtocol.h"
#include <dlfcn.h>

@interface fde_service : NSObject <fde_serviceProtocol>

@property void *libcsfdeHandle;
@property void *libodfdeHandle;

@end
