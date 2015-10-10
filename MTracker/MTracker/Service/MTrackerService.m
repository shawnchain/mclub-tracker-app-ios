//
//  MTrackerService.m
//  MTracker
//
//  Created by Shawn Chain on 15/9/21.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import "MTrackerService.h"
#import <CoreLocation/CoreLocation.h>

@interface MTrackerService()
@property(strong, nonatomic) QServiceEndpoint *endpoint;
@end

@implementation MTrackerService

NSString *const kMTConfigUsername = @"kMTConfigUsername";
NSString *const kMTConfigDisplayName = @"kMTConfigDiplayName";
NSString *const kMTConfigPassword = @"kMTConfigPassword";
NSString *const kMTConfigServiceToken = @"kMTConfigServiceToken";
NSString *const kMTConfigServiceRootURL = @"kMTConfigServiceRootURL";

#if 0
NSString *const defaultServiceRootURL = @"http://localhost:8080/mclub/api";
#else
//NSString *const defaultServiceRootURL = @"http://aprs2.mclub.to:20880/mtracker/api";
NSString *const defaultServiceRootURL = @"https://aprs.hamclub.net/mtracker/api";
#endif

+(MTrackerService*)sharedInstance{
    static id instance = nil;
    if(!instance){
        instance = [[self alloc] init];
    }
    return (MTrackerService*)instance;
}

-(id)init{
    self = [super init];
    self.endpoint = [[QServiceEndpoint alloc] initWithURL:defaultServiceRootURL];
    return self;
}

-(NSString*) getConfig:(NSString*)key{
    if(key == kMTConfigServiceRootURL){
        return defaultServiceRootURL;
    }
    return [[NSUserDefaults standardUserDefaults] stringForKey:key];
}

-(void) setConfig:(NSString*)key value:(NSString*)value{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(value == nil){
        [defaults removeObjectForKey:key];
    }else{
        [defaults setValue:value forKey:key];
    }
}

-(NSString*)getDeviceId{
    return [[UIDevice currentDevice].identifierForVendor.UUIDString substringFromIndex:24];
}

-(void) login:(NSString*)username password:(NSString*)password onCompletion:(MTServiceCompletionCallback)callback{
    NSAssert(callback != nil,@"callback is nil");
    QServiceRequest *req = [QServiceRequest requestForOperation:@"/login" returnType:[NSDictionary class] completeBlock:^(QServiceRequest *request, NSDictionary* result) {
        NSNumber *code = result[@"code"];
        NSString *message = result[@"message"];
        NSLog(@"login result: %@, %@, %@",code, message, result);
        if(callback)callback(code.intValue,message,result);
    } failBlock:^(QServiceRequest *request, NSError *error) {
        //error(request,error);
        NSLog(@"login error: %@",error);
        NSDictionary *dict = @{@"error":error};
        if(callback)callback(NETWORK_ERROR,@"Network error",dict);
    }];
    
    [req addPostValueString:username forKey:@"username"];
    [req addPostValueString:password forKey:@"password"];
    // append the device id
    NSString *udid = [[self loadDeviceIDString] substringFromIndex:24];
    [req addPostValueString:udid forKey:@"udid"];
    
    [self.endpoint sendRequest:req];
}

-(NSString*) loadDeviceIDString{
    NSUUID *udid = [UIDevice currentDevice].identifierForVendor;
    return udid.UUIDString;
}

-(void) regist:(NSString*)udid dispName:(NSString*)dispName password:(NSString*)password phone:(NSString*)phone onCompletion:(MTServiceCompletionCallback)callback;{
    NSAssert(callback != nil,@"callback is nil");
    QServiceRequest *req = [QServiceRequest requestForOperation:@"/register" returnType:[NSDictionary class] completeBlock:^(QServiceRequest *request, NSDictionary* result) {
        NSNumber *code = result[@"code"];
        NSString *message = result[@"message"];
        NSLog(@"login result: %@, %@, %@",code, message, result);
        if(callback)callback(code.intValue,message,result);
    } failBlock:^(QServiceRequest *request, NSError *error) {
        //error(request,error);
        NSLog(@"login error: %@",error);
        NSDictionary *dict = @{@"error":error};
        if(callback)callback(NETWORK_ERROR,@"Network error",dict);
    }];
    
    [req addPostValueString:udid forKey:@"udid"];
    [req addPostValueString:password forKey:@"password"];
    [req addPostValueString:phone forKey:@"phone"];
    [req addPostValueString:dispName forKey:@"display_name"];
    
    [self.endpoint sendRequest:req];
}

-(void) updateLocation:(CLLocation*)location onCompletion:(MTServiceCompletionCallback)callback{
    QServiceRequest *req = [QServiceRequest requestForOperation:@"/update_position" returnType:[NSDictionary class] completeBlock:^(QServiceRequest *request, NSDictionary* result) {
        NSNumber *code = result[@"code"];
        NSString *message = result[@"message"];
        NSLog(@"update_location result: %@, %@, %@",code, message, result);
        if(callback)callback(code.intValue,message,result);
    } failBlock:^(QServiceRequest *request, NSError *error) {
        //error(request,error);
        NSLog(@"login error: %@",error);
        NSDictionary *dict = @{@"error":error};
        if(callback)callback(NETWORK_ERROR,@"Network error",dict);
    }];
    
    NSString *udid = [self getDeviceId];
    [req addPostValueString:udid forKey:@"udid"];
    
    NSString *token = [self getConfig:kMTConfigServiceToken];
    [req addPostValueString:token forKey:@"token"];
    
    NSString *lat = [NSString stringWithFormat:@"%.6f",location.coordinate.latitude];
    [req addPostValueString:lat forKey:@"lat"];
    NSString *lon = [NSString stringWithFormat:@"%.6f",location.coordinate.longitude];
    [req addPostValueString:lon forKey:@"lon"];
    if(location.speed >=0){
        NSString *spd = [NSString stringWithFormat:@"%.0f",location.speed];
        [req addPostValueString:spd forKey:@"speed"];
    }
    if(location.course >=0){
        NSString *crs = [NSString stringWithFormat:@"%.0f",location.course];
        [req addPostValueString:crs forKey:@"heading"];
    }
    [req addPostValueString:@"Greetings from iOS!" forKey:@"message"];
    
    [self.endpoint sendRequest:req];

}

-(void) loadUserInfo:(MTServiceCompletionCallback)callback{
    NSAssert(callback != nil,@"callback is nil");
    QServiceRequest *req = [QServiceRequest requestForOperation:@"/user" returnType:[NSDictionary class] completeBlock:^(QServiceRequest *request, NSDictionary* result) {
        NSNumber *code = result[@"code"];
        NSString *message = result[@"message"];
        NSLog(@"login result: %@, %@, %@",code, message, result);
        if(callback)callback(code.intValue,message,result);
    } failBlock:^(QServiceRequest *request, NSError *error) {
        //error(request,error);
        NSLog(@"login error: %@",error);
        NSDictionary *dict = @{@"error":error};
        if(callback)callback(NETWORK_ERROR,@"Network error",dict);
    }];
    
    NSString *token = [self getConfig:kMTConfigServiceToken];
    [req addPostValueString:token forKey:@"token"];
    [self.endpoint sendRequest:req];
}
@end
