//
//  MTSmartBeaconFilter.m
//  MTracker
//
//  Created by Shawn Chain on 15/10/6.
//  Copyright © 2015年 MClub. All rights reserved.
//

#import "MTSmartBeaconFilter.h"

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#define PI 3.1415926535897932384626433832795
#define HALF_PI 1.5707963267948966192313216916398
#define TWO_PI 6.283185307179586476925286766559
#define DEG_TO_RAD 0.017453292519943295769236907684886
#define RAD_TO_DEG 57.295779513082320876798154814105
#define METER_TO_FEET 3.2808399

#define RADIANS(x) ((x) * DEG_TO_RAD)
#define sq(x) ((x)*(x))


#define SB_FAST_RATE 30		// 30 seconds
#define SB_SLOW_RATE 120	// 3 minutes
#define SB_LOW_SPEED 5		// 5KM/h
#define SB_HI_SPEED 70		// 80KM/H
#define SB_TURN_TIME 15
#define SB_TURN_MIN 10.f
#define SB_TURN_SLOPE 240.f

typedef struct Location{
    float latitude; 	// decimal(xx.xx) degrees of latitude
    float longitude;
    float speedInKMH;
    uint16_t heading;
    uint16_t altitude;	// altitude value reads from GPGGA[8]
    int32_t timestamp;
}Location;

static Location lastLocation = {
    .latitude=0.f,
    .longitude=0.f,
    .speedInKMH=0.f,
    .heading=0,
    .timestamp = 0
};
static int32_t lastSendTimeSeconds = 0; // in seconds

static uint16_t _calc_heading(Location *l1, Location *l2){
    uint16_t d = abs(l1->heading - l2->heading) % 360;
    return (d <= 180)? d : 360 - d;
}

static float gps_distance_between(Location *loc1, Location *loc2, float units_per_meter) {
    // returns distance in meters between two positions, both specified
    // as signed decimal-degrees latitude and longitude. Uses great-circle
    // distance computation for hypothised sphere of radius 6372795 meters.
    // Because Earth is no exact sphere, rounding errors may be upto 0.5%.
    float lat1 = loc1->latitude;
    float lat2 = loc2->latitude;
    
    float delta = RADIANS(loc1->longitude - loc2->longitude);
    float sdlong = sin(delta);
    float cdlong = cos(delta);
    lat1 = RADIANS(lat1);
    lat2 = RADIANS(lat2);
    float slat1 = sin(lat1);
    float clat1 = cos(lat1);
    float slat2 = sin(lat2);
    float clat2 = cos(lat2);
    delta = (clat1 * slat2) - (slat1 * clat2 * cdlong);
    delta = sq(delta);
    delta += sq(clat2 * sdlong);
    delta = sqrt(delta);
    float denom = (slat1 * slat2) + (clat1 * clat2 * cdlong);
    delta = atan2(delta, denom);
    return fabs(delta) * 6372795 * units_per_meter;
}

/*
 * returns the max speed since last location
 */
static uint16_t _calc_speed_kmh(Location *l1, Location *l2){
    float dist = gps_distance_between(l1,l2,1); // distance in meters
    int16_t time_diff = abs(l1->timestamp - l2->timestamp); // in seconds, in one day
    float s = dist / time_diff * 3.6; // convert to kmh
    float s2 = MAX(l1->speedInKMH, l2->speedInKMH);
    return lroundf( MAX(s, s2) );
}
static bool _smart_beacon_turn_angle_check(Location *location,uint16_t secs_since_beacon){
    // we're stopped.
    if(location->heading == 0 || location->speedInKMH == 0){
        return false;
    }
    
    // previous location.heading == 0 means we're just started from last stop point.
    if(lastLocation.heading == 0){
        return secs_since_beacon >=  SB_TURN_TIME;
    }
    
    uint16_t heading_change_since_beacon =_calc_heading(location,&lastLocation); // (0~180 degrees)
    uint16_t turn_threshold = lroundf(SB_TURN_MIN + (SB_TURN_SLOPE/location->speedInKMH)); // slope/speed [kmh]
    if(secs_since_beacon >= SB_TURN_TIME && heading_change_since_beacon > turn_threshold){
        return true;
    }
    //DEBUG
    //NSLog(&g_serial.fd,"%d,%d,%d,%d\r\n",secs_since_beacon,speed_kmh,heading_change_since_beacon,turn_threshold);
    return false;
}

