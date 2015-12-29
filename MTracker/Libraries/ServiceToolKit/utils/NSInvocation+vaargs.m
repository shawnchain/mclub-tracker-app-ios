//
//  NSInvocation+CWVariableArguments.m
//  CWFoundationAdditions
//
//  Copyright 2009 Jayway. All rights reserved.
//  Created by Fredrik Olsson.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSInvocation+vaargs.h"
#include <stdarg.h>
#include <objc/runtime.h>

@implementation NSInvocation (CWVariableArguments)

+(NSInvocation*)invocationWithTarget:(id)target
                            selector:(SEL)aSelector
                     retainArguments:(BOOL)retainArguments
                           argList:(NSArray*)args{
    NSMethodSignature* signature = [target methodSignatureForSelector:aSelector];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
    if (retainArguments) {
        [invocation retainArguments];
    }
    [invocation setTarget:target];
    [invocation setSelector:aSelector];
    
    for (NSInteger index = 0; (index + 2 < [signature numberOfArguments]) && (index < args.count); index++) {
        id arg = [args objectAtIndex:index];
        [invocation setArgument:&arg atIndex:index + 2];
    }
    
    return invocation;
}


-(void)invokeInBackground;
{
	[self performSelectorInBackground:@selector(invoke) withObject:nil];
}

-(void)invokeOnMainThreadWaitUntilDone:(BOOL)wait;
{
	[self invokeOnThread:[NSThread mainThread] waitUntilDone:wait];
}

-(void)invokeOnThread:(NSThread*)thread waitUntilDone:(BOOL)wait;
{
    if ([[NSThread currentThread] isEqual:thread]) {
    	[self invoke];
    } else {
    	[self performSelector:@selector(invoke) 
                     onThread:thread
                   withObject:nil
                waitUntilDone:wait];
    }
}


@end

