//
//  QServiceRequest.m
//
//  Created by Shawn Chain on 12-12-16.
//  Copyright (c) 2012年 JoyLabs. All rights reserved.
//

#import "QServiceRequest.h"
#import "QServiceToolkit-Internals.h"
#import "QService_URLStrings.h"
#import "QLogger.h"

#pragma mark - ServiceRequest Implementation
@implementation QServiceRequest

+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType{
    return [self requestForOperation:opName returnType:returnType delegate:nil];
}

+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType delegate:(id<QServiceRequestDelegate>)delegate{
    QServiceRequest *req = [[QServiceRequest alloc] init];
    req.httpMethod = kQService_HTTP_METHOD_GET;
    req.operationName = opName;
    req.returnType = returnType;
    req.delegate = delegate;
    req.status = MServiceRequestStatusInitialized;
    return [req autorelease];
}

+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType delegate:(id)delegate completeSelector:(SEL)completeSelector failSelector:(SEL)failSelector{
    QServiceRequestSelectorDelegate *del = [QServiceRequestSelectorDelegate delegateWithTarget:delegate completeSelector:completeSelector failSelector:failSelector];
    return [self requestForOperation:opName returnType:returnType delegate:del];
}

+(QServiceRequest*)requestForOperation:(NSString*)opName returnType:(Class)returnType completeBlock:(QServiceRequestCompleteBlock)completeBlock failBlock:(QServiceRequestErrorBlock)failBlock{
    QServiceRequestBlockDelegate *del = [QServiceRequestBlockDelegate delegateWithCompleteBlock:completeBlock failBlock:failBlock];
    return [self requestForOperation:opName returnType:returnType delegate:del];
}

-(void)dealloc{
    DBG(@"dealloc request %@",self);
    self.httpMethod = nil;
    self.operationName = nil;
    self.contentType = nil;
    
    self.responseData = nil;
    self.returnObject = nil;
    self.error = nil;
    
    self.connection = nil;
    self.httpRequest = nil;
    self.httpResponse = nil;
    
    self.delegate = nil;
    self.endpoint = nil;
    self.endpointName = nil;
    
    self.userData = nil;
    
    [_postValues release];
    [_parameters release];
    
    [super dealloc];
}

-(void)addPostValueInt:(int)value forKey:(NSString*)key{
    [self addPostValue:[NSNumber numberWithInt:value] forKey:key];
}
-(void)addPostValueDouble:(double)value forKey:(NSString*)key{
    [self addPostValue:[NSNumber numberWithDouble:value] forKey:key];
}

-(void)addPostValueString:(NSString*)value forKey:(NSString*)key{
    [self addPostValue:value forKey:key];
}

-(void)addPostValue:(id)value forKey:(NSString*)key{
    NSAssert(_status == MServiceRequestStatusInitialized,@"Could not change request after it has been sent!");
    if(_postValues == nil){
        _postValues = [[NSMutableDictionary alloc] initWithCapacity:32];
        if([self.httpMethod isEqualToString:kQService_HTTP_METHOD_GET]){
            self.httpMethod = kQService_HTTP_METHOD_POST;
            self.contentType = kQSERVICE_CONTENT_TYPE_FORM;
        }
    }
    [_postValues setValue:value forKey:key];
}

-(NSDictionary*)getPostValues{
    if(_postValues){
        return [NSDictionary dictionaryWithDictionary:_postValues];
    }else{
        return nil;
    }
}

-(void)addParameter:(NSString*)value forKey:(NSString*)key{
    NSAssert(_status == MServiceRequestStatusInitialized,@"Could not change request after it has been sent!");
    if(_parameters == nil){
        _parameters = [[NSMutableDictionary alloc] initWithCapacity:32];
    }
    [_parameters setValue:value forKey:key];
}

-(NSDictionary*)getParameters{
    if(_parameters){
        return [NSDictionary dictionaryWithDictionary:_parameters];
    }else{
        return nil;
    }
}

/*
 * get the internal mutable parameter dict. Internal use only!
 */
-(NSMutableDictionary*) getMutableParameters{
    return _parameters;
}

-(NSMutableURLRequest*) httpRequest{
    if(_httpRequest == nil){
        /*
         * build http request object and the existing one will be override
         */
        if([self.httpMethod isEqualToString:kQService_HTTP_METHOD_POST]){
            [self _buildHttpPostRequest];
        }else if([self.httpMethod isEqualToString:kQService_HTTP_METHOD_GET]){
            [self _buildHttpGetRequest];
        }else{
            NSAssert(NO,@"Unsupported http method: %@",self.httpMethod);
        }
    }
    return _httpRequest;
}

static NSString* _assembleURL(NSString* base, NSString* path, NSDictionary* params){
    NSMutableString *url = [[[NSMutableString alloc] initWithCapacity:128] autorelease];
    if(path.length > 0){
        [url appendString:[base stringByAppendingUrlPathComponent:path]];
    }else{
        [url appendString:base];
    }
    if(params && [params count] > 0){
        [url appendString:@"?"];
        [url appendString:[params stringWithFormEncodedComponents]];
    }
    return url;
}

