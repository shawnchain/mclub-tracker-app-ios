//
//  URLUtils.h
//
//
//  Created by Shawn on 12-1-30.
//  Copyright 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - NSString Extension
@interface NSString(QService_URLString)

-(NSString*)stringByAppendingUrlPathComponent:(NSString*) path;

// LROAuth2Client
//
// Created by Luke Redpath on 14/05/2010.
// Copyright 2010 LJR Software Limited. All rights reserved.
- (NSString*)stringByEscapingForURLQuery;
- (NSString*)stringByUnescapingFromURLQuery;

//// NSString+OAuthParamString support
//// From http://oauth.googlecode.com/svn/code/obj-c/OAuthConsumer/NSString+URLEncoding.m
//- (NSString*) URLEncodedString;
//- (NSString*) URLDecodedString;

@end


//=========================================================================
//
// NSURL+QueryInspector.h
// LROAuth2Client
//
// Created by Luke Redpath on 14/05/2010.
// Copyright 2010 LJR Software Limited. All rights reserved.
//
@interface NSURL (QService_URLString)

- (NSDictionary *)queryDictionary;

@end


//=========================================================================
//
// NSDictionary+QueryString.h
// LROAuth2Client
//
// Created by Luke Redpath on 14/05/2010.
// Copyright 2010 LJR Software Limited. All rights reserved.
//
@interface NSDictionary (QService_URLString)

+ (NSDictionary *)dictionaryWithFormEncodedString:(NSString *)encodedString;
- (NSString *)stringWithFormEncodedComponents;

@end
