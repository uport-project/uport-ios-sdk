//
//  EthCall.swift
//  UPort
//
//  Created by mac on 4/5/18.
//

import UIKit

public struct EthCall
{
    var address: String = ""
    var data: String?
    
    public init(address: String, data: String)
    {
        self.address = address
        self.data = data
    }

    public static func toJsonRpcBaseRequest(registryAddress: String, encodedFunctionCall: String) -> JsonRpcBaseRequest
    {
        let ethCall = EthCall(address: registryAddress, data: encodedFunctionCall)

        return JsonRpcBaseRequest(ethCall: ethCall)
    }
}
