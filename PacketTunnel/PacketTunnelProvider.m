//
//  PacketTunnelProvider.m
//  Tunnel
//
//  Created by blankwonder on 7/16/15.
//  Copyright © 2015 Yach. All rights reserved.
//

#import "PacketTunnelProvider.h"
#import <resolv.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

static NSString * const ShadowVPNTunnelProviderErrorDomain = @"ShadowVPNTunnelProviderErrorDomain";

typedef NS_ENUM(int, TunnelProviderErrorCode) {
    TunnelProviderErrorCodeInvalidConfiguration = 1,
    TunnelProviderErrorCodeDNSFailed = 2
};

@implementation PacketTunnelProvider {
    NWUDPSession *_UDPSession;
    NWTCPConnection *_TCPSession;
    NSUserDefaults *_sharedDefaults;
    
    NSString *_hostIPAddress;
    NSMutableArray *_outgoingBuffer;
    
    dispatch_queue_t _dispatchQueue;
    
    NSString *_systemDNSServer;
    NSDictionary *config;
}

- (void)startTunnelWithOptions:(nullable NSDictionary<NSString *,NSObject *> *)options
             completionHandler:(void (^)(NSError * __nullable error))completionHandler {
    _outgoingBuffer = [NSMutableArray arrayWithCapacity:100];
    _dispatchQueue = dispatch_queue_create("manager", NULL);
    config = [[NSDictionary alloc] init];
    NETunnelProviderProtocol *aaa = (NETunnelProviderProtocol *)self.protocolConfiguration;
    config = aaa.providerConfiguration;
    [self startConnectionWithCompletionHandler:completionHandler];
    [self tunToUDP];
}

- (void)startConnectionWithCompletionHandler:(void (^)(NSError * __nullable error))completionHandler {
    _hostIPAddress = config[@"ippublicserver"];
    
    NEPacketTunnelNetworkSettings *settings = [self prepareTunnelNetworkSettings];
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError * __nullable error) {
        if (error)  {
            completionHandler(error);
        } else {
            completionHandler(nil);
            dispatch_async(_dispatchQueue, ^{
                [self setupUDPSession];
                [self setupDNSServer];
                [self udpToTun];
                [self readTun];
            });
        }
    }];
}
- (void) udpToTun{
    NSLog(@"write to UDP session");
    __weak typeof(self) weakSelf = self;
    [_UDPSession setReadHandler:^(NSArray<NSData *> * _Nullable _packets, NSError * _Nullable error) {
        // This is where decrypt() should reside, I just omit it like above
        NSArray *protocols = [NSMutableArray arrayWithCapacity:_packets.count];
        [weakSelf.packetFlow writePackets:_packets withProtocols:protocols];
    } maxDatagrams:NSIntegerMax];
    
}

- (void)interfaceDidChange {
    dispatch_async(_dispatchQueue, ^{
        
        self.reasserting = YES;
        [self releaseUDPSession];
        [self releaseDNSServer];
        
        [self setTunnelNetworkSettings:nil completionHandler:^(NSError * _Nullable error) {
            if (error)  {
                [self cancelTunnelWithError:error];
            } else {
                dispatch_async(_dispatchQueue, ^{
                    [self startConnectionWithCompletionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            [self cancelTunnelWithError:error];
                        } else {
                            [self setReasserting:NO];
                        }
                    }];
                });
            }
        }];
    });
}

- (void)setupDNSServer {

}


- (void)releaseDNSServer {
}

- (NEPacketTunnelNetworkSettings *)prepareTunnelNetworkSettings {
    __weak typeof(self) weakSelf = self;
    
    NSString *client = config[@"ipclient"];
    NEPacketTunnelNetworkSettings *tunnelNetworkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:self.protocolConfiguration.serverAddress];//vpn_server_public_ip_address
    
    tunnelNetworkSettings.IPv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[config[@"ipclient"]]
                                                                       subnetMasks:@[@"255.255.0.0"]];
    
    tunnelNetworkSettings.MTU = [NSNumber numberWithInt:[config[@"mtu"] intValue]];
    
    NEDNSSettings *dnsSetting = [[NEDNSSettings alloc] initWithServers: @[@"8.8.8.8", @"8.8.4.8"]];
    tunnelNetworkSettings.DNSSettings = dnsSetting;
    
    NSMutableArray *includedRoutes = [[NSMutableArray alloc] init];
    NEIPv4Route *route;
    
   // route = [NEIPv4Route defaultRoute];
   // [includedRoutes addObject:route];
    
    route = [[NEIPv4Route alloc] initWithDestinationAddress:@"10.10.0.0" subnetMask:@"255.255.0.0"];
    [includedRoutes addObject:route];
    
    route = [[NEIPv4Route alloc] initWithDestinationAddress:@"10.10.255.255" subnetMask:@"255.255.255.255"];
    [includedRoutes addObject:route];
    
    
    route = [[NEIPv4Route alloc] initWithDestinationAddress:@"255.255.255.255" subnetMask:@"255.255.255.255"];
    [includedRoutes addObject:route];
    
    tunnelNetworkSettings.IPv4Settings.includedRoutes  = includedRoutes;
    
    return tunnelNetworkSettings;
}

