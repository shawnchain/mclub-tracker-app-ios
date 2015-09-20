//
//  MServiceHttpConnector.h
//
//  Created by Shawn Chain on 12-1-3.
//  Copyright 2012 shawn.chain@gmail.com, Alibaba Group
//  All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QServiceToolkit-Internals.h"

/*
 * Service Http Connector
 *
 */
@interface QServiceHttpConnector : NSObject{
    @private
    NSMutableArray *_requestQueue;
}

-(void)perform:(QServiceRequest*)request;

-(void)cancel:(QServiceRequest*)request;
-(void)cancelAll;
@end
