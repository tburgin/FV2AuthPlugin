//
//  main.m
//  fde-service
//
//  Created by Burgin, Thomas (NIH/CIT) [C] on 10/15/15.
//  Copyright (c) 2015 NIH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "fde_service.h"

@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation ServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:
(NSXPCConnection *)newConnection {
    
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:
                                       @protocol(fde_serviceProtocol)];
    fde_service *exportedObject = [fde_service new];
    newConnection.exportedObject = exportedObject;
    [newConnection resume];
    
    return YES;
}

@end

int main(int argc, const char *argv[])
{
    // Create the delegate for the service.
    ServiceDelegate *delegate = [ServiceDelegate new];
    
    // Set up the one NSXPCListener for this service. It will handle all incoming connections.
    NSXPCListener *listener = [NSXPCListener serviceListener];
    listener.delegate = delegate;
    
    // Resuming the serviceListener starts this service. This method does not return.
    [listener resume];
    return 0;
}
