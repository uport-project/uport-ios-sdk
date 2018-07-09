//
//  UPTHDSigner.h
//  uPortMobile
//
//  Created by josh on 1/5/18.
//  Copyright © 2018 ConsenSys AG. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UPTProtectionLevel.h"

/// @param ethAddress    an Ethereum adderss with prefix '0x'. May be nil if error occured
/// @param publicKey    a base 64 encoded representation of the NSData public key. Note: encoded with no line
///                     breaks. May be nil if error occured.
/// @param error        non-nil only if an error occured
typedef void (^UPTHDSignerSeedCreationResult)(NSString *ethAddress, NSString *publicKey, NSError *error);

/// @param  phrase      12 space delimited words
typedef void (^UPTHDSignerSeedPhraseResult)(NSString *phrase, NSError *error);

typedef void (^UPTHDSignerTransactionSigningResult)(NSDictionary *signature, NSError *error);
typedef void (^UPTHDSignerJWTSigningResult)(NSString *signature, NSError *error);

/// param privateKey is a base64 string
typedef void (^UPTHDSignerPrivateKeyResult)(NSString *privateKeyBase64, NSError *error);

FOUNDATION_EXPORT NSString * const UPTHDSignerErrorCodeLevelParamNotRecognized;
FOUNDATION_EXPORT NSString * const UPTHDSignerErrorCodeLevelPrivateKeyNotFound;

FOUNDATION_EXPORT NSString * const UPORT_ROOT_DERIVATION_PATH;
FOUNDATION_EXPORT NSString * const METAMASK_ROOT_DERIVATION_PATH;

@interface UPTHDSigner : NSObject

+ (BOOL)hasSeed;

/// @param  callback contains phrase
+ (void)showSeed:(NSString *)rootAddress prompt:(NSString *)prompt callback:(UPTHDSignerSeedPhraseResult)callback;


/// @param  callback     a root account Ethereum address and root account public key
+ (void)createHDSeed:(UPTHDSignerProtectionLevel)protectionLevel callback:(UPTHDSignerSeedCreationResult)callback __attribute__((deprecated));
+ (void)createHDSeed:(UPTHDSignerProtectionLevel)protectionLevel rootDerivationPath:(NSString *)rootDerivationPath callback:(UPTHDSignerSeedCreationResult)callback;

/// @param  callback     a root account Ethereum address and root account public key
+ (void)importSeed:(UPTHDSignerProtectionLevel)protectionLevel phrase:(NSString *)phrase callback:(UPTHDSignerSeedCreationResult)callback __attribute__((deprecated));
+ (void)importSeed:(UPTHDSignerProtectionLevel)protectionLevel phrase:(NSString *)phrase rootDerivationPath:(NSString *)rootDerivationPath callback:(UPTHDSignerSeedCreationResult)callback;

/// @param  address     a root account Ethereum address
/// @param  callback    the derived Ethereum address and derived public key
+ (void)computeAddressForPath:(NSString *)address derivationPath:(NSString *)derivationPath prompt:(NSString *)prompt callback:(UPTHDSignerSeedCreationResult)callback;


/// @param  ethereumAddress     a root account Ethereum address
+ (void)signTransaction:(NSString *)ethereumAddress derivationPath:(NSString *)derivationPath txPayload:(NSString *)txPayload prompt:(NSString *)prompt callback:(UPTHDSignerTransactionSigningResult)callback;

/// @param  ethereumAddress     a root account Ethereum address
+ (void)signJWT:(NSString *)ethereumAddress derivationPath:(NSString *)derivationPath data:(NSString *)data prompt:(NSString *)prompt callback:(UPTHDSignerJWTSigningResult)callback;

/// @param rootAddress  a root account Ethereum address
+ (void)privateKeyForPath:(NSString *)rootAddress derivationPath:(NSString *)derivationPath prompt:(NSString *)prompt callback:(UPTHDSignerPrivateKeyResult)callback;

// utils
+ (NSArray<NSString *> *)wordsFromPhrase:(NSString *)phrase;
+ (NSData*)randomEntropy;
+ (UPTHDSignerProtectionLevel)enumStorageLevelWithStorageLevel:(NSString *)storageLevel;
+ (NSString *)base64StringWithURLEncodedBase64String:(NSString *)URLEncodedBase64String;
+ (NSString *)URLEncodedBase64StringWithBase64String:(NSString *)base64String;

@end
