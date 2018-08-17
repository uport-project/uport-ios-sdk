//
//  JsonRPC.swift
//  uPortSDK
//
//  Created by josh on 8/13/18.
//

import Foundation

public enum JsonRpcError: Error {
    case invalidRpcUrl
    case jsonConversionIssue
    case invalidResult
}

public struct JsonRPC {
    private var rpcURL: String?
    
    func ethCall( address: String, data: String, callback: @escaping (_ result: String?, _ error: Error? ) -> Void ) {
        guard let rpcURL = self.rpcURL else {
            callback( nil, JsonRpcError.invalidRpcUrl )
            return
        }
        
        let ethCall = EthCall( address: address, data: data )
        guard let params = JsonRpcBaseRequest( ethCall: ethCall ).toJsonRPC() else {
            callback( nil, JsonRpcError.jsonConversionIssue )
            return
        }

        DispatchQueue.global().async {
            let ( response, error ) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: params )
            DispatchQueue.main.async {
                callback( response, error )
            }
        }
    }
    
}
