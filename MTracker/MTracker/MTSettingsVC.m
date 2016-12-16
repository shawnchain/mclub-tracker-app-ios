//
//  MTSettingsVC.m
//  MTracker
//
//  Created by Shawn Chain on 16/12/3.
//  Copyright © 2016年 MClub. All rights reserved.
//

#import "MTSettingsVC.h"

@interface MTSettingsVC ()

@end

@implementation MTSettingsVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"设定";
    
#if 0
    [self.navigationItem setHidesBackButton:YES];
#else
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onCancelAction:)];
    self.navigationItem.leftBarButtonItem = back;
#endif

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onCancelAction:(id)sender{
    //[self.navigationController popViewControllerAnimated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)onConnectTNC:(id)sender{
    //TODO perform ble connection
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
