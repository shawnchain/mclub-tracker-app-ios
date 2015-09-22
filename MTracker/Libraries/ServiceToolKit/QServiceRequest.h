//
//  MServiceRequest.h
//  AppManagerClient
//
//  Created by Shawn Chain on 12-12-16.
//  Copyright (c) 2012年 JoyLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QServiceRequest;

/////////////////////////////////////////////
#pragma mark - QServiceRequestDelegate protocol
/**
 * QServiceRequest delegate protocol.
 */
@protocol QServiceRequestDelegate<NSObject>


-(void)request:(QServiceRequest*)request completedWithObject:(id)returnObject;

@optional
-(void)request:(QServiceRequest*)request failedWithError:(NSError*)error;


-(void)request:(QServiceRequest*)request updatedWithProgress:(double)progress;

//-(void)request:(MServiceRequest*)request canceldWithReason:(NSString*)reason;
@end






/////////////////////////////////////////////
#pragma mark - QServiceRequestBlockDelegate

typedef void (^QServiceRequestCompleteBlock)(QServiceRequest *request, id returnObject);
typedef void (^QServiceRequestErrorBlock)(QServiceRequest *request, NSError *error);
typedef void (^QServiceRequestUpdateBlock)(QServiceRequest *request, double updateProgress);
typedef void (^QServiceRequestCancelBlock)(QServiceRequest *request, NSString *reason);

/*
 * MServiceDelegate implementation that callbacks to fine-grained blockers when service returns
 */
@interface QServiceRequestBlockDelegate:NSObject<QServiceRequestDelegate>

@property (nonatomic,copy) QServiceRequestCompleteBlock completeBlock;
@property (nonatomic,copy) QServiceRequestErrorBlock failBlock;
@property (nonatomic,copy) QServiceRequestUpdateBlock updateBlock;
@property (nonatomic,copy) QServiceRequestCancelBlock cancelBlock;

/*
 * Create a delegate with finish clalback blocker and update blocker
 *
 * @param MServiceCallbackBlock aFinishBlock
 * @param MServiceCallbackBlock aUpdateBlock
 *
 * @returns id<MServiceDelegate>
 */
+(id<QServiceRequestDelegate>)delegateWithCompleteBlock:(QServiceRequestCompleteBlock)completeBlock failBlock:(QServiceRequestErrorBlock)failBlock updateBlock:(QServiceRequestUpdateBlock)updatedBlock cancelBlock:(QServiceRequestCancelBlock)cancelBlock;
+(id<QServiceRequestDelegate>)delegateWithCompleteBlock:(QServiceRequestCompleteBlock)completeBlock failBlock:(QServiceRequestErrorBlock)failBlock;
+(id<QServiceRequestDelegate>)delegateWithCompleteBlock:(QServiceRequestCompleteBlock)completeBlock;
@end





/////////////////////////////////////////////
#pragma mark - QServiceRequestSelectorDelegate
/*
 * MServiceRequestSelectorDelegate implementation that callbacks to fine-grained selectors when service returns
 */
@interface QServiceRequestSelectorDelegate:NSObject<QServiceRequestDelegate> {
}
/*
 * target object
 */
@property(nonatomic,strong) id target;
/**
 * completed callback selector
 */
@property(nonatomic,assign) SEL completeSelector;
/**
 * failed callback selector
 */
@property(nonatomic,assign) SEL errorSelector;
/**
 * updated callback selector
 */
@property(nonatomic,assign) SEL updateSelector;

@property(nonatomic,assign) SEL cancelSelector;


+(id<QServiceRequestDelegate>)delegateWithTarget:(id)target completeSelector:(SEL)completeSelector failSelector:(SEL)failSelector updateSelector:(SEL)updateSelector cancelSelector:(SEL)cancelSelector;

/**
 * dispatch callbacks to different selectors
 */
+(id<QServiceRequestDelegate>)delegateWithTarget:(id)target completeSelector:(SEL)completeSelector failSelector:(SEL)failSelector;


+(id<QServiceRequestDelegate>)delegateWithTarget:(id)target completeSelector:(SEL)completeSelector;
@end



