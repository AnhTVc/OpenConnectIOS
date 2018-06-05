//
//  ViewController.m
//  OpenConnectNew
//
//  Created by Tran Viet Anh on 7/28/17.
//  Copyright © 2017 NextVPN Corporation. All rights reserved.
//

#import "VPNViewController.h"
#include <openconnect.h>
#include <NetworkExtension/NETunnelProviderManager.h>
#include <NetworkExtension/NEVPNConnection.h>
#include <NetworkExtension/NETunnelProviderProtocol.h>
#import "Wrapper.h"
extern int main_openconenct(int argc, char **argv);
extern int openconnect_setup_cmd_pipe(struct openconnect_info *vpninfo);
void usage(void);
@interface VPNViewController (){
    __block NETunnelProviderManager * vpnManager;
    bool isConnect;
}
@end

@implementation VPNViewController
char *vpnInfo;
- (void)viewDidLoad {
    [super viewDidLoad];
    vpnManager = [[NETunnelProviderManager alloc] init];
    isConnect = false;
    self.coreVPN = dispatch_queue_create("check coreVPN", 0);
    self.checkVPNCore = dispatch_queue_create("check connect", 0);
    // help
    dispatch_async(self.coreVPN, ^{
        [Wrapper startWithOptions:@[@"--no-cert-check",
                                    @"--user", @"test33",
                                    @"1.2.3.4"]];
    });
    
    while (1) {
        if([Wrapper isConnected]){
            // Connect complete ==> tunnel
            vpnInfo = [Wrapper getVPNInfo];
            //[_btn setTitle:@"Connect" forState:UIControlStateNormal];
            [self saveToPreferences];
            //[_btn setTitle:@"Connect" forState:UIControlStateNormal];
            break;
        }
    }
    
    
}
- (void) VPNStatusDidChange{
    switch (vpnManager.connection.status) {
        case NEVPNStatusInvalid:
            NSLog(@"Invalid");
            //[_btn setTitle:@"Invalid" forState:UIControlStateNormal];
            isConnect = false;
            break;
        case NEVPNStatusConnecting:
            NSLog(@"Connecting");
            //[_btn setTitle:@"Connecting" forState:UIControlStateNormal];
            isConnect = false;
            break;
        case NEVPNStatusConnected:
            //[_btn setTitle:@"Disconect" forState:UIControlStateNormal];
            NSLog(@"Disconnected");
            isConnect = true;
            break;
            
        case NEVPNStatusReasserting:
            NSLog(@"Reasserting");
            isConnect = false;
            //[_btn setTitle:@"Reasserting" forState:UIControlStateNormal];
            break;
        case NEVPNStatusDisconnected:
            NSLog(@"Disconnected");
            isConnect = false;
            //[_btn setTitle:@"Connect" forState:UIControlStateNormal];
            break;
        case NEVPNStatusDisconnecting:
            NSLog(@"Disconnecting");
            isConnect = false;
            //[_btn setTitle:@"Disconnecting" forState:UIControlStateNormal];
            break;
        default:
            NSLog(@"xxxxxx");
            isConnect = false;
            //[_btn setTitle:@"xxxxx" forState:UIControlStateNormal];
            break;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) saveToPreferences{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(VPNStatusDidChange)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    NSString * strVPNInfo = [NSString stringWithFormat:@"%s", vpnInfo];
    
    NSLog(@"%@", strVPNInfo);
    NSString *tunnelBundleId = @"ne.packet.tunnel.vpn.openvpn.NEPacketTunnelVPNDemoTunnel";
    NSArray *lines = [strVPNInfo componentsSeparatedByString:@"\n"];
    NSString *mtu = lines[1];
    NSString *ip = lines[2];
    NSString *subnet = @"255.255.255.255";
    NSString *hostname = lines[4];
    NSString *dns = lines[5];
    NSString *server = @"192.95.47.204";
    NSString *ippublicserver = @"192.95.47.204";
    NSString *port  = @"443";
    
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray* newManagers, NSError *error)
     {
         if(error != nil){
             NSLog(@"Load Preferences error: %@", error);
         }else{
             if([newManagers count] > 0)
             {
                 vpnManager = newManagers[0];
             }
             [vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error){
                 if(error != nil){
                     NSLog(@"Load Preferences error: %@", error);
                 }else{
                     __block NETunnelProviderProtocol *protocol = [[NETunnelProviderProtocol alloc] init];
                     
                     protocol.providerBundleIdentifier = tunnelBundleId;
                     
                     protocol.providerConfiguration = @{@"port": port,
                                                        @"server": server,
                                                        @"ippublicserver": ippublicserver,
                                                        @"mtu": mtu,
                                                        @"dns": dns,
                                                        @"ipclient": ip,
                                                        @"subnet": subnet};
                     protocol.serverAddress = @"192.95.47.204"; //VPN server address
                     vpnManager.protocolConfiguration = protocol;
                     vpnManager.localizedDescription  = @"OPEN CONNECT";
                     [vpnManager setEnabled:true];
                     
                     [vpnManager saveToPreferencesWithCompletionHandler:^(NSError *error){
                         if (error != nil) {
                             NSLog(@"Save to Preferences Error: %@", error);
                         }else{
                             NSLog(@"Save successfully");
                         }
                         
                     }];
                     
                 }}];
         }
     }];
}
- (void) openTunnel{
    NSLog(@"GO ----");
    [vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if(error != nil){
            NSLog(@"%@", error);
        }else{
            NSError *startError = nil;
            //[vpnManager.connection startVPNTunnelAndReturnError:&startError];
            [vpnManager.connection startVPNTunnelWithOptions:nil andReturnError:&startError];
            
            if(startError != nil){
                NSLog(@"%@", startError);
            }
            else{
                NSLog(@"Complete");
            }
            [self VPNStatusDidChange];
            
        }
    }];
}

- (IBAction)btnConnect:(id)sender {
    if(isConnect){
        [vpnManager.connection stopVPNTunnel];
        isConnect = false;
        //[_btn setTitle:@"Connect" forState:UIControlStateNormal];
    }else{
        [self openTunnel];
    }
}
@end
