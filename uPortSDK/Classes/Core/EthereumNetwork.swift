//
//  Networks.swift
//  uPortSDK
//
//  Created by mac on 3/26/18.
//

import UIKit

public enum EthereumNetworkId: String
{
    case mainnet = "0x01"
    case ropsten = "0x03"
    case kovan = "0x2a"
    case rinkeby = "0x04"
}

public struct EthereumNetwork
{
    var name: String = ""            //  ex: "kovan"
    var networkId: String = ""       //  ex: "0x2a"
    var registry: String = ""        //  ex: MNID.encode({address: '0x5f8e9351dc2d238fb878b6ae43aa740d62fc9758', network: '0x2a'})
    var rpcUrl: String = ""          //  ex: "https://kovan.infura.io/uport"
    var explorerUrl: String = ""     //  ex: "https://kovan.etherscan.io"
    var faucetUrl: String = ""       //  ex: "https://sensui.uport.me/api/v1/fund/"
    var relayUrl: String = ""        //  ex: "https://sensui.uport.me/api/v2/relay/"
    var txRelayAddress = ""
    
    public init?(network: String)
    {
        guard let networkInfo = self.networks[network] else
        {
            return nil // network not supported at this time
        }
        
        self.name = networkInfo["name"]!
        self.networkId = networkInfo["networkId"]!
        self.registry = networkInfo["registry"]!
        self.rpcUrl = networkInfo["rpcUrl"]!
        self.explorerUrl = networkInfo["explorerUrl"]!
        self.faucetUrl = networkInfo["faucetUrl"]!
        self.relayUrl = networkInfo["relayUrl"]!
    }
    
    public init?(ethNetworkId: EthereumNetworkId)
    {
        self.init(network: ethNetworkId.rawValue)
    }
    
    private lazy var networks: [String: [String: String]] =
    {
        return [
                   "0x01":
                   [
                       "name": "mainnet",
                       "networkId": "0x01",
                       "registry": MNID.encode( network: "0x01", address: "0xab5c8051b9a1df1aab0149f8b0630848b7ecabf6" )!,
                       "rpcUrl": "https://mainnet.infura.io/uport",
                       "explorerUrl": "https://etherscan.io",
                       "faucetUrl": "https://sensui.uport.me/api/v1/fund/",
                       "relayUrl": "https://sensui.uport.me/api/v2/relay/",
                       "txRelayAddress": "0xec2642cd5a47fd5cca2a8a280c3b5f88828aa578"
                   ],
                   "0x03":
                   [
                       "name": "ropsten",
                       "networkId": "0x03",
                       "registry": MNID.encode( network:"0x03", address: "0x41566e3a081f5032bdcad470adb797635ddfe1f0")!,
                       "rpcUrl": "https://ropsten.infura.io/uport",
                       "explorerUrl": "https://ropsten.io",
                       "faucetUrl": "https://sensui.uport.me/api/v1/fund/",
                       "relayUrl": "https://sensui.uport.me/api/v2/relay/",
                       "txRelayAddress": "0xa5e04cf2942868f5a66b9f7db790b8ab662039d5"
                   ],
                   "0x2a":
                   [
                       "name": "kovan",
                       "networkId": "0x2a",
                       "registry": MNID.encode( network: "0x2a", address: "0x5f8e9351dc2d238fb878b6ae43aa740d62fc9758")!,
                       "rpcUrl": "https://kovan.infura.io/uport",
                       "explorerUrl": "https://kovan.etherscan.io",
                       "faucetUrl": "https://sensui.uport.me/api/v1/fund/",
                       "relayUrl": "https://sensui.uport.me/api/v2/relay/",
                       "txRelayAddress": "0xa9235151d3afa7912e9091ab76a36cbabe219a0c"
                   ],
                   "0x04":
                   [
                       "name": "rinkeby",
                       "networkId": "0x04",
                       "registry": MNID.encode( network: "0x04", address: "0x2cc31912b2b0f3075a87b3640923d45a26cef3ee")!,
                       "rpcUrl": "https://rinkeby.infura.io/uport",
                       "explorerUrl": "https://rinkeby.etherscan.io",
                       "faucetUrl": "https://api.uport.me/sensui/fund/",
                       "relayUrl": "https://api.uport.me/sensui/fund/",
                       "txRelayAddress": "0xda8c6dce9e9a85e6f9df7b09b2354da44cb48331"
                   ]
               ]
    }()
}
