//
//  MServiceEndpoint.m
//  
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#import "QServiceEndpoint.h"

#import "QServiceToolkit-Internals.h"
#import "QServiceHttpConnector.h"
#import "QServiceProtocol.h"
#import "JSONKit.h"
#import "QLogger.h"
#import "QService_URLStrings.h"
#import "QServiceModel.h"

NSString* const kMService_HTTP_METHOD_GET = @"GET";
NSString* const kMService_HTTP_METHOD_POST = @"POST";
NSString* const kMSERVICE_CONTENT_TYPE_FORM = @"application/x-www-form-urlencoded";
NSString* const kMSERVICE_CONTENT_TYPE_JSON = @"text/json";
NSString* const kMSERVICE_ERROR_DOMAIN = @"MServiceErrorDomain";
NSString* const kMSERVICE_SETTINGS_API_ROOT_KEY = @"mservice_settings_api_root";
NSString* const kMSERVICE_SETTINGS_ACCESS_TOKEN_KEY = @"mservice_settings_access_token";

#pragma mark - MServiceEndpoint
@implementation QServiceEndpoint

@synthesize URLString = _URLString;
@synthesize appkey = _appkey;

+(QServiceEndpoint*)endpointWithName:(NSString*)serviceNameOrURL{
    NSString *schema = [[serviceNameOrURL substringToIndex:8] uppercaseString];
    
    if([schema  hasPrefix:@"HTTP://"] || [schema hasPrefix:@"HTTPS://"]){
        return [[[QServiceEndpoint alloc] initWithURL:serviceNameOrURL] autorelease];
    }else if([schema hasPrefix:@"MTOP://"]){
        // it's a mtop call
        serviceNameOrURL = [NSString stringWithFormat:@"http://%@",[serviceNameOrURL substringFromIndex:7]];
        return [[[QServiceEndpoint alloc] initWithURL:serviceNameOrURL protocol:kMSERVICE_PROTOCOL_MTOP] autorelease];
    }
    return [[[QServiceEndpoint alloc] initWithName:serviceNameOrURL]autorelease];
}


#pragma mark Endpoint Filters
//WARNING - not thread safe
static NSMutableArray *_globalFilters = nil;
+(void)registerGlobalFilter:(id<MServiceEndpointFilter>)filter{

    if(_globalFilters == nil){
        _globalFilters = [[NSMutableArray alloc] initWithCapacity:32];
    }
    
    if(![_globalFilters containsObject:filter]){
        [_globalFilters addObject:filter];
    }
}

+(void)unregisterGlobalFilter:(id<MServiceEndpointFilter>)filter{
    if(!_globalFilters){
        return;
    }

    [_globalFilters removeObject:filter];
}

+(NSArray*)globalFilters{
    return _globalFilters;
}

#if 0
-(SEL)_getSelectorFromCallStack:(NSInteger)index{
    //    void *addr[2];
    //    int nframes = backtrace(addr, sizeof(addr)/sizeof(void*));
    //    if (nframes > 1) {
    //        char **syms = backtrace_symbols(addr, nframes);
    //        NSLog(@"%s: caller: %s", __func__, syms[1]);
    //        free(syms);
    //    } else {
    //        NSLog(@"%s: *** Failed to generate backtrace.", __func__);
    //    }
    NSArray *syms = [NSThread callStackSymbols]; 
    SEL sel = nil;
    if([syms count] > index+1){
        NSString* aFrame = [syms objectAtIndex:index+1];
        //2   KMLViewer                           0x0000f609 -[MCTravelService listTravel:] + 52
        DBG(@"%@", aFrame);
        
        NSRange start = [aFrame rangeOfString:@"["];
        NSRange stop = [aFrame rangeOfString:@"]"];
        NSRange myRange;
        if(start.location != NSNotFound && stop.location != NSNotFound){
            myRange.location = start.location +1;
            myRange.length = stop.location - myRange.location;            
            NSString* classAndSelName = [aFrame substringWithRange:myRange];
            NSRange spaceRange = [classAndSelName rangeOfString:@" "];
            if(spaceRange.location != NSNotFound){
                NSString* selName = [classAndSelName substringFromIndex:spaceRange.location +1];
                sel = NSSelectorFromString(selName);
            }
        }
    }
    return sel;
}
#endif

