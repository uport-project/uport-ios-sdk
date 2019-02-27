//
//  Transaction.swift
//  UPort
//
//  Created by mac on 8/21/18.
//

import Foundation
import BigInt

public let ETH_IN_WEI = BigInt("1000000000000000000")!
public let DEFAULT_GAS_PRICE = BigInt("20000000000")!
public let DEFAULT_GAS_LIMIT = BigInt("21000")!

public struct Transaction
{
    var chainDefinition: ChainDefinition?
    var creationEpochSecond: Int64?
    var from: EthAddress?
    var gasLimit: BigInt
    var gasPrice: BigInt
    var input: [UInt8]
    var nonce: BigInt?
    var to: EthAddress?
    var txHash: String?
    var value: BigInt

    public init(chain: ChainDefinition?,
                creationEpochSecond: Int64?,
                from: EthAddress?,
                gasLimit: BigInt = DEFAULT_GAS_LIMIT,
                gasPrice: BigInt = DEFAULT_GAS_PRICE,
                input: [UInt8] = [UInt8](),
                nonce: BigInt? = nil,
                to: EthAddress?,
                txHash: String? = nil,
                value: BigInt)
    {
        self.chainDefinition = chain
        self.creationEpochSecond = creationEpochSecond
        self.from = from
        self.gasLimit = gasLimit
        self.gasPrice = gasPrice
        self.input = input
        self.nonce = nonce
        self.to = to
        self.txHash = txHash
        self.value = value
    }

    public static func defaultTransaction(chain: ChainDefinition? = nil,
                                          creationEpochSecond: Int64? = nil,
                                          from: EthAddress,
                                          gasLimit: BigInt = DEFAULT_GAS_LIMIT,
                                          gasPrice: BigInt = DEFAULT_GAS_PRICE,
                                          input: [UInt8] = [UInt8](),
                                          nonce: BigInt? = nil,
                                          to: EthAddress?,
                                          txHash: String? = nil,
                                          value: BigInt) -> Transaction
    {
        return Transaction(chain: chain,
                           creationEpochSecond: creationEpochSecond,
                           from: from,
                           gasLimit: gasLimit,
                           gasPrice: gasPrice,
                           input: input,
                           nonce: nonce,
                           to: to,
                           txHash: txHash,
                           value: value)
    }
}
