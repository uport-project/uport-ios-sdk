//
//  Crypto.swift
//  UPort
//

import Foundation
import Sodium
import Clibsodium

public enum CryptoError: Error
{
    case secretKeyNot32Bytes
}

/// [uPort spec]: https://github.com/uport-project/specs/blob/develop/messages/encryption.md ""
/// Struct exposing methods to encrypt and decrypt messages according to the [uPort spec].
public struct Crypto
{
    public struct Constants
    {
        static let asyncEncryptionAlgorithm = "x25519-xsalsa20-poly1305"
        static let blockSize = 64.0
    }

    /// [uPort spec]: https://github.com/uport-project/specs/blob/develop/messages/encryption.md ""
    /// Struct encapsulating an encrypted message that was produced using [uPort spec].
    public struct EncryptedMessage: Codable
    {
        var version: String = Constants.asyncEncryptionAlgorithm
        var nonce: String
        var ephemPublicKey: String
        var ciphertext: String
        
        public init(nonce: String, ephemPublicKey: String, ciphertext: String)
        {
            self.nonce = nonce
            self.ephemPublicKey = ephemPublicKey
            self.ciphertext = ciphertext
        }
        
        public func toJson() throws -> Data
        {
            return try Data(JSONEncoder().encode(self))
        }
        
        public static func fromJson(jsonData: Data) throws -> EncryptedMessage
        {
            return try JSONDecoder().decode(EncryptedMessage.self, from: jsonData)
        }
    }

    /// Calculates the encryption public key corresponding to the secret key.
    ///
    /// - Parameter secretKey: The Base64 encoded secret key.
    ///
    /// - Returns: Base64 encoded public key.
    public static func getEncryptionPublicKey(secretKey: String) throws -> String?
    {
        let secretKeyDecoded = try! secretKey.decodeBase64()
        let skBytes = Bytes(secretKeyDecoded)
        guard skBytes.count == 32 else
        {
            throw CryptoError.secretKeyNot32Bytes
        }
        
        var pk = [UInt8](repeating: 0, count: 32)
        
        guard 0 == crypto_scalarmult_base(&pk, skBytes) else
        {
            print("Calculation failed")

            return nil
        }
        
        return Data(pk).base64EncodedString()
    }

    /// Encrypts a message with a sender's secret key, recipient's public key, and encryption nonce.
    ///
    /// - Parameter message: The plaintext message to be encrypted.
    /// - Parameter boxPub: The public encryption key of the receiver, encoded as a base64 [String].
    ///
    /// - Returns: An `EncryptedMessage` instance containing a `version`, `nonce`, `ephemPublicKey` and `ciphertext`
    public static func encrypt(message: String, boxPub: String) -> EncryptedMessage
    {
        let sodium = Sodium()
        
        // Decode base64 public key
        let boxPubDecoded = try! boxPub.decodeBase64()
        
        // Create ephemeral keypair
        let ephemKeyPair = sodium.box.keyPair()!
        let ephemPublicKeyString = Data(ephemKeyPair.publicKey).base64EncodedString()
        
        // Generate random nonce, should be 24 bytes
        let nonce = sodium.randomBytes.buf(length: sodium.box.NonceBytes)!
        let nonceString = Data(nonce).base64EncodedString()
        
        // Pad message
        let msg = message.padToBlock()
        
        // Seal box
        let cipherText = sodium.box.seal(message: msg,
                                         recipientPublicKey: Bytes(boxPubDecoded),
                                         senderSecretKey: ephemKeyPair.secretKey,
                                         nonce: nonce)
        
        let cipherString = Data(cipherText!).base64EncodedString()
        
        // Create encrypted payload object
        let encPayload = EncryptedMessage(nonce: nonceString,
                                          ephemPublicKey: ephemPublicKeyString,
                                          ciphertext: cipherString)
        
        return encPayload
    }

    /// Decrypts a message with a recipient's secret key.
    ///
    /// - Parameter encrypted: EncryptedMessage object.
    /// - Parameter secretKey: The recipients Secret key as a string.
    ///
    /// - Returns: The decrypted message as a String.
    public static func decrypt(encrypted: EncryptedMessage, secretKey: Array<UInt8>) -> String
    {
        let sodium = Sodium()
        let decodedCipherText = try! Bytes(encrypted.ciphertext.decodeBase64())
        let decodedEphemPublicKey = try! Bytes(encrypted.ephemPublicKey.decodeBase64())
        let decodedNonce = try! Bytes(encrypted.nonce.decodeBase64())
        
        let decrypted = sodium.box.open(authenticatedCipherText: decodedCipherText,
                                        senderPublicKey: decodedEphemPublicKey,
                                        recipientSecretKey: secretKey,
                                        nonce: decodedNonce)!
        let unpadded = decrypted.unpadFromBlock()

        return unpadded
    }
}

extension String
{
    func padToBlock() -> Array<UInt8>
    {
        let bytes: [UInt8] = Array(self.utf8)
        let paddingSize = Int(ceil(Double(bytes.count) / Crypto.Constants.blockSize) * Crypto.Constants.blockSize) -
                          bytes.count
        let padding: Array<UInt8> = Array(repeating: 0, count: paddingSize)

        return bytes + padding
    }
}

extension Array where Element == UInt8
{
    func unpadFromBlock() -> String
    {
        if let firstZero = self.firstIndex(of: 0)
        {
            let unpadded = self[0..<firstZero]

            return String(bytes: unpadded, encoding: .utf8)!
        }
        else
        {
            return String(bytes: self, encoding: .utf8)!
        }
    }
}
