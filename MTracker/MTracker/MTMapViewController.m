//
//  MTMapViewController.m
//  MTracker
//
//  Created by Shawn Chain on 15/9/20.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import "MTMapViewController.h"
#import "MTMenuViewController.h"
#import "MTLoginViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface MTMapViewController () <MKMapViewDelegate>

@end

@implementation MTMapViewController

- (void)viewDidLoad {
    // Do any additional setup after loading the view from its nib.
    //self.leftMenu = [[MTMenuViewController alloc] initWithNibName:@"MTMenuViewController" bundle:nil];
    [super viewDidLoad];
    UIBarButtonItem *setup = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(onSetupButtonClicked:)];
    self.navigationItem.leftBarButtonItem = setup;
    
    UIBarButtonItem *login = [[UIBarButtonItem alloc] initWithTitle:@"登录" style:UIBarButtonItemStylePlain target:self action:@selector(onLoginButtonClicked:)];
    self.navigationItem.rightBarButtonItem = login;

    self.title = @"Tracker Map";
    if([self checkGPSPermission]){
        MKMapView *map = (MKMapView*)(self.view);
        map.userTrackingMode = MKUserTrackingModeFollowWithHeading;
    }
}

-(void)onSetupButtonClicked:(id)sender{
    NSLog(@"TODO - call setup view");
}

-(void)onLoginButtonClicked:(id)sender{
    MTLoginViewController *login = [[MTLoginViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:login animated:YES];
//    [self.navigationController presentViewController:login animated:YES completion:^{
//        // noop;
//    }];
    NSLog(@"TODO - call setup view");
}


-(BOOL)checkGPSPermission{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch(status){
        case kCLAuthorizationStatusAuthorizedAlways:
            return true;
            break;
        case kCLAuthorizationStatusNotDetermined:{
            CLLocationManager *clm = [[CLLocationManager alloc] init];
            [clm requestAlwaysAuthorization];
            break;
        }
        default:{
            // alert user for the permission;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"You have to grant app the ALWAYS access permission to  GPS to make me happy. \r Or I'll stop working for you" preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
    }
    return false;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - Overriding methods
- (void)configureLeftMenuButton:(UIButton *)button
{
    CGRect frame = button.frame;
    frame.origin = (CGPoint){0,0};
    frame.size = (CGSize){40,40};
    button.frame = frame;
    
    [button setImage:[UIImage imageNamed:@"icon-menu.png"] forState:UIControlStateNormal];
}

//- (void)configureRightMenuButton:(UIButton *)button
//{
//    CGRect frame = button.frame;
//    frame.origin = (CGPoint){0,0};
//    frame.size = (CGSize){40,40};
//    button.frame = frame;
//    
//    [button setImage:[UIImage imageNamed:@"icon-menu.png"] forState:UIControlStateNormal];
//}

- (BOOL)deepnessForLeftMenu
{
    return YES;
}

//- (CGFloat)maxDarknessWhileRightMenu
//{
//    return 0.5f;
//}


@end
