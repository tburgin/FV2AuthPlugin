//
//  AuthorizationPlugin.m
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 5/5/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import "AuthorizationPlugin.h"

#pragma mark
#pragma mark Entry Points Wrappers

static OSStatus PluginDestroy(AuthorizationPluginRef inPlugin) {
    return [AuthorizationPlugin PluginDestroy:inPlugin];
}

static OSStatus MechanismCreate(AuthorizationPluginRef inPlugin, AuthorizationEngineRef inEngine, AuthorizationMechanismId mechanismId, AuthorizationMechanismRef *outMechanism) {
    return [AuthorizationPlugin MechanismCreate:inPlugin EngineRef:inEngine MechanismId:mechanismId MechanismRef:outMechanism];
}

static OSStatus MechanismInvoke(AuthorizationMechanismRef inMechanism) {
    return [AuthorizationPlugin MechanismInvoke:inMechanism];
}

static OSStatus MechanismDeactivate(AuthorizationMechanismRef inMechanism) {
    return [AuthorizationPlugin MechanismDeactivate:inMechanism];
}

static OSStatus MechanismDestroy(AuthorizationMechanismRef inMechanism) {
    return [AuthorizationPlugin MechanismDestroy:inMechanism];
}

static AuthorizationPluginInterface gPluginInterface = {
    kAuthorizationPluginInterfaceVersion,
    &PluginDestroy,
    &MechanismCreate,
    &MechanismInvoke,
    &MechanismDeactivate,
    &MechanismDestroy
};

extern OSStatus AuthorizationPluginCreate(const AuthorizationCallbacks *callbacks, AuthorizationPluginRef *outPlugin, const AuthorizationPluginInterface **outPluginInterface) {
    return [AuthorizationPlugin AuthorizationPluginCreate:callbacks PluginRef:outPlugin PluginInterface:outPluginInterface];
}

#pragma mark
#pragma mark AuthorizationPlugin Implementation

@implementation AuthorizationPlugin

+ (OSStatus) MechanismInvoke:(AuthorizationMechanismRef)inMechanism {
    OSStatus                    err;
    MechanismRecord *           mechanism;
    
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);

    
#pragma mark
#pragma mark AddUsers Mech
    
    if (mechanism->fAddUsers) {
        NSLog(@"FV2AuthPlugin:MechanismInvoke:AddUsers *************************************");
        
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
        
    }
    
    err = mechanism->fPlugin->fCallbacks->SetResult(mechanism->fEngine, kAuthorizationResultAllow);
    return err;
    
}

#pragma mark
#pragma mark Authorization Plugin Methods. No need to edit below.


+ (BOOL) MechanismValid:(const MechanismRecord *)mechanism {
    return (mechanism != NULL)
    && (mechanism->fMagic == kMechanismMagic)
    && (mechanism->fEngine != NULL)
    && (mechanism->fPlugin != NULL);
}

+ (BOOL) PluginValid:(const PluginRecord *)plugin {
    return (plugin != NULL)
    && (plugin->fMagic == kPluginMagic)
    && (plugin->fCallbacks != NULL)
    && (plugin->fCallbacks->version >= kAuthorizationCallbacksVersion);
}

+ (OSStatus) MechanismCreate:(AuthorizationPluginRef)inPlugin
                   EngineRef:(AuthorizationEngineRef)inEngine
                 MechanismId:(AuthorizationMechanismId)mechanismId
                MechanismRef:(AuthorizationMechanismRef *)outMechanism {
    
    OSStatus            err;
    PluginRecord *      plugin;
    MechanismRecord *   mechanism;
    
    plugin = (PluginRecord *) inPlugin;
    assert([self PluginValid:plugin]);
    assert(inEngine != NULL);
    assert(mechanismId != NULL);
    assert(outMechanism != NULL);
    
    err = noErr;
    mechanism = (MechanismRecord *) malloc(sizeof(*mechanism));
    if (mechanism == NULL) {
        err = memFullErr;
    }
    
    if (err == noErr) {
        mechanism->fMagic = kMechanismMagic;
        mechanism->fEngine = inEngine;
        mechanism->fPlugin = plugin;
        mechanism->fAddUsers = (strcmp(mechanismId, "add-users") == 0);
    }
    
    *outMechanism = mechanism;
    
    assert( (err == noErr) == (*outMechanism != NULL) );
    
    return err;

}

+ (OSStatus) MechanismDeactivate:(AuthorizationMechanismRef)inMechanism {
    OSStatus            err;
    MechanismRecord *   mechanism;
    
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    err = mechanism->fPlugin->fCallbacks->DidDeactivate(mechanism->fEngine);
    
    return err;
}

+ (OSStatus) MechanismDestroy:(AuthorizationMechanismRef)inMechanism {
    MechanismRecord *   mechanism;
    
    mechanism = (MechanismRecord *) inMechanism;
    assert([self MechanismValid:mechanism]);
    
    free(mechanism);
    
    return noErr;

}

+ (OSStatus) PluginDestroy:(AuthorizationPluginRef)inPlugin {
    PluginRecord *  plugin;
    
    plugin = (PluginRecord *) inPlugin;
    assert([self PluginValid:plugin]);
    
    free(plugin);
    
    return noErr;
}

+ (OSStatus) AuthorizationPluginCreate:(const AuthorizationCallbacks *)callbacks
                             PluginRef:(AuthorizationPluginRef *)outPlugin
                       PluginInterface:(const AuthorizationPluginInterface **)outPluginInterface {
    
    OSStatus        err;
    PluginRecord *  plugin;
    
    assert(callbacks != NULL);
    assert(callbacks->version >= kAuthorizationCallbacksVersion);
    assert(outPlugin != NULL);
    assert(outPluginInterface != NULL);
    
    // Create the plugin.
    err = noErr;
    plugin = (PluginRecord *) malloc(sizeof(*plugin));
    if (plugin == NULL) {
        err = memFullErr;
    }
    
    // Fill it in.
    if (err == noErr) {
        plugin->fMagic     = kPluginMagic;
        plugin->fCallbacks = callbacks;
    }
    
    *outPlugin = plugin;
    *outPluginInterface = &gPluginInterface;
    
    assert( (err == noErr) == (*outPlugin != NULL) );
    
    return err;
    
}


@end
