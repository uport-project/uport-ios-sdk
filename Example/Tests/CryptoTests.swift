//
//  CryptoTests.swift
//  uPortSDK_Tests
//
//  Created by Aldi Gjoka on 12/5/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import Sodium
@testable import uPortSDK

class CryptoTests: QuickSpec {
    override func spec() {
        describe("Tests encryption") {
            
            it("zero padding") {
                let original = "hello"
                let padded = original.pad()
                expect(padded) !== original
                let unpadded = padded.unpad()
                expect(unpadded) == original
            }
            
            it("Encrypt and decrypt") {
                let originalMessage = "Hello EIP1098"
                let boxSecret = "Qgigj54O7CsQOhR5vLTfqSQyD3zmq/Gb8ukID7XvC3o=".decodeBase64()
                let boxPub = "oGZhZ0cvwgLKslgiPEQpBkRoE+CbWEdi738efvQBsH0="
                
                let result = Crypto.encrypt(message: originalMessage, boxPub: boxPub)
                let decrypted = Crypto.decrypt(encrypted: result, secretKey: boxSecret)
                expect(decrypted) == originalMessage
            }
            
            
            it("Decrypts message") {
                let c = Crypto.EncryptedMessage(cipherText: "f8kBcl/NCyf3sybfbwAKk/np2Bzt9lRVkZejr6uh5FgnNlH/ic62DZzy",
                                         nonce: "1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej",
                                         ephemPublicKey: "FBH1/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=")
                
                let decryptedMessage = Crypto.decrypt(encrypted: c,
                                               secretKey: Data(hex: "7e5374ec2ef0d91761a6e72fdf8f6ac665519bfdf6da0a2329cf0d804514b816"))
                
                expect(decryptedMessage) == "My name is Satoshi Buterin"
            }
        }
    }
}
