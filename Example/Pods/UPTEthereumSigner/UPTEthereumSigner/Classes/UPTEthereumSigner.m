//
//  UPTEthSigner.m
//  uPortMobile
//
//  Created by josh on 10/18/17.
//  Copyright © 2017 ConsenSys AG. All rights reserved.
//

@import Valet;

#import "UPTEthereumSigner.h"
#import "CoreBitcoin/CoreBitcoin+Categories.h"
#import <openssl/rand.h>
#include <openssl/ec.h>
#include <openssl/ecdsa.h>
#include <openssl/bn.h>
#include <openssl/evp.h>
#include <openssl/obj_mac.h>
#include <openssl/rand.h>
#include "keccak.h"

static int     BTCRegenerateKey(EC_KEY *eckey, BIGNUM *priv_key);
static int     ECDSA_SIG_recover_key_GFp(EC_KEY *eckey, BIGNUM *r, BIGNUM *s, const unsigned char *msg, int msglen, int recid, int check);

NSString *const ReactNativeKeychainProtectionLevelNormal = @"simple";
NSString *const ReactNativeKeychainProtectionLevelICloud = @"cloud"; // icloud keychain backup
NSString *const ReactNativeKeychainProtectionLevelPromptSecureEnclave = @"prompt";
NSString *const ReactNativeKeychainProtectionLevelSinglePromptSecureEnclave = @"singleprompt";

/// @description identifiers so valet can encapsulate our keys in the keychain
NSString *const UPTPrivateKeyIdentifier = @"UportPrivateKeys";
NSString *const UPTProtectionLevelIdentifier = @"UportProtectionLevelIdentifier";
NSString *const UPTEthAddressIdentifier = @"UportEthAddressIdentifier";

/// @desctiption the key prefix to concatenate with the eth address necessary to lookup the private key
NSString *const UPTPrivateKeyLookupKeyNamePrefix = @"address-";
NSString *const UPTProtectionLevelLookupKeyNamePrefix = @"level-address-";

NSString * const UPTSignerErrorCodeLevelParamNotRecognized = @"-11";
NSString * const UPTSignerErrorCodeLevelPrivateKeyNotFound = @"-12";

@implementation UPTEthereumSigner

+ (void)createKeyPairWithStorageLevel:(UPTEthKeychainProtectionLevel)protectionLevel result:(UPTEthSignerKeyPairCreationResult)result {
    BTCKey *keyPair = [[BTCKey alloc] init];
    [UPTEthereumSigner saveKey:keyPair.privateKey protectionLevel:protectionLevel result:result];
}


+ (NSMutableData*) compressedPublicKey:(EC_KEY *)key {
    if (!key) return nil;
    EC_KEY_set_conv_form(key, POINT_CONVERSION_COMPRESSED);
    int length = i2o_ECPublicKey(key, NULL);
    if (!length) return nil;
    NSAssert(length <= 65, @"Pubkey length must be up to 65 bytes.");
    NSMutableData* data = [[NSMutableData alloc] initWithLength:length];
    unsigned char* bytes = [data mutableBytes];
    if (i2o_ECPublicKey(key, &bytes) != length) return nil;
    return data;
}

