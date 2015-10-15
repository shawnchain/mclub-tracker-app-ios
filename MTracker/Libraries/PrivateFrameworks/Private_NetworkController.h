//
//  NetworkController.h
//  MTracker
//
//  Created by Shawn Chain on 15/9/22.
//  Copyright © 2015年 MClub. All rights reserved.
//

#ifndef NetworkController_h
#define NetworkController_h

@class NSString, NSTimer;

@interface NetworkController : NSObject
{
    struct __SCDynamicStore *_store;
    NSString *_domainName;
    unsigned int _waitingForDialToFinish:1;
    unsigned int _checkedNetwork:1;
    unsigned int _isNetworkUp:1;
    unsigned int _isFatPipe:1;
    unsigned int _edgeRequested:1;
    NSTimer *_notificationTimer;
}

+ (id)sharedInstance;
- (void)dealloc;
- (id)init;
- (BOOL)isNetworkUp;
- (BOOL)isFatPipe;
- (BOOL)inAirplaneMode;
- (id)domainName;
- (BOOL)isHostReachable:(id)fp8;
- (id)primaryEthernetAddressAsString;
- (id)IMEI;
- (id)edgeInterfaceName;
- (BOOL)isEdgeUp;
- (void)bringUpEdge;
- (void)keepEdgeUp;
- (void *)createPacketContextAssertionWithIdentifier:(id)fp8;

@end

#endif /* NetworkController_h */
