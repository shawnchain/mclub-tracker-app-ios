//
//  QServiceHttpConnector.m
//
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#import "QServiceHttpConnector.h"
#import "JSONKit.h"
#import "QLogger.h"
#import <UIKit/UIApplication.h>
#import "NSInvocation+vaargs.h"

@implementation QServiceHttpConnector

#define DEFAULT_DATA_BUFFER_SIZE 4096 * 1024 // 4K buffer size

-(id)init{
    self = [super init];
    if(self){
        _requestQueue = [[NSMutableArray alloc] initWithCapacity:8];
    }
    return self;
}

-(void)dealloc{
    DBG(@"dealloc connector %@",self);
    [self cancelAll];
    [_requestQueue release];
    [super dealloc];
}

-(QServiceRequest*)_getRequestByConnection:(NSURLConnection*)conn{
    for(QServiceRequest* r in _requestQueue){
        if(r.connection == conn){
            return r;
        }
    }
    return nil;
}

-(void)_handleRequest:(QServiceRequest*)request{
    [self _enableNetworkActivity:NO];
    // mark ticket as finished
    request.status = MServiceRequestStatusFinished;
    
    if(request.error){
        ERROR(@"request(%@) finished with error %@",request.httpRequest.URL.lastPathComponent, request.error);
    }else{
        INFO(@"request(%@) finished successfully with %d bytes read in total.",request.httpRequest.URL.lastPathComponent,[request.responseData length]);
        
        // delegate to the endpoint for ticket handling. eg: parse the response as json data...
        [request.endpoint _handleRequest:request];
    }
    
    id<QServiceRequestDelegate> delegate = request.delegate;
    NSInvocation *i = nil;
    if(request.error){
        SEL failSelector = @selector(request:failedWithError:);
        if(delegate && [delegate respondsToSelector:failSelector]){
            // call delegate's fial selector on mian thread
            i = [NSInvocation invocationWithTarget:delegate selector:failSelector retainArguments:YES argList:@[request,request.error]];
        }
    }else{
        SEL completeSelector = @selector(request:completedWithObject:);
        if(delegate && [delegate respondsToSelector:completeSelector]){
            // call delegate's complete selector on mian thread
            i = [NSInvocation invocationWithTarget:delegate selector:completeSelector retainArguments:YES argList:@[request,request.returnObject]];
        }
    }
    [i invokeOnMainThreadWaitUntilDone:NO];

    
    // we'll remove ticket from queue
    // if caller not retain the ticket, it might be released
    // so retain and autorelease again.
    [[request retain] autorelease];
    //@finally remove ticket from queue
    [_requestQueue removeObject:request];
}

-(void) _enableNetworkActivity:(BOOL)enabled{
    static int enableCount = 0;
    if(enabled){
        if((++enableCount) == 1){
            // enable
            [UIApplication sharedApplication].networkActivityIndicatorVisible = enabled;
        }
    }else{
        if(enableCount > 0 && (--enableCount) == 0){
            // disable
            [UIApplication sharedApplication].networkActivityIndicatorVisible = enabled;
        }
    }
    NSAssert(enableCount >=0,@"invalid enableCount: %d",enableCount);
}

#pragma mark - Public methods
-(void) cancel:(QServiceRequest*)request{
    [self _enableNetworkActivity:NO];
    request.status = MServiceRequestStatusCanceled;
    [request.connection cancel];
    [[request retain] autorelease];
    [_requestQueue removeObject:request];
    //TODO - notify delegate ?
    //request.delegate = nil;
}

-(void) cancelAll{
    [self _enableNetworkActivity:NO];
    for(QServiceRequest* request in _requestQueue){
        [request.connection cancel];
        request.status = MServiceRequestStatusCanceled;
    }
    [_requestQueue removeAllObjects];
}

