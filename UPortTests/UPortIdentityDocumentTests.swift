//
//  UPortIdentityDocumentTests.swift
//  UPortTests
//
//  Created by Cornelis van der Bent on 17/12/2018.
//  Copyright © 2018 ConsenSys. All rights reserved.
//

import XCTest
@testable import UPort

class UPortIdentityDocumentTests: XCTestCase
{
    func testInit()
    {
        let document = UPortIdentityDocument(context: "context",
                                             type: "type",
                                             publicKey: "publicKey",
                                             publicEncKey: "publicEncKey",
                                             description: "description",
                                             image: nil,
                                             name: "name")

        XCTAssertEqual(document.context, "context")
        XCTAssertEqual(document.type, "type")
        XCTAssertEqual(document.publicKey, "publicKey")
        XCTAssertEqual(document.publicEncKey, "publicEncKey")
        XCTAssertEqual(document.description, "description")
        XCTAssertNil(document.image)
        XCTAssertEqual(document.name, "name")
    }

    func testJson()
    {
        let jsonString = """
                         {
                             "@context" : "http://schema.org",
                             "@type" : "Organization",
                             "publicKey" : "some-key",
                             "publicEncKey" : "some-enc-key",
                             "name" : "uPort @ Devcon 3",
                             "description" : "Uport Attestations",
                             "image" :
                             {
                                 "@type" : "ImageObject",
                                 "name" : "avatar",
                                 "contentUrl" : "/ipfs/QmSCnmXC91Arz2gj934Ce4DeR7d9fULWRepjzGMX6SSazB"
                             }
                         }
                         """

        if let jsonData = jsonString.data(using: .utf8)
        {
            let decoder = JSONDecoder()
            var document: UPortIdentityDocument? = nil
            XCTAssertNoThrow(document = try decoder.decode(UPortIdentityDocument.self, from: jsonData))
            if let doc = document
            {
                XCTAssertEqual(doc.context, "http://schema.org")
                XCTAssertEqual(doc.type, "Organization")
                XCTAssertEqual(doc.publicKey, "some-key")
                XCTAssertEqual(doc.publicEncKey, "some-enc-key")
                XCTAssertEqual(doc.description, "Uport Attestations")
                XCTAssertEqual(doc.image?.type, "ImageObject")
                XCTAssertEqual(doc.image?.name, "avatar")
                XCTAssertEqual(doc.image?.contentUrl, "/ipfs/QmSCnmXC91Arz2gj934Ce4DeR7d9fULWRepjzGMX6SSazB")
                XCTAssertEqual(doc.name, "uPort @ Devcon 3")
            }
            else
            {
                XCTFail()
            }
        }
        else
        {
            XCTFail()
        }
    }
}
