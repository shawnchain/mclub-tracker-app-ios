//
//  MTLoginViewController.m
//  MTracker
//
//  Created by Shawn Chain on 15/9/20.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import "MTLoginViewController.h"
#import "MBProgressHUD.h"
#import "MTrackerService.h"
#import "MTRegisterViewController.h"

NSString *const kMTNotifyDeviceLoggedIn = @"kMTNotifyDeviceLoggedIn";

NSString *const kMTNotifyDeviceLoggedOut = @"kMTNotifyDeviceLoggedOut";

@interface MTLoginViewController () <MBProgressHUDDelegate>
@property(strong,nonatomic) MBProgressHUD *progressHUD;
@end

@implementation MTLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"登录";
    [self.navigationItem setHidesBackButton:YES];

    if(!self.hideRegisterButton){
        // show the register button
        UIBarButtonItem *reg = [[UIBarButtonItem alloc] initWithTitle:@"注册" style:UIBarButtonItemStylePlain target:self action:@selector(onRegisterAction:)];
        self.navigationItem.rightBarButtonItem = reg;
    }

    // load saved user name if any
    NSString *loginName = [[MTrackerService sharedInstance] getConfig:kMTConfigPhone];
    if(!loginName){
        loginName = [[MTrackerService sharedInstance] getConfig:kMTConfigUsername];
    }
    if(loginName)
        self.txtUsername.text = loginName;
    [self.txtUsername becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)onCancelAction:(id)sender{
    //[self.navigationController popViewControllerAnimated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)onLoginAction:(id)sender{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    [self.navigationController.view addSubview:hud];
    hud.delegate = self;
    hud.labelText = @"登录中";
    [hud show:YES];
    self.progressHUD = hud;
    
    MTrackerService *mts = [MTrackerService sharedInstance];
    if(self.txtUsername.text.length > 0){
        [mts setConfig:kMTConfigUsername value:self.txtUsername.text];
    }
    [mts setConfig:kMTConfigServiceToken value:@""];
    [mts login:self.txtUsername.text password:self.txtPassword.text onCompletion:^(MTServiceCode code, NSString *message, NSDictionary *data) {
        if(code == NO_ERROR){
            NSString *token = data[@"token"];
            if(token){
                [mts setConfig:kMTConfigServiceToken value:token];
                [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotifyDeviceLoggedIn object:data];
                self.progressHUD.tag = 1; // should return
                [self.progressHUD hide:YES];
                return;
            }
        }
        NSLog(@"Login failed, %@",message);
        self.progressHUD.labelText = @"登录失败";
        if(message) self.progressHUD.detailsLabelText = message;
        [self.progressHUD hide:YES afterDelay:3];
    }];
    
}

-(IBAction)onRegisterAction:(id)sender{
    MTRegisterViewController *reg = [[MTRegisterViewController alloc] initWithNibName:nil bundle:nil];
    reg.hideLoginButton = YES;
    [self.navigationController pushViewController:reg animated:YES];
}


#pragma mark - Progress HUD callback
- (void)hudWasHidden:(MBProgressHUD *)hud{
    BOOL shouldReturn = self.progressHUD.tag == 1;
    [self.progressHUD removeFromSuperViewOnHide];
    self.progressHUD = nil;
    if(shouldReturn){
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

@end
