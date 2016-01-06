//
//  fde_service.m
//  fde-service
//
//  Created by Burgin, Thomas (NIH/CIT) [C] on 10/9/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import "fde_service.h"

@implementation fde_service

- (id)init {
    
    NSLog(@"FV2AuthPlugin:[+] fde_service init");
    
    self = [super init];
    if (self != nil) {
        
        // Open libcsfde.dylib.
        _libcsfdeHandle = dlopen("libcsfde.dylib", RTLD_LOCAL | RTLD_LAZY);
        if (!_libcsfdeHandle) {
            NSLog(@"FV2AuthPlugin:[!] Unable to load library: %s\n", dlerror());
        }
        
        // Open libodfde.dylib.
        _libodfdeHandle = dlopen("libodfde.dylib", RTLD_LOCAL | RTLD_LAZY);
        if (!_libodfdeHandle) {
            NSLog(@"FV2AuthPlugin:[!] Unable to load library: %s\n", dlerror());
        }
    }
    
    return self;
    
}

- (CFStringRef)CSFDEStorePassphrase:(NSString *)password {
    
    CFStringRef passwordRef = NULL;
    
    // Grab the CSFDEStorePassphrase symbol
    CFStringRef (*CSFDEStorePassphrase)(const char *) =
    dlsym(_libcsfdeHandle, "CSFDEStorePassphrase");
    
    if (!CSFDEStorePassphrase) {
        NSLog(@"FV2AuthPlugin:[!] Unable to get symbol: %s\n", dlerror());
        return passwordRef;
    }
    
    passwordRef = CSFDEStorePassphrase((const char *)[password UTF8String]);
    return passwordRef;
}

- (void)CSFDERemovePassphrase:(CFStringRef)passwordRef {
    
    // Grab the CSFDEStorePassphrase symbol
    void (*CSFDERemovePassphrase)(CFStringRef) =
    dlsym(_libcsfdeHandle, "CSFDERemovePassphrase");
    
    if (!CSFDERemovePassphrase) {
        NSLog(@"FV2AuthPlugin:[!] Unable to get symbol: %s\n", dlerror());
    }
    
    CSFDERemovePassphrase(passwordRef);
}

- (void)ODFDEAddUser:(NSString *)username
        withPassword:(NSString *)password
           withReply:(void (^)(BOOL))reply {
    
    // Check libHandles
    if (!_libcsfdeHandle || !_libodfdeHandle) {
        NSLog(@"FV2AuthPlugin:[!] libHandles not loaded");
        reply(false);
        return;
    }
    
    // Grab the ODFDEAddUser symbol
    BOOL (*ODFDEAddUser)(CFStringRef,
                         CFStringRef,
                         CFStringRef,
                         CFStringRef) = dlsym(_libodfdeHandle, "ODFDEAddUser");
    if (!ODFDEAddUser) {
        NSLog(@"FV2AuthPlugin:[!] Unable to get symbol: %s\n", dlerror());
        reply(false);
        return;
    }
    
    CFStringRef passwordRef = [self CSFDEStorePassphrase:password];
    
    // Try and add the user
    BOOL ret = ODFDEAddUser((__bridge CFStringRef)username,
                            passwordRef,
                            (__bridge CFStringRef)username,
                            passwordRef);
    
    if (passwordRef) {
        [self CSFDERemovePassphrase:passwordRef];
    }
    
    reply(ret);
}

@end