// Handles most of the signing code
+ (NSDictionary *) genericSignature:(BTCKey*)keypair forHash:(NSData*)hash enforceLowS: (BOOL)lowS {
    NSMutableData *privateKey = [keypair privateKey];
    EC_KEY* key = EC_KEY_new_by_curve_name(NID_secp256k1);

    BIGNUM *bignum = BN_bin2bn(privateKey.bytes, (int)privateKey.length, BN_new());
    BTCRegenerateKey(key, bignum);


    const BIGNUM *privkeyBIGNUM = EC_KEY_get0_private_key(key);

    BTCMutableBigNumber* privkeyBN = [[BTCMutableBigNumber alloc] initWithBIGNUM:privkeyBIGNUM];
    BTCBigNumber* n = [BTCCurvePoint curveOrder];

    NSMutableData* kdata = [keypair signatureNonceForHash:hash];
    BTCMutableBigNumber* k = [[BTCMutableBigNumber alloc] initWithUnsignedBigEndian:kdata];
    [k mod:n]; // make sure k belongs to [0, n - 1]

    BTCDataClear(kdata);

    BTCCurvePoint* K = [[BTCCurvePoint generator] multiply:k];
    BTCBigNumber* Kx = K.x;

    BTCBigNumber* hashBN = [[BTCBigNumber alloc] initWithUnsignedBigEndian:hash];

    // Compute s = (k^-1)*(h + Kx*privkey)

    BTCBigNumber* signatureBN = [[[privkeyBN multiply:Kx mod:n] add:hashBN mod:n] multiply:[k inverseMod:n] mod:n];

    BIGNUM *r = BN_new(); BN_copy(r, Kx.BIGNUM);
    BIGNUM *s = BN_new(); BN_copy(s, signatureBN.BIGNUM);
  
    BN_clear_free(bignum);
    BTCDataClear(privateKey);
    [privkeyBN clear];
    [k clear];
    [hashBN clear];
    [K clear];
    [Kx clear];
    [signatureBN clear];

    BN_CTX *ctx = BN_CTX_new();
    BN_CTX_start(ctx);

    const EC_GROUP *group = EC_KEY_get0_group(key);
    BIGNUM *order = BN_CTX_get(ctx);
    BIGNUM *halforder = BN_CTX_get(ctx);
    EC_GROUP_get_order(group, order, ctx);
    BN_rshift1(halforder, order);
    if (lowS && BN_cmp(s, halforder) > 0) {
        // enforce low S values, by negating the value (modulo the order) if above order/2.
        BN_sub(s, order, s);
    }
    EC_KEY_free(key);

    BN_CTX_end(ctx);
    BN_CTX_free(ctx);
    NSMutableData* rData = [NSMutableData dataWithLength:32];
    NSMutableData* sData = [NSMutableData dataWithLength:32];
  
    BN_bn2bin(r,rData.mutableBytes);
    BN_bn2bin(s,sData.mutableBytes);
    return @{
             @"r": rData,
             @"s": sData
             };
}

+ (NSDictionary*) ethereumSignature:(BTCKey*)keypair forHash:(NSData*)hash {
    NSDictionary *sig = [self genericSignature: keypair forHash: hash enforceLowS: YES];
    NSData *rData = (NSData *)sig[@"r"];
    NSData *sData = (NSData *)sig[@"s"];
    int rec = -1;
    const unsigned char* hashbytes = hash.bytes;
    int hashlength = (int)hash.length;
    BIGNUM *r = BN_new(); BN_bin2bn(rData.bytes ,32, r);
    BIGNUM *s = BN_new(); BN_bin2bn(sData.bytes ,32, s);
    int nBitsR = BN_num_bits(r);
    int nBitsS = BN_num_bits(s);
    if (nBitsR <= 256 && nBitsS <= 256) {
        NSData* pubkey = [keypair compressedPublicKey];
        BOOL foundMatchingPubkey = NO;
        for (int i=0; i < 4; i++) {
            EC_KEY* key2 = EC_KEY_new_by_curve_name(NID_secp256k1);
            if (ECDSA_SIG_recover_key_GFp(key2, r, s, hashbytes, hashlength, i, 1) == 1) {
                NSData* pubkey2 = [self compressedPublicKey: key2];
                if ([pubkey isEqual:pubkey2]) {
                    rec = i;
                    foundMatchingPubkey = YES;
                    break;
                }
            }
        }
        NSAssert(foundMatchingPubkey, @"At least one signature must work.");
    }
    NSDictionary *signatureDictionary = @{ @"v": @(0x1b + rec),
            @"r": [rData base64EncodedStringWithOptions:0],
            @"s":[sData base64EncodedStringWithOptions:0]};
    return signatureDictionary;
}

+ (NSData*) simpleSignature:(BTCKey*)keypair forHash:(NSData*)hash {
    NSDictionary *sig = [self genericSignature: keypair forHash: hash enforceLowS: NO];
    NSData *rData = (NSData *)sig[@"r"];
    NSData *sData = (NSData *)sig[@"s"];
    ///////
    NSMutableData *sigData = [NSMutableData dataWithLength:64];
    unsigned char* sigBytes = sigData.mutableBytes;
    memset(sigBytes, 0, 64);

    memcpy(sigBytes, rData.bytes, 32);
    memcpy(sigBytes+32, sData.bytes, 32);
    return sigData;
}

