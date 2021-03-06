//
//  EthrDIDResolverTests.swift
//  UPortTests
//
//  Created by Cornelis van der Bent on 09/01/2019.
//  Copyright © 2019 ConsenSys. All rights reserved.
//

import XCTest
import BigInt
@testable import UPort

class EthrDIDResolverTests: XCTestCase
{
    func testRealAddressWithActivityHasLogs()
    {
        let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
        let realAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
        let resolver = EthrDIDResolver(rpc: rpc)
        guard let lastChanged = try? resolver.lastChangedSynchronous(identity: realAddress).hexToBigUInt() else
        {
            XCTFail("Last change resolving issue.")

            return
        }

        guard lastChanged != nil else
        {
            XCTFail("Last changed was nil.")

            return
        }

        let topics = [nil, realAddress.hexToBytes32()]
        let logResponse = try? rpc.getLogsSynchronous(address: resolver.registryAddress,
                                                      topics:topics,
                                                      fromBlock: lastChanged!,
                                                      toBlock: lastChanged!)
        XCTAssertNotNil(logResponse)
        XCTAssertFalse(logResponse?.isEmpty ?? true)
    }

    func testLastChangeIsBlankForNewAddress()
    {
        let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
        let imaginaryAddress = "0x1234"
        let lastChanged = try? EthrDIDResolver(rpc: rpc).lastChangedSynchronous(identity: imaginaryAddress)

        XCTAssertEqual(lastChanged?.hexToBigUInt(), BigUInt(integerLiteral: 0))
    }

    func testLastChangeIsNonZeroForRealAddressWithChangedOwner()
    {
        let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
        let imaginaryAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
        let lastChanged = try? EthrDIDResolver(rpc: rpc).lastChangedSynchronous(identity: imaginaryAddress)
        print("lastChanged should not be 0 and is -> \(lastChanged!)")

        XCTAssertNotEqual(lastChanged?.hexToBigUInt(), BigUInt(integerLiteral: 0))
    }

    func testCanParseOwnerChangedLogs()
    {
        let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
        let realAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
        let resolver = EthrDIDResolver(rpc: rpc)
        let lastChanged = BigUInt(integerLiteral: 2_784_036)
        let logs = try? rpc.getLogsSynchronous(address: resolver.registryAddress,
                                               topics: [nil, realAddress.hexToBytes32()],
                                               fromBlock: lastChanged,
                                               toBlock: lastChanged)
        print("logs for real address -> \(logs!)")

        let topics = logs![0].topics!
        let data = logs![0].data!.withoutHexPrefix

        let notHexTopics = topics.map(
        { (topic) -> String in
            return topic.withoutHexPrefix
        })

        let args = try? EthereumDIDRegistry.Events.DIDOwnerChanged.decode(topics: notHexTopics, data: data)
        XCTAssertNotNil(args)
        print("args is -> \(args!)")
        let previousBlock = args!.previouschange.value
        XCTAssertNotEqual(previousBlock, BigUInt(integerLiteral: 0))
        print("prevousBlock is -> \(previousBlock)")
    }

    func testCanParseMultipleEventLogs()
    {
        let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
        let realAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
        let resolver = EthrDIDResolver(rpc: rpc)
        let events = resolver.getHistory(identity: realAddress)
        print("events -> \(events)")

        XCTAssertFalse(events.isEmpty)
    }

    func testCanParseAttributeRegex()
    {
        // "did/pub/(Secp256k1|Rsa|Ed25519)/(veriKey|sigAuth)/(hex|base64)",
        let attributeRegexes =
        [
            "did/pub/Secp256k1/veriKey/hex",
            "did/pub/Rsa/veriKey/hex",
            "did/pub/Ed25519/veriKey/hex",
            "did/pub/Secp256k1/sigAuth/hex",
            "did/pub/Rsa/sigAuth/hex",
            "did/pub/Ed25519/sigAuth/hex",
            "did/pub/Secp256k1/veriKey/base64",
            "did/pub/Rsa/veriKey/base64",
            "did/pub/Ed25519/veriKey/base64",
            "did/pub/Secp256k1/sigAuth/base64",
            "did/pub/Rsa/sigAuth/base64",
            "did/pub/Ed25519/sigAuth/base64",
            "did/pub/Secp256k1/veriKey",
            "did/pub/Rsa/veriKey",
            "did/pub/Ed25519/veriKey",
            "did/pub/Secp256k1/sigAuth",
            "did/pub/Rsa/sigAuth",
            "did/pub/Ed25519/sigAuth",
            "did/pub/Secp256k1",
            "did/pub/Rsa",
            "did/pub/Ed25519"
        ]

        let regex = try? NSRegularExpression(pattern: "^did/(pub|auth|svc)/(\\w+)(/(\\w+))?(/(\\w+))?$",
                                             options: .caseInsensitive)
        for attributeRegex in attributeRegexes
        {
            let textCheckingResults = regex?.matches(in: attributeRegex,
                                                     options: [],
                                                     range: NSRange(location: 0, length: attributeRegex.count))
            let textCheckingResult = textCheckingResults?.first
            XCTAssertNotNil(textCheckingResult)

            var section: String?
            if let sectionRange = Range(textCheckingResult!.range(at: 1), in: attributeRegex)
            {
                let sectionSlice = attributeRegex[sectionRange]
                section = String(sectionSlice)
            }

            var algorithm: String?
            if let algorithmRange = Range(textCheckingResult!.range(at: 2), in: attributeRegex)
            {
                let algorithmSlice = attributeRegex[algorithmRange]
                algorithm = String(algorithmSlice)
            }

            var rawType: String?
            if let rawTypeRange = Range(textCheckingResult!.range(at: 4), in: attributeRegex)
            {
                let rawTypeSlice = attributeRegex[rawTypeRange]
                rawType = String(rawTypeSlice)
            }

            var encoding: String?
            if let encodingRange = Range(textCheckingResult!.range(at: 6), in: attributeRegex)
            {
                let encodingSlice = attributeRegex[encodingRange]
                encoding = String(encodingSlice)
            }

            print("section -> \(section ?? "nil"), algorithm -> \(algorithm ?? "nil"), " +
                  "rawType -> \(rawType ?? "nil"), encoding -> \(encoding ?? "nil")")

            XCTAssertNotNil(section)
            XCTAssertNotNil(algorithm)
            XCTAssertFalse(section!.isEmpty)
            XCTAssertFalse(algorithm!.isEmpty)
        }
    }

