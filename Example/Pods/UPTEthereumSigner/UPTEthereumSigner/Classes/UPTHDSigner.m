//
//  UPTHDSigner.m
//  uPortMobile
//
//  Created by josh on 1/5/18.
//  Copyright © 2018 ConsenSys AG. All rights reserved.
//

@import Valet;
#import "UPTHDSigner.h"
#import "CoreBitcoin/BTCMnemonic.h"
#import "keccak.h"
#import "CoreBitcoin/CoreBitcoin+Categories.h"
#import <openssl/obj_mac.h>

// https://github.com/ethereum/EIPs/issues/84
NSString * const UPORT_ROOT_DERIVATION_PATH = @"m/7696500'/0'/0'/0'";
NSString * const METAMASK_ROOT_DERIVATION_PATH = @"m/44'/60'/0'/0";

/// @description identifiers so valet can encapsulate our keys in the keychain
NSString *const UPTHDPrivateKeyIdentifier = @"UportPrivateKeys";
NSString *const UPTHDProtectionLevelIdentifier = @"UportProtectionLevelIdentifier";
NSString *const UPTHDAddressIdentifier = @"UportEthAddressIdentifier";

/// @desctiption the key prefix to concatenate with the eth address necessary to lookup the private key
NSString *const UPTHDEntropyLookupKeyNamePrefix = @"seed-";
NSString *const UPTHDEntropyProtectionLevelLookupKeyNamePrefix = @"level-seed-";

NSString * const UPTHDSignerErrorCodeLevelParamNotRecognized = @"-11";
NSString * const UPTHDSignerErrorCodeLevelPrivateKeyNotFound = @"-12";

@implementation UPTHDSigner

#pragma mark - Public methods

+ (BOOL)hasSeed {
    VALValet *addressKeystore = [UPTHDSigner ethAddressesKeystore];
    NSArray *addressKeys = [[addressKeystore allKeys] allObjects];
    BOOL hasSeed = NO;
    for ( NSString *addressKey in addressKeys ) {
        if ( [addressKey containsString:@"seed"] ) {
            hasSeed = YES;
        }
    }

    return hasSeed;
}

+ (void)showSeed:(NSString *)rootAddress prompt:(NSString *)prompt callback:(UPTHDSignerSeedPhraseResult)callback {
    UPTHDSignerProtectionLevel protectionLevel = [UPTHDSigner protectionLevelWithEthAddress:rootAddress];
    if ( protectionLevel == UPTHDSignerProtectionLevelNotRecognized ) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTHDSignerError" code:UPTHDSignerErrorCodeLevelParamNotRecognized.integerValue userInfo:@{@"message": @"protection level not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    NSData *masterEntropy = [UPTHDSigner entropyWithEthAddress:rootAddress userPromptText:prompt protectionLevel:protectionLevel];
    if (!masterEntropy) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTHDError" code:UPTHDSignerErrorCodeLevelPrivateKeyNotFound.integerValue userInfo:@{@"message": @"private key not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    BTCMnemonic *mnemonic = [[BTCMnemonic alloc] initWithEntropy:masterEntropy password:@"" wordListType:BTCMnemonicWordListTypeEnglish];
    NSString *phrase = [mnemonic.words componentsJoinedByString:@" "];
    callback( phrase, nil );
}

+ (void)createHDSeed:(UPTHDSignerProtectionLevel)protectionLevel callback:(UPTHDSignerSeedCreationResult)callback {
    [UPTHDSigner
        createHDSeed:protectionLevel
        rootDerivationPath:UPORT_ROOT_DERIVATION_PATH
        callback:callback
    ];
}
+ (void)createHDSeed:(UPTHDSignerProtectionLevel)protectionLevel
    rootDerivationPath:(NSString *)rootDerivationPath
    callback:(UPTHDSignerSeedCreationResult)callback
{
    NSData *randomEntropy = [UPTHDSigner randomEntropy];
    BTCMnemonic *mnemonic = [[BTCMnemonic alloc] initWithEntropy:randomEntropy password:@"" wordListType:BTCMnemonicWordListTypeEnglish];
    NSString *wordsString = [mnemonic.words componentsJoinedByString:@" "];
    [UPTHDSigner importSeed:protectionLevel phrase:wordsString rootDerivationPath:rootDerivationPath callback:callback];
}