-(void)_buildHttpPostRequest{
    NSDictionary* params = self.parameters;
    NSData* data = [[self.postValues stringWithFormEncodedComponents]dataUsingEncoding:NSUTF8StringEncoding];
    NSString* contentType = self.contentType;
    
    // Setup the request
    NSURL *url = [NSURL URLWithString:_assembleURL(self.endpoint.URLString,self.operationName,params)];
    DBG(@"Build http request: POST: %@",url);
    NSMutableURLRequest* httpRequest = [NSMutableURLRequest requestWithURL:url];
    [httpRequest setTimeoutInterval:25.0]; //FIXME - configurable timeout
    [httpRequest setHTTPMethod:kQService_HTTP_METHOD_POST];
    if(contentType){
        [httpRequest setValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
    [httpRequest setValue:[NSString stringWithFormat:@"%d",(int)[data length]] forHTTPHeaderField:@"Content-Length"];
    [httpRequest setHTTPBody:data];
    self.httpRequest = httpRequest;
}

-(void)_buildHttpGetRequest{
    NSDictionary* params = self.parameters;
    
    NSURL *url = [NSURL URLWithString:_assembleURL(self.endpoint.URLString,self.operationName,params)];
    DBG(@"Build http request: GET %@",url.absoluteString);
    
    NSMutableURLRequest* httpRequest = [NSMutableURLRequest requestWithURL:url];
    [httpRequest setHTTPMethod:kQService_HTTP_METHOD_GET];
    [httpRequest setTimeoutInterval:15.0];
    self.httpRequest = httpRequest;
}


#pragma mark - Block callback accessor
-(QServiceRequestBlockDelegate*) _getBlockDelegate{
    if(_delegate!= nil && ![_delegate isKindOfClass:[QServiceRequestBlockDelegate class]]){
        //OVERRIDE OR BAIL-OUT ?
        // user already has a delegate set
        NSAssert(false,@"completeBlock could not be set while request.delegate is %@",_delegate);
    }
    if(_delegate == nil){
        _delegate = [[QServiceRequestBlockDelegate alloc] init];
    }
    QServiceRequestBlockDelegate *bd = (QServiceRequestBlockDelegate*)_delegate;
    return bd;
}
-(void)setCompleteBlock:(QServiceRequestCompleteBlock)completeBlock{
    [self _getBlockDelegate].completeBlock = completeBlock;
}

-(QServiceRequestCompleteBlock) completeBlock{
    if([_delegate isKindOfClass:[QServiceRequestBlockDelegate class]]){
        return ((QServiceRequestBlockDelegate*)_delegate).completeBlock;
    }
    return nil;
}
-(void)setFailBlock:(QServiceRequestErrorBlock)failBlock{
    [self _getBlockDelegate].failBlock = failBlock;
}
-(QServiceRequestErrorBlock)failBlock{
    if([_delegate isKindOfClass:[QServiceRequestBlockDelegate class]]){
        return ((QServiceRequestBlockDelegate*)_delegate).failBlock;
    }
    return nil;
}
-(void)setUpdateBlock:(QServiceRequestUpdateBlock)updateBlock{
    [self _getBlockDelegate].updateBlock = updateBlock;
}
-(QServiceRequestUpdateBlock)updateBlock{
    if([_delegate isKindOfClass:[QServiceRequestBlockDelegate class]]){
        return ((QServiceRequestBlockDelegate*)_delegate).updateBlock;
    }
    return nil;
}



-(void)send{
    NSString *ename = self.endpointName;
    if(!ename){
        ename = @"/";
    }
    [self sendToEndpoint:ename];
}

-(void)sendToEndpoint:(NSString*)endpointName{
    [[QServiceEndpoint endpointWithName:endpointName] sendRequest:self];
}

-(void)cancel{
    [self.endpoint _cancelRequest:self];
}
@end



//===============================================================================================
// MServiceRequestBlockDelegate implementation
//===============================================================================================
@implementation QServiceRequestBlockDelegate

+(id<QServiceRequestDelegate>)delegateWithCompleteBlock:(QServiceRequestCompleteBlock)completeBlock failBlock:(QServiceRequestErrorBlock)failBlock updateBlock:(QServiceRequestUpdateBlock)updatedBlock cancelBlock:(QServiceRequestCancelBlock)cancelBlock{
    
    QServiceRequestBlockDelegate *delegate = [[self alloc] init];
    delegate.completeBlock = completeBlock;
    delegate.failBlock = failBlock;
    delegate.updateBlock = updatedBlock;
    delegate.cancelBlock = cancelBlock;
    return [delegate autorelease];
}

+(id<QServiceRequestDelegate>)delegateWithCompleteBlock:(QServiceRequestCompleteBlock)completeBlock failBlock:(QServiceRequestErrorBlock)failBlock{
    return [self delegateWithCompleteBlock:completeBlock failBlock:failBlock updateBlock:nil cancelBlock:nil];
}

+(id<QServiceRequestDelegate>)delegateWithCompleteBlock:(QServiceRequestCompleteBlock)completeBlock{
    return [self delegateWithCompleteBlock:completeBlock failBlock:nil updateBlock:nil cancelBlock:nil];
}


-(void)dealloc{
    DBG(@"dealloc delegate %@",self);
    self.completeBlock = nil;
    self.failBlock = nil;
    self.updateBlock = nil;
    self.cancelBlock = nil;
    [super dealloc];
}

//FIXME - delegate is always called in main thread inside service tookit(connector)
-(void) request:(QServiceRequest *)request completedWithObject:(id)returnObject{
    //NOTE - we assume the selector accepts the only one parameter of ticket;
    if(_completeBlock){
        //__block MServiceTicket *tkt = ticket;
        //dispatch_async(dispatch_get_main_queue(),^{_finishedBlock(_tkt);});
        dispatch_async(dispatch_get_main_queue(),^{_completeBlock(request,returnObject);});
    }
}

-(void) request:(QServiceRequest *)request failedWithError:(NSError *)error{
    // If we have fail block set, call it.
    // If not, fall back to the complete block, and user handles the request.error manually    
    if(_failBlock){
        dispatch_async(dispatch_get_main_queue(),^{_failBlock(request,error);});
    }else{
        [self request:request completedWithObject:request.returnObject];
    }
}

-(void) request:(QServiceRequest *)request updatedWithProgress:(double)progress{
    if(_updateBlock){
        dispatch_async(dispatch_get_main_queue(),^{_updateBlock(request,progress);});
    }
}

@end



//===============================================================================================
// MServiceRequestSelectorDelegate implementation
//===============================================================================================
#pragma mark - ServiceRequestDelegate Implementation
@implementation QServiceRequestSelectorDelegate

+(id<QServiceRequestDelegate>)delegateWithTarget:(id)target completeSelector:(SEL)completeSelector failSelector:(SEL)failSelector updateSelector:(SEL)updateSelector cancelSelector:(SEL)cancelSelector{
    QServiceRequestSelectorDelegate *delegate = [[QServiceRequestSelectorDelegate alloc] init];
    
    delegate.target = target;
    delegate.completeSelector = completeSelector;
    delegate.errorSelector = failSelector;
    delegate.updateSelector = updateSelector;
    delegate.cancelSelector = cancelSelector;
    
    return [delegate autorelease];
}

/**
 * dispatch callbacks to different selectors
 */
+(id<QServiceRequestDelegate>)delegateWithTarget:(id)target completeSelector:(SEL)completeSelector failSelector:(SEL)failSelector{
    return [self delegateWithTarget:target completeSelector:completeSelector failSelector:failSelector updateSelector:nil cancelSelector:nil];
}


+(id<QServiceRequestDelegate>)delegateWithTarget:(id)target completeSelector:(SEL)completeSelector{
    return [self delegateWithTarget:target completeSelector:completeSelector failSelector:nil updateSelector:nil cancelSelector:nil];
}


-(void)dealloc{
    self.target = nil;
    [super dealloc];
}


-(NSInvocation*)_createInvocationWithTarget:(id)target selector:(SEL)aSelector retainArguments:(BOOL)retainArguments, ...;
{
    va_list ap;
    va_start(ap, retainArguments);
    char* args = (char*)ap;
    NSMethodSignature* signature = [target methodSignatureForSelector:aSelector];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    if (retainArguments) {
        [invocation retainArguments];
    }
    [invocation setTarget:target];
    [invocation setSelector:aSelector];
    for (int index = 2; index < [signature numberOfArguments]; index++) {
        const char *type = [signature getArgumentTypeAtIndex:index];
        NSUInteger size, align;
        NSGetSizeAndAlignment(type, &size, &align);
        NSUInteger mod = (NSUInteger)args % align;
        if (mod != 0) {
            args += (align - mod);
        }
        [invocation setArgument:args atIndex:index];
        args += size;
    }
    va_end(ap);
    return invocation;
}

//===============================================================================================
//FIXME - delegate is always called in main thread inside service tookit(connector)
//===============================================================================================
-(void) request:(QServiceRequest *)request completedWithObject:(id)returnObject{
    if(_completeSelector){
        NSInvocation *i = [self _createInvocationWithTarget:_target selector:_completeSelector retainArguments:NO, request,returnObject];
        [i performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
}
-(void) request:(QServiceRequest *)request failedWithError:(NSError *)error{
    // If we have fail selector set, call it.
    // If not, fall back to the completed selector, and user handles the request.error manually
    if(_errorSelector){
        NSInvocation *i = [self _createInvocationWithTarget:_target selector:_errorSelector retainArguments:NO, request,error];
        [i performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }else{
        [self request:request completedWithObject:request.returnObject];
    }
}
-(void) request:(QServiceRequest *)request updatedWithProgress:(double)progress{
    if(_updateSelector){
        NSInvocation *i = [self _createInvocationWithTarget:_target selector:_updateSelector retainArguments:NO, request,progress];
        [i performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
    }
}
@end