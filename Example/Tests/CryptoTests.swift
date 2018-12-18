//
//  CryptoTests.swift
//  uPortSDK_Tests
//
//  Created by Aldi Gjoka on 12/5/18.
//  Copyright © 2018 ConsenSys. All rights reserved.
//
import Sodium
import XCTest
@testable import uPortSDK

class CryptoTests: XCTestCase
{
    override func setUp()
    {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPadding()
    {
        let original = "hello"
        let padded = original.padToBlock()
        print(padded)
        print(padded.count)
        let unpadded = padded.unpad()
        print(unpadded)
        print(unpadded == original)
        XCTAssertEqual(unpadded, original)
    }
    
    func testEncryptAndDecrypt()
    {
        let originalMessage = "Hello EIP1098"
        let boxSecret = Array<UInt8>(base64: "Qgigj54O7CsQOhR5vLTfqSQyD3zmq/Gb8ukID7XvC3o=")
        let boxPub = "oGZhZ0cvwgLKslgiPEQpBkRoE+CbWEdi738efvQBsH0="
        
        let result = Crypto.encrypt(message: originalMessage, boxPub: boxPub)
        let decrypted = Crypto.decrypt(encrypted: result, secretKey: boxSecret)
        XCTAssertEqual(decrypted, originalMessage)
    }
    
    func testDecrypt()
    {
        let c = Crypto.EncryptedMessage(cipherText: "f8kBcl/NCyf3sybfbwAKk/np2Bzt9lRVkZejr6uh5FgnNlH/ic62DZzy",
                                        nonce: "1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej",
                                        ephemPublicKey: "FBH1/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=")
        
        let decryptedMessage = Crypto.decrypt(encrypted: c,
                                              secretKey: Array<UInt8>(hex: "7e5374ec2ef0d91761a6e72fdf8f6ac665519bfdf6da0a2329cf0d804514b816"))
        
        XCTAssertEqual(decryptedMessage,"My name is Satoshi Buterin")
    }
}
