//
//  QServiceProtocol_JOYAPI.m
//
//  Created by Shawn Chain on 13-4-20.
//  Copyright (c) 2013年 taobao inc. All rights reserved.
//

#import "QServiceProtocol_JOYAPI.h"
#import "QServiceToolkit-Internals.h"
#import "QServiceRequestSigner.h"
#import "JSONKit.h"
#import "QLogger.h"


@implementation QServiceProtocol_JOYAPI

/*
 * The default protocol
 * See OpenAPI Protocol definitions
 
 1. 正常：HTTP 200
 * 返回空
 空串或空{}
 
 * 直接返回对象
 {
 ...
 }
 
 * 返回对象列表
 [
 {...},
 {...},
 ]
 
 * 返回分页对象列表
 {
 type:"page"
 offset:0,
 size:0
 total:0
 items:
 [
 {...},
 {...},
 ]
 }
 
 2. 异常：HTTP 40x,50x
 * 返回空
 空串或空{}
 * 返回单条信息
 error_message
 
 * 返回结构化异常信息
 {
 errors:
 [
 { type:"E"
 code:“E001”
 message:
 desc:
 },
 {...}
 ]
 }
 
 
 3. error code
 * 000 - 999 // system reserved
 * E000 - OK
 * E001 - json parse error
 * E002 -
 * E003 -
 * 1000 - 1999 // application defined
 * 2000 - 2999
 */
-(id)_unmarshallPlainResult:(id)dictOrArray type:(Class)type{
    id modelOrArray = nil;
    // result might be eigher array or dict
    if([dictOrArray isKindOfClass:[NSDictionary class]]){
        if(type == [NSDictionary class]){
            // Caller just want a raw dict, so juct return that.
            modelOrArray = (NSDictionary*)dictOrArray;
        }else{
            modelOrArray = [[[type alloc] initWithDict:dictOrArray] autorelease];
        }
    }else if([dictOrArray isKindOfClass:[NSArray class]]){
        modelOrArray = [[[NSMutableArray alloc] initWithCapacity:[dictOrArray count]] autorelease];
        //TODO support nested array
        for (NSDictionary* element in dictOrArray) {
            [modelOrArray addObject:[self _unmarshallPlainResult:element type:type]];
        }
    }else{
        // what the hell it is ?
        WARN(@"Unknown object type from service response result: %@ - %@",[dictOrArray class],dictOrArray);
    }
    return modelOrArray;
}

-(id)_unmarshallPageResult:(id)dict type:(Class)type{
    id array = [dict valueForKey:@"items"];
    if(array != nil){
        if([array isKindOfClass:[NSArray class]]){
            QServicePageResult *page = [[[QServicePageResult alloc] init]autorelease];
            page.size = [[dict objectForKey:@"size"] integerValue];
            page.offset = [[dict objectForKey:@"offset"] integerValue];
            page.items = [self _unmarshallPlainResult:array type:type];
            return page;
        }else{
            WARN(@"Invalid paged results");
        }
    }
    return nil;
}

/*
 * Parse errors from request
 */
-(void)_parseErrors:(QServiceRequest*)ticket{
    
    NSData *data = ticket.responseData;
    
    // 1. empty
    if(!data){
        // just the error code
        ticket.error = [NSError errorWithDomain:kQSERVICE_ERROR_DOMAIN code:ticket.httpResponse.statusCode userInfo:nil];
        return;
    }
    
    // error structure
    /*
     {
     errors:
     [
     {   code:
     message:
     desc:
     }
     ]
     }
     */
    NSError *parseError = nil;
    id dict = [[JSONDecoder decoderWithParseOptions:JKParseOptionStrict] objectWithData:data error:&parseError];
    if(dict != nil && [dict isKindOfClass:[NSDictionary class]]){
        id array = [dict objectForKey:@"errors"];
        if(array){
            id errors = [self _unmarshallPlainResult:array type:[QServiceError class]];
            if([errors isKindOfClass:[NSArray class]]){
                NSArray *errorArray = (NSArray*)errors;
                if([errors count] >0){
                    // just get the first error currently,currently
                    QServiceError *error = [errorArray objectAtIndex:0];
                    NSString *errMsg = [NSString stringWithFormat:@"%@ %@ %@",error.code, error.message,error.desc];
                    NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:errMsg,NSLocalizedDescriptionKey,error,@"serviceError",nil];
                    ticket.error = [NSError errorWithDomain:kQSERVICE_ERROR_DOMAIN code:ticket.httpResponse.statusCode userInfo:errorInfo];
                    return;
                }
            }
        }
    }
    
    if(parseError){
        INFO(@"Parse response as JSON failed: %@",parseError);
    }
    
    // 2. Not a json string
    NSString *dataStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSString *errMsg = [NSString stringWithFormat:@"%@",dataStr];
    QServiceError *error = [QServiceError errorWithMessage:errMsg];
    //error.code = @"E999";
    NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:errMsg,NSLocalizedDescriptionKey,error,@"serviceError",nil];
    ticket.error = [NSError errorWithDomain:kQSERVICE_ERROR_DOMAIN code:ticket.httpResponse.statusCode userInfo:errorInfo];
}

