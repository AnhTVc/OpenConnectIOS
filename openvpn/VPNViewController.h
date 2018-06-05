//
//  ViewController.h
//  OpenConnectNew
//
//  Created by Tran Viet Anh on 7/28/17.
//  Copyright © 2017 NextVPN Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VPNViewController : UIViewController
- (IBAction)btnConnect:(id)sender;
@property (nonatomic) dispatch_queue_t coreVPN;
@property (strong, nonatomic) IBOutlet UIView *labelBTN;
@property (nonatomic) dispatch_queue_t checkVPNCore;
@property (strong, nonatomic) IBOutlet UIButton *btn;
@end

