//
//  JsonRpcBaseRequest.swift
//  uPortSDK
//
//  Created by mac on 4/5/18.
//

import UIKit

public struct JsonRpcBaseRequest {
    var params = [Any]()
    var methodName: String = "eth_call"
    var version: String = "latest"
    var id: Int = 1
    var jsonrpc: String = "2.0"
    
    public init( ethCall: EthCall, methodName: String = "eth_call", version: String = "latest", id: Int = 1, jsonrpc: String = "2.0" ) {
        self.params =  [ [ "to": ethCall.address, "data": ethCall.data], version ]
        self.methodName = methodName
        self.version = version
        self.id = id
        self.jsonrpc = jsonrpc
    }

    public init( address: String, method: String ) {
        self.params = [address, self.version]
        self.methodName = method
    }

    public init( methodName: String = "eth_call", params: [Any] = [Any]() ) {
        self.params = params
        self.methodName = methodName
    }

    public func toJsonRPC( ) -> String? {
        let objectToConvertToJson: [String: Any] = [ "method": self.methodName, "params": params, "id": self.id, "jsonrpc": self.jsonrpc ]
        guard let jsonData: Data = try?  JSONSerialization.data( withJSONObject: objectToConvertToJson, options: JSONSerialization.WritingOptions.init(rawValue: 0) ) else {
            print( "uPortSDK: could not convert ethcall + jsonrpcbaserequest to json" )
            return nil
        }
        
        guard let jsonString = String(data: jsonData, encoding: String.Encoding.ascii) else {
            print( "uPortSDK: error converting jsonData to json string" )
            return nil
        }
        
        return jsonString
    }
}

public struct JsonRpcBaseResponse {
    public var result: Any?
    public var error: JsonRpcError?
    public var id = 1
    public var jsonrpc = "2.0"

    public static func fromJson( json: String ) -> JsonRpcBaseResponse {
        guard let jsonData = json.data( using: .utf8 ) else {
            var errorResponse = JsonRpcBaseResponse()
            errorResponse.error = .jsonConversionIssue
            return errorResponse
        }

        let responseObject = try? JSONSerialization.jsonObject(with: jsonData)
        guard let object = responseObject as? [String: Any] else {
            var errorResponse = JsonRpcBaseResponse()
            errorResponse.error = .jsonConversionIssue
            return errorResponse
        }

        var jsonRpcResponse = JsonRpcBaseResponse()
        jsonRpcResponse.result = object[ "result" ]
        return jsonRpcResponse
    }


}
