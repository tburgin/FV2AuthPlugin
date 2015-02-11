//
//  CreateLocalAdminUser.m
//  FV2AuthPlugin
//
// Copyright 2015 Thomas Burgin.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