+ (void)signTransaction:(NSString *)ethAddress data:(NSString *)payload userPrompt:(NSString*)userPromptText  result:(UPTEthSignerTransactionSigningResult)result {
    UPTEthKeychainProtectionLevel protectionLevel = [UPTEthereumSigner protectionLevelWithEthAddress:ethAddress];
    if ( protectionLevel == UPTEthKeychainProtectionLevelNotRecognized ) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTSignerErrorCodeLevelParamNotRecognized.integerValue userInfo:@{@"message": @"protection level not found for eth address"}];
        result( nil, protectionLevelError);
        return;
    }

    BTCKey *key = [self keyPairWithEthAddress:ethAddress userPromptText:userPromptText protectionLevel:protectionLevel];
    if (key) {
        NSData *payloadData = [[NSData alloc] initWithBase64EncodedString:payload options:0];
        NSData *hash = [UPTEthereumSigner keccak256:payloadData];
        NSDictionary *signature = [self ethereumSignature: key forHash:hash];
        result(signature, nil);
    } else {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTSignerErrorCodeLevelPrivateKeyNotFound.integerValue userInfo:@{@"message": @"private key not found for eth address"}];
        result( nil, protectionLevelError);
    }

}

+ (void)signJwt:(NSString *)ethAddress userPrompt:(NSString*)userPromptText data:(NSData *)payload result:(UPTEthSignerJWTSigningResult)result {
    UPTEthKeychainProtectionLevel protectionLevel = [UPTEthereumSigner protectionLevelWithEthAddress:ethAddress];
    if ( protectionLevel == UPTEthKeychainProtectionLevelNotRecognized ) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTSignerErrorCodeLevelParamNotRecognized.integerValue userInfo:@{@"message": @"protection level not found for eth address"}];
        result( nil, protectionLevelError);
        return;
    }

    BTCKey *key = [self keyPairWithEthAddress:ethAddress userPromptText:userPromptText protectionLevel:protectionLevel];
    if (key) {
        NSData *hash = [payload SHA256];
        NSData *signature = [self simpleSignature:key forHash:hash];
        result(signature, nil);
    } else {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTSignerErrorCodeLevelPrivateKeyNotFound.integerValue userInfo:@{@"message": @"private key not found for eth address"}];
        result( nil, protectionLevelError);
    }

}

+ (NSArray *)allAddresses {
    VALValet *addressKeystore = [UPTEthereumSigner ethAddressesKeystore];
    return [[addressKeystore allKeys] allObjects];
}


/// @description - saves the private key and requested protection level in the keychain
///              - private key converted to nsdata without base64 encryption
+ (void)saveKey:(NSData *)privateKey protectionLevel:(UPTEthKeychainProtectionLevel)protectionLevel result:(UPTEthSignerKeyPairCreationResult)result {
    BTCKey *keyPair = [[BTCKey alloc] initWithPrivateKey:privateKey];
    NSString *ethAddress = [UPTEthereumSigner ethAddressWithPublicKey:keyPair.publicKey];
    VALValet *privateKeystore = [UPTEthereumSigner privateKeystoreWithProtectionLevel:protectionLevel];
    NSString *privateKeyLookupKeyName = [UPTEthereumSigner privateKeyLookupKeyNameWithEthAddress:ethAddress];
    [privateKeystore setObject:keyPair.privateKey forKey:privateKeyLookupKeyName];
    [UPTEthereumSigner saveProtectionLevel:protectionLevel withEthAddress:ethAddress];
    [UPTEthereumSigner saveEthAddress:ethAddress];
    NSString *publicKeyString = [keyPair.publicKey base64EncodedStringWithOptions:0];
    result( ethAddress, publicKeyString, nil );
}

#pragma mark - Private

+ (void)saveProtectionLevel:(UPTEthKeychainProtectionLevel)protectionLevel withEthAddress:(NSString *)ethAddress {
    VALValet *protectionLevelsKeystore = [UPTEthereumSigner keystoreForProtectionLevels];
    NSString *protectionLevelLookupKey = [UPTEthereumSigner protectionLevelLookupKeyNameWithEthAddress:ethAddress];
    NSString *keystoreCompatibleProtectionLevel = [UPTEthereumSigner keychainCompatibleProtectionLevel:protectionLevel];
    [protectionLevelsKeystore setString:keystoreCompatibleProtectionLevel forKey:protectionLevelLookupKey];
}

+ (UPTEthKeychainProtectionLevel)protectionLevelWithEthAddress:(NSString *)ethAddress {
    NSString *protectionLevelLookupKeyName = [UPTEthereumSigner protectionLevelLookupKeyNameWithEthAddress:ethAddress];
    VALValet *protectionLevelsKeystore = [UPTEthereumSigner keystoreForProtectionLevels];
    NSString *keychainSourcedProtectionLevel = [protectionLevelsKeystore stringForKey:protectionLevelLookupKeyName];
    return [UPTEthereumSigner protectionLevelFromKeychainSourcedProtectionLevel:keychainSourcedProtectionLevel];
}

