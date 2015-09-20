//
//  MServiceProtocol.h
//
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QServiceEndpoint.h"
@class QServiceRequest;


/////////////////////////////////////////////
#pragma mark - MServceProtocol

extern NSString* const kMSERVICE_PROTOCOL_MTOP;
extern NSString* const kMSERVICE_PROTOCOL_DEFAULT;

/**
 * Servie protocol abstraction
 *
 * @discussion Protocol handles the response string and unmarshall to model objects. 
 * By default, an instance that supports JoyAPI protocol will be returned.
 *
 */
@interface QServiceProtocol : NSObject<MServiceEndpointFilter>

/**
 * @returns default protocol instance that supports JoyAPI
 */
+(QServiceProtocol*)defaultProtocol;

/**
 * @returns protocol instance or null if protocol is not supported
 */
+(QServiceProtocol*)protocolNamed:(NSString*)protocolName;

#pragma mark - MServiceEndpoint Filter calss
-(void)endpoint:(QServiceEndpoint*)endpoint willSendRequest:(QServiceRequest*)request;

-(void)endpoint:(QServiceEndpoint*)endpoint didReceivedResponseForRequest:(QServiceRequest*)request;

@end
