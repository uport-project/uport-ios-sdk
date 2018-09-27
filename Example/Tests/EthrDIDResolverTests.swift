//
//  EthrDIDResolverTests.swift
//  uPortSDK_Tests
//
//  Created by mac on 8/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//


import Quick
import Nimble
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
        }
    }
}
