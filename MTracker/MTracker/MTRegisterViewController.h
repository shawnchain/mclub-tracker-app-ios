//
//  MTRegisterViewController.h
//  MTracker
//
//  Created by Shawn Chain on 15/9/20.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTRegisterViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *txtDeviceId;
@property (strong, nonatomic) IBOutlet UITextField *txtPhoneNumber;
@property (strong, nonatomic) IBOutlet UITextField *txtDisplayName;
@property (strong, nonatomic) IBOutlet UITextField *txtPassword;

@end
