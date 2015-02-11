//
//  Main.m
//  FV2AuthPlugin
//
//  Created by Burgin, Thomas (NIH/NIMH) [C] on 2/10/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreServices/CoreServices.h>
#include <DirectoryService/DirectoryService.h>
#include <Security/AuthorizationPlugin.h>
#include <Security/AuthSession.h>
#include <Security/AuthorizationTags.h>

#import "CreateLocalAdminUser.h"

#pragma mark ***** Define External FDE fuctions


extern CFStringRef CSFDEStorePassphrase(const char* password);
extern BOOL ODFDEAddUser(CFStringRef authuser, CFStringRef authpass, CFStringRef username, CFStringRef password);



#pragma mark ***** Core Data Structures

typedef struct PluginRecord PluginRecord;           // forward decl

#pragma mark *     Mechanism

// MechanismRecord is the per-mechanism data structure.  One of these
// is created for each mechanism that's instantiated, and holds all
// of the data needed to run that mechanism.  In this trivial example,
// that data set is very small.
//
// Mechanisms are single threaded; the code does not have to guard
// against multiple threads running inside the mechanism simultaneously.

enum {
    kMechanismMagic = 'Mchn'
};

struct MechanismRecord {
    OSType                          fMagic;         // must be kMechanismMagic
    AuthorizationEngineRef          fEngine;
    const PluginRecord *            fPlugin;
    Boolean                         fWaitForDebugger;
    Boolean                         fAddUsers;
};
typedef struct MechanismRecord MechanismRecord;

static Boolean MechanismValid(const MechanismRecord *mechanism)
{
    return (mechanism != NULL)
    && (mechanism->fMagic == kMechanismMagic)
    && (mechanism->fEngine != NULL)
    && (mechanism->fPlugin != NULL);
}




#pragma mark *     Plugin

// PluginRecord is the per-plugin data structure.  As the system only
// instantiates a plugin once per plugin host, this information could
// just as easily be kept in global variables.  However, just to keep
// things tidy, I pushed it all into a single record.
//
// As a plugin may host multiple mechanism, and there's no guarantee
// that these mechanisms won't be running on different threads, data
// in this record should be protected from multiple concurrent access.
// In my case, however, all of the data is read-only, so I don't need
// to do anything special.

enum {
    kPluginMagic = 'PlgN'
};

struct PluginRecord {
    OSType                          fMagic;         // must be kPluginMagic
    const AuthorizationCallbacks *  fCallbacks;
};

static Boolean PluginValid(const PluginRecord *plugin)
{
    return (plugin != NULL)
    && (plugin->fMagic == kPluginMagic)
    && (plugin->fCallbacks != NULL)
    && (plugin->fCallbacks->version >= kAuthorizationCallbacksVersion);
}

/////////////////////////////////////////////////////////////////////


#pragma mark ***** Mechanism Entry Points

static OSStatus MechanismCreate(
                                AuthorizationPluginRef      inPlugin,
                                AuthorizationEngineRef      inEngine,
                                AuthorizationMechanismId    mechanismId,
                                AuthorizationMechanismRef * outMechanism
                                )