#define timer_clock_seconds()  [[NSDate date] timeIntervalSince1970]
static bool _fixed_interval_beacon_check(void){
    int32_t rate = SB_FAST_RATE;
    if(lastSendTimeSeconds == 0){
        return true;
    }
    
    int32_t currentTimeStamp = timer_clock_seconds();
    return (currentTimeStamp - lastSendTimeSeconds > (rate));
}

/*
 * smart beacon algorithm - http://www.hamhud.net/hh2/smartbeacon.html
 *
 * reference aprsdroid - https://github.com/ge0rg/aprsdroid/blob/master/src/location/SmartBeaconing.scala
 */
static bool _smart_beacon_check(Location *location){
    if(lastSendTimeSeconds == 0 || lastLocation.timestamp == 0){
        return true;
    }
    // get the delta of time/speed/heading for current location vs last location
    int16_t secs_since_beacon = location->timestamp - lastLocation.timestamp; //[second]
    if(secs_since_beacon <= 0){
        //	that could happen when current and last spot spans one day, so drop that
        return false;
    }
    
    // SMART HEADING CHECK
    if(_smart_beacon_turn_angle_check(location,secs_since_beacon))
        return true;
    
    // SMART TIME CHECK
    float beaconRate;
    uint16_t calculated_speed_kmh = _calc_speed_kmh(location,&lastLocation);    //calcluated speed based on current/previous locations
    if(calculated_speed_kmh/*location->speedInKMH*/ < SB_LOW_SPEED){
        beaconRate = SB_SLOW_RATE;
    }else{
        if(calculated_speed_kmh /*location->speedInKMH*/ > SB_HI_SPEED){
            beaconRate = SB_FAST_RATE;
        }else{
            //beaconRate = (float)SB_FAST_RATE * (SB_HI_SPEED / location.speedInKMH);
            beaconRate = SB_FAST_RATE + (SB_SLOW_RATE - SB_FAST_RATE) * (SB_HI_SPEED - calculated_speed_kmh/*location->speedInKMH*/) / (SB_HI_SPEED-SB_LOW_SPEED);
        }
    }
    long rate = lroundf(beaconRate);
    return (timer_clock_seconds() - lastSendTimeSeconds) > (rate);
}


#pragma mark - Internal Class Implementation

@interface MTSmartBeaconFilter()
@end

@implementation MTSmartBeaconFilter

-(id)init{
    self = [super init];
    if(self){
        lastSendTimeSeconds = 0;
        memset(&lastLocation,0,sizeof(Location));
    }
    
    return self;
}

-(BOOL) accept:(CLLocation*) location{
    BOOL shouldAccept = NO;
    if(self.enableSmartCheck){
        Location loc;
        loc.latitude = location.coordinate.latitude;
        loc.longitude = location.coordinate.longitude;
        loc.altitude = location.altitude;
        loc.speedInKMH = location.speed  * 3.6f;
        loc.heading = location.course;
        loc.timestamp = [location.timestamp timeIntervalSince1970];
        
        shouldAccept = _smart_beacon_check(&loc);
        if(shouldAccept){
            memcpy(&lastLocation,&loc,sizeof(Location));
            lastSendTimeSeconds = timer_clock_seconds();
        }
        
    }else{
        shouldAccept = _fixed_interval_beacon_check();
        if(shouldAccept){
            lastSendTimeSeconds = timer_clock_seconds();
        }
    }
    return shouldAccept;
}

@end
