//
//  JsonRPC.swift
//  uPortSDK
//
//  Created by josh on 8/13/18.
//

import Foundation
import BigInt
import Promises

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

    init(rpcURL: String)
    {
        self.rpcURL = rpcURL
    }
    
    public func ethCall(address: String, data: String, callback: @escaping (_ result: String?, _ error: Error?) -> Void)
    {
        guard let rpcURL = self.rpcURL else
        {
            callback(nil, JsonRpcError.invalidRpcUrl)

            return
        }

        let ethCall = EthCall(address: address, data: data)
        guard let params = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC() else
        {
            callback(nil, JsonRpcError.jsonConversionIssue)

            return
        }

        DispatchQueue.global().async
        {
            let (response, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: params)
            DispatchQueue.main.async
            {
                callback(response, error)
            }
        }
    }
    
    public func ethCall( address: String, data: String ) -> Promise<String?>
    {
        return Promise<String?>
        { fulfill, reject in
            do
            {
                let response = try self.ethCallSynchronous(address: address, data: data)
                fulfill(response)
            }
            catch
            {
                reject(error)
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
                                 callback: @escaping (_ transactionCount: BigInt?, _ error: Error?) -> Void)
    {
        guard let rpcURL = self.rpcURL else
        {
            callback(nil, JsonRpcError.invalidRpcUrl)

            return
        }

        guard let payloadRequest = JsonRpcBaseRequest(address: address,
                                                      method: "eth_getTransactionCount").toJsonRPC() else
        {
            callback(nil, JsonRpcError.jsonConversionIssue)

            return
        }

        DispatchQueue.global().async
        {
            let (jsonRpcString, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: payloadRequest)
            guard error == nil else
            {
                DispatchQueue.main.async
                {
                    callback(nil, error!)
                }

                return
            }

            guard let jsonRpcStringUnwrapped = jsonRpcString else
            {
                DispatchQueue.main.async
                {
                    callback(nil, JsonRpcError.missingPayload)
                }

                return
            }

            let parsedResponse = JsonRpcBaseResponse.fromJson(json: jsonRpcStringUnwrapped)
            guard parsedResponse.error == nil else
            {
                DispatchQueue.main.async
                {
                    callback(nil, parsedResponse.error!)
                }

                return
            }

            guard let stringResult = parsedResponse.result as? String else
            {
                DispatchQueue.main.async
                {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            guard let count = BigInt(stringResult.withoutHexPrefix, radix: 16) else
            {
                DispatchQueue.main.async
                {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            DispatchQueue.main.async
            {
                callback(count, nil)
            }
        }

    }

    public func transactionCount(address: String) -> Promise<BigInt>
    {
        return Promise<BigInt>
        { fulfill, reject in
            self.transactionCount(address: address, callback:
            { (transactionCountBigInt, error ) in
                guard error == nil else
                {
                    reject(error!)

                    return
                }

                guard let transactionCountBigIntUnwrapped = transactionCountBigInt else
                {
                    reject(JsonRpcError.missingPayload)

                    return
                }

                fulfill(transactionCountBigIntUnwrapped)
            })
        }
    }

    public func gasPrice(callback: @escaping (_ gasPrice: BigInt?, _ error: Error?) -> Void)
    {
        guard let rpcURL = self.rpcURL else
        {
            callback(nil, JsonRpcError.invalidRpcUrl)

            return
        }

        guard let payloadRequest = JsonRpcBaseRequest(methodName: "eth_gasPrice", params: [Any]()).toJsonRPC() else
        {
            callback(nil, JsonRpcError.jsonConversionIssue)

            return
        }

        DispatchQueue.global().async
        {
            let (jsonRpcString, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: payloadRequest)
            guard error == nil else
            {
                DispatchQueue.main.async
                {
                    callback(nil, error!)
                }

                return
            }

            guard let jsonRpcStringUnwrapped = jsonRpcString else
            {
                DispatchQueue.main.async
                {
                    callback(nil, JsonRpcError.missingPayload)
                }

                return
            }

            let parsedResponse = JsonRpcBaseResponse.fromJson(json: jsonRpcStringUnwrapped)
            guard parsedResponse.error == nil else
            {
                DispatchQueue.main.async
                {
                    callback(nil, parsedResponse.error!)
                }

                return
            }

            guard let stringResult = parsedResponse.result as? String else
            {
                DispatchQueue.main.async
                {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            guard let count = BigInt(stringResult.withoutHexPrefix, radix: 16) else {
                DispatchQueue.main.async
                {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            DispatchQueue.main.async
            {
                callback(count, nil)
            }
        }
    }

    public func gasPrice() -> Promise<BigInt>
    {
        return Promise<BigInt>
        { fulfill, reject in
            self.gasPrice
            { (transactionCountBigInt: BigInt?, error: Error?) in
                guard error == nil else
                {
                    reject(error!)
                    return
                }

                guard let transactionCountBigIntUnwrapped = transactionCountBigInt else
                {
                    reject(JsonRpcError.missingPayload)
                    return
                }

                fulfill(transactionCountBigIntUnwrapped)
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
    
    public func getLogs(address: String,
                        topics: [Any?] = [Any?](),
                        fromBlock: BigUInt,
                        toBlock: BigUInt ) -> Promise<[JsonRpcLogItem]>
    {
        return Promise<[JsonRpcLogItem]>
        { fulfill, reject in
            DispatchQueue.global().async
            {
                var logItems: [JsonRpcLogItem]?
                do
                {
                    logItems = try self.getLogsSynchronous(address: address, topics: topics, fromBlock: fromBlock, toBlock: toBlock)
                }
                catch
                {
                    reject(error)
                }
                
                fulfill(logItems!)
            }
        }
    }
}
