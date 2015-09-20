//
//  URLUtils.m
//
//
//  Created by Shawn on 12-1-30.
//  Copyright 2012年 __MyCompanyName__. All rights reserved.
//

#import "QService_URLStrings.h"

@implementation NSString(QService_URLString)
-(NSString*)stringByAppendingUrlPathComponent:(NSString*) path{
    NSString *base = self;
    
    NSUInteger last = [base length] - 1;
    if('/' == [base characterAtIndex:last]){
        // remove the endinging '/'
        base = [base substringToIndex:last];
    }
    
    if('/' == [path characterAtIndex:0]){
        // remove the leading '/'
        path = [path substringFromIndex:1];
    }
    return [NSString stringWithFormat:@"%@/%@",base,path];
}


- (NSString*)stringByEscapingForURLQuery
{
    NSString *result = self;
    
    CFStringRef originalAsCFString = (CFStringRef) self;
    CFStringRef leaveAlone = CFSTR(" ");
    CFStringRef toEscape = CFSTR("\n\r?[]()$,!'*;:@&=#%+/");
    
    CFStringRef escapedStr;
    escapedStr = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalAsCFString, leaveAlone, toEscape, kCFStringEncodingUTF8);
    
    if (escapedStr) {
        NSMutableString *mutable = [NSMutableString stringWithString:(NSString *)escapedStr];
        CFRelease(escapedStr);
        
        [mutable replaceOccurrencesOfString:@" " withString:@"+" options:0 range:NSMakeRange(0, [mutable length])];
        result = mutable;
    }
    return result;
}

- (NSString*)stringByUnescapingFromURLQuery
{
    return [[self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
}


//// From http://oauth.googlecode.com/svn/code/obj-c/OAuthConsumer/NSString+URLEncoding.m for oAuth parameter string encoding
//- (NSString *)URLEncodedString
//{
//    NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
//                                                                           (CFStringRef)self,
//                                                                           NULL,
//                                                                           CFSTR("!*'();:@&=+$,/?%#[]"),
//                                                                           kCFStringEncodingUTF8);
//    [result autorelease];
//    return result;
//}
//
//- (NSString*)URLDecodedString
//{
//    NSString *result = (NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
//                                                                                           (CFStringRef)self,
//                                                                                           CFSTR(""),
//                                                                                           kCFStringEncodingUTF8);
//    [result autorelease];
//    return result;
//}

@end


//=========================================================================
#pragma mark -
@implementation NSURL (QService_URLString)

- (NSDictionary *)queryDictionary;
{
    return [NSDictionary dictionaryWithFormEncodedString:self.query];
}

@end


//=========================================================================
#pragma mark -
@implementation NSDictionary (QService_URLString)

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString
{
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    NSArray* pairs = [encodedString componentsSeparatedByString:@"&"];
    
    for (NSString* kvp in pairs)
    {
        if ([kvp length] == 0)
            continue;
        
        NSRange pos = [kvp rangeOfString:@"="];
        NSString *key;
        NSString *val;
        
        if (pos.location == NSNotFound)
        {
            key = [kvp stringByUnescapingFromURLQuery];
            val = @"";
        }
        else
        {
            key = [[kvp substringToIndex:pos.location] stringByUnescapingFromURLQuery];
            val = [[kvp substringFromIndex:pos.location + pos.length] stringByUnescapingFromURLQuery];
        }
        
        if (!key || !val)
            continue; // I'm sure this will bite my arse one day
        
        [result setObject:val forKey:key];
    }
    return result;
}

- (NSString *)stringWithFormEncodedComponents
{
    NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:[self count]];
    for (NSString* key in self)
    {
        [arguments addObject:[NSString stringWithFormat:@"%@=%@",
                              [key stringByEscapingForURLQuery],
                              [[[self objectForKey:key] description] stringByEscapingForURLQuery]]];
    }
    
    return [arguments componentsJoinedByString:@"&"];
}

@end