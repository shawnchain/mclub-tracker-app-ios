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
#import "MTRegisterViewController.h"
#import "MTrackerService.h"

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MTSmartBeaconFilter.h"

@interface MTMapViewController () <MKMapViewDelegate,CLLocationManagerDelegate>
@property(strong,nonatomic) CLLocationManager *locationManager;
@property(strong,atomic) CLLocation *currentNewLocation;
@property(strong,nonatomic) NSTimer *updateTimer;

@property(strong,nonatomic) MTSmartBeaconFilter *smartBeaconFilter;
@end

@implementation MTMapViewController

- (void)viewDidLoad {
    // Do any additional setup after loading the view from its nib.
    //self.leftMenu = [[MTMenuViewController alloc] initWithNibName:@"MTMenuViewController" bundle:nil];
    [super viewDidLoad];
    UIBarButtonItem *setup = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(onSetupAction:)];
    self.navigationItem.leftBarButtonItem = setup;

    // register for the registation and login notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyReceived:) name:kMTNotifyDeviceLoggedIn object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotifyReceived:) name:kMTNotifyDeviceLoggedOut object:nil];
    
    [self setupRightButtons];
    
    CLLocationManager *locMan = [[CLLocationManager alloc] init];
    locMan.delegate = self;
    locMan.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;//kCLLocationAccuracyBestForNavigation;
    self.locationManager = locMan;

    // Use smartbeaconf ilter
    self.smartBeaconFilter = [[MTSmartBeaconFilter alloc] init];
    self.smartBeaconFilter.enableSmartCheck = YES;
}

-(void)setupRightButtons{
    MTrackerService *mts = [MTrackerService sharedInstance];
    NSString *storedUsername = [mts getConfig:kMTConfigUsername];
    if(storedUsername && storedUsername.length > 0){
        //if([[MTrackerService sharedInstance] getConfig:kMTConfigUsername]){
        // show the login
        UIBarButtonItem *login = [[UIBarButtonItem alloc] initWithTitle:@"登录" style:UIBarButtonItemStylePlain target:self action:@selector(onLoginAction:)];
        self.navigationItem.rightBarButtonItem = login;
    }else{
        // show the register
        UIBarButtonItem *reg = [[UIBarButtonItem alloc] initWithTitle:@"注册" style:UIBarButtonItemStylePlain target:self action:@selector(onRegisterAction:)];
        self.navigationItem.rightBarButtonItem = reg;
    }
    
    self.title = @"Tracker Map";
}

-(void)onNotifyReceived:(NSNotification*)notify{
    if(notify.name == kMTNotifyDeviceLoggedIn){
        MTrackerService *mts = [MTrackerService sharedInstance];
        NSString *username = [mts getConfig:kMTConfigUsername];
        NSString *token = [mts getConfig:kMTConfigServiceToken];
        if(username && token){
            // user logged in, update the right button with tracker
            UIBarButtonItem *track =[[UIBarButtonItem alloc] initWithTitle:@"跟踪" style:UIBarButtonItemStylePlain target:self action:@selector(onTrackAction:)];
            self.navigationItem.rightBarButtonItem = track;
            self.title = [NSString stringWithFormat:@"%@",username];
        }
        
        // load user settings
        [mts loadUserInfo:^(MTServiceCode code, NSString *message, NSDictionary *data) {
            if(code == NO_ERROR){
                // refresh user settings
                NSDictionary *userInfo = data[@"user"];
                NSString *displayName = userInfo[@"displayName"];
                [mts setConfig:kMTConfigDisplayName value:displayName];
                if(displayName){
                    self.title = displayName;
                }
                //NSString *avatar = data[@"avatar"];
            }
        }];
        
    }else if(notify.name == kMTNotifyDeviceLoggedOut){
        // Remove the token
        [[MTrackerService sharedInstance] setConfig:kMTConfigServiceToken value:nil];
        // Stop tracking if any
        if(self.navigationItem.rightBarButtonItem.tag == 1){
            [self onTrackAction:self.navigationItem.rightBarButtonItem];
        }
        
        // Prompt user of the logout
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WARN" message:@"您的会话已经过期，请重新登录" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *act = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:act];
        [self presentViewController:alert animated:YES completion:nil];
        
        // and logout
        [self setupRightButtons];
    }
}

-(IBAction)onSetupAction:(id)sender{
    NSLog(@"TODO - call setup view");
}