+ (NSString *)ethAddressWithPublicKey:(NSData *)publicKey {
    NSData *strippedPublicKey = [publicKey subdataWithRange:NSMakeRange(1,[publicKey length]-1)];
    NSData *address = [[UPTEthereumSigner keccak256:strippedPublicKey] subdataWithRange:NSMakeRange(12, 20)];
    return [NSString stringWithFormat:@"0x%@", [address hex]];
}

+ (VALValet *)keystoreForProtectionLevels {
    return [VALValet valetWithIdentifier:UPTProtectionLevelIdentifier accessibility:VALAccessibilityAlways];
}

+ (NSString *)privateKeyLookupKeyNameWithEthAddress:(NSString *)ethAddress {
    return [NSString stringWithFormat:@"%@%@", UPTPrivateKeyLookupKeyNamePrefix, ethAddress];
}

+ (NSString *)protectionLevelLookupKeyNameWithEthAddress:(NSString *)ethAddress {
    return [NSString stringWithFormat:@"%@%@", UPTProtectionLevelLookupKeyNamePrefix, ethAddress];
}

+ (VALValet *)ethAddressesKeystore {
    return [VALValet valetWithIdentifier:UPTEthAddressIdentifier accessibility:VALAccessibilityAlways];
}

/// @return NSString a derived version of UPTEthKeychainProtectionLevel appropriate for keychain storage
+ (NSString *)keychainCompatibleProtectionLevel:(UPTEthKeychainProtectionLevel)protectionLevel {
    return @(protectionLevel).stringValue;
}

/// @param protectionLevel sourced from the keychain. Was originally created with +(NSString *)keychainCompatibleProtectionLevel:
+ (UPTEthKeychainProtectionLevel)protectionLevelFromKeychainSourcedProtectionLevel:(NSString *)protectionLevel {
    return (UPTEthKeychainProtectionLevel)protectionLevel.integerValue;
}

+ (NSSet *)addressesFromKeystore:(UPTEthKeychainProtectionLevel)protectionLevel {
    VALValet *keystore = [UPTEthereumSigner privateKeystoreWithProtectionLevel:protectionLevel];
    NSArray *keys = [[keystore allKeys] allObjects];
    NSMutableSet *addresses = [NSMutableSet new];
    for (NSString *key in keys) {
        NSString *ethAddress = [key substringFromIndex:UPTPrivateKeyLookupKeyNamePrefix.length];
        [addresses addObject:ethAddress];
    }

    return addresses;
}


+ (void)saveEthAddress:(NSString *)ethAddress {
    VALValet *addressKeystore = [UPTEthereumSigner ethAddressesKeystore];
    [addressKeystore setString:ethAddress forKey:ethAddress];
}

/// @param userPromptText the string to display to the user when requesting access to the secure enclave
/// @return private key as NSData
+ (NSData *)privateKeyWithEthAddress:(NSString *)ethAddress userPromptText:(NSString *)userPromptText protectionLevel:(UPTEthKeychainProtectionLevel)protectionLevel {
    VALValet *privateKeystore = [self privateKeystoreWithProtectionLevel:protectionLevel];
    NSString *privateKeyLookupKeyName = [UPTEthereumSigner privateKeyLookupKeyNameWithEthAddress:ethAddress];
    NSData *privateKey;
    switch ( protectionLevel ) {
        case UPTEthKeychainProtectionLevelNormal: {
            privateKey = [privateKeystore objectForKey:privateKeyLookupKeyName];
            break;
        }
        case UPTEthKeychainProtectionLevelICloud: {
            privateKey = [privateKeystore objectForKey:privateKeyLookupKeyName];
            break;
        }
        case UPTEthKeychainProtectionLevelPromptSecureEnclave: {
            privateKey = [(VALSecureEnclaveValet *)privateKeystore objectForKey:privateKeyLookupKeyName userPrompt:userPromptText userCancelled:nil];
            break;
        }
        case UPTEthKeychainProtectionLevelSinglePromptSecureEnclave: {
            privateKey = [(VALSinglePromptSecureEnclaveValet *)privateKeystore objectForKey:privateKeyLookupKeyName userPrompt:userPromptText userCancelled:nil];
            break;
        }
        case UPTEthKeychainProtectionLevelNotRecognized:
            // then it will return nil
            break;
        default:
            // then it will return nil
            break;
    }

    return privateKey;
}
/// @param userPromptText the string to display to the user when requesting access to the secure enclave
/// @return BTCKey
+ (BTCKey *)keyPairWithEthAddress:(NSString *)ethAddress userPromptText:(NSString *)userPromptText protectionLevel:(UPTEthKeychainProtectionLevel)protectionLevel {
  NSData *privateKey = [self privateKeyWithEthAddress:ethAddress userPromptText:userPromptText protectionLevel:protectionLevel];
  if (privateKey) {
    return [[BTCKey alloc] initWithPrivateKey:privateKey];
  } else {
    return nil;
  }
}

