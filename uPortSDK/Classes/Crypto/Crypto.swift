//
//  Crypto.swift
//  uPortSDK
//

import Foundation
import Sodium

/**
 * This struct exposes methods to encrypt and decrypt messages according to the uPort spec at
 * https://github.com/uport-project/specs/blob/develop/messages/encryption.md
 */
public struct Crypto {
    private static let ASYNC_ENC_ALGORITHM = "x25519-xsalsa20-poly1305"
    public static let BLOCK_SIZE = 64
    
    /**
     * This class encapsulates an encrypted message that was produced using
     * https://github.com/uport-project/specs/blob/develop/messages/encryption.md
     */
    public struct EncryptedMessage: Codable {
        var cipherText: String
        var nonce: String
        var ephemPublicKey: String
        var version: String = ASYNC_ENC_ALGORITHM
        
        public init(cipherText: String, nonce: String, ephemPublicKey: String) {
            self.cipherText = cipherText
            self.nonce = nonce
            self.ephemPublicKey = ephemPublicKey
        }
        
        public func encode() -> Data {
            return try! Data(JSONEncoder().encode(self))
        }
        
        public static func decode(jsonData: Data) -> EncryptedMessage {
            return try! JSONDecoder().decode(EncryptedMessage.self, from: jsonData)
        }
    }
    
    /**
     Encrypts a message with a sender's public key, recipient's secret key, and encryption nonce.
     
     - Parameter message: The plaintext message to be encrypted.
     - Parameter boxPub: The public encryption key of the receiver, encoded as a base64 [String].
     
     - Returns: An `EncryptedMessage` instance containing a `version`, `nonce`, `ephemPublicKey` and `ciphertext`
     */
    public static func encrypt(message: String, boxPub: String) -> EncryptedMessage {
        let sodium = Sodium()
        
        //Decode base64 public key
        let boxPubDecoded = boxPub.decodeBase64()
        
        //create ephemeral keypair
        let ephemKeyPair = sodium.box.keyPair()!
        let ephemPublicKeyString = Data(ephemKeyPair.publicKey).base64EncodedString()
        
        //generate random nonce, should be 24 bytes
        let nonce = sodium.randomBytes.buf(length: sodium.box.NonceBytes)!
        let nonceString = Data(nonce).base64EncodedString()
        
        //pad message
        let msg = message.pad()
        let msgBytes = Bytes(msg.utf8)
        
        //seal box
        let cipherText = sodium.box.seal(message: msgBytes,
                                         recipientPublicKey: Bytes(boxPubDecoded),
                                         senderSecretKey: ephemKeyPair.secretKey,
                                         nonce: nonce)
        
        let cipherString = Data(cipherText!).base64EncodedString()
        
        //Create encrypted payload object
        let encPayload = EncryptedMessage(cipherText: cipherString,
                                          nonce: nonceString,
                                          ephemPublicKey: ephemPublicKeyString)
        
        return encPayload
    }
    
    /**
     Decrypts a message with a recipient's secret key.
     
     - Parameter encrypted: EncryptedMessage object.
     - Parameter secretKey: The recipients Secret key as a string
     
     - Returns: The decrypted message as a String.
     */
    public static func decrypt(encrypted: EncryptedMessage, secretKey: Data) -> String {
        let sodium = Sodium()
        let decodedCipherText = Bytes(encrypted.cipherText.decodeBase64())
        let decodedEphemPublicKey = Bytes(encrypted.ephemPublicKey.decodeBase64())
        let decodedNonce = Bytes(encrypted.nonce.decodeBase64())
        let secretKeyBytes = Bytes(secretKey)
        
        let decrypted = sodium.box.open(authenticatedCipherText: decodedCipherText, senderPublicKey: decodedEphemPublicKey, recipientSecretKey: secretKeyBytes, nonce: decodedNonce)!
        let decryptedString = String(bytes: decrypted, encoding: .utf8)!
        
        let unpadded = decryptedString.unpad()//unpad(message: decrypted)
        return unpadded
    }
    
}

extension String {
    func decodeBase64() -> Data {
        return Data(base64Encoded: self)!
    }
    
    func pad() -> String {
        let paddingSize = ((self.count / Crypto.BLOCK_SIZE ) + 1) * Crypto.BLOCK_SIZE
        let padding = String(repeatElement("\0", count: paddingSize - self.count))
        return self + padding
    }
    
    func unpad() -> String{
        var unpadded = self
        unpadded = self.replacingOccurrences(of: "\0", with: "")
        return unpadded
    }
}
