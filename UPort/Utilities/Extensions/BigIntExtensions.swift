//
//  BigIntExtensions.swift
//  uPortSDK
//
//  Created by mac on 9/21/18.
//

import Foundation
import BigInt

extension String
{
    public func hexToBigUInt() -> BigUInt?
    {
        return BigUInt(self.withoutHexPrefix, radix: 16)
    }
}

extension BigUInt
{
    public func hexStringWithoutPrefix() -> String
    {
        return String( self, radix: 16 ).withoutHexPrefix
    }
}