    func testCanParseSampleAttrChangeEvent()
    {
        let soon = UInt64(Date().timeIntervalSince1970 + 600)
        let identity = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
        let owner = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"

        let identityBigUInt = identity.hexToBigUInt()
        let identityAddressSolidity = try! Solidity.Address(bigUInt: identityBigUInt!)
        let name = try! Solidity.Bytes32("did/pub/Secp256k1/veriKey/base64".data(using: .utf8 )!)
        let valueBytes = Solidity.Bytes(Data(hex: "0x02b97c30de767f084ce3080168ee293053ba33b235d7116a3263d29f1450936b71"))
        let soonBigUInt = BigUInt(integerLiteral: soon)
        let soonUInt256 = try! Solidity.UInt256(soonBigUInt)
        let previousChangeUInt256 = try! Solidity.UInt256(BigUInt(integerLiteral: 0))
        let event = EthereumDIDRegistry.Events.DIDAttributeChanged.Arguments(identity: identityAddressSolidity,
                                                                             name: name,
                                                                             value: valueBytes!,
                                                                             validto: soonUInt256,
                                                                             previouschange: previousChangeUInt256)

        let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)

        let ddo = try! EthrDIDResolver(rpc: rpc).wrapDidDocument(normalizedDid: "did:ethr:\(identity)",
                                                                 owner: owner,
                                                                 history: [event])
        print("DID doc is -> \(ddo)")

        XCTAssertTrue(true)
    }

    func testToAndFromSolidityBytes()
    {
        let str = "did/pub/Secp256k1/veriKey/hex"
        let sol = try! Solidity.Bytes32( str.data(using: .utf8)!)
        let decodedStr = String(data: sol.value, encoding: .utf8)

        XCTAssertEqual(decodedStr, str)
    }

    func testCanResolveRealAddress()
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

        let referenceDDO = DIDDocument(context: context,
                                       id: id,
                                       publicKey: [publicKeyEntry],
                                       authentication: authentication,
                                       service: [ServiceEntry]())
        let realAddress = "0xb9c5714089478a327f09197987f16f9e5d936e8a"
        let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
        let resolver = EthrDIDResolver(rpc: rpc)
        let ddo = try! resolver.resolveSync(did: realAddress)

        XCTAssertEqual(ddo, referenceDDO)
        print("found ddo-> \(ddo)")
    }

    func testCanNormalizeDID()
    {
        let validDids =
        [
            "0xb9c5714089478a327f09197987f16f9e5d936e8a",
            "0xB9C5714089478a327F09197987f16f9E5d936E8a",
            "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a",
            "did:ethr:0xB9C5714089478a327F09197987f16f9E5d936E8a"
        ]

        let invalidDids =
        [
            "0xb9c5714089478a327f09197987f16f9e5d936e",
            "B9C5714089478a327F09197987f16f9E5d936E8a",
            "ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a",
            "B9C5714089478a327F09197987f16f9E5d936E8a",
            "B9C5714089478a327F09197987f16f9E5d936E"
        ]

        for validDid in validDids
        {
            let normalizedDid = NormalizedEthrDID(didCandidate: validDid)

            XCTAssertNil(normalizedDid.error)
            XCTAssertEqual(normalizedDid.value.lowercased(), "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a")
        }

        for invalidDid in invalidDids
        {
            let normalizedDid = NormalizedEthrDID(didCandidate: invalidDid)

            XCTAssertNotNil(normalizedDid.error)
        }
    }
}
