//
//  CreateLocalAdminUser.h
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 2/10/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenDirectory/OpenDirectory.h>


@interface CreateLocalAdminUser : NSObject

- (BOOL) createRecord:(NSString *)user_name tempPassword:(NSString*)temp_password;
- (void) destoryCreatedRecord;

@property (nonatomic, retain) ODRecord *group;
@property (nonatomic, retain) ODRecord *myRecord;


@end
