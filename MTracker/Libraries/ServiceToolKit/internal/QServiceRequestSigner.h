//
//  MServiceRequestSigner.h
//  AppManagerClient
//
//  Created by Shawn Chain on 13-2-10.
//  Copyright (c) 2013年 JoyLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QServiceRequest;

@interface QServiceRequestSigner : NSObject

+ (NSString *)signRequestString:(NSString *)baseString appSecret:(NSString *)appSecret;

+ (NSString *)signRequest:(QServiceRequest *)request appSecret:(NSString *)appSecret;
@end
