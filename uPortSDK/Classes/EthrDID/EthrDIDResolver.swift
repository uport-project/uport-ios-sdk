//
//  EthrDidResolver.swift
//  uPortSDK
//
//  Created by josh on 8/7/18.
//

import Foundation

public struct EthrDIDResolver {

    let REGISTRY = "0xdca7ef03e98e0dc2b855be647c39abe984fcf21b"
    var rpc : JsonRPC
    
    func register( configuration: [String: Any] ) {
        let provider = configuration[ "provider" ] ?? configuration[ "rpcUrl" ] // ?? "https://mainnet.infura.io/ethr-did"
//        let eth = Eth( provider )
//        let registeryAddress = conf[ "registry" ] ?? REGISTRY
//        let didReg = new DidReg( registeryAddress )
//        let logDecoder = abai.log
        
        func resolve( did: String, parsed: [String: Any] ) {
            
            
        }
        
    }
    
}
