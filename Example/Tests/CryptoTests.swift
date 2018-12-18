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
        let unpadded = padded.unpad()
        XCTAssertEqual(unpadded, original)
    }
    
    func testZeroPaddingUnicode()
    {
        let messages: Array<String> =
        [
            "hello",
            "小路の藪",
            "柑子、パイ",
            "ポパイポ パイ",
            "ポのシューリンガ",
            "ン。五劫の擦り切れ",
            "、食う寝る処に住む処",
            "。グーリンダイのポンポ",
            "コピーのポンポコナーの、",
            "長久命の長助、寿限無、寿限",
            "無、グーリンダイのポンポコピ",
            "ーのポンポコナーの。やぶら小路",
            "🇯🇵 🇰🇷 🇩🇪 🇨🇳 🇺🇸 🇫🇷 🇪🇸 🇮🇹 🇷🇺 🇬🇧",
            "🎄 🌟 ❄️ 🎁 🎅 🦌"
        ]
        
        for message in messages
        {
            let padded = message.padToBlock()            
            XCTAssertNotEqual(Array(message.utf8), padded)
            XCTAssertTrue(padded.count % 64 == 0)
            
            let unpadded = padded.unpad()
            XCTAssertEqual(message, unpadded)
            
        }
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
        let c = Crypto.EncryptedMessage(nonce: "1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej",
                                        ephemPublicKey: "FBH1/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=",
                                        ciphertext: "f8kBcl/NCyf3sybfbwAKk/np2Bzt9lRVkZejr6uh5FgnNlH/ic62DZzy")
        
        let decryptedMessage = Crypto.decrypt(encrypted: c,
                                              secretKey: Array<UInt8>(hex: "7e5374ec2ef0d91761a6e72fdf8f6ac665519bfdf6da0a2329cf0d804514b816"))
        
        XCTAssertEqual(decryptedMessage,"My name is Satoshi Buterin")
    }
    
    func testJsonDeserialization()
    {
        let json =
        """
        {"version":"x25519-xsalsa20-poly1305","nonce":"JAX+g+/e3RnnNXHRS4ct5Sb+XdgYoJeY","ephemPublicKey":"JLBIe7eSVyq6egVexeWrlKQyOukSo66G3N0PlimMUyI","ciphertext":"Yr2o6x831YWFZr6KESzSkBqpMv1wYkxPULbVSZi21J+2vywrVeZnDe/U2GW40wzUpLv4HhFgL1kvt+cORrapsqCfSy2L1ltMtkilX06rJ+Q"}
        """
        
        let enc = Crypto.EncryptedMessage.fromJson(jsonData: json.data(using: .utf8)!)
        XCTAssertEqual("x25519-xsalsa20-poly1305", enc.version)
        XCTAssertEqual("JAX+g+/e3RnnNXHRS4ct5Sb+XdgYoJeY", enc.nonce)
        XCTAssertEqual("JLBIe7eSVyq6egVexeWrlKQyOukSo66G3N0PlimMUyI", enc.ephemPublicKey)
        XCTAssertEqual("Yr2o6x831YWFZr6KESzSkBqpMv1wYkxPULbVSZi21J+2vywrVeZnDe/U2GW40wzUpLv4HhFgL1kvt+cORrapsqCfSy2L1ltMtkilX06rJ+Q", enc.ciphertext)
        
    }
    
    func testJsonSerialization()
    {
        //language=JSON
        let expected = """
        {"ciphertext":"f8kBcl\\/NCyf3sybfbwAKk\\/np2Bzt9lRVkZejr6uh5FgnNlH\\/ic62DZzy","nonce":"1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej","ephemPublicKey":"FBH1\\/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=","version":"x25519-xsalsa20-poly1305"}
        """
        let expectedDictionary = try! JSONSerialization.jsonObject(with: expected.data(using: .utf8)!, options: []) as! [String: Any]
        
        
        let input = Crypto.EncryptedMessage(nonce: "1dvWO7uOnBnO7iNDJ9kO9pTasLuKNlej",
                                            ephemPublicKey: "FBH1/pAEHOOW14Lu3FWkgV3qOEcuL78Zy+qW1RwzMXQ=",
                                            ciphertext: "f8kBcl/NCyf3sybfbwAKk/np2Bzt9lRVkZejr6uh5FgnNlH/ic62DZzy")
        let inputJson = input.toJson()
        
        if let inputDictionary = try! JSONSerialization.jsonObject(with: inputJson, options: []) as? [String: Any]
        {
            if let nonce = inputDictionary["nonce"] as? String
            {
                XCTAssertEqual(expectedDictionary["nonce"] as! String, nonce)
            }
            
            if let ciphertext = inputDictionary["ciphertext"] as? String
            {
                XCTAssertEqual(expectedDictionary["ciphertext"] as! String, ciphertext)
            }
            
            if let version = inputDictionary["version"] as? String
            {
                XCTAssertEqual(expectedDictionary["version"] as! String, version)
            }
            
            if let ephemPublicKey = inputDictionary["ephemPublicKey"] as? String
            {
                XCTAssertEqual(expectedDictionary["ephemPublicKey"] as! String, ephemPublicKey)
            }
        }
        
    }
}
