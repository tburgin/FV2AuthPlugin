//
//  fde_serviceProtocol.h
//  fde-service
//
//  Created by Burgin, Thomas (NIH/CIT) [C] on 10/9/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol fde_serviceProtocol

- (void)ODFDEAddUser:(NSString *)username
        withPassword:(NSString *)password
           withReply:(void (^)(BOOL))reply;

@end

