//
//  MTRegisterViewController.m
//  MTracker
//
//  Created by Shawn Chain on 15/9/20.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import "MTRegisterViewController.h"
#import "MTLoginViewController.h"
#import "MBProgressHUD.h"
#import "MTrackerService.h"
#import "Private_NetworkController.h"
#import "Private_CoreTelephony.h"


@interface MTRegisterViewController ()<MBProgressHUDDelegate>
@property(strong,nonatomic) MBProgressHUD *progressHUD;
@end

@implementation MTRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"注册";
    [self.navigationItem setHidesBackButton:YES];
    
    // show the login
    if(!self.hideLoginButton){
        UIBarButtonItem *login = [[UIBarButtonItem alloc] initWithTitle:@"登录" style:UIBarButtonItemStylePlain target:self action:@selector(onLoginAction:)];
        self.navigationItem.rightBarButtonItem = login;
    }
    
    NSString *udid = [self loadDeviceIMSI];
    if(!udid){
        NSLog(@"Failed to load IMSI, trying vendor identifier");
        udid = [[self loadDeviceIDString] substringFromIndex:24];
    }
    
    NSLog(@"device udid: %@",udid);
    self.txtDeviceId.text = udid;
    
    NSString *phone = [self loadDevicePhoneNumber];
    if(phone){
        self.txtPhoneNumber.text = phone;
    }
    
    //self.txtDeviceId.text = [[self loadDeviceIDString] substringFromIndex:24];
    self.txtDeviceId.enabled = NO;
}

-(NSString*) loadDeviceIMEI{
    /*
     NetworkController *ntc = [NetworkController sharedInstance];
     NSString *imei = [ntc IMEI];
     */
    return nil;
}
-(NSString*) loadDeviceIMSI{
    return CTSIMSupportCopyMobileSubscriberIdentity();
}

-(NSString*) loadDevicePhoneNumber{
    return CTSettingCopyMyPhoneNumber();
}

-(NSString*) loadDeviceIDString{
    NSUUID *udid = [UIDevice currentDevice].identifierForVendor;
    return udid.UUIDString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onLoginAction:(id)sender{
    //[self.navigationController popViewControllerAnimated:YES];
    MTLoginViewController *login = [[MTLoginViewController alloc] initWithNibName:nil bundle:nil];
    login.hideRegisterButton = YES;
#if 1
    [self.navigationController pushViewController:login animated:YES];
#else
    [self.navigationController popViewControllerAnimated:YES];
    
    //FIXME - Hey, I have no idea about how to hookup the completion callback of popViewController!
    UINavigationController *navi = self.navigationController;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC*100),dispatch_get_main_queue(), ^{
        [navi pushViewController:login animated:YES];
    });
#endif
}

-(IBAction)onCancelAction:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)onRegisterAction:(id)sender{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.delegate = self;
    hud.labelText = @"注册中";
    [hud show:YES];
    self.progressHUD = hud;
    
    MTrackerService *mts = [MTrackerService sharedInstance];
    [mts regist:self.txtDeviceId.text dispName:self.txtDisplayName.text password:self.txtPassword.text phone:self.txtPhoneNumber.text onCompletion:^(MTServiceCode code, NSString *message, NSDictionary *data) {
        if(code == NO_ERROR){
            // retrieve the user name and save in preference
            NSString* username = data[@"username"];
            NSString* token = data[@"token"];
            if(token && username){
                [mts setConfig:kMTConfigServiceToken value:token];
                [mts setConfig:kMTConfigUsername value:username];
                [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotifyDeviceLoggedIn object:data];
                self.progressHUD.tag = 1;
                self.progressHUD.labelText= @"注册设备成功";
                // we're done
                [self.progressHUD hide:YES afterDelay:1];
                return;
            }
        }
        self.progressHUD.labelText = @"注册设备失败";
        if(message) self.progressHUD.detailsLabelText = message;
        [self.progressHUD hide:YES afterDelay:3];
    }];
}

#pragma mark - Progress HUD callback
- (void)hudWasHidden:(MBProgressHUD *)hud{
    BOOL shouldReturn = self.progressHUD.tag == 1;
    [self.progressHUD removeFromSuperViewOnHide];
    self.progressHUD = nil;

    if(shouldReturn)
        [self.navigationController popToRootViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
