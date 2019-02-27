//
//  DIDObjectTests.swift
//  UPortTests
//
//  Created by Cornelis van der Bent on 07/12/2018.
//  Copyright © 2018 ConsenSys. All rights reserved.
//

import XCTest
@testable import UPort

class DIDObjectTests: XCTestCase
{
    func testDid()
    {
        let dido = try! DIDObject("did:method:1234567890")
        XCTAssertEqual(dido.did, "did:method:1234567890")
    }

    func testScheme()
    {
        let dido = try! DIDObject("did:method:1234567890")
        XCTAssertEqual(dido.scheme, "did")
    }

    func testWrongScheme()
    {
        XCTAssertThrowsError(try DIDObject("scheme:method:1234567890"))

        do
        {
            _ = try DIDObject("scheme:method:1234567890")
        }
        catch DIDObjectError.wrongScheme("scheme")
        {
        }
        catch
        {
            XCTAssertTrue(false, "DIDObjectError.wrongScheme(\"scheme\") should have been thrown")
        }

        do
        {
            _ = try DIDObject("scheme:method:1234567890")
        }
        catch DIDObjectError.wrongScheme("other")
        {
            XCTAssertTrue(false, "DIDObjectError.wrongScheme(\"scheme\") should have been thrown")
        }
        catch
        {
        }

        do
        {
            _ = try DIDObject("scheme:method:1234567890")
        }
        catch DIDObjectError.wrongScheme
        {
        }
        catch
        {
            XCTAssertTrue(false, "DIDObjectError.wrongScheme should have been thrown")
        }
    }

    func testMissingScheme()
    {
        XCTAssertThrowsError(try DIDObject(":method:1234567890"))
        XCTAssertThrowsError(try DIDObject("method:1234567890"))
    }

    func testMethod()
    {
        let dido = try! DIDObject("did:method:1234567890")
        XCTAssertEqual(dido.method, "method")
    }

    func testMissingMethod()
    {
        XCTAssertThrowsError(try DIDObject("did::1234567890"))
        XCTAssertThrowsError(try DIDObject("did:1234567890"))
    }

    func testId()
    {
        let dido = try! DIDObject("did:method:1234567890")
        XCTAssertEqual(dido.id, "1234567890")
    }

    func testMissingId()
    {
        XCTAssertThrowsError(try DIDObject("did:method:"))
        XCTAssertThrowsError(try DIDObject("did:method"))
    }

    func testPath()
    {
        let dido = try! DIDObject("did:method:1234567890/path/path/path")
        XCTAssertNotEqual(dido.path, "/path/path/path", "Starting / should be omitted from path")
        XCTAssertEqual(dido.path, "path/path/path")
        XCTAssertEqual(dido.method, "method")
        XCTAssertEqual(dido.id, "1234567890")
    }

    func testEmptyPath()
    {
        let dido = try! DIDObject("did:method:1234567890/")
        XCTAssertNil(dido.path)
        XCTAssertEqual(dido.method, "method")
        XCTAssertEqual(dido.id, "1234567890")
    }

    func testPathWithFragment()
    {
        let dido = try! DIDObject("did:method:1234567890/path/path/path#fragment")
        XCTAssertNotEqual(dido.path, "/path/path/path#fragment", "Starting / should be omitted from path")
        XCTAssertEqual(dido.path, "path/path/path#fragment")
        XCTAssertEqual(dido.method, "method")
        XCTAssertEqual(dido.id, "1234567890")
    }

    func testFragment()
    {
        let dido = try! DIDObject("did:method:1234567890#fragment")
        XCTAssertNotEqual(dido.fragment, "#fragment", "Starting # should be omitted from fragment")
        XCTAssertEqual(dido.fragment, "fragment")
        XCTAssertEqual(dido.method, "method")
        XCTAssertEqual(dido.id, "1234567890")
    }

    func testEmptyFragment()
    {
        let dido = try! DIDObject("did:method:1234567890#")
        XCTAssertNil(dido.fragment)
        XCTAssertEqual(dido.method, "method")
        XCTAssertEqual(dido.id, "1234567890")
    }

    func testNonDIDFragment()
    {
        let dido = try! DIDObject("did:method:1234567890/path/path/path#fragment")
        XCTAssertNil(dido.fragment, "Fragment after path should not be parsed as DID fragment")
        XCTAssertEqual(dido.method, "method")
        XCTAssertEqual(dido.id, "1234567890")
    }

    func testIsReference()
    {
        let dido1 = try! DIDObject("did:method:1234567890/path/path/path#fragment")
        XCTAssertTrue(dido1.isReference)

        let dido2 = try! DIDObject("did:method:1234567890#fragment")
        XCTAssertTrue(dido2.isReference)

        let dido3 = try! DIDObject("did:method:1234567890/path")
        XCTAssertTrue(dido3.isReference)
    }

    func testIsNotReference()
    {
        let dido1 = try! DIDObject("did:method:1234567890/")
        XCTAssertFalse(dido1.isReference)

        let dido2 = try! DIDObject("did:method:1234567890#")
        XCTAssertFalse(dido2.isReference)

        let dido3 = try! DIDObject("did:method:1234567890")
        XCTAssertFalse(dido3.isReference)
    }
}