// Called by the plugin host to create a mechanism, that is, a specific
// instance of authentication.
//
// inPlugin is the plugin reference, that is, the value returned by
// AuthorizationPluginCreate.
//
// inEngine is a reference to the engine that's running the plugin.
// We need to keep it around because it's a parameter to all the
// callbacks.
//
// mechanismId is the name of the mechanism.  When you configure your
// mechanism in "/etc/authorization", you supply a string of the
// form:
//
//   plugin:mechanism[,privileged]
//
// where:
//
// o plugin is the name of this bundle (without the extension)
// o mechanism is the string that's passed to mechanismId
// o privileged, if present, causes this mechanism to be
//   instantiated in the privileged (rather than the GUI-capable)
//   plug-in host
//
// You can use the mechanismId to support multiple types of
// operation within the same plugin code.  For example, your plugin
// might have two cooperating mechanisms, one that needs to use the
// GUI and one that needs to run privileged.  This allows you to put
// both mechanisms in the same plugin.
//
// outMechanism is a pointer to a place where you return a reference to
// the newly created mechanism.
{
    OSStatus            err;
    PluginRecord *      plugin;
    MechanismRecord *   mechanism;
    
    plugin = (PluginRecord *) inPlugin;
    assert(PluginValid(plugin));
    assert(inEngine != NULL);
    assert(mechanismId != NULL);
    assert(outMechanism != NULL);
    
    // Normally one would test mechanismId to distinguish various mechanisms
    // supported by the same plugin.  In this case, the only thing we care about
    // is if the mechanismId is "WaitForDebugger", in which case we set the
    // fWaitForDebugger flag, which changes the behaviour of MechanismInvoke.
    // All other mechanism IDs are considered equal.
    
    // Allocate the space for the MechanismRecord.
    
    err = noErr;
    mechanism = (MechanismRecord *) malloc(sizeof(*mechanism));
    if (mechanism == NULL) {
        err = memFullErr;
    }
    
    // Fill it in.
    
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




static OSStatus MechanismInvoke(AuthorizationMechanismRef inMechanism)
// Called by the system to start authentication using this mechanism.
// In a real plugin, this is where the real work is done.
{
    OSStatus                    err;
    MechanismRecord *           mechanism;
    
    mechanism = (MechanismRecord *) inMechanism;
    assert(MechanismValid(mechanism));
    
    
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




static OSStatus MechanismDeactivate(AuthorizationMechanismRef inMechanism)
// Called by the system to deactivate the mechanism, in the traditional
// GUI sense of deactivating a window.  After your plugin has deactivated
// it's UI, it should call the DidDeactivate callback.
//
// In our case, we have no UI, so we just call DidDeactivate immediately.
{
    OSStatus            err;
    MechanismRecord *   mechanism;
    
    mechanism = (MechanismRecord *) inMechanism;
    assert(MechanismValid(mechanism));
    
    err = mechanism->fPlugin->fCallbacks->DidDeactivate(mechanism->fEngine);
    
    return err;
}




static OSStatus MechanismDestroy(AuthorizationMechanismRef inMechanism)
// Called by the system when it's done with the mechanism.
{
    MechanismRecord *   mechanism;
    
    mechanism = (MechanismRecord *) inMechanism;
    assert(MechanismValid(mechanism));
    
    free(mechanism);
    
    return noErr;
}




/////////////////////////////////////////////////////////////////////
#pragma mark ***** Plugin Entry Points

static OSStatus PluginDestroy(AuthorizationPluginRef inPlugin)
// Called by the system when it's done with the plugin.
// All of the mechanisms should have been destroyed by this time.
{
    PluginRecord *  plugin;
    
    plugin = (PluginRecord *) inPlugin;
    assert(PluginValid(plugin));
    
    free(plugin);
    
    return noErr;
}




// gPluginInterface is the plugin's dispatch table, a pointer to
// which you return from AuthorizationPluginCreate.  This is what
// allows the system to call the various entry points in the plugin.

static AuthorizationPluginInterface gPluginInterface = {
    kAuthorizationPluginInterfaceVersion,
    &PluginDestroy,
    &MechanismCreate,
    &MechanismInvoke,
    &MechanismDeactivate,
    &MechanismDestroy
};




extern OSStatus AuthorizationPluginCreate(
                                          const AuthorizationCallbacks *          callbacks,
                                          AuthorizationPluginRef *                outPlugin,
                                          const AuthorizationPluginInterface **   outPluginInterface
                                          )
// The primary entry point of the plugin.  Called by the system
// to instantiate the plugin.
//
// callbacks is a pointer to a bunch of callbacks that allow
// your plugin to ask the system to do operations on your behalf.
//
// outPlugin is a pointer to a place where you can return a
// reference to the newly created plugin.
//
// outPluginInterface is a pointer to a place where you can return
// a pointer to your plugin dispatch table.
{
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