-(void)handleRequest:(QServiceRequest*)request{
    NSData* data = request.responseData;
#ifdef DEBUG_DUMP
    NSString *dataStrForDbg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DBG(@"Received response data: \n%@",dataStrForDbg);
    [dataStrForDbg release];
#endif
    
    // Check status code
    if(request.httpResponse.statusCode != 200){
        // Parse response as errors
        [self _parseErrors:request];
        return;
    }
    
    //
    //1. no data
    if(!data){
        return;
    }
    //2. no return type specified, parse data as UTF-8 string
    if(request.returnType == nil){
        request.returnObject = data;
        return;
    }else if(request.returnType == [NSString class]){
        request.returnObject = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        return;
    }
    
    //3. try parse as JSON
    NSError *parseError = nil;
    // Use NSData Category introduced by JSONKit
    // id serviceResponse = [data objectFromJSONDataWithParseOptions:JKParseOptionStrict error:&parseError];
    id dictOrArray = [[JSONDecoder decoderWithParseOptions:JKParseOptionStrict] objectWithData:data error:&parseError];
    
    //3.1 not a valid json
    if (dictOrArray == nil){
        // parse error
        NSString *errMsg = [NSString stringWithFormat:@"Error parsing response as JSON, %@",parseError];
        WARN(errMsg);
        QServiceError *error = [QServiceError errorWithMessage:errMsg];
        //error.code = @"E999";
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:errMsg,NSLocalizedDescriptionKey,error,@"serviceError",nil];
        request.error = [NSError errorWithDomain:kQSERVICE_ERROR_DOMAIN code:request.httpResponse.statusCode userInfo:errorInfo];
        // return response data as utf-8 string
        request.returnObject = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];//data;
        return;
    }
    
    //3.2 an dict
    if([dictOrArray isKindOfClass:[NSDictionary class]]){
        
        NSDictionary *dict = (NSDictionary*)dictOrArray;
        if([dict count] == 0){
            // an empty dict, bail out.
            return;
        }
        
        NSString *type = [dict objectForKey:@"type"];
        if(type && [type isKindOfClass:[NSString class]] && [type caseInsensitiveCompare:@"page"] == NSOrderedSame){
            //3.1.2 paged result
            /*
             {
             type="page",
             size=100,
             offset=0,
             items=[
             {...},
             {...}
             ]
             }
             */
            DBG(@"Got paged result, %@",dict);
            request.returnObject = [self _unmarshallPageResult:dict type:request.returnObject];
        }else{
            // plain result, dict or array
            request.returnObject = [self _unmarshallPlainResult:dict type:request.returnType];
        }
    }
    
    // 3.3 an array
    else if([dictOrArray isKindOfClass:[NSArray class]]){
        NSArray *array = (NSArray*)dictOrArray;
        request.returnObject = [self _unmarshallPlainResult:array type:request.returnType];
    }else{
        WARN(@"Unknown response object %@",dictOrArray);
        request.returnObject = dictOrArray;
        return;
    }
    
    if(!request.returnObject){
        NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"Failed to unmarshall response payload",NSLocalizedDescriptionKey,nil];
        request.error = [NSError errorWithDomain:kQSERVICE_ERROR_DOMAIN code:request.httpResponse.statusCode userInfo:errorInfo];
        request.returnObject = dictOrArray;
    }
}


#pragma mark MServiceEndpointFilter callback

-(void)endpoint:(QServiceEndpoint*)endpoint willSendRequest:(QServiceRequest*)request{
    // Add access tokens to request parameters
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken = [defaults stringForKey:@"ACCESS_TOKEN"];
    if(accessToken && accessToken.length > 0){
        //FIXME - httpRequest is created
        //        if(![request.parameters objectForKey:@"access_token"]){
        //            [request addParameter:accessToken forKey:@"access_token"];
        //        }
        [request.httpRequest setValue:accessToken forHTTPHeaderField:@"access_token"];
    }
    
    // DEBUG - append signature
    [QServiceRequestSigner signRequest:request appSecret:nil];
}

-(void)endpoint:(QServiceEndpoint*)endpoint didReceivedResponseForRequest:(QServiceRequest*)request{
    [self handleRequest:request];
}
@end