- (void)setupUDPSession {
    if (_UDPSession) {
        return;
    }
    NWHostEndpoint *endpoint = [NWHostEndpoint endpointWithHostname:self.protocolConfiguration.serverAddress
                                                               port:@"443"];
    
    _UDPSession = [self createUDPSessionToEndpoint:endpoint fromEndpoint:nil];
    [_UDPSession setReadHandler:^(NSArray<NSData *> *datagrams, NSError *error) {
        if (error) {
        } else {
            [self processUDPIncomingDatagrams:datagrams];
        }
    } maxDatagrams:NSUIntegerMax];
}

- (void)releaseUDPSession {
   // [_UDPSession removeObserver:self forKeyPath:@"state"];
    _UDPSession = nil;
}

- (void) tunToUDP{
    NSLog(@"read UDP to Tun");
    __weak typeof(self) weakSelf = self;
    [weakSelf.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
        for(NSData *packet in packets){
            [_UDPSession writeDatagram:packet completionHandler:^(NSError * _Nullable error) {
                [weakSelf setupUDPSession];
                return;
            }];
        }
    }];
}
- (void)processOutgoingBuffer {
    if (!_UDPSession || _UDPSession.state != NWUDPSessionStateReady) {
        return;
    }
    
    NSArray *datas;
    @synchronized(_outgoingBuffer) {
        if (_outgoingBuffer.count == 0) return;
        datas = [_outgoingBuffer copy];
        [_outgoingBuffer removeAllObjects];
    }
    
    [_UDPSession writeMultipleDatagrams:datas completionHandler:^(NSError * _Nullable error) {
        if (error){
            @synchronized(_outgoingBuffer) {
                [_outgoingBuffer addObjectsFromArray:datas];
            }
        }
    }];
}

- (void)readTun {
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * __nonnull packets, NSArray<NSNumber *> * __nonnull protocols) {
        NSMutableArray *datas = [NSMutableArray arrayWithCapacity:packets.count];
        [packets enumerateObjectsUsingBlock:^(NSData * data, NSUInteger idx, BOOL * stop) {
            if ([protocols[idx] intValue] != AF_INET) return;
            /*
            NSData *encryptedData = [ShadowVPNCrypto encryptData:data];
            if (!encryptedData) {
                KDClassLog(@"Encrypt failed: %@", data);
                return;
            }
            */
            [datas addObject:data];
            
        }];
        
        @synchronized(_outgoingBuffer) {
            [_outgoingBuffer addObjectsFromArray:datas];
        }
        [self processOutgoingBuffer];
        
        [self readTun];
    }];
}

- (void)processUDPIncomingDatagrams:(NSArray *)datagrams {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:datagrams.count];
    NSMutableArray *protocols = [NSMutableArray arrayWithCapacity:datagrams.count];
    
    for (NSData *data in datagrams) {
        /*NSData *decryptedData = [ShadowVPNCrypto decryptData:data];
        if (!decryptedData) {
            KDClassLog(@"Decrypt failed! Data length: %lu", (unsigned long)data.length);
            //            KDClassLog(@"%@", [data base64EncodedStringWithOptions:0]);
            return;
        }
        */
        [result addObject:data];
        [protocols addObject:@(AF_INET)];
    }
    
    [self.packetFlow writePackets:result withProtocols:protocols];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    dispatch_async(_dispatchQueue, ^{
        [self releaseDNSServer];
        [self releaseUDPSession];
        completionHandler();
    });
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(nullable void (^)(NSData * __nullable responseData))completionHandler {
    completionHandler(nil);
}



- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    completionHandler();
}

- (void)wake {
}

@end

#pragma clang diagnostic pop
