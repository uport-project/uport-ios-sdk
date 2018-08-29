//
//  EthrDidResolver.swift
//  uPortSDK
//
//  Created by josh on 8/7/18.
//

import Foundation

public struct EthrDIDResolver {

    var registryAddress = "0xdca7ef03e98e0dc2b855be647c39abe984fcf21b"
    var rpc : JsonRPC

    public init( rpc: JsonRPC, registryAddress: String = "0xdca7ef03e98e0dc2b855be647c39abe984fcf21b" ) {
        self.rpc = rpc
        self.registryAddress = registryAddress
    }

    func resolve( did: String ) -> DDO {
        let normalizedDid = NormalizedDID( didCandidate: did  )
        let identity = self.parseIdentity( normalizedDid: normalizedDid.value )
        let ethrdidContract = EthrDID(address: identity, rpc: self.rpc, registry: self.registryAddress )
//        let owner = ethrdidContract.lookupOWner( cache: false )
        return DDO( id: "TODO: implement" )
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
