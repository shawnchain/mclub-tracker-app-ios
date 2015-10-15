//
//  QServiceProtocol.m
//
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#import "QServiceToolkit-Internals.h"
#import "QServiceProtocol.h"
#import "QServiceRequest.h"
#import "QServiceRequestSigner.h"
#import "QServiceProtocol_JOYAPI.h"

#pragma mark - QServiceProtocol

NSString* const kQSERVICE_PROTOCOL_MTOP = @"MTOP";
NSString* const kQSERVICE_PROTOCOL_DEFAULT = @"JoyAPI";

@implementation QServiceProtocol

+(QServiceProtocol*)defaultProtocol{
    return [self protocolNamed:kQSERVICE_PROTOCOL_DEFAULT];
}

+(QServiceProtocol*)protocolNamed:(NSString*)protocolName{
    if(protocolName == nil || [kQSERVICE_PROTOCOL_DEFAULT isEqualToString:protocolName]){
        // the DEFAULT protocol
        return [[[QServiceProtocol_JOYAPI alloc] init] autorelease];
    }else if([kQSERVICE_PROTOCOL_MTOP isEqualToString:protocolName]){
        // the MTOP protocol
        return nil;
    }else{
        return nil;
    }
}

-(void)endpoint:(QServiceEndpoint*)endpoint willSendRequest:(QServiceRequest*)request{
    // NOOP;
}

-(void)endpoint:(QServiceEndpoint*)endpoint didReceivedResponseForRequest:(QServiceRequest*)request{
    NSAssert(1 + 1 == 3,@"didReceivedResponseForRequest is not implemented yet!");
}

@end