-(IBAction)onLoginAction:(id)sender{
    MTLoginViewController *login = [[MTLoginViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:login animated:YES];
//    [self.navigationController presentViewController:login animated:YES completion:^{
//        // noop;
//    }];
    NSLog(@"TODO - call setup view");
}

-(IBAction)onRegisterAction:(id)sender{
    MTRegisterViewController *reg = [[MTRegisterViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:reg animated:YES];
    //    [self.navigationController presentViewController:login animated:YES completion:^{
    //        // noop;
    //    }];
    NSLog(@"TODO - call setup view");
}

-(IBAction)onTrackAction:(id)sender{
    if(![self checkGPSPermission]){
        return;
    }
    MKMapView *map = (MKMapView*)self.view;
    map.showsUserLocation = YES;
    [map setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
    UIBarButtonItem *btn = (UIBarButtonItem*)sender;
    if(btn.tag == 0){
        btn.tag = 1;
        [self.locationManager startUpdatingLocation];
        btn.title = @"正在跟踪";
        
        // The timer will check every 1s, because we have smart beacon filter applied in the locatio update callback function.
        #define UPDATE_TIMER_INTERVAL 1
        self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:UPDATE_TIMER_INTERVAL target:self selector:@selector(onUpdateTimerFired:) userInfo:nil repeats:YES];
    }else{
        btn.tag = 0;
        [self.updateTimer invalidate];
        self.updateTimer = nil;
        [self.locationManager stopUpdatingLocation];
        btn.title = @"跟踪";
    }
    
}

-(void)onUpdateTimerFired:(NSTimer*)timer{
    if(self.currentNewLocation){
        // perform update
        [self doUpdateLocation:self.currentNewLocation];
        self.currentNewLocation = nil;
    }
}

#define MAX_ERROR_RETRY_COUNT 10 // about 10 minutes
-(void)doUpdateLocation:(CLLocation*)location{
    static int errorCount = 0;
#if DEBUG
    NSLog(@"New location updated: %@",location);
#endif
    
    MTrackerService *mts = [[MTrackerService alloc] init];
    [mts updateLocation:location onCompletion:^(MTServiceCode code, NSString *message, NSDictionary *data) {
        if(code == NO_ERROR){
            errorCount = 0;
            // we're done
            return;
        }
        
        if(code == SESSION_EXPIRED_ERROR || code == AUTH_DENIED_ERROR){
            // no permission - TODO perform logout
            NSLog(@"Session expired! %@",message);
            [[NSNotificationCenter defaultCenter] postNotificationName:kMTNotifyDeviceLoggedOut object:nil];
            return;
        }else{
            errorCount++;
            NSLog(@"Unknown error: %@", message);
        }
        
        // stop location updates
        if(errorCount >=MAX_ERROR_RETRY_COUNT){
            errorCount = 0;
            [self onTrackAction:self.navigationItem.rightBarButtonItem];
            
            // Prompt user of the logout
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WARN" message:@"位置更新失败，请稍后重试" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *act = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [alert dismissViewControllerAnimated:YES completion:nil];
            }];
            [alert addAction:act];
            [self presentViewController:alert animated:YES completion:nil];
            
        }
    }];
}

-(BOOL)checkGPSPermission{
    NSString *errorMessage = nil;
    UIAlertController *alert = nil;
    
    if(![CLLocationManager locationServicesEnabled]){
        errorMessage = @"You have to enable location service to make me happy. \r Or I'll stop working for you";
        goto exit;
    }

    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    switch(status){
        case kCLAuthorizationStatusAuthorizedAlways:
            return true;
            break;
        case kCLAuthorizationStatusNotDetermined:{
            [self.locationManager requestAlwaysAuthorization];
            return false;
            break;
        }
        default:{
            errorMessage = @"You have to grant app the ALWAYS access permission to  GPS to make me happy. \r Or I'll stop working";
            break;
        }
    }
exit:
    // alert user for the permission;
    alert = [UIAlertController alertControllerWithTitle:@"Error" message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *act = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    [alert addAction:act];
    [self presentViewController:alert animated:YES completion:nil];
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


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
//    [self checkGPSPermission];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    CLLocation *newLocation = [locations lastObject];
    if([self.smartBeaconFilter accept:newLocation]){
        self.currentNewLocation = newLocation;
        
        if([self runningInForeground]){
            // update current location label
            MKMapView *map = (MKMapView*)self.view;
            NSString *title = [NSString stringWithFormat:@"当前位置(%.0f km/h)",newLocation.speed * 3.6f];
            [[map userLocation] setTitle:title];
        }else{
            [self scheduleAlarmForLocation:newLocation];
        }
    }
}

#pragma mark - Local Notification For Test Purpose

#define ALARM_INTERVAL_SECONDS 15
- (void)scheduleAlarmForLocation:(CLLocation*)location {
    static NSDate *lastNotifyTime = nil;
    
    NSDate *t = [NSDate date];
    if(lastNotifyTime != nil && fabs([t timeIntervalSinceDate:lastNotifyTime]) < ALARM_INTERVAL_SECONDS){
        return;
    }
    lastNotifyTime = t;
    
    UIApplication* app = [UIApplication sharedApplication];
    NSArray*    oldNotifications = [app scheduledLocalNotifications];
    
    // Clear out the old notification before scheduling a new one.
    if ([oldNotifications count] > 0)
        [app cancelAllLocalNotifications];
    
    // Create a new notification.
    UILocalNotification* alarm = [[UILocalNotification alloc] init];
    if (alarm)
    {
        alarm.fireDate = [[NSDate alloc] initWithTimeIntervalSinceNow:1];
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
        alarm.soundName = @"alarmsound.caf";
        alarm.alertBody = [NSString stringWithFormat:@"正在跟踪，当前速度(%.0f km/h)",location.speed > 0 ? (location.speed * 3.6f):0.f];
        NSLog(@"Local Notif: %@",alarm.alertBody);
        
        [app scheduleLocalNotification:alarm];
    }
}


#pragma mark - Application BG/FG state check
-(BOOL) runningInBackground
{
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    BOOL result = (state == UIApplicationStateBackground);
    
    return result;
}

-(BOOL) runningInForeground
{
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    BOOL result = (state == UIApplicationStateActive);
    
    return result;
}

@end
