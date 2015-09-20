//
//  MServiceEndpoint.h
//  
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#import <Foundation/Foundation.h>

@class QServiceEndpoint;
@class QServiceRequest;

/**
 * Enum MServiceModelConvertProfile
 */
typedef enum{
    MServiceModelConvertProfileDefault = 0,
    MServiceModelConvertProfilePost = 1
}MServiceModelConvertProfile;


@protocol MServiceEndpointFilter<NSObject>
@optional
-(void)endpoint:(QServiceEndpoint*)endpoint willSendRequest:(QServiceRequest*)request;
-(void)endpoint:(QServiceEndpoint*)endpoint didReceivedResponseForRequest:(QServiceRequest*)request;
@end

/////////////////////////////////////////////
#pragma mark - MServiceEndpoint

// forwared declaration
@class QServiceHttpConnector;
@class QServiceProtocol;

/**
 * MServiceEndpoint
 *
 */
@interface QServiceEndpoint :NSObject

@property(nonatomic,readonly)NSString* URLString;

/*
 * App key for service api access. 
 *
 * //TODO - should be refactored into MServiceAuthPolicy
 *
 */
@property(nonatomic,strong)NSString *appkey;

/**
 * Register service API root
 *
 * @discussion manually sepecify service api root, but will take no effect if app settings contains value with key "mservice_settings_api_root", 
 */
+(void)registerServiceAPIRoot:(NSString*)url;

/*
 * Get service API root
 */
+(NSString*)getServiceAPIRoot;

/*
 * Register service filter for additional hook-up
 *
 */
+(void)registerGlobalFilter:(id<MServiceEndpointFilter>)filter;

/*
 * Unregister service filter
 *
 */
+(void)unregisterGlobalFilter:(id<MServiceEndpointFilter>)filter;

/**
 * Get shared endpoint instance by name
 *
 */
+(QServiceEndpoint*)endpointWithName:(NSString*)serviceNameOrURL;

/**
 * Initialize the endpoint with service name
 *
 * @discussion endpoint will read app settings for api root url with key "mservice_settings_api_root"
 */
-(id)initWithName:(NSString*)serviceName;

/**
 * Initialize the endpoint with full URL string
 * 
 * @discussion endpoint will use the parameter as it's full URL string, ingore all other root api URL settings.
 */
-(id)initWithURL:(NSString*)url;

/**
 * Initialize the endpoint with full URL string and protocol
 *
 * @discussion url:endpoint will use the parameter as it's full URL string, ingore all other root api URL settings.
 * @discussion protocolName: the protocol name used for service API call. Currently only JoyAPI & MTOP is supported
 */
-(id)initWithURL:(NSString*)url protocol:(NSString*)protocolName;

/**
 * Initialize the endpoint with API root URL and servie name
 */
-(id)initWithRootURL:(NSString*)url serviceName:(NSString*)serviceName;

/**
 * Hook point for post-initialize
 */
-(void)endpointDidInitialized;

/**
 * Send request to server
 * @discussion this method returns immediately and delegate will be fired when there are something happen(updated or finished).
 *
 * @returns the ticket
 */
-(void)sendRequest:(QServiceRequest*)request;
@end

/**
 *@discussion setting key for API ROOT URL
 */
extern NSString* const kMSERVICE_SETTINGS_API_ROOT_KEY;

/*
 * settings key for Access Token
 */
extern NSString* const kMSERVICE_SETTINGS_ACCESS_TOKEN_KEY;