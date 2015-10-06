//
//  MTSmartBeaconFilter.h
//  MTracker
//
//  Created by Shawn Chain on 15/10/6.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface MTSmartBeaconFilter : NSObject

@property(assign,nonatomic) BOOL enableSmartCheck;

-(BOOL) accept:(CLLocation*) location;

@end
