//
//  QServiceConnection-Internal.h
//  
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QServiceEndpoint.h"
#import "QServiceModel.h"
#import "QServiceRequest.h"

/////////////////////////////////////////////
// Service content type
extern NSString* const kQService_HTTP_METHOD_GET;
extern NSString* const kQService_HTTP_METHOD_POST;
extern NSString* const kQSERVICE_CONTENT_TYPE_FORM;
extern NSString* const kQSERVICE_CONTENT_TYPE_JSON;


/*
 * MServiceRequest internals
 */
@interface QServiceRequest(){
@private NSMutableDictionary *_postValues,*_parameters;
}

@property(nonatomic,strong)NSString* operationName;
@property(nonatomic,strong)NSString* httpMethod;
@property(nonatomic,strong)NSString* contentType;
@property(nonatomic,assign)Class returnType;
@property(nonatomic,assign)QServiceRequestStatus status;

@property(nonatomic,strong) NSMutableData* responseData;
@property(nonatomic,strong) id returnObject;
@property(nonatomic,strong) NSError* error;
@property(nonatomic,assign) float progress;

@property(nonatomic,strong) NSURLConnection* connection;
@property(nonatomic,strong) NSMutableURLRequest* httpRequest;
@property(nonatomic,strong) NSHTTPURLResponse* httpResponse;

@property(nonatomic,strong) QServiceEndpoint* endpoint;

-(NSMutableDictionary*) getMutableParameters;
@end

/*
 * MServiceEndpoint internals
 */
@interface QServiceEndpoint()

@property(nonatomic,strong) QServiceHttpConnector *connector;
//@property(nonatomic,strong) QerviceProtocol *protocol;
@property(nonatomic,strong) NSMutableArray *filters;

//@property(nonatomic,strong) id<QServiceEndpointDelegate> delegate;
//@property(nonatomic,strong) id<QServiceEndpointAuthDelegate> authDelegate;

// Internal callbacks by connectors
-(void)_cancelRequest:(QServiceRequest*)request;
-(void)_handleRequest:(QServiceRequest*)request;
-(void)_beforeSendRequest:(QServiceRequest*)request;
@end

/*
 * QService model internals
 */
@interface QServicePageResult()
@property(nonatomic,assign) NSInteger size;
@property(nonatomic,assign) NSInteger offset;
@property(nonatomic,strong) NSArray* items;
@end

@interface QServiceError()
    @property(nonatomic,strong) NSString* code;
    @property(nonatomic,strong) NSString* message;
    @property(nonatomic,strong) NSString* desc;
@end