/// @param protectionLevel indicates which private keystore to create and return
/// @return returns VALValet or valid subclass: VALSynchronizableValet, VALSecureEnclaveValet, VALSinglePromptSecureEnclaveValet
+ (VALValet *)privateKeystoreWithProtectionLevel:(UPTEthKeychainProtectionLevel)protectionLevel {
    VALValet *keystore;
    switch ( protectionLevel ) {
        case UPTEthKeychainProtectionLevelNormal: {
            keystore = [VALValet valetWithIdentifier:UPTPrivateKeyIdentifier accessibility:VALAccessibilityWhenUnlockedThisDeviceOnly];
            break;
        }
        case UPTEthKeychainProtectionLevelICloud: {
            keystore = [VALValet iCloudValetWithIdentifier:UPTPrivateKeyIdentifier accessibility:VALCloudAccessibilityWhenUnlocked];
            break;
        }
        case UPTEthKeychainProtectionLevelPromptSecureEnclave: {
            keystore = [VALSecureEnclaveValet valetWithIdentifier:UPTPrivateKeyIdentifier accessControl:VALSecureEnclaveAccessControlUserPresence];
            break;
        }
        case UPTEthKeychainProtectionLevelSinglePromptSecureEnclave: {
            keystore = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:UPTPrivateKeyIdentifier accessControl:VALSecureEnclaveAccessControlUserPresence];
            break;
        }
        case UPTEthKeychainProtectionLevelNotRecognized:
            // then it will return nil
            break;
        default:
            // then it will return nil
            break;
    }

    return keystore;
}

static int BTCRegenerateKey(EC_KEY *eckey, BIGNUM *priv_key) {
    BN_CTX *ctx = NULL;
    EC_POINT *pub_key = NULL;

    if (!eckey) return 0;

    const EC_GROUP *group = EC_KEY_get0_group(eckey);

    BOOL success = NO;
    if ((ctx = BN_CTX_new())) {
        if ((pub_key = EC_POINT_new(group))) {
            if (EC_POINT_mul(group, pub_key, priv_key, NULL, NULL, ctx)) {
                EC_KEY_set_private_key(eckey, priv_key);
                EC_KEY_set_public_key(eckey, pub_key);
                success = YES;
            }
        }
    }

    if (pub_key) EC_POINT_free(pub_key);
    if (ctx) BN_CTX_free(ctx);

    return success;
}

