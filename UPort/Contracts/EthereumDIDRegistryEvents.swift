//
//  File.swift
//  UPort
//
//  Created by Cornelis van der Bent on 15/01/2019.
//  Copyright © 2019 ConsenSys. All rights reserved.
//

/// Human extention of Bivrost generated code.
extension EthereumDIDRegistry
{
    struct Events
    {
        struct DIDOwnerChanged
        {
            static let EVENT_ID: String = "38a5a6e68f30ed1ab45860a4afb34bcb2fc00f22ca462d249b8a8d40cda6f7a3"
            typealias Arguments = (identity: Solidity.Address, owner: Solidity.Address, previouschange: Solidity.UInt256)

            static func decode(topics: [String], data: String ) throws -> Arguments {
                let topicsSource = BaseDecoder.PartitionData.init(topics)
                guard try topicsSource.consume() == EVENT_ID else {
                    throw  EthereumDidRegistryError.illegalArgumentException( "topics[0] does not match event id" )
                }

                let t1 = try Solidity.Address.decode(source: topicsSource)

                // Decode data
                let source = BaseDecoder.partition(data)
                let arg0 = try Solidity.Address.decode(source: source)
                let arg1 = try Solidity.UInt256.decode(source: source)

                return Arguments( identity: t1, owner: arg0, previouschange: arg1 )
            }
        }

        struct DIDDelegateChanged
        {
            static let EVENT_ID: String = "5a5084339536bcab65f20799fcc58724588145ca054bd2be626174b27ba156f7"
            typealias Arguments = (identity: Solidity.Address,
                                   delegatetype: Solidity.Bytes32,
                                   delegate: Solidity.Address,
                                   validto: Solidity.UInt256,
                                   previouschange: Solidity.UInt256)

            static func decode(topics: [String], data: String ) throws -> Arguments
            {
                let topicsSource = BaseDecoder.PartitionData.init(topics)
                guard try topicsSource.consume() == EVENT_ID else
                {
                    throw  EthereumDidRegistryError.illegalArgumentException( "topics[0] does not match event id" )
                }

                let t1 = try Solidity.Address.decode(source: topicsSource)

                // Decode data
                let source = BaseDecoder.partition(data)
                let arg0 = try Solidity.Bytes32.decode(source: source)
                let arg1 = try Solidity.Address.decode(source: source)
                let arg2 = try Solidity.UInt256.decode(source: source)
                let arg3 = try Solidity.UInt256.decode(source: source)

                return Arguments( identity: t1, delegatetype: arg0, delegate: arg1, validto: arg2, previouschange: arg3 )
            }
        }

        struct DIDAttributeChanged
        {
            static let EVENT_ID: String = "18ab6b2ae3d64306c00ce663125f2bd680e441a098de1635bd7ad8b0d44965e4"
            typealias Arguments = (identity: Solidity.Address,
                                   name: Solidity.Bytes32,
                                   value: Solidity.Bytes,
                                   validto: Solidity.UInt256,
                                   previouschange: Solidity.UInt256)

            static func decode(topics: [String], data: String ) throws -> Arguments
            {
                let topicsSource = BaseDecoder.PartitionData.init(topics)
                guard try topicsSource.consume() == EVENT_ID else
                {
                    throw  EthereumDidRegistryError.illegalArgumentException( "topics[0] does not match event id" )
                }

                let t1 = try Solidity.Address.decode(source: topicsSource)

                // Decode data
                let source = BaseDecoder.partition(data)
                let arg0 = try Solidity.Bytes32.decode(source: source)
                let arg2 = try Solidity.UInt256.decode(source: source)
                let arg3 = try Solidity.UInt256.decode(source: source)
                let arg1 = try Solidity.Bytes.decode(source: source)

                return Arguments( identity: t1, name: arg0, value: arg1, validto: arg2, previouschange: arg3 )
            }
        }
    }
}
