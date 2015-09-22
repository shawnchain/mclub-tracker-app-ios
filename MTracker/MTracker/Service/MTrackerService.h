//
//  MTrackerService.h
//  MTracker
//
//  Created by Shawn Chain on 15/9/21.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QServiceToolKit.h"

FOUNDATION_EXPORT NSString *const kMTConfigUsername;
FOUNDATION_EXPORT NSString *const kMTConfigPassword;
FOUNDATION_EXPORT NSString *const kMTConfigServiceToken;
FOUNDATION_EXPORT NSString *const kMTConfigServiceRootURL;

@class CLLocation;

typedef enum{
    NO_ERROR = 0,
    OPERATION_FAIL_ERROR = 1,
    SESSION_EXPIRED_ERROR = 2,
    AUTH_DENIED_ERROR = 3,
    NETWORK_ERROR = 99
}MTServiceCode;

typedef void (^MTServiceCompletionCallback)(MTServiceCode code, NSString* message, NSDictionary* data);


@interface MTrackerService : NSObject

+(MTrackerService*)sharedInstance;

-(NSString*) getConfig:(NSString*)key;

-(void) setConfig:(NSString*)key value:(NSString*)value;


-(void) login:(NSString*)username password:(NSString*)password onCompletion:(MTServiceCompletionCallback)callback;

-(void) regist:(NSString*)udid dispName:(NSString*)dispName password:(NSString*)password phone:(NSString*)phone onCompletion:(MTServiceCompletionCallback)callback;

-(void) updateLocation:(CLLocation*)location onCompletion:(MTServiceCompletionCallback)callback;

-(NSString*) getDeviceId;
@end
