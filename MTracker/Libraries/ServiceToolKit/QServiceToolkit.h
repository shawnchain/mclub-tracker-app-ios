//
//  MServiceToolkit.h
//
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#ifndef MServiceToolkit_h
#define MServiceToolkit_h

#import "MServiceRequest.h"
#import "MServiceEndpoint.h"
#import "MServiceModel.h"


/////////////////////////////////////////////
// Service Macros
#ifndef DECLARE_SERVICE
#define DECLARE_SERVICE(__CLASS_TYPE__) +(__CLASS_TYPE__*)sharedInstance;

#define SYNTHESIZE_SERVICE(__CLASS_TYPE__) \
+(__CLASS_TYPE__*)sharedInstance{\
static __CLASS_TYPE__* instance = nil;\
if(instance==nil){\
instance = [[self alloc] init];\
}\
return instance;\
}
#endif


//@interface MServiceToolkit
//+(void)registerServiceInterceptor;
//@end

#endif
