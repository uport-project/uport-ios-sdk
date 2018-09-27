//
//  Networks.swift
//  uPortSDK
//
//  Created by mac on 9/26/18.
//

import Foundation

public enum NetworksError: Error {
    case networkNotConfigured
}

public struct Networks {
    
    static let shared = Networks()
    
    let mainnet = EthereumNetwork(ethNetworkId: .mainnet )!
    let ropsten = EthereumNetwork(ethNetworkId: .ropsten )!
    let kovan = EthereumNetwork(ethNetworkId: .kovan )!
    let rinkeby = EthereumNetwork(ethNetworkId: .rinkeby )!
    
    private var customNetworks = [String: EthereumNetwork]()
    
    private init(){}
    
    mutating func registerNetwork( networkId: String, network: EthereumNetwork ) {
        let normalizedNetworkId = self.cleanId( networkId )
        self.customNetworks[ normalizedNetworkId ] = network
    }
    
    func getNetwork( networkId: String ) throws -> EthereumNetwork?  {
        let normalizedNetworkId = self.cleanId( networkId )
        guard let network = self.customNetworks[ normalizedNetworkId ] else {
            throw NetworksError.networkNotConfigured
        }
        
        return network
    }
    
    private func cleanId(_ id: String ) -> String {
        return id.withoutHexPrefix.pad( toMultipleOf: 2, character: "0", location: .left).withHexPrefix()
    }
}
