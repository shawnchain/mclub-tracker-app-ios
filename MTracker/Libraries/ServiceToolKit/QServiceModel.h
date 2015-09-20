//
//  MServiceModel.h
//  AppManagerClient
//
//  Created by Shawn Chain on 12-12-14.
//  Copyright (c) 2012年 JoyLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

/////////////////////////////////////////////
#pragma mark - MServiceModel
/**
 * Model Object
 * @discussion Use KVC to unmarshall model object from dict.
 */
@interface QServiceModel :NSObject

/**
 * initialize model with dict
 * @discussion KVC will be used by default
 */
-(id)initWithDict:(NSDictionary*)dict;
@end

/**
 * Paged Result Object
 */
@interface MServicePageResult : NSObject
/**
 * page size
 */
@property(nonatomic,readonly,assign) NSInteger size;
/**
 * page offset
 */
@property(nonatomic,readonly,assign) NSInteger offset;
/**
 * page items
 * @discussion NSArray contains the unmarshalled model objects
 */
@property(nonatomic,readonly,strong) NSArray* items;
@end

/**
 * Error Object
 */
@interface MServiceError : NSObject
@property(nonatomic,readonly,strong) NSString* code;
@property(nonatomic,readonly,strong) NSString* message;
@property(nonatomic,readonly,strong) NSString* desc;

/**
 *@discussion construct error object with code, message and description
 */
+(id)errorWithCode:(NSString*)code message:(NSString*)message desc:(NSString*)desc;
/**
 *@discussion construct error object with code
 */
+(id)errorWithCode:(NSString*)code;
/**
 *@discusson construct error object with message
 */
+(id)errorWithMessage:(NSString*)message;
@end


extern NSString* const kMSERVICE_ERROR_DOMAIN;