+ (void)importSeed:(UPTHDSignerProtectionLevel)protectionLevel
    phrase:(NSString *)phrase
    callback:(UPTHDSignerSeedCreationResult)callback
{
    [UPTHDSigner
        importSeed:protectionLevel
        phrase:phrase
        rootDerivationPath:UPORT_ROOT_DERIVATION_PATH
        callback:callback
    ];
}
+ (void)importSeed:(UPTHDSignerProtectionLevel)protectionLevel
    phrase:(NSString *)phrase
    rootDerivationPath:(NSString *)derivationPath
    callback:(UPTHDSignerSeedCreationResult)callback
{
    NSArray<NSString *> *words = [UPTHDSigner wordsFromPhrase:phrase];
    BTCMnemonic *mnemonic = [[BTCMnemonic alloc] initWithWords:words password:@"" wordListType:BTCMnemonicWordListTypeEnglish];
    BTCKeychain *masterKeychain = [[BTCKeychain alloc] initWithSeed:mnemonic.seed];

    BTCKeychain *rootKeychain = [masterKeychain derivedKeychainWithPath:derivationPath];
    NSString *rootPublicKeyString = [rootKeychain.key.uncompressedPublicKey base64EncodedStringWithOptions:0];
    NSString *rootEthereumAddress = [UPTHDSigner ethereumAddressWithPublicKey:rootKeychain.key.uncompressedPublicKey];

    VALValet *privateKeystore = [UPTHDSigner privateKeystoreWithProtectionLevel:protectionLevel];
    NSString *privateKeyLookupKeyName = [UPTHDSigner entropyLookupKeyNameWithEthAddress:rootEthereumAddress];
    [privateKeystore setObject:mnemonic.entropy forKey:privateKeyLookupKeyName];
    [UPTHDSigner saveProtectionLevel:protectionLevel withEthAddress:rootEthereumAddress];
    [UPTHDSigner saveEthAddress:rootEthereumAddress];

    callback( rootEthereumAddress, rootPublicKeyString, nil );
}

+ (void)computeAddressForPath:(NSString *)rootAddress derivationPath:(NSString *)derivationPath prompt:(NSString *)prompt callback:(UPTHDSignerSeedCreationResult)callback {
    UPTHDSignerProtectionLevel protectionLevel = [UPTHDSigner protectionLevelWithEthAddress:rootAddress];
    if ( protectionLevel == UPTHDSignerProtectionLevelNotRecognized ) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTHDSignerError" code:UPTHDSignerErrorCodeLevelParamNotRecognized.integerValue userInfo:@{@"message": @"protection level not found for eth address"}];
        callback( nil, nil, protectionLevelError);
        return;
    }

    NSData *masterEntropy = [UPTHDSigner entropyWithEthAddress:rootAddress userPromptText:prompt protectionLevel:protectionLevel];
    if (!masterEntropy) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTHDSignerErrorCodeLevelPrivateKeyNotFound.integerValue userInfo:@{@"message": @"private key not found for eth address"}];
        callback( nil, nil, protectionLevelError);
        return;
    }

    BTCMnemonic *mnemonic = [[BTCMnemonic alloc] initWithEntropy:masterEntropy password:@"" wordListType:BTCMnemonicWordListTypeEnglish];
    BTCKeychain *masterKeychain = [[BTCKeychain alloc] initWithSeed:mnemonic.seed];

    BTCKeychain *rootKeychain = [masterKeychain derivedKeychainWithPath:derivationPath];
    NSString *rootPublicKeyString = [rootKeychain.key.uncompressedPublicKey base64EncodedStringWithOptions:0];
    NSString *rootEthereumAddress = [UPTHDSigner ethereumAddressWithPublicKey:rootKeychain.key.uncompressedPublicKey];
    callback( rootEthereumAddress, rootPublicKeyString, nil );
}

