//
//  EthAddress.swift
//  uPortSDK
//
//  Created by mac on 8/21/18.
//

import Foundation

public struct EthAddress
{
    private var input: String
    var cleanHex: String { get { return self.input.withoutHexPrefix } }
    var hex: String { get { return "0x\(self.cleanHex)" } }
    
    public init(input: String)
    {
        self.input = input
    }
    
    public func toString() -> String
    {
        return String(address: self)
    }
}

public extension String
{
    public init(address: EthAddress)
    {
        self = address.hex
    }
}
