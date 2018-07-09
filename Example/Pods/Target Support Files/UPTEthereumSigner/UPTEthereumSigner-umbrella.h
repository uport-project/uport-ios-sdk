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

#import "keccak.h"
#import "UPTEthereumSigner.h"
#import "UPTHDSigner.h"
#import "UPTProtectionLevel.h"

FOUNDATION_EXPORT double UPTEthereumSignerVersionNumber;
FOUNDATION_EXPORT const unsigned char UPTEthereumSignerVersionString[];

