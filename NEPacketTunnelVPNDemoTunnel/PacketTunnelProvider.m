//
//  PacketTunnelProvider.m
//  Tunnel
//
//  Created by Tran Viet Anh on 6/15/17.
//  Copyright © 2017 NextVPN Corporation. All rights reserved.
//

#import "PacketTunnelProvider.h"
@implementation PacketTunnelProvider{
    //NWUDPSession *_UDPSession;
    NWTCPConnection *_TCPConnect;
    NSDictionary *config;
}

- (void) setupPacketTunnelNetworkSettings {
    
    NEPacketTunnelNetworkSettings *tunnelNetworkSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:self.protocolConfiguration.serverAddress];//vpn_server_public_ip_address
    
    tunnelNetworkSettings.IPv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[config[@"ipclient"]]
                                                                       subnetMasks:@[@"255.255.0.0"]];
    
    tunnelNetworkSettings.MTU = [NSNumber numberWithInt:[config[@"mtu"] intValue]];
    
    NEDNSSettings *dnsSetting = [[NEDNSSettings alloc] initWithServers: @[@"8.8.8.8", @"8.8.4.8"]];
    tunnelNetworkSettings.DNSSettings = dnsSetting;
    
    NSMutableArray *includedRoutes = [[NSMutableArray alloc] init];
    NEIPv4Route *route;
    
    route = [NEIPv4Route defaultRoute];
    [includedRoutes addObject:route];
    
    
    tunnelNetworkSettings.IPv4Settings.includedRoutes  = includedRoutes;
    
    [self setTunnelNetworkSettings:tunnelNetworkSettings completionHandler:^(NSError * _Nullable error){
       // [self udpToTun];
    }];
}

- (void) setupUDPSession{
    
    self.reasserting = false;
    
    __weak typeof(self) weakSelf = self;
    NSString *_serverAddress = config[@"ippublicserver"];
    NSString *_port = config[@"port"];
    self.reasserting = false;
    
    //[weakSelf setupPacketTunnelNetworkSettings];
    [self setTunnelNetworkSettings:nil completionHandler:^(NSError * _Nullable error){
        if(error != nil){
            NSLog(@"Error set TunnelNetwork %@", error);
        }
        _TCPConnect = [self createTCPConnectionToEndpoint:[NWHostEndpoint endpointWithHostname:_serverAddress port:_port] enableTLS:false TLSParameters:NULL delegate:self];
        
       // _UDPSession = [self createUDPSessionToEndpoint:[NWHostEndpoint endpointWithHostname:_serverAddress port:_port] fromEndpoint:nil];
        [self setupPacketTunnelNetworkSettings];
    }];
}

/*
- (void) tunToUDP{
    NSLog(@"read UDP to Tun");
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
        for(NSData *packet in packets){
            [_UDPSession writeDatagram:packet completionHandler:^(NSError * _Nullable error) {
                if(error != nil){
                    NSLog(@"%@", error);
                    [self setupUDPSession];
                    return;
                }
                
            }];
        }
        // Recursive to keep reading
        [self tunToUDP];
    }];
}

- (void) udpToTun{
    __weak typeof(self) weakSelf = self;
    [_UDPSession setReadHandler:^(NSArray<NSData *> * _Nullable _packets, NSError * _Nullable error) {
        if(_packets != nil){
            // This is where decrypt() should reside, I just omit it like above
            NSArray *protocols = [NSMutableArray arrayWithCapacity:_packets.count];
            [weakSelf.packetFlow writePackets:_packets withProtocols:protocols];
        }
    } maxDatagrams:NSIntegerMax];
    
}
*/

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler
{
    config = [[NSDictionary alloc] init];
    NETunnelProviderProtocol *aaa = (NETunnelProviderProtocol *)self.protocolConfiguration;
    config = aaa.providerConfiguration;
    [self setupUDPSession];
   // [self tunToUDP];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler
{
    [_TCPConnect cancel];
    completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler
{
    // Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler
{
    // Add code here to get ready to sleep.
    completionHandler();
}

- (void)wake
{
    // Add code here to wake up.
}

@end