-(void) _cancelRequest:(QServiceRequest*)request{
    [_connector cancel:request];
}

-(void) _handleRequest:(QServiceRequest*) request{
    // apply filters
    for(id<MServiceEndpointFilter> filter in _filters){
        if([filter respondsToSelector:@selector(endpoint:didReceivedResponseForRequest:)]){
            [filter endpoint:self didReceivedResponseForRequest:request];
        }
    }
    
    // protocol handling
    //[_protocol handleRequest:request];
}

-(void) _beforeSendRequest:(QServiceRequest*) request{
    // call filter callbacks
    for(id<MServiceEndpointFilter> filter in  _filters){
        if([filter respondsToSelector:@selector(endpoint:willSendRequest:)]){
            [filter endpoint:self willSendRequest:request];
        }
    }
}

#pragma mark - Lifecycle
-(void)endpointDidInitialized{
    
}

-(id)initWithName:(NSString *)serviceName{
    NSString *root = [[NSUserDefaults standardUserDefaults]stringForKey:kMSERVICE_SETTINGS_API_ROOT_KEY];//[[MSettings sharedInstance] stringForKey:MSETTINGS_SERVICE_ROOT];
    NSAssert(root != nil,@"No settings found for key %@",kMSERVICE_SETTINGS_API_ROOT_KEY);
    return [self initWithRootURL:root serviceName:serviceName];
}

-(id)initWithRootURL:(NSString*)rootUrl serviceName:(NSString*)serviceName{
    NSAssert(rootUrl != nil, @"service root url is nil, check settings!");
    NSString* url = [rootUrl stringByAppendingUrlPathComponent:serviceName];
    return [self initWithURL:url];
}

-(id)initWithURL:(NSString*)url{
    return [self initWithURL:url protocol:kMSERVICE_PROTOCOL_DEFAULT];
}

-(id)initWithURL:(NSString*)url protocol:(NSString*)protocolName{
    self = [super init];
    if(self){
        _URLString = [[NSString alloc] initWithFormat:@"%@",url];
        
        // http connector and joy protocol
        self.connector = [[[QServiceHttpConnector alloc] init] autorelease];
        
        self.filters = [NSMutableArray arrayWithCapacity:32];
        [self.filters addObjectsFromArray:[[self class] globalFilters]];

        // determin the protocol filter
        QServiceProtocol *proto = [QServiceProtocol protocolNamed:protocolName];
        NSAssert((proto != nil),@"Unsupported protocol: %@",protocolName);
        [self.filters addObject:proto];
        //self.protocol = [MServiceProtocol joyProtocol];
        [self endpointDidInitialized];
    }
    return self;
}



-(void)dealloc{
    DBG(@"dealloc endpoint %@",self);
//    self.protocol = nil;
    self.connector = nil;// connector will cancel all pending requests
    self.filters = nil;
    [_URLString release];
    self.appkey = nil;
    [super dealloc];
}

#pragma mark - Public methods
-(void)sendRequest:(QServiceRequest*)request{
    request.endpoint = self;
//#if 0
//    if(!aMethod){
//        aMethod = [self _getSelectorFromCallStack:1];
//    }
//#endif
    
    // moved to _beforeSendRequest()
//    // apply filters
//    for(id<MServiceEndpointFilter> filter in  _filters){
//        if([filter respondsToSelector:@selector(endpoint:willSendRequest:)]){
//            [filter endpoint:self willSendRequest:request];
//        }
//    }
    
    [_connector perform:request];
}

#pragma mark - Configurations

/**
 * Register service API root
 */
+(void)registerServiceAPIRoot:(NSString*)url{
    NSAssert(url != nil, @"Service API Root is nil");
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    
    NSString* existing = [settings stringForKey:kMSERVICE_SETTINGS_API_ROOT_KEY];
    if(existing){
        WARN(@"kMSERVICE_SETTINGS_API_ROOT_KEY exists in settings with value: %@, current registered root %@ will be ignored",existing,url);
        return;
    }
    [settings setObject:url forKey:kMSERVICE_SETTINGS_API_ROOT_KEY];
}

+(NSString*)getServiceAPIRoot{
     NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    return [settings stringForKey:kMSERVICE_SETTINGS_API_ROOT_KEY];
}
@end