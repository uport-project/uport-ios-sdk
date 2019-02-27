//
//  SwiftBaseXTests.swift
//  UPortTests
//
//  Created by Pelle Steffen Braendgaard on 7/22/17.
//  Copyright © 2017 Consensys AG. All rights reserved.
//

import XCTest
@testable import UPort

class SwiftBaseXTests: XCTestCase
{
    func testHexEncode()
    {
        XCTAssertEqual(encode(alpha:HEX, data:"hello".data(using: String.Encoding.utf8)!), "68656c6c6f")
    }

    func testBase58Encode()
    {
        XCTAssertEqual(encode(alpha:BASE58, data:"hello".data(using: String.Encoding.utf8)!), "Cn8eVZg")
    }

    func testHexEncodeExtension()
    {
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.hexEncodedString(), "68656c6c6f")
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.hexEncodedString(true), "0x68656c6c6f")
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.fullHexEncodedString(), "68656c6c6f")
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.fullHexEncodedString(true), "0x68656c6c6f")
    }

    func testBase58EncodeExtension()
    {
        XCTAssertEqual("hello".data(using: String.Encoding.utf8)!.base58EncodedString(), "Cn8eVZg")
    }
    
    func testHexDecode()
    {
        XCTAssertEqual(try! decode(alpha:HEX, data:"68656c6c6f"), "hello".data(using: String.Encoding.utf8)!)
    }

    func testHexDecodeInvalid()
    {
        XCTAssertThrowsError(try decode(alpha:HEX, data:"68656c6c6g"))
        XCTAssertThrowsError(try decode(alpha:HEX, data:"68656c6c6f "))
        XCTAssertThrowsError(try decode(alpha:HEX, data:" 68656c6c6f"))
    }
    
    func testBase58Decode()
    {
        XCTAssertEqual(try! decode(alpha:BASE58, data:"Cn8eVZg"), "hello".data(using: String.Encoding.utf8)!)
    }

    func testBsse58DecodeInvalid()
    {
        XCTAssertThrowsError(try decode(alpha:BASE58, data:"Cn8eVZg=="))
        XCTAssertThrowsError(try decode(alpha:BASE58, data:"Cn8eVZg "))
        XCTAssertThrowsError(try decode(alpha:BASE58, data:" Cn8eVZg"))
    }

    func testHexDecodeExtension()
    {
        XCTAssertEqual(try! "68656c6c6f".decodeHex(), "hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(try! "0x68656c6c6f".decodeHex(), "hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(try! "68656c6c6f".decodeFullHex(), "hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(try! "0x68656c6c6f".decodeFullHex(), "hello".data(using: String.Encoding.utf8)!)
    }

    func testBase58DecodeExtension()
    {
        XCTAssertEqual(try! "Cn8eVZg".decodeBase58(), "hello".data(using: String.Encoding.utf8)!)
    }

    func testAllHexEncode()
    {
        let fixtures = parseTestCases("valid")
        for pair in fixtures
        {
            // TODO: There are two implementations of `hexEncodedString()`, one in `BaseX.swift` and one in
            //       a Bivrost helper module `DataExtension.swift`. The Bivrost version performs what's called here a
            //       'full hex' encoding, while the BaseX collapses leading `0`s (i.e. leading 0 bytes are represented
            //       as a single `0`).
            //
            //       The BaseX version has a parameter which by default is `false`, so to make sure this is called (and
            //       not the `DataExtension.swift` one), we do `hexEncodedString(false)`.
            //
            //       This duplicate use of the same function name for different logic is very confusing and can result
            //       errors (because you may thing to use one, while the other is called) and should be sorted out.
            XCTAssertEqual(try pair["base64"]?.decodeBase64().hexEncodedString(false), pair["hex"])
            let fullHex = pair["fullhex"] != nil ? pair["fullhex"] : pair["hex"]
            XCTAssertEqual(try pair["base64"]?.decodeBase64().fullHexEncodedString(), fullHex)
        }
    }
    
    func testAllHexDecode()
    {
        let fixtures = parseTestCases("valid")
        for pair in fixtures
        {
            XCTAssertEqual(try! pair["hex"]?.decodeHex(), try pair["base64"]?.decodeBase64())
            let fullHex = pair["fullhex"] != nil ? pair["fullhex"] : pair["hex"]
            XCTAssertEqual(try! fullHex?.decodeFullHex(), try pair["base64"]?.decodeBase64())
        }
    }

    func testAllBase58Decode()
    {
        let fixtures = parseTestCases("valid")
        for pair in fixtures
        {
            XCTAssertEqual(try! pair["base58"]?.decodeBase58(), try pair["base64"]?.decodeBase64())
        }
    }

    func testAllBase58Encode()
    {
        let fixtures = parseTestCases("valid")
        for pair in fixtures
        {
            XCTAssertEqual(try pair["base64"]?.decodeBase64().base58EncodedString(), pair["base58"])
        }
    }

    func parseTestCases(_ fileName: String) -> [[String:String]]
    {
        do
        {
            let file = Bundle(for: type(of: self)).url(forResource: fileName, withExtension: "json")
            let data = try Data(contentsOf: file!)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String:String]] else
            {
                return []
            }

            return json!
        }
        catch
        {
            print(error)

            return []
        }
    }

    // TODO: Add decodeBase64() tests.
}
