//
//  APTIBle.h
//  MTracker
//
//  Created by Shawn Chain on 16/12/3.
//  Copyright © 2016年 MClub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class APTIBle;

typedef enum{
    APTI_NO_ERROR = 0,
    APTI_CONNECTED,
    APTI_TIMEOUT,
    APTI_ERROR, /*READ/WRITE ERROR*/
}APTIBleStatusCode;

typedef void (^APTIBleCallback)(APTIBle *device,APTIBleStatusCode code, NSData *data);

@interface APTIBle : NSObject

-(id) initWithCallback:(APTIBleCallback) cb;

-(void) connect;

-(void) disconnect;
@end


#pragma mark Extensions
@interface CBCharacteristic(APTIBle)
-(NSString*) stringValue;
-(NSUInteger)uint32Value;
@end


@interface CBUUID(APTIBle)
+(CBUUID*)UUIDWithShort:(unsigned short) value;
-(unsigned short) shortValue;
@end
