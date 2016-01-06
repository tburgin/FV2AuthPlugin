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
    assert([FV2MechanismHelper MechanismValid:_mechanism]);
    return self;
}

- (OSStatus)runMechanism {
    
    NSLog(@"FV2AuthPlugin:MechanismInvoke:AddUsers **************************");
    
    uid_t uid = [FV2MechanismHelper getUID:_mechanism];
    if (uid < 501) {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:AddUsers Skipping user [%u]", uid);
        OSStatus err = _mechanism->fPlugin->fCallbacks->
        SetResult(_mechanism->fEngine, kAuthorizationResultAllow);
        return err;
    }
    
    _connectionToService = [[NSXPCConnection alloc]
                            initWithServiceName:@"gov.nih.fde-service"];

    _connectionToService.remoteObjectInterface = [NSXPCInterface
                                                   interfaceWithProtocol:
                                                   @protocol(fde_serviceProtocol)];
    [_connectionToService resume];
    
    _username = [FV2MechanismHelper getUserName:_mechanism];
    _password = [FV2MechanismHelper getPassword:_mechanism];
    
    if (!_username || !_password) {
        NSLog(@"FV2AuthPlugin:[+] _username or _password is null");
        [self allowLogin];
    }
    
    NSLog(@"FV2AuthPlugin:[+] Okay. XPC Time");
    
    id remoteObject = [_connectionToService remoteObjectProxyWithErrorHandler:^(NSError *error) {
        NSLog(@"%@", [error description]);
        [self allowLogin];
    }];
    
    [remoteObject ODFDEAddUser:_username
                  withPassword:_password
                     withReply:^(BOOL reply) {
                         NSLog(@"FV2AuthPlugin:[+] ODFDEAddUser: %@", reply ? @"Success" : @"FAIL");
                         if (reply) {
                             NSLog(@"FV2AuthPlugin:[+] User [%@] added to FV2", _username);
                         }
                     }];
    NSLog(@"FV2AuthPlugin:[+] FV2AuthPluginMechanism is now complete.");
    NSLog(@"FV2AuthPlugin:[+] For more info follow the fde-service process.");
    OSStatus err = _mechanism->fPlugin->fCallbacks->
    SetResult(_mechanism->fEngine, kAuthorizationResultAllow);
    return err;
}

- (OSStatus)allowLogin {
    NSLog(@"FV2AuthPlugin:[+] Done. Thanks and have a lovely day.");
    
    [_connectionToService invalidate];

    OSStatus err = _mechanism->fPlugin->fCallbacks->
    SetResult(_mechanism->fEngine, kAuthorizationResultAllow);
    
    return err;
}

@end
