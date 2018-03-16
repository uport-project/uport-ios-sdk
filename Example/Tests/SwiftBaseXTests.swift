//
//  SwiftBaseXTests.swift
//  SwiftBaseXTests
//
//  Created by Pelle Steffen Braendgaard on 7/22/17.
//  Copyright © 2017 Consensys AG. All rights reserved.
//

import XCTest
//@testable import SwiftBaseX
import uPortSDK

class SwiftBaseXTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testHexEncode() {
        XCTAssertEqual(encode(alpha:HEX, data:"hello".data(using: String.Encoding.utf8)!), "68656c6c6f")
    }

    func testBase58Encode() {
        XCTAssertEqual(encode(alpha:BASE58, data:"hello".data(using: String.Encoding.utf8)!), "Cn8eVZg")
    }

    func testHexEncodeExtension() {
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.hexEncodedString(), "68656c6c6f")
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.hexEncodedString(true), "0x68656c6c6f")
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.fullHexEncodedString(), "68656c6c6f")
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.fullHexEncodedString(true), "0x68656c6c6f")
    }

    func testBase58EncodeExtension() {
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.base58EncodedString(), "Cn8eVZg")
    }
    
    func testHexDecode() {
        XCTAssertEqual(try! decode(alpha:HEX, data:"68656c6c6f"), "hello".data(using: String.Encoding.utf8)!)
    }

    func testHexDecodeInvalid() {
        XCTAssertThrowsError(try decode(alpha:HEX, data:"68656c6c6g"))
        XCTAssertThrowsError(try decode(alpha:HEX, data:"68656c6c6f "))
        XCTAssertThrowsError(try decode(alpha:HEX, data:" 68656c6c6f"))
    }
    
    func testBase58Decode() {
        XCTAssertEqual(try! decode(alpha:BASE58, data:"Cn8eVZg"), "hello".data(using: String.Encoding.utf8)!)
    }

    func testBsse58DecodeInvalid() {
        XCTAssertThrowsError(try decode(alpha:BASE58, data:"Cn8eVZg=="))
        XCTAssertThrowsError(try decode(alpha:BASE58, data:"Cn8eVZg "))
        XCTAssertThrowsError(try decode(alpha:BASE58, data:" Cn8eVZg"))
    }

    func testHexDecodeExtension() {
        XCTAssertEqual(try! "68656c6c6f".decodeHex(), "hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(try! "0x68656c6c6f".decodeHex(), "hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(try! "68656c6c6f".decodeFullHex(), "hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(try! "0x68656c6c6f".decodeFullHex(), "hello".data(using: String.Encoding.utf8)!)
    }

    func testBase58DecodeExtension() {
        XCTAssertEqual(try! "Cn8eVZg".decodeBase58(), "hello".data(using: String.Encoding.utf8)!)
    }

    func testAllHexEncode() {
        let fixtures = parseTestCases("valid")
        for pair in fixtures {
            XCTAssertEqual(pair["base64"]?.decodeBase64().hexEncodedString(), pair["hex"])
            let fullHex = pair["fullhex"] != nil ? pair["fullhex"] : pair["hex"]
            XCTAssertEqual(pair["base64"]?.decodeBase64().fullHexEncodedString(), fullHex)
        }
    }
    
    func testAllHexDecode() {
        let fixtures = parseTestCases("valid")
        for pair in fixtures {
            XCTAssertEqual(try! pair["hex"]?.decodeHex(), pair["base64"]?.decodeBase64())
            let fullHex = pair["fullhex"] != nil ? pair["fullhex"] : pair["hex"]
            XCTAssertEqual(try! fullHex?.decodeFullHex(), pair["base64"]?.decodeBase64() )
        }
    }

    func testAllBase58Decode() {
        let fixtures = parseTestCases("valid")
        for pair in fixtures {
            XCTAssertEqual(try! pair["base58"]?.decodeBase58(), pair["base64"]?.decodeBase64())
        }
    }

    func testAllBase58Encode() {
        let fixtures = parseTestCases("valid")
        for pair in fixtures {
            XCTAssertEqual(pair["base64"]?.decodeBase64().base58EncodedString(), pair["base58"])
        }
    }

    func parseTestCases(_ fileName: String) -> [[String:String]] {
        do {            
            let file = Bundle(for: type(of: self)).url(forResource: fileName, withExtension: "json")
            let data = try Data(contentsOf: file!)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String:String]] else {
                return []
            }
            return json!
        } catch {
            print(error)
            return []
        }
    }

}

extension String {
    func decodeBase64() -> Data {
        return Data(base64Encoded: self)!
    }
}

