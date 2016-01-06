/*
 
    FV2AuthPluginPlugin
    Copyright © NIH. All rights reserved.
    Republication or redistribution of NIH content is prohibited without the
    prior written consent of NIH.
    Created by Burgin, Thomas (NIH/NIMH) [C]

*/

#import "FV2MechanismHelper.h"

@implementation FV2MechanismHelper

+ (BOOL)MechanismValid:(const MechanismRecord *)mechanism {
    return (mechanism != NULL)
    && (mechanism->fMagic == kMechanismMagic)
    && (mechanism->fEngine != NULL)
    && (mechanism->fPlugin != NULL);
}

+ (account_t)getAccountType:(AuthorizationMechanismRef)inMechanism {
    
    NSLog(@"FV2AuthPlugin:MechanismInvoke:getAccountType [+] Attempting to check the Account Type");
    
    MechanismRecord *mechanism;
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    OSStatus                    err;
    int                         accountType;
    NSDictionary                *authData;
    const AuthorizationValue    *value;
    AuthorizationContextFlags   flags;
    CFDataRef                   data = NULL;
    CFPropertyListRef           propList = NULL;
    
    // Define default account type
    accountType = kUnknownAccountType;
    
    // Get kDSNAttrAuthenticationAuthority for the Authenticating User
    err = noErr;
    NSLog(@"FV2AuthPlugin:MechanismInvoke:getAccountType [+] Attempting to receive kDSNAttrAuthenticationAuthority.");
    
    err = mechanism->fPlugin->fCallbacks->
    GetContextValue(mechanism->fEngine,
                    kDSNAttrAuthenticationAuthority,
                    &flags, &value);
    
    if (err == noErr) {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getAccountType [+] kDSNAttrAuthenticationAuthority received. Attempting plist to dict.");
    } else {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getAccountType [!] kDSNAttrAuthenticationAuthority was unreadable.");
        return accountType;
    }
    
    // Convert and read. We can then determine account type.
    // Currently LocalCachedUser, NetLogon, @LKDC are all
    // mutually exclusive. If this changes or if your environment is
    // different, the algorithm below will need to be modified.
    data = CFDataCreate(NULL, value->data, value->length);
    if (data != NULL) {
        propList = CFPropertyListCreateFromXMLData(NULL,
                                                   data,
                                                   kCFPropertyListImmutable,
                                                   NULL);
        if (propList != NULL) {
            authData = (__bridge NSDictionary *)propList;
            for (NSString * e in authData) {
                if ([e rangeOfString:@";LocalCachedUser;"].location !=
                    NSNotFound) {
                    NSLog(@"FV2AuthPlugin:MechanismInvoke:getAccountType [+] Account Type is kMobile");
                    accountType = kMobile;
                    break;
                }
                else if ([e rangeOfString:@";NetLogon;"].location != \
                         NSNotFound) {
                    NSLog(@"FV2AuthPlugin:MechanismInvoke:getAccountType [+] Account Type is kNetwork");
                    accountType = kNetwork;
                    break;
                }
                else if ([e rangeOfString:@"@LKDC"].location != NSNotFound) {
                    NSLog(@"FV2AuthPlugin:MechanismInvoke:getAccountType [+] Account Type is kLocal");
                    accountType = kLocal;
                    break;
                }
            }
        }
    }
    
    if (data) CFRelease(data);
    if (propList) CFRelease(propList);
    
    return accountType;

}
+ (NSString *)getUserName:(AuthorizationMechanismRef)inMechanism {
    MechanismRecord *mechanism;
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    OSStatus                    err;
    const AuthorizationValue    *value;
    AuthorizationContextFlags   flags;
    NSString                    *userName = NULL;
    
    // Get the AuthorizationEnvironmentUsername
    err = noErr;
    NSLog(@"FV2AuthPlugin:MechanismInvoke:getUserName [+] Attempting to receive kAuthorizationEnvironmentUsername");
    
    err = mechanism->fPlugin->fCallbacks->
    GetContextValue(mechanism->fEngine,
                    kAuthorizationEnvironmentUsername,
                    &flags, &value);
    
    if ((err == noErr) && (value->length > 0) && (value->data != NULL)) {
        userName = [[NSString alloc] initWithBytes:value->data
                                            length:value->length
                                          encoding:NSUTF8StringEncoding];
        userName = [userName stringByReplacingOccurrencesOfString:@"\0" withString:@""];
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getUserName [+] kAuthorizationEnvironmentUsername [%@] was used.", userName);
    } else {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getUserName [!] kAuthorizationEnvironmentUsername was unreadable.");
    }
    
    return userName;

}
+ (NSString *)getPassword:(AuthorizationMechanismRef)inMechanism {
    MechanismRecord *mechanism;
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    OSStatus                    err;
    const AuthorizationValue    *value;
    AuthorizationContextFlags   flags;
    NSString                    *password = NULL;
    
    // Get the kAuthorizationEnvironmentPassword
    err = noErr;
    NSLog(@"FV2AuthPlugin:MechanismInvoke:getUserName [+] Attempting to receive kAuthorizationEnvironmentUsername");
    
    err = mechanism->fPlugin->fCallbacks->
    GetContextValue(mechanism->fEngine,
                    kAuthorizationEnvironmentPassword,
                    &flags, &value);
    
    if ((err == noErr) && (value->length > 0) && (value->data != NULL)) {
        password = [[NSString alloc] initWithBytes:value->data
                                            length:value->length
                                          encoding:NSUTF8StringEncoding];
        password = [password stringByReplacingOccurrencesOfString:@"\0" withString:@""];
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getUserName [+] kAuthorizationEnvironmentPassword received.");
    } else {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getUserName [!] kAuthorizationEnvironmentPassword was unreadable.");
    }
    
    return password;
    
}
+ (NSString *)getTokenName:(AuthorizationMechanismRef) inMechanism {
    MechanismRecord *mechanism;
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    OSStatus                    err;
    const AuthorizationValue    *value;
    NSString                    *tokenName = NULL;
    
    err = noErr;
    NSLog(@"FV2AuthPlugin:MechanismInvoke:getUserName [+] Attempting to receive the authenticating SmartCard Keychain");
    
    err = mechanism->fPlugin->fCallbacks->
    GetHintValue(mechanism->fEngine, "token-name", &value);
    
    if ((err == noErr) && (value->length > 0) && (value->data != NULL)) {
        tokenName = [[NSString alloc] initWithBytes:value->data
                                             length:value->length
                                           encoding:NSUTF8StringEncoding];
        tokenName = [tokenName stringByReplacingOccurrencesOfString:@"\0" withString:@""];
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getTokenName: [+] Success. SmartCard Keychain [%@] was used.", tokenName);
    } else {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getTokenName: [!] token-name was unreadable");
    }
    
    return tokenName;

}
+ (uid_t)getUID:(AuthorizationMechanismRef) inMechanism {
    MechanismRecord *mechanism;
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    OSStatus                    err;
    const AuthorizationValue    *value;
    AuthorizationContextFlags   flags;
    uid_t uid = (uid_t) -2;

    err = noErr;
    err = mechanism->fPlugin->fCallbacks->GetContextValue(mechanism->fEngine,
                                                          "uid",
                                                          &flags, &value);
    if ((err == noErr) && (value->length == sizeof(uid_t))) {
        uid = *(const uid_t *) value->data;
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getUID [+] uid: [%u] Retrieved", uid);
    } else {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getUID [!] Error Retrieving the authenticating uid");
    }
    
    return uid;

}
+ (gid_t)getGID:(AuthorizationMechanismRef) inMechanism {
    MechanismRecord *mechanism;
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    OSStatus                    err;
    const AuthorizationValue    *value;
    AuthorizationContextFlags   flags;
    gid_t gid = (uid_t) -2;
    
    err = noErr;
    err = mechanism->fPlugin->fCallbacks->GetContextValue(mechanism->fEngine,
                                                          "gid",
                                                          &flags, &value);
    if ( (err == noErr) && (value->length == sizeof(gid_t))) {
        gid = *(const uid_t *) value->data;
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getGID [+] gid: [%u] Retrieved", gid);
    } else {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getGID [!] Error Retrieving the authenticating gid");
        NSLog(@"FV2AuthPlugin:MechanismInvoke:getGID [!] Error: [%d]", (int)err);
    }
    
    return gid;
    
}

@end