-(void) perform:(QServiceRequest*)request{
    // endpoint callback
    [request.endpoint _beforeSendRequest:request];

    // update request status
    request.status = MServiceRequestStatusPending;
    
    // update network activity
    [self _enableNetworkActivity:YES];
    
    // perform connect
    if(request.delegate){
        //send request asynchronously
        //Queue ticket w/o duplications.
        if(![_requestQueue containsObject:request]){
            [_requestQueue addObject:request];
        }
        
        NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest:request.httpRequest delegate:self startImmediately:NO] ;
        request.connection = conn;
        [conn start];
        [conn release];
    }else{
        //no delegate, send request synchronously
        NSURLResponse* resp = nil;
        NSError* error = nil;
        NSData* resultData = [NSURLConnection sendSynchronousRequest:request.httpRequest returningResponse:&resp error:&error];
        if(resultData){
            NSMutableData* respData = request.responseData;
            if(!respData){
                respData = [[NSMutableData alloc] initWithCapacity:DEFAULT_DATA_BUFFER_SIZE];
                request.responseData = respData;
                [respData release];
            }
            [respData appendData:resultData];
        }
        
        NSAssert(resp!=nil && [resp isKindOfClass:[NSHTTPURLResponse class]],
                 @"Expected an instance of NSHTTPURLResponse, but got %@:%@",[resp class],resp);
        request.httpResponse = (NSHTTPURLResponse*)resp;
        
        //DBG(@"_requestFinished ticket %@, error %@",ticket,error);
        if(error){
            request.error = error;
        }
        [self _handleRequest:request];
    }
}

/////////////////////////////////////////////
#pragma mark - connection delegate callbacks
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    DBG(@"sent %d of %d bytes, %d bytes left",bytesWritten,totalBytesExpectedToWrite,totalBytesExpectedToWrite - totalBytesWritten);
    //TODO update progress if uploading huge file
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    QServiceRequest *_currentRequest = [self _getRequestByConnection:connection];
    if(!_currentRequest){
        DBG(@"No request found in queue for connection %@, maybe canceled, URLConnection callback aborted",connection);
        return;
    }
    
#if DEBUG
    long long expectedContentLength = [response expectedContentLength];
    DBG(@"got response, expected content length is:%d",expectedContentLength);
#endif
    
    NSAssert([response isKindOfClass:[NSHTTPURLResponse class]],
             @"Expected an instance of NSHTTPURLResponse, but got %@:%@.",[response class],response);
    _currentRequest.httpResponse = (NSHTTPURLResponse*)response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    QServiceRequest *_currentRequest = [self _getRequestByConnection:connection];
    if(!_currentRequest){
        DBG(@"No ticket found in queue for connection %@, maybe canceled, URLConnection callback aborted",connection);
        return;
    }
    
    long long expectedContentLength = [_currentRequest.httpResponse expectedContentLength];
    NSMutableData* respData = _currentRequest.responseData;
    if(!respData){
        NSUInteger bufferSize = (expectedContentLength > 0 &&  expectedContentLength < DEFAULT_DATA_BUFFER_SIZE)?(NSUInteger)expectedContentLength:DEFAULT_DATA_BUFFER_SIZE;
        respData = [[NSMutableData alloc] initWithCapacity:bufferSize];
        _currentRequest.responseData = respData;
        [respData release];
    }
    [respData appendData:data];
    
    float progress = 0;
    if(expectedContentLength > 0){
        progress = (float)[respData length] /(float)expectedContentLength;
        _currentRequest.progress = progress;
    }
    DBG(@"received %d bytes, progress: %d%%",[data length],(int)(progress * 100));
    
    // Notify the delegate for progress update.
    id<QServiceRequestDelegate> delegate = _currentRequest.delegate;
    
    SEL updateSelector = @selector(request:updatedWithProgress:);
    if([delegate respondsToSelector:updateSelector]){
        NSInvocation *i = [NSInvocation invocationWithTarget:delegate selector:updateSelector retainArguments:NO argList:@[_currentRequest, [NSNumber numberWithFloat:_currentRequest.progress]]];
        [i invokeOnMainThreadWaitUntilDone:NO];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    QServiceRequest *_currentRequest = [self _getRequestByConnection:connection];
    if(!_currentRequest){
        DBG(@"No ticket found in queue for connection %@, maybe canceled, URLConnection callback aborted",connection);
        return;
    }
    
    [self _handleRequest:_currentRequest];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    QServiceRequest *_currentRequest = [self _getRequestByConnection:connection];
    if(!_currentRequest){
        DBG(@"No ticket found in queue for connection %@, maybe canceled, URLConnection callback aborted",connection);
        return;
    }
    _currentRequest.error = error;
    [self _handleRequest:_currentRequest];
}

@end
