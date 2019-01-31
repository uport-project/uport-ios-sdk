//
//  HexExtensions.swift
//  uPortSDK
//
//  Created by mac on 9/21/18.
//

import Foundation

public extension String
{
    public func hexToBytes32() -> String
    {
        return self.withoutHexPrefix.pad(toMultipleOf: 64, character: "0", location: .left).withHexPrefix
    }
    
    public func has0xPrefix() -> Bool
    {
        return self.starts(with: "0x")
    }
    
    var withHexPrefix: String
    {
        return self.has0xPrefix() ? "\(self)"  : "0x\(self)"
    }
}
