//
//  EthrDIDResolverTests.swift
//  uPortSDK_Tests
//
//  Created by mac on 8/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//


import Quick
import Nimble
import BigInt
@testable import uPortSDK

class EthrDIDResolverTests: QuickSpec {
    override func spec() {
       
        describe("EthrDIDResolver") {
            
            it( "can normalize DID" ) {
                let validDids = [
                    "0xb9c5714089478a327f09197987f16f9e5d936e8a",
                    "0xB9C5714089478a327F09197987f16f9E5d936E8a",
                    "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a",
                    "did:ethr:0xB9C5714089478a327F09197987f16f9E5d936E8a"
                ]
                
                let invalidDids = [
                    "0xb9c5714089478a327f09197987f16f9e5d936e",
                    "B9C5714089478a327F09197987f16f9E5d936E8a",
                    "ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a",
                    "B9C5714089478a327F09197987f16f9E5d936E8a",
                    "B9C5714089478a327F09197987f16f9E5d936E"
                ]
                
                for validDid in validDids {
                    let normalizedDid = NormalizedDID( didCandidate: validDid )
                    expect( !normalizedDid.value.isEmpty ).to( beTrue() )
                    expect( normalizedDid.value.lowercased() ) == "did:ethr:0xb9c5714089478a327f09197987f16f9e5d936e8a"
                }
                
                for invalidDid in invalidDids {
                    let normalizedDid = NormalizedDID( didCandidate: invalidDid )
                    expect( normalizedDid.value.isEmpty ).to( beTrue() )
                }
            }
            
            it( "real address with activity has logs" ) {
                let rpc = JsonRPC( rpcURL: Networks.shared.rinkeby.rpcUrl )
                let realAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
                let resolver = EthrDIDResolver( rpc: rpc )
                guard let lastChanged = try? resolver.lastChangedSynchronous(identity: realAddress).hexToBigUInt() else {
                    print( "last change resolving issue" )
                    return
                }
                
                guard lastChanged != nil else {
                    print( "last chaged was nil" )
                    return
                }

                let topics = [nil, realAddress.hexToBytes32()]
                let logResponse = try? rpc.getLogsSynchronous(address: resolver.registryAddress, topics:topics, fromBlock: lastChanged!, toBlock: lastChanged!)
                expect( logResponse ).toNot( beNil() )
                expect( logResponse ).toNot( beEmpty() )
                
            }
            
            it( "last change is blank for new address" ) {
                let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
                let imaginaryAddress = "0x1234"
                let lastChanged = try? EthrDIDResolver(rpc: rpc).lastChangedSynchronous(identity: imaginaryAddress)
                expect(lastChanged?.hexToBigUInt()).to( equal(BigUInt(integerLiteral: 0)))
            }
            
            it( "last change is non-zero for real address with changed owner" ) {
                let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
                let imaginaryAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
                let lastChanged = try? EthrDIDResolver(rpc: rpc).lastChangedSynchronous(identity: imaginaryAddress)
                print( "lastChanged should not be 0 and is -> \(lastChanged!)")
                expect(lastChanged?.hexToBigUInt()).toNot( equal(BigUInt(integerLiteral: 0)))
            }
            
            it( "can parse owner changed logs" ) {
                let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
                let realAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
                let resolver = EthrDIDResolver( rpc: rpc )
                let lastChanged = BigUInt( integerLiteral: 2_784_036 )
                let logs = try? rpc.getLogsSynchronous(address: resolver.registryAddress, topics: [nil, realAddress.hexToBytes32()], fromBlock: lastChanged, toBlock: lastChanged)
                print( "logs for real address -> \(logs!)")
                
                let topics = logs![0].topics!
                let data = logs![0].data!.withoutHexPrefix
                
                let notHexTopics = topics.map({ (topic) -> String in
                    return topic.withoutHexPrefix
                })
                let args = try? EthereumDIDRegistry.Events.DIDOwnerChanged.decode(topics: notHexTopics, data: data)
                print( "args is -> \(args!)" )
                let previousBlock = args!.previouschange.value
                print( "prevousBlock is -> \(previousBlock)")
            }
            
            it( "can parse multiple event logs" ) {
                let rpc = JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl)
                let realAddress = "0xf3beac30c498d9e26865f34fcaa57dbb935b0d74"
                let resolver = EthrDIDResolver( rpc: rpc )
                let events = resolver.getHistory(identity: realAddress)
                print( "events -> \(events)" )
                expect( events ).toNot(beEmpty())
            }
            
            // "did/pub/(Secp256k1|Rsa|Ed25519)/(veriKey|sigAuth)/(hex|base64)",
            let attributeRegexes = [
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
            
            it( "can parse attribute regex" ) {
                let regex = try? NSRegularExpression( pattern: "^did/(pub|auth|svc)/(\\w+)(/(\\w+))?(/(\\w+))?$", options: .caseInsensitive )
                for attributeRegex in attributeRegexes {
                    let textCheckingResults = regex?.matches(in: attributeRegex, options: [], range: NSRange(location: 0, length: attributeRegex.count))
                    let textCheckingResult = textCheckingResults?.first
                    expect( textCheckingResult ).toNot( beNil() )
                    var matches = [String]()
                    for index in 1..<textCheckingResult!.numberOfRanges {
                        let range = Range(textCheckingResult!.range(at: index), in: attributeRegex )
                        if range != nil {
                            let stringSlice = attributeRegex[ range! ]
                            let match = String( stringSlice  )
                            matches.append( match )
                        }
                    }
                    print( " matches are -> \(matches)" )
                    if matches.count != 6 {
                        print( "possible invalid match -> \(matches)" )
                    }
                    
                    let section = matches[0]
                    let algorithm = matches[1]
                    expect( section ).toNot( beNil() )
                    expect( algorithm ).toNot( beNil() )
                    expect( section.isEmpty ).to( beFalse() )
                    expect( algorithm.isEmpty ).to( beFalse() )
                }
                
            }
            
            it( "can parse sample attr change event" ) {
                
                
            }
            
            it( "to and from solidity bytes" ) {
                
            }
            
            it( "can resolve real address" ) {
                
            }
            
            it( "can normalize DID" ) {
                
            }
        }
    }
}
