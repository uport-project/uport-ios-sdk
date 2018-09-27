//
//  EthrDidResolver.swift
//  uPortSDK
//
//  Created by josh on 8/7/18.
//

import Foundation
import Promises
import BigInt

public enum EthrDIDResolverError: Error {
    case invalidIdentity
    case invalidRPCResponse
}

public struct EthrDIDResolver {
    public static let DEFAULT_REGISTERY_ADDRESS = "0xdca7ef03e98e0dc2b855be647c39abe984fcf21b"
    
    var registryAddress = DEFAULT_REGISTERY_ADDRESS
    var rpc : JsonRPC

    public init( rpc: JsonRPC, registryAddress: String = DEFAULT_REGISTERY_ADDRESS ) {
        self.rpc = rpc
        self.registryAddress = registryAddress
    }

    func resolve( did: String ) -> Promise<DDO> {
        return Promise<DDO> { fulfill, reject in
            let normalizedDidObject = NormalizedDID( didCandidate: did  )
            guard normalizedDidObject.error == nil else {
                reject( normalizedDidObject.error! )
                return
            }
            
            let identity = self.parseIdentity( normalizedDid: normalizedDidObject.value )
            let ethrDidContract = EthrDID(address: identity, rpc: self.rpc, registry: self.registryAddress )
            let history = self.getHistory(identity: identity)
            let promises = ethrDidContract.lookupOwner( cache: false )
            promises.then { owner in
                let ddo = self.wrapDidDocument( normalizedDid: normalizedDidObject.value, owner: owner, history: history )
                fulfill( ddo )
            }
        }
    }
    
    func getHistory( identity: String ) -> [Any] {
        var lastChangedQueue = [BigUInt]()
        var events = [Any]()
        var lastChanged = try?  self.lastChangedSynchronous(identity: identity)
        var lastChangedBigInt: BigUInt?
        let zeroBigInt = BigUInt(integerLiteral: 0)
        guard let lastChangedBigIntUnwrapped = lastChanged?.hexToBigUInt() else {
            print( "invalid bigint conversion" )
            return events
        }
        
        lastChangedBigInt = lastChangedBigIntUnwrapped
        lastChangedQueue.append( lastChangedBigInt! )
        repeat {
            lastChangedBigInt = lastChangedQueue.popLast()
            let topics = [nil, identity.hexToBytes32()]
            guard let logs = try? self.rpc.getLogsSynchronous(address: self.registryAddress, topics: topics, fromBlock: lastChangedBigInt!, toBlock: lastChangedBigInt!) else {
                print( "error fetching logs" )
                continue
            }
            
//            for log in logs {
//                let topics = log.topics
//                let data = log.data
//
//                EthereumDIDRegistry.Changed
//
//            }
        } while lastChangedBigInt != nil && lastChangedBigInt != zeroBigInt
        
        return events
    }
    
    func wrapDidDocument( normalizedDid: String, owner: String, history: [Any] ) -> DDO {
        return DDO(id: "TODO: implement")
    }
    
    func lastChanged( identity: String ) -> Promise<String> {
        return Promise<String> { fulfill, reject in
            guard let address = BigUInt( identity.withoutHexPrefix, radix: 16 ),
                    let solidityAddress = try? Solidity.Address( bigUInt: address ) else {
                reject( EthrDIDResolverError.invalidIdentity )
                return
            }
            
            let encodedCall = EthereumDIDRegistry.Changed.encodeCall( arguments: solidityAddress )
            self.rpc.ethCall(address: self.registryAddress, data: encodedCall).then({ response in
                guard let responseUnwrapped = response else {
                    reject( EthrDIDResolverError.invalidRPCResponse )
                    return
                }
                
                let parsedResponse = JsonRpcBaseResponse.fromJson(json: responseUnwrapped)
                guard parsedResponse.error == nil || parsedResponse.result != nil else {
                    reject( EthrDIDResolverError.invalidRPCResponse )
                    return
                }
                
                fulfill( "\(parsedResponse.result!)")
            }).catch({ error in
                reject( error )
            })
        }
    }
    
    func lastChangedSynchronous( identity: String ) throws -> String {
        guard let address = BigUInt( identity.withoutHexPrefix, radix: 16 ),
            let solidityAddress = try? Solidity.Address( bigUInt: address ) else {
            throw EthrDIDResolverError.invalidIdentity
        }
        
        let encodedCall = EthereumDIDRegistry.Changed.encodeCall( arguments: solidityAddress )
        let response = try? self.rpc.ethCallSynchronous(address: self.registryAddress, data: encodedCall)
        guard let responseUnwrapped = response else {
            throw EthrDIDResolverError.invalidRPCResponse
        }
        
        let parsedResponse = JsonRpcBaseResponse.fromJson(json: responseUnwrapped ?? "")
        guard parsedResponse.error == nil || parsedResponse.result != nil else {
            throw EthrDIDResolverError.invalidRPCResponse
        }
        
        return "\(parsedResponse.result!)"
    }
    
    public let identityExtractionPattern = try? NSRegularExpression( pattern: "^did:ethr:(0x[0-9a-fA-F]{40})", options: .caseInsensitive )
    
    func parseIdentity( normalizedDid: String ) -> String {
        let textCheckingResults = self.identityExtractionPattern?.matches(in: normalizedDid, options: [], range: NSRange( location: 0, length: normalizedDid.count) )
        
        guard let textCheckingResult = textCheckingResults?.first else {
            return ""
        }
        
        var matches = [String]()
        for index in 1..<textCheckingResult.numberOfRanges {
            let range = Range(textCheckingResult.range(at: index), in: normalizedDid )
            if range != nil {
                let stringSlice = normalizedDid[ range! ]
                let match = String( stringSlice  )
                matches.append( match )
            }
        }
        
        return matches.first ?? ""
    }

}
