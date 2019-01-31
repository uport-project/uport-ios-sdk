//
//  SwiftKeccakTests.swift
//  SwiftKeccakTests
//
//  Created by Pelle Steffen Braendgaard on 7/19/17.
//  Copyright © 2017 Consensys AG. All rights reserved.
//

import XCTest
@testable import UPort
import UPTEthereumSigner

class SwiftKeccakTests: XCTestCase
{
    func testKeccak256OnData()
    {
        let digest : Data = UPTEthSigner.keccak256("hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(digest.base64EncodedString(), "HIr/lQaFwu1LwxdPNHIoe1bZUXuclIEnMZoJp6Nt6sg=")
    }
    
    func testKeccak256OnString()
    {
        let digest : Data = UPTEthSigner.keccak256("hello")
        XCTAssertEqual(digest.base64EncodedString(), "HIr/lQaFwu1LwxdPNHIoe1bZUXuclIEnMZoJp6Nt6sg=")
    }

    func testKeccakDataExtension()
    {
        let digest : Data = "hello".data(using: String.Encoding.utf8)!.keccak()
        XCTAssertEqual(digest.base64EncodedString(), "HIr/lQaFwu1LwxdPNHIoe1bZUXuclIEnMZoJp6Nt6sg=")
    }
    
    func testKeccakStringExtension()
    {
        let digest : Data = "hello".keccak()
        XCTAssertEqual(digest.base64EncodedString(), "HIr/lQaFwu1LwxdPNHIoe1bZUXuclIEnMZoJp6Nt6sg=")
    }

    func testSha3FinalOnData()
    {
        let digest : Data = sha3Final256("hello".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(digest.base64EncodedString(), "Mzi+aU9QxfM4gUmGzfBoZFOoiLhPQk15KvS5ICOY85I=")
    }
    
    func testSha3FinalOnString()
    {
        let digest : Data = sha3Final256("hello")
        XCTAssertEqual(digest.base64EncodedString(), "Mzi+aU9QxfM4gUmGzfBoZFOoiLhPQk15KvS5ICOY85I=")
    }
    
    func testSha3FinalDataExtension()
    {
        let digest : Data = "hello".data(using: String.Encoding.utf8)!.sha3Final()
        XCTAssertEqual(digest.base64EncodedString(), "Mzi+aU9QxfM4gUmGzfBoZFOoiLhPQk15KvS5ICOY85I=")
    }
    
    func testSha3FinalStringExtension()
    {
        let digest : Data = "hello".sha3Final()
        XCTAssertEqual(digest.base64EncodedString(), "Mzi+aU9QxfM4gUmGzfBoZFOoiLhPQk15KvS5ICOY85I=")
    }
}