+ (void)signTransaction:(NSString *)rootAddress derivationPath:(NSString *)derivationPath txPayload:(NSString *)txPayload prompt:(NSString *)prompt callback:(UPTHDSignerTransactionSigningResult)callback {
    UPTHDSignerProtectionLevel protectionLevel = [UPTHDSigner protectionLevelWithEthAddress:rootAddress];
    if ( protectionLevel == UPTHDSignerProtectionLevelNotRecognized ) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTHDSignerError" code:UPTHDSignerErrorCodeLevelParamNotRecognized.integerValue userInfo:@{@"message": @"protection level not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    NSData *masterEntropy = [UPTHDSigner entropyWithEthAddress:rootAddress userPromptText:prompt protectionLevel:protectionLevel];
    if (!masterEntropy) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTHDSignerErrorCodeLevelPrivateKeyNotFound.integerValue userInfo:@{@"message": @"private key not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    BTCMnemonic *mnemonic = [[BTCMnemonic alloc] initWithEntropy:masterEntropy password:@"" wordListType:BTCMnemonicWordListTypeEnglish];
    BTCKeychain *masterKeychain = [[BTCKeychain alloc] initWithSeed:mnemonic.seed];
    BTCKeychain *derivedKeychain = [masterKeychain derivedKeychainWithPath:derivationPath];

    NSData *payloadData = [[NSData alloc] initWithBase64EncodedString:txPayload options:0];
    NSData *hash = [UPTHDSigner keccak256:payloadData];
    NSDictionary *signature = [self ethereumSignature: derivedKeychain.key forHash:hash];
    callback(signature, nil);
}

+ (void)signJWT:(NSString *)rootAddress derivationPath:(NSString *)derivationPath data:(NSString *)data prompt:(NSString *)prompt callback:(UPTHDSignerJWTSigningResult)callback {
    UPTHDSignerProtectionLevel protectionLevel = [UPTHDSigner protectionLevelWithEthAddress:rootAddress];
    if ( protectionLevel == UPTHDSignerProtectionLevelNotRecognized ) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTHDSignerError" code:UPTHDSignerErrorCodeLevelParamNotRecognized.integerValue userInfo:@{@"message": @"protection level not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    NSData *masterEntropy = [UPTHDSigner entropyWithEthAddress:rootAddress userPromptText:prompt protectionLevel:protectionLevel];
    if (!masterEntropy) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTHDSignerErrorCodeLevelPrivateKeyNotFound.integerValue userInfo:@{@"message": @"private key not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    BTCMnemonic *mnemonic = [[BTCMnemonic alloc] initWithEntropy:masterEntropy password:@"" wordListType:BTCMnemonicWordListTypeEnglish];
    BTCKeychain *masterKeychain = [[BTCKeychain alloc] initWithSeed:mnemonic.seed];
    BTCKeychain *derivedKeychain = [masterKeychain derivedKeychainWithPath:derivationPath];

    NSData *payloadData = [[NSData alloc] initWithBase64EncodedString:data options:0];
    NSData *hash = [payloadData SHA256];
    NSData *signature = [self simpleSignature:derivedKeychain.key forHash:hash];
    NSString *base64EncodedSignature = [signature base64EncodedStringWithOptions:0];
    NSString *webSafeBase64Signature = [UPTHDSigner URLEncodedBase64StringWithBase64String:base64EncodedSignature];
    callback(webSafeBase64Signature, nil);
}

+ (void)privateKeyForPath:(NSString *)rootAddress derivationPath:(NSString *)derivationPath prompt:(NSString *)prompt callback:(UPTHDSignerPrivateKeyResult)callback {
    UPTHDSignerProtectionLevel protectionLevel = [UPTHDSigner protectionLevelWithEthAddress:rootAddress];
    if ( protectionLevel == UPTHDSignerProtectionLevelNotRecognized ) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTHDSignerError" code:UPTHDSignerErrorCodeLevelParamNotRecognized.integerValue userInfo:@{@"message": @"protection level not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    NSData *masterEntropy = [UPTHDSigner entropyWithEthAddress:rootAddress userPromptText:prompt protectionLevel:protectionLevel];
    if (!masterEntropy) {
        NSError *protectionLevelError = [[NSError alloc] initWithDomain:@"UPTError" code:UPTHDSignerErrorCodeLevelPrivateKeyNotFound.integerValue userInfo:@{@"message": @"private key not found for eth address"}];
        callback( nil, protectionLevelError);
        return;
    }

    BTCMnemonic *mnemonic = [[BTCMnemonic alloc] initWithEntropy:masterEntropy password:@"" wordListType:BTCMnemonicWordListTypeEnglish];
    BTCKeychain *masterKeychain = [[BTCKeychain alloc] initWithSeed:mnemonic.seed];
    BTCKeychain *derivedKeychain = [masterKeychain derivedKeychainWithPath:derivationPath];

    NSString *derivedPrivateKeyBase64 = [derivedKeychain.key.privateKey base64EncodedStringWithOptions:0];
    callback( derivedPrivateKeyBase64, nil );
}


#pragma mark - Private methods

+ (NSString *)ethereumAddressWithPublicKey:(NSData *)publicKey {
    NSData *strippedPublicKey = [publicKey subdataWithRange:NSMakeRange(1,[publicKey length]-1)];
    NSData *address = [[UPTHDSigner keccak256:strippedPublicKey] subdataWithRange:NSMakeRange(12, 20)];
    return [NSString stringWithFormat:@"0x%@", [address hex]];
}

+ (NSData *)keccak256:(NSData *)input {
    char *outputBytes = malloc(32);
    sha3_256((unsigned char *)outputBytes, 32, (unsigned char *)[input bytes], (unsigned int)[input length]);
    return [NSData dataWithBytes:outputBytes length:32];
}

+ (UPTHDSignerProtectionLevel)protectionLevelWithEthAddress:(NSString *)ethAddress {
    NSString *protectionLevelLookupKeyName = [UPTHDSigner protectionLevelLookupKeyNameWithEthAddress:ethAddress];
    VALValet *protectionLevelsKeystore = [UPTHDSigner keystoreForProtectionLevels];
    NSString *keychainSourcedProtectionLevel = [protectionLevelsKeystore stringForKey:protectionLevelLookupKeyName];
    return [UPTHDSigner protectionLevelFromKeychainSourcedProtectionLevel:keychainSourcedProtectionLevel];
}

/// @param protectionLevel sourced from the keychain. Was originally created with +(NSString *)keychainCompatibleProtectionLevel:
+ (UPTHDSignerProtectionLevel)protectionLevelFromKeychainSourcedProtectionLevel:(NSString *)protectionLevel {
    return (UPTHDSignerProtectionLevel)protectionLevel.integerValue;
}

/// @param protectionLevel indicates which private keystore to create and return
/// @return returns VALValet or valid subclass: VALSynchronizableValet, VALSecureEnclaveValet, VALSinglePromptSecureEnclaveValet
+ (VALValet *)privateKeystoreWithProtectionLevel:(UPTHDSignerProtectionLevel)protectionLevel {
    VALValet *keystore;
    switch ( protectionLevel ) {
        case UPTHDSignerProtectionLevelNormal: {
            keystore = [VALValet valetWithIdentifier:UPTHDPrivateKeyIdentifier accessibility:VALAccessibilityAlwaysThisDeviceOnly];
            break;
        }
        case UPTHDSignerProtectionLevelICloud: {
            keystore = [VALValet iCloudValetWithIdentifier:UPTHDPrivateKeyIdentifier accessibility:VALCloudAccessibilityWhenUnlocked];
            break;
        }
        case UPTHDSignerProtectionLevelPromptSecureEnclave: {
            keystore = [VALSecureEnclaveValet valetWithIdentifier:UPTHDPrivateKeyIdentifier accessControl:VALSecureEnclaveAccessControlUserPresence];
            break;
        }
        case UPTHDSignerProtectionLevelSinglePromptSecureEnclave: {
            keystore = [VALSinglePromptSecureEnclaveValet valetWithIdentifier:UPTHDPrivateKeyIdentifier accessControl:VALSecureEnclaveAccessControlUserPresence];
            break;
        }
        case UPTHDSignerProtectionLevelNotRecognized:
            // then it will return nil
            break;
        default:
            // then it will return nil
            break;
    }

    return keystore;
}


+ (void)saveProtectionLevel:(UPTHDSignerProtectionLevel)protectionLevel withEthAddress:(NSString *)ethAddress {
    VALValet *protectionLevelsKeystore = [UPTHDSigner keystoreForProtectionLevels];
    NSString *protectionLevelLookupKey = [UPTHDSigner protectionLevelLookupKeyNameWithEthAddress:ethAddress];
    NSString *keystoreCompatibleProtectionLevel = [UPTHDSigner keychainCompatibleProtectionLevel:protectionLevel];
    [protectionLevelsKeystore setString:keystoreCompatibleProtectionLevel forKey:protectionLevelLookupKey];
}

+ (VALValet *)keystoreForProtectionLevels {
    return [VALValet valetWithIdentifier:UPTHDProtectionLevelIdentifier accessibility:VALAccessibilityAlways];
}

+ (NSString *)entropyLookupKeyNameWithEthAddress:(NSString *)ethAddress {
    return [NSString stringWithFormat:@"%@%@", UPTHDEntropyLookupKeyNamePrefix, ethAddress];
}

+ (NSString *)protectionLevelLookupKeyNameWithEthAddress:(NSString *)ethAddress {
    return [NSString stringWithFormat:@"%@%@", UPTHDEntropyProtectionLevelLookupKeyNamePrefix, ethAddress];
}

+ (VALValet *)ethAddressesKeystore {
    return [VALValet valetWithIdentifier:UPTHDAddressIdentifier accessibility:VALAccessibilityAlways];
}

/// @return NSString a derived version of UPTEthKeychainProtectionLevel appropriate for keychain storage
+ (NSString *)keychainCompatibleProtectionLevel:(UPTHDSignerProtectionLevel)protectionLevel {
    return @(protectionLevel).stringValue;
}

+ (void)saveEthAddress:(NSString *)ethAddress {
    VALValet *addressKeystore = [UPTHDSigner ethAddressesKeystore];
    [addressKeystore setString:ethAddress forKey:ethAddress];
}

/// @param userPromptText the string to display to the user when requesting access to the secure enclave
/// @return private key as NSData
+ (NSData *)entropyWithEthAddress:(NSString *)ethAddress userPromptText:(NSString *)userPromptText protectionLevel:(UPTHDSignerProtectionLevel)protectionLevel {
    VALValet *entropyKeystore = [self privateKeystoreWithProtectionLevel:protectionLevel];
    NSString *entropyLookupKeyName = [UPTHDSigner entropyLookupKeyNameWithEthAddress:ethAddress];
    NSData *entropy;
    switch ( protectionLevel ) {
        case UPTHDSignerProtectionLevelNormal: {
            entropy = [entropyKeystore objectForKey:entropyLookupKeyName];
            break;
        }
        case UPTHDSignerProtectionLevelICloud: {
            entropy = [entropyKeystore objectForKey:entropyLookupKeyName];
            break;
        }
        case UPTHDSignerProtectionLevelPromptSecureEnclave: {
            entropy = [(VALSecureEnclaveValet *)entropyKeystore objectForKey:entropyLookupKeyName userPrompt:userPromptText userCancelled:nil];
            break;
        }
        case UPTHDSignerProtectionLevelSinglePromptSecureEnclave: {
            entropy = [(VALSinglePromptSecureEnclaveValet *)entropyKeystore objectForKey:entropyLookupKeyName userPrompt:userPromptText userCancelled:nil];
            break;
        }
        case UPTHDSignerProtectionLevelNotRecognized:
            // then it will return nil
            break;
        default:
            // then it will return nil
            break;
    }

    return entropy;
}


+ (NSMutableData*) compressedPublicKey:(EC_KEY *)key {
    if (!key) return nil;
    EC_KEY_set_conv_form(key, POINT_CONVERSION_COMPRESSED);//POINT_CONVERSION_UNCOMPRESSED //POINT_CONVERSION_COMPRESSED
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

+ (NSArray<NSString *> *)wordsFromPhrase:(NSString *)phrase {
    NSArray<NSString *> *words = [phrase componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return [words filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
}

+ (NSData*)randomEntropy {
    NSUInteger entropyCapacity = 128 / 8;
    NSMutableData* entropy = [NSMutableData dataWithCapacity:(128 / 8)];
    NSUInteger numBytes = entropyCapacity / 4;
    for( NSUInteger i = 0 ; i < numBytes; ++i ) {
        u_int32_t randomBits = arc4random();
        [entropy appendBytes:(void *)&randomBits length:4];
    }

    return entropy;
}

+ (UPTHDSignerProtectionLevel)enumStorageLevelWithStorageLevel:(NSString *)storageLevel {
    NSArray<NSString *> *storageLevels = @[ ReactNativeHDSignerProtectionLevelNormal,
            ReactNativeHDSignerProtectionLevelICloud,
            ReactNativeHDSignerProtectionLevelPromptSecureEnclave,
            ReactNativeHDSignerProtectionLevelSinglePromptSecureEnclave];
    return (UPTHDSignerProtectionLevel)[storageLevels indexOfObject:storageLevel];
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