/////////////////////////////////////////////
#pragma mark - MServiceRequest

/*
 * Enum MServiceTicketStatus
 */
typedef enum {
    MServiceRequestStatusInitialized = 0,
    MServiceRequestStatusPending = 1,
    MServiceRequestStatusFinished = 2,
    MServiceRequestStatusCanceled = 3
}QServiceRequestStatus;

/**
 * Service Request Object
 * @discussion encapsulates all request info: operation path, http method, parameters...
 */
@interface QServiceRequest : NSObject

/*
 *
 */
@property(nonatomic,readonly,strong)NSString* operationName;
/*
 *
 */
@property(nonatomic,readonly,assign)Class returnType;
/*
 *
 */
@property(nonatomic,strong)NSString* endpointName;
/*
 *
 */
@property(nonatomic,strong)id<QServiceRequestDelegate> delegate;


/*
 *
 */
@property(nonatomic,readonly, getter = getPostValues)NSDictionary *postValues;
/*
 *
 */
@property(nonatomic,readonly, getter = getParameters)NSDictionary *parameters;

/*
 *
 */
@property(nonatomic, assign)QServiceRequestCompleteBlock completeBlock;
/*
 *
 */
@property(nonatomic, assign)QServiceRequestErrorBlock failBlock;
/*
 *
 */
@property(nonatomic, assign)QServiceRequestUpdateBlock updateBlock;
/*
 *
 */
//@property(nonatomic, assign)MServiceRequestCancelBlock cancelBlock;

/*
 * server return value
 * @discussion unmarshalled as object if returnType specified. or the NSData for raw response.
 */
@property(nonatomic,readonly,strong) id returnObject;
/*
 * Ticket error
 * @discussion if something wrong from server response, error will be set.
 */
@property(nonatomic,readonly,strong) NSError* error;
/*
 * the overall progress of ticket request
 */
@property(nonatomic,readonly,assign) float progress;
/*
 *
 */
@property(nonatomic,readonly,assign)QServiceRequestStatus status;

/*
 * Customized user data
 */
@property(nonatomic,retain)id userData;

/*
 * Construct service reuqest with basic info, need set delegate or block before sending
 */
+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType;

/*
 * Construct service request
 */
+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType delegate:(id<QServiceRequestDelegate>)delegate;

/*
 * Construct service request
 * @discussion Instantiate service request with fine-grained callback method selectors
 */
+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType delegate:(id)delegate completeSelector:(SEL)completeSelector failSelector:(SEL)failSelector;

/*
 *
 */
+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType completeBlock:(QServiceRequestCompleteBlock)completeBlock failBlock:(QServiceRequestErrorBlock)failBlock;


/*
 * Add value for POST request
 * @discussion Add standard key/value pair for posts. duplicated name/values are not supported yet
 */
-(void)addPostValue:(id)value forKey:(NSString*)key;

/*
 * Add value for POST request
 * @discussion Add standard key/value pair for posts. duplicated name/values are not supported yet
 */
-(void)addPostValueString:(NSString*)value forKey:(NSString*)key;

/*
 * Add value for POST request
 * @discussion Add standard key/value pair for posts. duplicated name/values are not supported yet
 */
-(void)addPostValueDouble:(double)value forKey:(NSString*)key;

/*
 * Add value for POST request
 * @discussion Add standard key/value pair for posts. duplicated name/values are not supported yet
 */
-(void)addPostValueInt:(int)value forKey:(NSString*)key;


/*
 * get post values
 */
-(NSDictionary*)getPostValues;

/*
 * Add request parameters
 * @discussion parameters will be append to the final url string with uuencoded
 */
-(void)addParameter:(NSString*)value forKey:(NSString*)key;

/*
 * Get URL parameters
 */
-(NSDictionary*)getParameters;


/*
 * Send request with specific service endpoint.
 */
-(void)sendToEndpoint:(NSString*)endpointName;

/*
 * Send request using default endpoint
 */
-(void)send;
/*
 * Cancel the request
 */
-(void)cancel;
@end
