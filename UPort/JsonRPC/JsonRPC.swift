//
//  JsonRPC.swift
//  UPort
//
//  Created by josh on 8/13/18.
//

import Foundation
import BigInt

public enum JsonRpcError: Error
{
    case invalidRpcUrl
    case jsonConversionIssue

    /// for when JsonRpcResponse has missing `result` property or `result` property not valid type
    case invalidResult

    /// for when server returns no error and no response
    case missingPayload
}

public struct JsonRPC
{
    private var rpcURL: String?

    public private(set) var completionQueue: DispatchQueue

    public init(rpcURL: String, completionQueue: DispatchQueue = DispatchQueue.main)
    {
        self.completionQueue = completionQueue
        self.rpcURL = rpcURL
    }
    
    public func ethCall(address: String,
                        data: String,
                        completionHandler: @escaping (_ result: String?, _ error: Error?) -> Void)
    {
        guard let rpcURL = self.rpcURL else
        {
            self.completionQueue.async
            {
                completionHandler(nil, JsonRpcError.invalidRpcUrl)
            }

            return
        }

        let ethCall = EthCall(address: address, data: data)
        guard let params = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC() else
        {
            self.completionQueue.async
            {
                completionHandler(nil, JsonRpcError.jsonConversionIssue)
            }

            return
        }

        DispatchQueue.global(qos: .userInitiated).async
        {
            let (response, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: params)
            self.completionQueue.async
            {
                completionHandler(response, error)
            }
        }
    }

    public func ethCallSynchronous(address: String, data: String) throws -> String
    {
        guard let rpcURL = self.rpcURL else
        {
            throw JsonRpcError.invalidRpcUrl
        }
        
        let ethCall = EthCall(address: address, data: data)
        guard let params = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC() else
        {
            throw JsonRpcError.jsonConversionIssue
        }
        
        let (responseOptional, errorOptional) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: params)
        guard errorOptional == nil else
        {
            throw errorOptional!
        }
        
        guard let response = responseOptional else
        {
            throw JsonRpcError.missingPayload
        }
        
        return response
    }

    public func transactionCount(address: String,
                                 completionHandler: @escaping (_ transactionCount: BigInt?, _ error: Error?) -> Void)
    {
        guard let rpcURL = self.rpcURL else
        {
            self.completionQueue.async
            {
                completionHandler(nil, JsonRpcError.invalidRpcUrl)
            }

            return
        }

        guard let payloadRequest = JsonRpcBaseRequest(address: address,
                                                      method: "eth_getTransactionCount").toJsonRPC() else
        {
            self.completionQueue.async
            {
                completionHandler(nil, JsonRpcError.jsonConversionIssue)
            }

            return
        }

        DispatchQueue.global(qos: .userInitiated).async
        {
            let (jsonRpcString, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: payloadRequest)
            guard error == nil else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, error!)
                }

                return
            }

            guard let jsonRpcStringUnwrapped = jsonRpcString else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, JsonRpcError.missingPayload)
                }

                return
            }

            let parsedResponse = JsonRpcBaseResponse.fromJson(json: jsonRpcStringUnwrapped)
            guard parsedResponse.error == nil else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, parsedResponse.error!)
                }

                return
            }

            guard let stringResult = parsedResponse.result as? String else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, JsonRpcError.invalidResult)
                }

                return
            }

            guard let count = BigInt(stringResult.withoutHexPrefix, radix: 16) else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, JsonRpcError.invalidResult)
                }

                return
            }

            self.completionQueue.async
            {
                completionHandler(count, nil)
            }
        }

    }

    public func gasPrice(completionHandler: @escaping (_ gasPrice: BigInt?, _ error: Error?) -> Void)
    {
        guard let rpcURL = self.rpcURL else
        {
            self.completionQueue.async
            {
                completionHandler(nil, JsonRpcError.invalidRpcUrl)
            }

            return
        }

        guard let payloadRequest = JsonRpcBaseRequest(methodName: "eth_gasPrice", params: [Any]()).toJsonRPC() else
        {
            self.completionQueue.async
            {
                completionHandler(nil, JsonRpcError.jsonConversionIssue)
            }

            return
        }

        DispatchQueue.global(qos: .userInitiated).async
        {
            let (jsonRpcString, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: payloadRequest)
            guard error == nil else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, error!)
                }

                return
            }

            guard let jsonRpcStringUnwrapped = jsonRpcString else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, JsonRpcError.missingPayload)
                }

                return
            }

            let parsedResponse = JsonRpcBaseResponse.fromJson(json: jsonRpcStringUnwrapped)
            guard parsedResponse.error == nil else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, parsedResponse.error!)
                }

                return
            }

            guard let stringResult = parsedResponse.result as? String else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, JsonRpcError.invalidResult)
                }

                return
            }

            guard let count = BigInt(stringResult.withoutHexPrefix, radix: 16) else
            {
                self.completionQueue.async
                {
                    completionHandler(nil, JsonRpcError.invalidResult)
                }

                return
            }

            self.completionQueue.async
            {
                completionHandler(count, nil)
            }
        }
    }
    
    public func getLogsSynchronous(address: String,
                                   topics: [Any?] = [Any?](),
                                   fromBlock: BigUInt,
                                   toBlock: BigUInt) throws -> [JsonRpcLogItem]
    {
        let params: [Any?] = [ [ "fromBlock" : fromBlock.hexStringWithoutPrefix().withHexPrefix,
                                 "toBlock" : toBlock.hexStringWithoutPrefix().withHexPrefix,
                                 "address" : address,
                                 "topics" : topics ] ]
        
        let jsonRpcRequest = JsonRpcBaseRequest(methodName: "eth_getLogs", params: params)
        guard let payloadRequest = jsonRpcRequest.toJsonRPC() else
        {
            throw JsonRpcError.jsonConversionIssue
        }
        
        guard let rpcURLUnwrapped = self.rpcURL else
        {
            throw JsonRpcError.invalidRpcUrl
        }
        
        let (response, error) = HTTPClient.synchronousPostRequest(url: rpcURLUnwrapped, jsonBody: payloadRequest)
        guard error == nil else
        {
            throw error!
        }
        
        guard let responseUnwrapped = response else
        {
             throw JsonRpcError.missingPayload
        }
        
        let parsedResponse = JsonRpcBaseResponse.fromJson(json: responseUnwrapped)
        guard parsedResponse.error == nil else
        {
            throw parsedResponse.error!
        }
        
        var result = parsedResponse.result
        if result == nil
        {
            result = [[String: Any]]()
        }
        
        guard let jsonRpcLogItemDictionaries = result as? [[String: Any]] else
        {
            throw JsonRpcError.invalidResult
        }
        
        var logItems = [JsonRpcLogItem]()
        for logDictionary in jsonRpcLogItemDictionaries
        {
            logItems.append( JsonRpcLogItem(dictionary: logDictionary))
        }
                
        return logItems
    }
}
