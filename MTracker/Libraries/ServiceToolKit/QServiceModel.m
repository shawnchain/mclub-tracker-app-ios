//
//  QServiceModel.m
//
//  Created by Shawn Chain on 12-12-14.
//  Copyright (c) 2012年 JoyLabs. All rights reserved.
//

#import "QServiceModel.h"
#import "QServiceToolkit-Internals.h"

#import "QLogger.h"

#pragma mark - ServiceModel Class
@implementation QServiceModel
-(id)initWithDict:(NSDictionary*)dict{
    self = [super init];
    if(self){
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}
-(void)setValue:(id)aValue forUndefinedKey:(NSString*) aKey{
#ifdef DEBUG_SERVICE_MODEL
    DBG(@"Ignoring unknown kv pair, %@ = %@",aKey, aValue);
#endif
}

- (void)setNilValueForKey:(NSString *)key{
#ifdef DEBUG_SERVICE_MODEL
    DBG(@"setNilValueForkey:%@",key);
#endif
}

@end


@implementation QServicePageResult
@synthesize size,offset,items;
@end




#pragma mark - ServiceError
@implementation QServiceError

@synthesize code,message,desc;
-(id)initWithDict:(NSDictionary*)dict{
    self = [super init];
    if(self){
        self.code = [dict objectForKey:@"code"];
        self.message = [dict objectForKey:@"name"];
        self.desc = [dict objectForKey:@"desc"]; //optional
    }
    return self;
}
-(void)dealloc{
    DBG(@"dealloc error %@",self);
    self.code = nil;
    self.message = nil;
    self.desc = nil;
    [super dealloc];
}

+(id)errorWithCode:(NSString*)code message:(NSString*)message desc:(NSString*)desc{
    QServiceError *error = [[QServiceError alloc]init];
    error.code = code;
    error.message = message;
    error.desc = desc;
    return [error autorelease];
}
+(id)errorWithCode:(NSString*)code{
    return [self errorWithCode:code message:nil desc:nil];
}

+(id)errorWithMessage:(NSString*)message{
    return [self errorWithCode:nil message:message desc:nil];
}
@end
