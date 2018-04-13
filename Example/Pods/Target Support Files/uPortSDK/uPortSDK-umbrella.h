#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif


FOUNDATION_EXPORT double uPortSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char uPortSDKVersionString[];

#include "keccak-tiny.h"
int sha3_256(uint8_t* out, size_t outlen, const uint8_t* in, size_t inlen);

