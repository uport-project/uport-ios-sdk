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

#import "CoreBitcoin/BTCAddress.h"
#import "CoreBitcoin/BTCBase58.h"
#import "CoreBitcoin/BTCBigNumber.h"
#import "CoreBitcoin/BTCBlockchainInfo.h"
#import "CoreBitcoin/BTCCurvePoint.h"
#import "CoreBitcoin/BTCData.h"
#import "CoreBitcoin/BTCErrors.h"
#import "CoreBitcoin/BTCKey.h"
#import "CoreBitcoin/BTCKeychain.h"
#import "CoreBitcoin/BTCOpcode.h"
#import "CoreBitcoin/BTCProtocolSerialization.h"
#import "CoreBitcoin/BTCScript.h"
#import "CoreBitcoin/BTCScriptMachine.h"
#import "CoreBitcoin/BTCSignatureHashType.h"
#import "CoreBitcoin/BTCTransaction.h"
#import "CoreBitcoin/BTCTransactionInput.h"
#import "CoreBitcoin/BTCTransactionOutput.h"
#import "CoreBitcoin/BTCUnitsAndLimits.h"

#import "CoreBitcoin/NS+BTCBase58.h"
#import "CoreBitcoin/NSData+BTCData.h"

FOUNDATION_EXPORT double CoreEthereumVersionNumber;
FOUNDATION_EXPORT const unsigned char CoreEthereumVersionString[];
