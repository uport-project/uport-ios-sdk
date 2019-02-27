//
//  ChainDefinition.swift
//  UPort
//
//  Created by mac on 8/21/18.
//

import Foundation

public struct ChainDefinition
{
    var id: Int64
    fileprivate var prefix: String
    
    public init(id: Int64, prefix: String = "Eth")
    {
        self.id = id
        self.prefix = prefix
    }
    
    func toString() -> String
    {
        return String(chainDefinition: self)
    }
}

public extension String
{
    public init(chainDefinition: ChainDefinition)
    {
        self = "\(chainDefinition.prefix):\(chainDefinition.id)"
    }
}
