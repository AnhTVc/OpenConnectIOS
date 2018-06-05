//
//  OpenAdapter.m
//  openconnect
//
//  Created by Tran Viet Anh on 4/6/18.
//

#import "OpenAdapter.h"

@implementation OpenAdapter
#pragma mark - Lazy Initialization

- (OpenVPNNetworkSettingsBuilder *)networkSettingsBuilder {
    if (!_networkSettingsBuilder) {
        _networkSettingsBuilder = [[OpenVPNNetworkSettingsBuilder alloc] init];
    }
    return _networkSettingsBuilder;
}

- (BOOL)establishTunnel{
    NEPacketTunnelNetworkSettings *networkSettings = [self.networkSettingsBuilder networkSettings];
    if (!networkSettings) { return NO; }
    
    __weak typeof(self) weakSelf = self;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    void (^completionHandler)(id<OpenVPNAdapterPacketFlow> _Nullable) = ^(id<OpenVPNAdapterPacketFlow> flow) {
        __strong typeof(self) self = weakSelf;
        
        if (flow) {
            self.packetFlowBridge = [[OpenVPNPacketFlowBridge alloc] initWithPacketFlow:flow];
        }
        
        dispatch_semaphore_signal(semaphore);
    };
    
    [self.delegate openVPNAdapter:self configureTunnelWithNetworkSettings:networkSettings completionHandler:completionHandler];
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
    
    
    NSError *socketError;
    if (self.packetFlowBridge && [self.packetFlowBridge configureSocketsWithError:&socketError]) {
        [self.packetFlowBridge startReading];
        return YES;
    } else {
        if (socketError) { [self.delegate openVPNAdapter:self handleError:socketError]; }
        return NO;
    }
}

@end
