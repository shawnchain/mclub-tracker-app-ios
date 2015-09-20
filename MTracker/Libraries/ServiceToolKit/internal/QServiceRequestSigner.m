//
//  MServiceRequestSigner.m
//  AppManagerClient
//
//  Created by Shawn Chain on 13-2-10.
//  Copyright (c) 2013年 JoyLabs. All rights reserved.
//

#import "QServiceRequestSigner.h"
#import "QServiceToolkit-Internals.h"
#import "QService_URLStrings.h"

#import <CommonCrypto/CommonCrypto.h>
#import <Security/Security.h>
#include <math.h>
#include <string.h>
#import "QService_GTMStringEncoding.h"
#import "QLogger.h"


static const unsigned char key_rev = 0x00;
static const unsigned short key_count = 0x05;
static const unsigned short key_len = 16;// 128bit / 8bit;
static unsigned char key_data[5][16] = {
    {0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0xA},
    {0x1,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0xB},
    {0x2,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0xC},
    {0x3,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0xD},
    {0x4,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0x0,0xE},
};

#define API_SIGNATURE_KEY   @"joyapi-signature"
#define API_NONCE_KEY       @"joyapi-nonce"
#define API_TIMESTAMP_KEY   @"joyapi-ts"

@implementation QServiceRequestSigner

/**
 * Generate normalized request string: METHOD + & + URL_ENCODE(URL) + & + URL_ENCODE(PARAMS_STR), where PARAMS_STR
 * is the string concated "key=value" with alphabeta order
 *
 */
static NSString* _getNormalizedRequestString(QServiceRequest *request, NSString *nonce, NSString *timestamp){
    NSString* method = request.httpMethod;
    NSString* url = [[request.httpRequest.URL.absoluteString componentsSeparatedByString:@"?"] objectAtIndex:0];
    //NSMutableString *url = [NSMutableString stringWithString:[request.endpoint.URLString stringByAppendingUrlPathComponent:request.operationName]];
    
    // merge both GET/POST parameters
    NSMutableDictionary *mergedParams = [[[NSMutableDictionary alloc] initWithCapacity:64] autorelease];
    NSDictionary *params = request.parameters;
    for(NSString *key in params.keyEnumerator){
        NSMutableArray *values = [mergedParams objectForKey:key];
        if(!values){
            values = [[NSMutableArray alloc] initWithCapacity:1];
            [mergedParams setObject:values forKey:key];
            [values release];
        }
        [values addObject:[params objectForKey:key]];
    }
    
    params = request.postValues;
    for(NSString *key in params.keyEnumerator){
        NSMutableArray *values = [mergedParams objectForKey:key];
        if(!values){
            values = [[NSMutableArray alloc] initWithCapacity:1];
            [mergedParams setObject:values forKey:key];
            [values release];
        }
        [values addObject:[params objectForKey:key]];
    }
    [mergedParams setObject:[NSArray arrayWithObject:nonce] forKey:API_NONCE_KEY];
    [mergedParams setObject:[NSArray arrayWithObject:timestamp] forKey:API_TIMESTAMP_KEY];
    
    if([mergedParams count] > 0){
        // sort parameters by key and values
        NSArray *sortedKeys = [[mergedParams allKeys] sortedArrayUsingSelector:@selector(compare:)];
        // contact to param string
        NSMutableString *paramStringBuffer = [[[NSMutableString alloc] initWithCapacity:1024] autorelease];
        for(NSString *key in sortedKeys){
            NSArray *values = [mergedParams objectForKey:key];
            if(values.count > 1){
                // sort values if any
                values = [values sortedArrayUsingSelector:@selector(compare:)];
            }
            for(NSString *value in values){
                if(paramStringBuffer.length > 0){
                    [paramStringBuffer appendString:@"&"];
                }
                [paramStringBuffer appendFormat:@"%@=%@",[key stringByEscapingForURLQuery],[value stringByEscapingForURLQuery]];
            }
        }
        return [NSString stringWithFormat:@"%@&%@&%@",method,[url stringByEscapingForURLQuery],[paramStringBuffer stringByEscapingForURLQuery]];
    }else{
        return [NSString stringWithFormat:@"%@&%@",method,[url stringByEscapingForURLQuery]];
    }
}

+ (NSString *)signRequest:(QServiceRequest *)request appSecret:(NSString *)appSecret{
    // 1. generate the nonce and timestamp
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    
    NSString *nonce = (NSString *)string;
    NSString *timestamp = [NSString stringWithFormat:@"%ld", time(NULL)];
    // add to request header - TODO configurable header names
    [request.httpRequest setValue:nonce forHTTPHeaderField:API_NONCE_KEY];
    [request.httpRequest setValue:timestamp forHTTPHeaderField:API_TIMESTAMP_KEY];
    CFRelease(string);
    
    // 2. generate the full URL
    NSString *signature = [self signRequestString:_getNormalizedRequestString(request,nonce,timestamp) appSecret:appSecret];
    // add to request
    [request.httpRequest setValue:signature forHTTPHeaderField:API_SIGNATURE_KEY];
    return signature;
}

+ (NSString *)signRequestString:(NSString *)baseString appSecret:(NSString *)appSecret{
    // 0. choose key
    int keyIdx = arc4random() % key_count;
    const unsigned char* keyBytes = key_data[keyIdx];
    // 1. append app secret
    //TODO - secretKey = appKey$appSecret
    
    // 2. HmacSHA1 signing with CommonCrypto Lib by Apple
    DBG(@"Signing base string: \n%@\n",baseString);
    NSData *inputData = [baseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned int sign_data_len = 20 + 2;
    unsigned char sign_data[sign_data_len]; // alloc on stack, will it be overflowed ?
    CCHmac(kCCHmacAlgSHA1, keyBytes, key_len, [inputData bytes], [inputData length], sign_data);
    
    // 3. append key index, 0x00,0x01
    sign_data[20] = key_rev;
    sign_data[21] = keyIdx;

    NSString *b64Result = [[QService_GTMStringEncoding rfc4648Base64WebsafeStringEncoding] encode:[NSData dataWithBytes:sign_data length:sign_data_len]];
#if DEBUG
    DBG(@"signature<RAW>: %@",[NSData dataWithBytes:sign_data length:22]);
    DBG(@"signature<B64>: %@",b64Result);
#endif
    // 4. encode to WebSafe Base64 string
    return b64Result;
}
@end