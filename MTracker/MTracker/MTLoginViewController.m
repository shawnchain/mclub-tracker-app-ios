//
//  MTLoginViewController.m
//  MTracker
//
//  Created by Shawn Chain on 15/9/20.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import "MTLoginViewController.h"

@interface MTLoginViewController ()

@end

@implementation MTLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"登录";
    [self.navigationItem setHidesBackButton:YES];
    
    [self.txtUsername becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)onCancelAction:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
    //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)onLoginAction:(id)sender{
    NSLog(@"TODO - perform login");
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
