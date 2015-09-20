//
//  GTMStringEncoding.h
//
//  Copyright 2010 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import <Foundation/Foundation.h>

//==============================================
// Macros from GMTDefines.h
//==============================================
//#import "GTMDefines.h"

// Give ourselves a consistent way to do inlines.  Apple's macros even use
// a few different actual definitions, so we're based off of the foundation
// one.
#if !defined(GTM_INLINE)
#if (defined (__GNUC__) && (__GNUC__ == 4)) || defined (__clang__)
#define GTM_INLINE static __inline__ __attribute__((always_inline))
#else
#define GTM_INLINE static __inline__
#endif
#endif

// _GTMDevLog & _GTMDevAssert
//
// _GTMDevLog & _GTMDevAssert are meant to be a very lightweight shell for
// developer level errors.  This implementation simply macros to NSLog/NSAssert.
// It is not intended to be a general logging/reporting system.
//
// Please see http://code.google.com/p/google-toolbox-for-mac/wiki/DevLogNAssert
// for a little more background on the usage of these macros.
//
//    _GTMDevLog           log some error/problem in debug builds
//    _GTMDevAssert        assert if conditon isn't met w/in a method/function
//                           in all builds.
//
// To replace this system, just provide different macro definitions in your
// prefix header.  Remember, any implementation you provide *must* be thread
// safe since this could be called by anything in what ever situtation it has
// been placed in.
//

// We only define the simple macros if nothing else has defined this.
#ifndef _GTMDevLog

#ifdef DEBUG
#define _GTMDevLog(...) NSLog(__VA_ARGS__)
#else
#define _GTMDevLog(...) do { } while (0)
#endif

#endif // _GTMDevLog

#ifndef _GTMDevAssert
// we directly invoke the NSAssert handler so we can pass on the varargs
// (NSAssert doesn't have a macro we can use that takes varargs)
#if !defined(NS_BLOCK_ASSERTIONS)
#define _GTMDevAssert(condition, ...)                                       \
do {                                                                      \
if (!(condition)) {                                                     \
[[NSAssertionHandler currentHandler]                                  \
handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
file:[NSString stringWithUTF8String:__FILE__]  \
lineNumber:__LINE__                                  \
description:__VA_ARGS__];                             \
}                                                                       \
} while(0)
#else // !defined(NS_BLOCK_ASSERTIONS)
#define _GTMDevAssert(condition, ...) do { } while (0)
#endif // !defined(NS_BLOCK_ASSERTIONS)

#endif // _GTMDevAssert


//==============================================
// Class Implementations
//==============================================
#pragma mark -

// A generic class for arbitrary base-2 to 128 string encoding and decoding.
@interface QService_GTMStringEncoding : NSObject {
@private
    NSData *charMapData_;
    char *charMap_;
    int reverseCharMap_[128];
    int shift_;
    int mask_;
    BOOL doPad_;
    char paddingChar_;
    int padLen_;
}

// Create a new, autoreleased GTMStringEncoding object with a standard encoding.
+ (id)binaryStringEncoding;
+ (id)hexStringEncoding;
+ (id)rfc4648Base32StringEncoding;
+ (id)rfc4648Base32HexStringEncoding;
+ (id)crockfordBase32StringEncoding;
+ (id)rfc4648Base64StringEncoding;
+ (id)rfc4648Base64WebsafeStringEncoding;

// Create a new, autoreleased GTMStringEncoding object with the given string,
// as described below.
+ (id)stringEncodingWithString:(NSString *)string;

// Initialize a new GTMStringEncoding object with the string.
//
// The length of the string must be a power of 2, at least 2 and at most 128.
// Only 7-bit ASCII characters are permitted in the string.
//
// These characters are the canonical set emitted during encoding.
// If the characters have alternatives (e.g. case, easily transposed) then use
// addDecodeSynonyms: to configure them.
- (id)initWithString:(NSString *)string;

// Add decoding synonyms as specified in the synonyms argument.
//
// It should be a sequence of one previously reverse mapped character,
// followed by one or more non-reverse mapped character synonyms.
// Only 7-bit ASCII characters are permitted in the string.
//
// e.g. If a GTMStringEncoder object has already been initialised with a set
// of characters excluding I, L and O (to avoid confusion with digits) and you
// want to accept them as digits you can call addDecodeSynonyms:@"0oO1iIlL".
- (void)addDecodeSynonyms:(NSString *)synonyms;

// A sequence of characters to ignore if they occur during encoding.
// Only 7-bit ASCII characters are permitted in the string.
- (void)ignoreCharacters:(NSString *)chars;

// Indicates whether padding is performed during encoding.
- (BOOL)doPad;
- (void)setDoPad:(BOOL)doPad;

// Sets the padding character to use during encoding.
- (void)setPaddingChar:(char)c;

// Encode a raw binary buffer to a 7-bit ASCII string.
- (NSString *)encode:(NSData *)data;
- (NSString *)encodeString:(NSString *)string;

// Decode a 7-bit ASCII string to a raw binary buffer.
- (NSData *)decode:(NSString *)string;
- (NSString *)stringByDecoding:(NSString *)string;

@end