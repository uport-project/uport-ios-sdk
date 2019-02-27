//
//  UPortDIDResolverTests.swift
//  UPortTests
//
//  Created by Cornelis van der Bent on 08/01/2019.
//  Copyright © 2019 ConsenSys. All rights reserved.
//

import XCTest
@testable import UPort

class UPortDIDResolverTests: XCTestCase
{
    func testEncapsulateJsonRpc()
    {
        let expectedPayload = ("{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"0xaddress\"," +
                               "\"data\":\"some0xdatastring\"},\"latest\"],\"id\":1}").data(using: .utf8)
        guard let expected = try? JSONSerialization.jsonObject(with: expectedPayload!) as? [String: Any] else
        {
            XCTFail("Invalid JSON.")

            return
        }

        let ethCall = EthCall(address: "0xaddress", data: "some0xdatastring")
        guard let payloadJSON = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC() else
        {
            XCTFail("Missing payload.")

            return
        }

        guard let payload = try? JSONSerialization.jsonObject(with: payloadJSON.data(using: .utf8)!) as? [String: Any] else
        {
            XCTFail("Invalid server JSON.")

            return
        }

        let isJsonRPCSame = payload!["jsonrpc"] as! String == expected!["jsonrpc"] as! String
        XCTAssertTrue(isJsonRPCSame)
        let isMethodSame = payload!["method"] as! String == expected!["method"] as! String
        XCTAssertTrue(isMethodSame)
        let isIDSame = payload!["id"] as! Int == expected!["id"] as! Int
        XCTAssertTrue(isIDSame)

        let testParams =
        { (_ candidate: Any?, _ expected: Any?) in
            XCTAssertNotNil(candidate)
            XCTAssertNotNil(expected)

            if candidate is String
            {
                XCTAssertEqual(candidate as! String, expected as! String)
            }
            else if candidate is [String : String]
            {
                let candidateToValue = (candidate as! [String: String])["to"]
                let expectedToValue = (expected as! [String: String])["to"]
                XCTAssertEqual(candidateToValue, expectedToValue)
                let candidateDataValue = (candidate as! [String: String])["data"]
                let expectedDataValue = (expected as! [String: String])["data"]
                XCTAssertEqual(candidateDataValue, expectedDataValue)
            }
        }

        let candidateParams = payload!["params"] as! [Any]
        let candidateFirst = candidateParams.first
        let candidateLast = candidateParams.last
        let expectedParams = expected!["params"] as! [Any]
        let expectedFirst = type(of: expectedParams.first) == type(of: candidateFirst) ? expectedParams.first
                                                                                       : expectedParams.last
        let expectedLast = type(of: expectedParams.last) == type(of: candidateLast) ? expectedParams.last
                                                                                    : expectedParams.first
        testParams(candidateFirst, expectedFirst)
        testParams(candidateLast, expectedLast)
    }

    func testEncodeEthCall()
    {
        let expectedEncoding = "0x447885f075506f727450726f66696c654950465331323230000000000000000000000000" +
                               "000000000000000000000000f12c30cd32b4a027710c150ae742f50db07492130000000000" +
                               "00000000000000f12c30cd32b4a027710c150ae742f50db0749213"
        let acc = Account(network: "0x04", address: "0xf12c30cd32b4a027710c150ae742f50db0749213")!
        let encoding = try? UPortDIDResolver.encodeRegistryFunctionCall(registrationIdentifier: "uPortProfileIPFS1220",
                                                                        issuer: acc,
                                                                        subject: acc)

        XCTAssertEqual(encoding, expectedEncoding)
    }

    func testCanCallRegistryWithAppropriateServerResponse()
    {
        let expectedDocAddress = "QmWzBDtv8m21ph1aM57yVDWxdG7LdQd3rNf5xrRiiV2D2E"
        let docAddressHex = try? UPortDIDResolver.synchronousIpfsHash(mnid: "2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC")

        XCTAssertEqual(docAddressHex, expectedDocAddress)
    }

    func testCanGetJsonDid()
    {
        let expectedDDO = UPortIdentityDocument(context: "http://schema.org",
                                                type: "Person",
                                                publicKey: "0x04e8989d1826cd6258906cfaa71126e2" +
                                                             "db675eaef47ddeb9310ee10db69b339a" +
                                                             "b960649e1934dc1e1eac1a193a94bd7d" +
                                                             "c5542befc5f7339845265ea839b9cbe56f",
                                                publicEncKey: "k8q5G4YoIMP7zvqMC9q84i7xUBins6dXGt8g5H007F0=",
                                                description: nil,
                                                image: nil,
                                                name: nil)

        let ddo = try? UPortDIDResolver.synchronousProfileDocument(mnid: "2ozs2ntCXceKkAQKX4c9xp2zPS8pvkJhVqC")

        XCTAssertEqual(ddo, expectedDDO)
    }
}
