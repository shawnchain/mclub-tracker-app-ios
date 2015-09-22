//
//  MTLoginViewController.h
//  MTracker
//
//  Created by Shawn Chain on 15/9/20.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString *const kMTNotifyDeviceLoggedIn;
FOUNDATION_EXPORT NSString *const kMTNotifyDeviceLoggedOut;

@interface MTLoginViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *txtUsername;
@property (strong, nonatomic) IBOutlet UITextField *txtPassword;
@property (assign, nonatomic) BOOL hideRegisterButton;
@end
