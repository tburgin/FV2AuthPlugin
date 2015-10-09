//
//  FV2AuthPluginMechanism.m
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 5/7/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import "FV2AuthPluginMechanism.h"

@implementation FV2AuthPluginMechanism

- (id)initWithMechanism:(MechanismRecord *)inMechanism {
    NSLog(@"FV2AuthPlugin:MechanismInvoke: inMechanism=%p", inMechanism);
    _mechanism = (MechanismRecord *) inMechanism;
    assert([MechanismHelper MechanismValid:_mechanism]);
    return self;
}

- (OSStatus) runMechanism {
    
    NSLog(@"FV2AuthPlugin:MechanismInvoke:AddUsers **************************");
    
    // Open libcsfde.dylib.
    _libcsfde_handle = dlopen("libcsfde.dylib", RTLD_LOCAL | RTLD_LAZY);
    if (!_libcsfde_handle) {
        NSLog(@"FV2AuthPlugin:[!] [%s] Unable to load library: %s\n",
              __FILE__, dlerror());
        return [self allowLogin];
    }
    
    // Open libodfde.dylib.
    _libodfde_handle = dlopen("libodfde.dylib", RTLD_LOCAL | RTLD_LAZY);
    if (!_libodfde_handle) {
        NSLog(@"FV2AuthPlugin:[!] [%s] Unable to load library: %s\n",
              __FILE__, dlerror());
        return [self allowLogin];
    }
    
    _username = [MechanismHelper getUserName:_mechanism];
    _password = [MechanismHelper getPassword:_mechanism];
    
    if (!_username || !_password) {
        return [self allowLogin];
    }
    
    CFStringRef passwordRef = [self CSFDEStorePassphrase:_password];
    
    [self ODFDEAddUser:(__bridge CFStringRef)_username
          withPassword:passwordRef];
    
    if (passwordRef) {
        [self CSFDERemovePassphrase:passwordRef];
    }
    
    return [self allowLogin];
}

- (CFStringRef) CSFDEStorePassphrase:(NSString *)password {
    
    CFStringRef passwordRef = NULL;
    
    // Grab the CSFDEStorePassphrase symbol
    CFStringRef (*CSFDEStorePassphrase)(const char *) =
    dlsym(_libcsfde_handle, "CSFDEStorePassphrase");
    
    if (!CSFDEStorePassphrase) {
        NSLog(@"FV2AuthPlugin:[!] [%s] Unable to get symbol: %s\n",
              __FILE__, dlerror());
        [self allowLogin];
        return passwordRef;
    }
    
    passwordRef = CSFDEStorePassphrase((const char *)[password UTF8String]);
    
    return passwordRef;
}

- (void) CSFDERemovePassphrase:(CFStringRef)passwordRef {
    
    // Grab the CSFDEStorePassphrase symbol
    void (*CSFDERemovePassphrase)(CFStringRef) =
    dlsym(_libcsfde_handle, "CSFDERemovePassphrase");
    
    if (!CSFDERemovePassphrase) {
        NSLog(@"FV2AuthPlugin:[!] [%s] Unable to get symbol: %s\n",
              __FILE__, dlerror());
        [self allowLogin];
    }
    
    CSFDERemovePassphrase(passwordRef);
}

- (BOOL) ODFDEAddUser:(CFStringRef)usernameRef
         withPassword:(CFStringRef)passwordRef {
    
    // Grab the ODFDEAddUser symbol
    BOOL (*ODFDEAddUser)(CFStringRef,
                         CFStringRef,
                         CFStringRef,
                         CFStringRef) = dlsym(_libodfde_handle, "ODFDEAddUser");
    if (!ODFDEAddUser) {
        NSLog(@"FV2AuthPlugin:[!] [%s] Unable to get symbol: %s\n",
              __FILE__, dlerror());
        [self allowLogin];
    }
    
    // Try and add the user
    BOOL ret = ODFDEAddUser(usernameRef, passwordRef, usernameRef, passwordRef);
    
    if (ret) {
        NSLog(@"FV2AuthPlugin:[+] Success [%@] added to FV2",
              (__bridge NSString*)usernameRef);
    } else {
        NSLog(@"FV2AuthPlugin:[!] FAIL. User [%@] NOT added to FV2",
              (__bridge NSString*)usernameRef);
    }
    
    return ret;
}

- (OSStatus)allowLogin {
    NSLog(@"FV2AuthPlugin:[+] Done. Thanks and have a lovely day.");
    OSStatus err =
    
    _mechanism->
    fPlugin->
    fCallbacks->
    SetResult(_mechanism->fEngine, kAuthorizationResultAllow);
    
    return err;
}

- (BOOL) addUserToFV:(NSString*)user withPassword:(NSString*)pass {
    return true;
}

@end
