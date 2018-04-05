//
//  EthCall.swift
//  uPortSDK
//
//  Created by mac on 4/5/18.
//

import UIKit

public class EthCall: NSObject {
    var address: String = ""
    var data: String = ""

    override init() {
        super.init()
    }
    
    public convenience init( address: String, data: String ) {
        self.init()
        self.address = address
        self.data = data
    }

    public class func toJsonRpcBaseRequest( registryAddress: String, encodedFunctionCall: String ) -> JsonRpcBaseRequest {
        let ethCall = EthCall( address: registryAddress, data: encodedFunctionCall )
        return JsonRpcBaseRequest( ethCall: ethCall )
    }
}

