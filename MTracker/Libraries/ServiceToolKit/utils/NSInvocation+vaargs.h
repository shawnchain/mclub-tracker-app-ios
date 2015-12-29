//
//  NSInvocation+CWVariableArguments.h
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

#import <Foundation/Foundation.h>


/*!
 * @abstract Category on NSInvocation adding convinience methods for creating invocations and invoking on different targets.
 */
@interface NSInvocation (CWVariableArguments)



/*!
 * @abstract Create an NSInvication instance for a given target, selector, and a
 *					 variable list of arguments.
 *
 * @discussion Arguments are not retained by NSInvocation by default for
 *			   performance. Always retain arguments when passing objects across
 *             thread boundries.
 *
 * @param target target of invocation.
 * @param selector selector of method to invoke on target.
 * @param retainArguments YES if object arguments should be retained.
 * @param arguments a variable arguments list with arguments to send to the method when invoking.
 * @result a prepared invocation object.
 */
+(NSInvocation*)invocationWithTarget:(id)target
                            selector:(SEL)selector
                     retainArguments:(BOOL)retainArguments
                           argList:(NSArray*)arguments;

/*!
 * @abstract Perform invoke on a new bakcground thread.
 *
 * @discussion You should NOT read the return value, since there is no way to
 * 						 know when the invokation has finnished.
 */
-(void)invokeInBackground;

/*!
 * @abstract Perform invoke on the main thread, optionally wait until done.
 *
 * @abstract You should only read the return value if you have waited until the
 *           invocation is done.
 */
-(void)invokeOnMainThreadWaitUntilDone:(BOOL)wait;

/*!
 * @abstract Perform invoke on the specified thread, optionally waut until done.
 *
 * @abstract You should only read the return value if you have waited until the
 *           invocation is done.
 */
-(void)invokeOnThread:(NSThread*)thread waitUntilDone:(BOOL)wait;


@end
