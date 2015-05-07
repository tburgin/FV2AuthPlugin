//
//  FV2AuthPluginMechanism.m
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 5/7/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import "FV2AuthPluginMechanism.h"

@implementation FV2AuthPluginMechanism

+ (OSStatus) runMechanism:(MechanismRecord*)mechanism {
    
    NSLog(@"FV2AuthPlugin:MechanismInvoke:AddUsers *************************************");
    OSStatus err;
    const AuthorizationValue *value;
    AuthorizationContextFlags   flags;
    CFStringRef username;
    CFStringRef password;
    
    // Get auth user username
    err = noErr;
    err = mechanism->fPlugin->fCallbacks->GetContextValue(mechanism->fEngine, kAuthorizationEnvironmentUsername, &flags, &value);
    if (err == noErr) {
        username = CFStringCreateWithCString(NULL, (const char *) value->data, kCFStringEncodingUTF8);
    } else {
        err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);
        return err;
    }
    
    // Get auth user password
    err = noErr;
    err = mechanism->fPlugin->fCallbacks->GetContextValue(mechanism->fEngine, kAuthorizationEnvironmentPassword, &flags, &value);
    if (err == noErr) {
        password = CSFDEStorePassphrase((const char *) value->data);
    } else {
        err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);
        return err;
    }
    
    // Define temp's username and password
    NSString *temp_admin_username = @"fv2authplugin";
    NSString *temp_password = @"password123";
    
    // Create a temp admin account
    CreateLocalAdminUser *createLocalAdminUser = [[CreateLocalAdminUser alloc] init];
    BOOL ret = [createLocalAdminUser createRecord:temp_admin_username tempPassword:temp_password];
    
    if (ret == 0) {
        NSLog(@"Failed to create authenticating admin account. Exiting");
        err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);
        return err;
    }
    
    CFStringRef user_auth = CFStringCreateWithCString(NULL, (const char *)[temp_admin_username UTF8String], kCFStringEncodingUTF8);
    CFStringRef pass_auth = CSFDEStorePassphrase((const char *)[temp_password UTF8String]);
    
    NSLog(@"ODFDEAddUser [%hhd]", ODFDEAddUser(user_auth, pass_auth, username, password));
    
    // Delete the temp admin user
    [createLocalAdminUser destoryCreatedRecord];
    
    NSLog(@"Done. Exiting");
    err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);
    return err;

}

@end
