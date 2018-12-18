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

        let ethrResolver = EthrDIDResolver(rpc: JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl))
        let uPortResolver = UPortDIDResolver()
        XCTAssertNotNil(ethrResolver)
        XCTAssertNotNil(uPortResolver)
        XCTAssertNoThrow(try universalResolver.register(resolver: ethrResolver))
        XCTAssertNoThrow(try universalResolver.register(resolver: uPortResolver))

        let ethrDid = "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a"
        let referenceDocument = createEthrReferenceDocument()

        var document: DIDDocument?
        XCTAssertNoThrow(document = try universalResolver.resolve(did: ethrDid))
        XCTAssertEqual(document, referenceDocument)
    }

    func testResolveEthrId()
    {
        var universalResolver = UniversalDIDResolver()

        let ethrResolver = EthrDIDResolver(rpc: JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl))
        let uPortResolver = UPortDIDResolver()
        XCTAssertNotNil(ethrResolver)
        XCTAssertNotNil(uPortResolver)
        XCTAssertNoThrow(try universalResolver.register(resolver: ethrResolver))
        XCTAssertNoThrow(try universalResolver.register(resolver: uPortResolver))

        let id = "0xb9c5714089478a327f09197987f16f9e5d936e8a"
        let referenceDocument = createEthrReferenceDocument()

        var document: DIDDocument?
        XCTAssertNoThrow(document = try universalResolver.resolve(did: id))
        XCTAssertEqual(document, referenceDocument)
    }

    func testResolveUPortDid()
    {
        var universalResolver = UniversalDIDResolver()

        let ethrResolver = EthrDIDResolver(rpc: JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl))
        let uPortResolver = UPortDIDResolver()
        XCTAssertNotNil(uPortResolver)
        XCTAssertNotNil(ethrResolver)
        XCTAssertNoThrow(try universalResolver.register(resolver: ethrResolver))
        XCTAssertNoThrow(try universalResolver.register(resolver: uPortResolver))

        let uportDid = "did:uport:2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC"
        let referenceDocument = createUPortReferenceDocument()

        var document: UPortDIDDocument?
        XCTAssertNoThrow(document = try universalResolver.resolve(did: uportDid) as? UPortDIDDocument)
        XCTAssertEqual(document?.uportProfile, referenceDocument)
    }

    func testResolveUPortMnid()
    {
        var universalResolver = UniversalDIDResolver()

        let ethrResolver = EthrDIDResolver(rpc: JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl))
        let uPortResolver = UPortDIDResolver()
        XCTAssertNotNil(uPortResolver)
        XCTAssertNotNil(ethrResolver)
        XCTAssertNoThrow(try universalResolver.register(resolver: ethrResolver))
        XCTAssertNoThrow(try universalResolver.register(resolver: uPortResolver))

        let mnid = "2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC"
        let referenceDocument = createUPortReferenceDocument()

        var document: UPortDIDDocument?
        XCTAssertNoThrow(document = try universalResolver.resolve(did: mnid) as? UPortDIDDocument)
        XCTAssertEqual(document?.uportProfile, referenceDocument)
    }

    // MARK: - Helpers

    private func createEthrReferenceDocument() -> DIDDocument
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

        return DIDDocument(context: context,
                           id: id,
                           publicKey: [publicKeyEntry],
                           authentication: authentication,
                           service: [ServiceEntry]())
    }

    private func createUPortReferenceDocument() -> UPortIdentityDocument
    {
        return UPortIdentityDocument(context: "http://schema.org",
                                     type: "Person",
                                     publicKey: "0x04e8989d1826cd6258906cfaa71126e2" +
                                                "db675eaef47ddeb9310ee10db69b339a" +
                                                "b960649e1934dc1e1eac1a193a94bd7d" +
                                                "c5542befc5f7339845265ea839b9cbe56f",
                                     publicEncKey: "k8q5G4YoIMP7zvqMC9q84i7xUBins6dXGt8g5H007F0=",
                                     description: nil,
                                     image: nil,
                                     name: nil)
    }
}
