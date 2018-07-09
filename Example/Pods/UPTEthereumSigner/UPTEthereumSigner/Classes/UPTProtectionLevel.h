#import <Foundation/Foundation.h>

/// @description: these strings are the possible strings passed in from react native as indicated in clubhouse task 2565
FOUNDATION_EXPORT NSString *const ReactNativeKeychainProtectionLevelNormal;
FOUNDATION_EXPORT NSString *const ReactNativeKeychainProtectionLevelICloud;
FOUNDATION_EXPORT NSString *const ReactNativeKeychainProtectionLevelPromptSecureEnclave;
FOUNDATION_EXPORT NSString *const ReactNativeKeychainProtectionLevelSinglePromptSecureEnclave;
#define ReactNativeHDSignerProtectionLevelNormal ReactNativeKeychainProtectionLevelNormal
#define ReactNativeHDSignerProtectionLevelICloud ReactNativeKeychainProtectionLevelICloud
#define ReactNativeHDSignerProtectionLevelPromptSecureEnclave ReactNativeKeychainProtectionLevelPromptSecureEnclave
#define ReactNativeHDSignerProtectionLevelSinglePromptSecureEnclave ReactNativeKeychainProtectionLevelSinglePromptSecureEnclave

typedef NS_ENUM( NSInteger, UPTEthKeychainProtectionLevel ) {
  /// @description stores key via VALValet with VALAccessibilityWhenUnlockedThisDeviceOnly
  UPTEthKeychainProtectionLevelNormal = 0,
  
  /// @description stores key via VALSynchronizableValet
  UPTEthKeychainProtectionLevelICloud,
  
  /// @description stores key via VALSecureEnclaveValet
  UPTEthKeychainProtectionLevelPromptSecureEnclave,
  
  /// @description stores key via VALSinglePromptSecureEnclaveValet
  UPTEthKeychainProtectionLevelSinglePromptSecureEnclave,
  
  /// @description Indicates an invalid unrecognized storage level
  ///  Debug strategy:
  ///  1. confirm no typo on react native sender side,
  ///  2. confirm parity with android levels
  ///  3. maybe update string constants in this class
  UPTEthKeychainProtectionLevelNotRecognized = NSNotFound
};
#define UPTHDSignerProtectionLevel UPTEthKeychainProtectionLevel
#define UPTHDSignerProtectionLevelNormal UPTEthKeychainProtectionLevelNormal
#define UPTHDSignerProtectionLevelICloud UPTEthKeychainProtectionLevelICloud
#define UPTHDSignerProtectionLevelPromptSecureEnclave UPTEthKeychainProtectionLevelPromptSecureEnclave
#define UPTHDSignerProtectionLevelSinglePromptSecureEnclave UPTEthKeychainProtectionLevelSinglePromptSecureEnclave
#define UPTHDSignerProtectionLevelNotRecognized UPTEthKeychainProtectionLevelNotRecognized
