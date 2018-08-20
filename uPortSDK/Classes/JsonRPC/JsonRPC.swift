//
//  JsonRPC.swift
//  uPortSDK
//
//  Created by josh on 8/13/18.
//

import Foundation
import BigInt
import Promises

public enum JsonRpcError: Error {
    case invalidRpcUrl
    case jsonConversionIssue

    /// for when JsonRpcResponse has missing `result` property or `result` property not valid type
    case invalidResult

    /// for when server returns no error and no response
    case missingPayload
}

public struct JsonRPC {
    private var rpcURL: String?

    public func ethCall(address: String, data: String, callback: @escaping (_ result: String?, _ error: Error?) -> Void) {
        guard let rpcURL = self.rpcURL else {
            callback(nil, JsonRpcError.invalidRpcUrl)
            return
        }

        let ethCall = EthCall(address: address, data: data)
        guard let params = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC() else {
            callback(nil, JsonRpcError.jsonConversionIssue)
            return
        }

        DispatchQueue.global().async {
            let (response, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: params)
            DispatchQueue.main.async {
                callback(response, error)
            }
        }
    }

    public func transactionCount(address: String, callback: @escaping (_ transactionCount: BigInt?, _ error: Error?) -> Void) {
        guard let rpcURL = self.rpcURL else {
            callback(nil, JsonRpcError.invalidRpcUrl)
            return
        }

        guard let payloadRequest = JsonRpcBaseRequest(address: address, method: "eth_getTransactionCount").toJsonRPC() else {
            callback(nil, JsonRpcError.jsonConversionIssue)
            return
        }

        DispatchQueue.global().async {
            let (jsonRpcString, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: payloadRequest)
            guard error == nil else {
                DispatchQueue.main.async {
                    callback(nil, error!)
                }

                return
            }

            guard let jsonRpcStringUnwrapped = jsonRpcString else {
                DispatchQueue.main.async {
                    callback(nil, JsonRpcError.missingPayload)
                }

                return
            }

            let parsedResponse = JsonRpcBaseResponse.fromJson(json: jsonRpcStringUnwrapped)
            guard parsedResponse.error == nil else {
                DispatchQueue.main.async {
                    callback(nil, parsedResponse.error!)
                }

                return
            }

            guard let stringResult = parsedResponse.result as? String else {
                DispatchQueue.main.async {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            guard let count = BigInt(stringResult.withoutHexPrefix, radix: 16) else {
                DispatchQueue.main.async {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            DispatchQueue.main.async {
                callback(count, nil)
            }
        }

    }

    public func transactionCount(address: String) -> Promise<BigInt> {
        return Promise<BigInt> { fulfill, reject in
            self.transactionCount(address: address, callback: { (transactionCountBigInt, error ) in
                guard error == nil else {
                    reject(error!)
                    return
                }

                guard let transactionCountBigIntUnwrapped = transactionCountBigInt else {
                    reject(JsonRpcError.missingPayload)
                }

                fulfill(transactionCountBigIntUnwrapped)
            })
        }
    }

    public func gasPrice(callback: @escaping (_ gasPrice: BigInt?, _ error: Error?) -> Void) {
        guard let rpcURL = self.rpcURL else {
            callback(nil, JsonRpcError.invalidRpcUrl)
            return
        }

        guard let payloadRequest = JsonRpcBaseRequest(methodName: "eth_gasPrice", params: [Any]()).toJsonRPC() else {
            callback(nil, JsonRpcError.jsonConversionIssue)
            return
        }

        DispatchQueue.global().async {
            let (jsonRpcString, error) = HTTPClient.synchronousPostRequest(url: rpcURL, jsonBody: payloadRequest)
            guard error == nil else {
                DispatchQueue.main.async {
                    callback(nil, error!)
                }

                return
            }

            guard let jsonRpcStringUnwrapped = jsonRpcString else {
                DispatchQueue.main.async {
                    callback(nil, JsonRpcError.missingPayload)
                }

                return
            }

            let parsedResponse = JsonRpcBaseResponse.fromJson(json: jsonRpcStringUnwrapped)
            guard parsedResponse.error == nil else {
                DispatchQueue.main.async {
                    callback(nil, parsedResponse.error!)
                }

                return
            }

            guard let stringResult = parsedResponse.result as? String else {
                DispatchQueue.main.async {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            guard let count = BigInt(stringResult.withoutHexPrefix, radix: 16) else {
                DispatchQueue.main.async {
                    callback(nil, JsonRpcError.invalidResult)
                }

                return
            }

            DispatchQueue.main.async {
                callback(count, nil)
            }
        }
    }

    public func gasPrice() -> Promise<BigInt> {
        return Promise<BigInt> { fulfill, reject in
            self.gasPrice { (transactionCountBigInt: BigInt?, error: Error?) in
                guard error == nil else {
                    reject(error!)
                    return
                }

                guard let transactionCountBigIntUnwrapped = transactionCountBigInt else {
                    reject(JsonRpcError.missingPayload)
                }

                fulfill(transactionCountBigIntUnwrapped)
            }
        }
    }
}
