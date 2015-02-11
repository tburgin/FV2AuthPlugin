//
//  CreateLocalAdminUser.m
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 2/10/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import "CreateLocalAdminUser.h"

@implementation CreateLocalAdminUser
@synthesize group, myRecord;

- (BOOL)createRecord:(NSString *)user_name tempPassword:(NSString *)temp_password {
    
    NSError *err = NULL;
    ODSession *mySession = [ODSession defaultSession];
    ODNode *myNode = [ODNode nodeWithSession:mySession name:@"/Local/Default" error:&err];
    NSLog(@"Attempting to create user [%@]", user_name);
    group = [myNode recordWithRecordType:kODRecordTypeGroups name:@"admin" attributes:nil error:nil];
    myRecord = [myNode createRecordWithRecordType:kODRecordTypeUsers name:user_name attributes:nil error:&err];
    
    if (err != NULL) {
        
        err = NULL;
        NSLog(@"Failed. Trying to delete any local user named [%@]", user_name);
        myRecord = [myNode recordWithRecordType:kODRecordTypeUsers name:user_name attributes:nil error:&err];
        
        if (err != NULL) {
            NSLog(@"Failed. Exiting the method");
            return false;
        }
        
        [group removeMemberRecord:myRecord error:nil];
        err = NULL;
        [myRecord deleteRecordAndReturnError:&err];
        
        if (err != NULL) {
            NSLog(@"Failed. Exiting the method");
            return false;
        }
        
        err = NULL;
        NSLog(@"Attempting to create user [%@]", user_name);
        myRecord = [myNode createRecordWithRecordType:kODRecordTypeUsers name:user_name attributes:nil error:&err];
        
        if (err != NULL) {
            NSLog(@"Failed. Exiting the method");
            return false;
        }
        
    }
    
    err = NULL;
    [myRecord changePassword:nil toPassword:temp_password error:&err];
    
    if (err != NULL) {
        NSLog(@"Failed to set password. Exiting the method");
        return false;
    }
    
    
    [group addMemberRecord:myRecord error:&err];

    
    return true;
}



- (void) destoryCreatedRecord {
    
    [group removeMemberRecord:myRecord error:nil];
    [myRecord deleteRecordAndReturnError:nil];

}

@end