// Perform ECDSA key recovery (see SEC1 4.1.6) for curves over (mod p)-fields
// recid selects which key is recovered
// if check is non-zero, additional checks are performed
static int ECDSA_SIG_recover_key_GFp(EC_KEY *eckey, BIGNUM *r, BIGNUM *s, const unsigned char *msg, int msglen, int recid, int check) {
    if (!eckey) return 0;

    int ret = 0;
    BN_CTX *ctx = NULL;

    BIGNUM *x = NULL;
    BIGNUM *e = NULL;
    BIGNUM *order = NULL;
    BIGNUM *sor = NULL;
    BIGNUM *eor = NULL;
    BIGNUM *field = NULL;
    EC_POINT *R = NULL;
    EC_POINT *O = NULL;
    EC_POINT *Q = NULL;
    BIGNUM *rr = NULL;
    BIGNUM *zero = NULL;
    int n = 0;
    int i = recid / 2;

    const EC_GROUP *group = EC_KEY_get0_group(eckey);
    if ((ctx = BN_CTX_new()) == NULL) { ret = -1; goto err; }
    BN_CTX_start(ctx);
    order = BN_CTX_get(ctx);
    if (!EC_GROUP_get_order(group, order, ctx)) { ret = -2; goto err; }
    x = BN_CTX_get(ctx);
    if (!BN_copy(x, order)) { ret=-1; goto err; }
    if (!BN_mul_word(x, i)) { ret=-1; goto err; }
    if (!BN_add(x, x, r)) { ret=-1; goto err; }
    field = BN_CTX_get(ctx);
    if (!EC_GROUP_get_curve_GFp(group, field, NULL, NULL, ctx)) { ret=-2; goto err; }
    if (BN_cmp(x, field) >= 0) { ret=0; goto err; }
    if ((R = EC_POINT_new(group)) == NULL) { ret = -2; goto err; }
    if (!EC_POINT_set_compressed_coordinates_GFp(group, R, x, recid % 2, ctx)) { ret=0; goto err; }
    if (check) {
        if ((O = EC_POINT_new(group)) == NULL) { ret = -2; goto err; }
        if (!EC_POINT_mul(group, O, NULL, R, order, ctx)) { ret=-2; goto err; }
        if (!EC_POINT_is_at_infinity(group, O)) { ret = 0; goto err; }
    }
    if ((Q = EC_POINT_new(group)) == NULL) { ret = -2; goto err; }
    n = EC_GROUP_get_degree(group);
    e = BN_CTX_get(ctx);
    if (!BN_bin2bn(msg, msglen, e)) { ret=-1; goto err; }
    if (8*msglen > n) BN_rshift(e, e, 8-(n & 7));
    zero = BN_CTX_get(ctx);
    if (!BN_zero(zero)) { ret=-1; goto err; }
    if (!BN_mod_sub(e, zero, e, order, ctx)) { ret=-1; goto err; }
    rr = BN_CTX_get(ctx);
    if (!BN_mod_inverse(rr, r, order, ctx)) { ret=-1; goto err; }
    sor = BN_CTX_get(ctx);
    if (!BN_mod_mul(sor, s, rr, order, ctx)) { ret=-1; goto err; }
    eor = BN_CTX_get(ctx);
    if (!BN_mod_mul(eor, e, rr, order, ctx)) { ret=-1; goto err; }
    if (!EC_POINT_mul(group, Q, eor, R, sor, ctx)) { ret=-2; goto err; }
    if (!EC_KEY_set_public_key(eckey, Q)) { ret=-2; goto err; }

    ret = 1;

    err:
    if (ctx) {
        BN_CTX_end(ctx);
        BN_CTX_free(ctx);
    }
    if (R != NULL) EC_POINT_free(R);
    if (O != NULL) EC_POINT_free(O);
    if (Q != NULL) EC_POINT_free(Q);
    return ret;
}

#pragma mark - Utils

+ (NSData *)keccak256:(NSData *)input {
    char *outputBytes = malloc(32);
    sha3_256((uint8_t *)outputBytes, 32, (uint8_t *)[input bytes], (size_t)[input length]);
    return [NSData dataWithBytesNoCopy:outputBytes length:32 freeWhenDone:YES];
}

+ (UPTEthKeychainProtectionLevel)enumStorageLevelWithStorageLevel:(NSString *)storageLevel {
    NSArray<NSString *> *storageLevels = @[ ReactNativeKeychainProtectionLevelNormal,
                                            ReactNativeKeychainProtectionLevelICloud,
                                            ReactNativeKeychainProtectionLevelPromptSecureEnclave,
                                            ReactNativeKeychainProtectionLevelSinglePromptSecureEnclave];
    return (UPTEthKeychainProtectionLevel)[storageLevels indexOfObject:storageLevel];
}

+ (NSString *)hexStringWithDataKey:(NSData *)dataPrivateKey {
    return BTCHexFromData(dataPrivateKey);
}

+ (NSData *)dataFromHexString:(NSString *)originalHexString {
    return BTCDataFromHex(originalHexString);
}


+ (NSString *)base64StringWithURLEncodedBase64String:(NSString *)URLEncodedBase64String {
    NSMutableString *characterConverted = [[[URLEncodedBase64String stringByReplacingOccurrencesOfString:@"-" withString:@"+"] stringByReplacingOccurrencesOfString:@"_" withString:@"/"] mutableCopy];
    if ( characterConverted.length % 4 != 0 ) {
        NSUInteger numEquals = 4 - characterConverted.length % 4;
        NSString *equalsPadding = [@"" stringByPaddingToLength:numEquals withString: @"=" startingAtIndex:0];
        [characterConverted appendString:equalsPadding];
    }
    
    return characterConverted;
    
}

+ (NSString *)URLEncodedBase64StringWithBase64String:(NSString *)base64String {
    return [[[base64String stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"] stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

@end
