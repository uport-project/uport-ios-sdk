//
//  UniversalDIDResolverTests.swift
//  uPortSDK_Tests
//
//  Created by Cornelis van der Bent on 10/12/2018.
//  Copyright © 2018 ConsenSys. All rights reserved.
//

import XCTest
@testable import uPortSDK

class UniversalDIDResolverTests: XCTestCase
{
    override func setUp()
    {
    }

    override func tearDown()
    {
    }

    func testResolveEthrDid()
    {
        var universalResolver = UniversalDIDResolver()

        let resolver = EthrDIDResolver(rpc: JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl))
        XCTAssertNotNil(resolver)
        XCTAssertNoThrow(try universalResolver.register(resolver: resolver))

        let ethrDid = "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a"
        let referenceDocument = createReferenceDocument()

        var document: DIDDocument?
        XCTAssertNoThrow(document = try universalResolver.resolve(did: ethrDid))
        XCTAssertEqual(document, referenceDocument)
    }

    private func createReferenceDocument() -> DIDDocument
    {
        let context = "https://w3id.org/did/v1"
        let id = "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a"
        let publicKeyEntry = PublicKeyEntry(id: "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a#owner",
                                            type: .Secp256k1VerificationKey2018,
                                            owner: "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a",
                                            ethereumAddress: "0xb9c5714089478a327f09197987f16f9e5d936e8a")
        let publicKey = "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a#owner"
        let authenticationEntry = AuthenticationEntry(type: .Secp256k1SignatureAuthentication2018,
                                                      publicKey: publicKey)
        let authentication = [authenticationEntry]

        return DIDDocument(id: id,
                           publicKey: [publicKeyEntry],
                           authentication: authentication,
                           service: [ServiceEntry](),
                           context: context)
    }
}
