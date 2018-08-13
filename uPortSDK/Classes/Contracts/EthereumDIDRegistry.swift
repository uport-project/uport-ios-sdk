//
//  EthereumDIDRegistry.swift
//
//  Generated by Bivrost at 1534179538.94984.
//

struct EthereumDIDRegistry {

    struct RevokeAttributeSigned: SolidityFunction {
        static let methodId = "e476af5c"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, sigV: Solidity.UInt8, sigR: Solidity.Bytes32, sigS: Solidity.Bytes32, name: Solidity.Bytes32, value: Solidity.Bytes)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.sigV, arguments.sigR, arguments.sigS, arguments.name, arguments.value))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let sigV = try Solidity.UInt8.decode(source: source)
            let sigR = try Solidity.Bytes32.decode(source: source)
            let sigS = try Solidity.Bytes32.decode(source: source)
            let name = try Solidity.Bytes32.decode(source: source)
            // Ignore location for value (dynamic type)
            _ = try source.consume()
            // Dynamic Types (if any)
            let value = try Solidity.Bytes.decode(source: source)
            return Arguments(identity: identity, sigV: sigV, sigR: sigR, sigS: sigS, name: name, value: value)
        }
    }

    struct ValidDelegate: SolidityFunction {
        static let methodId = "622b2a3c"
        typealias Return = Solidity.Bool
        typealias Arguments = (identity: Solidity.Address, delegateType: Solidity.Bytes32, delegate: Solidity.Address)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.delegateType, arguments.delegate))"
        }

        static func decode(returnData: String) throws -> Return {
            let source = BaseDecoder.partition(returnData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.Bool.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let delegateType = try Solidity.Bytes32.decode(source: source)
            let delegate = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(identity: identity, delegateType: delegateType, delegate: delegate)
        }
    }

    struct ChangeOwner: SolidityFunction {
        static let methodId = "f00d4b5d"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, newOwner: Solidity.Address)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.newOwner))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let newOwner = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(identity: identity, newOwner: newOwner)
        }
    }

    struct Changed: SolidityFunction {
        static let methodId = "f96d0f9f"
        typealias Return = Solidity.UInt256
        typealias Arguments = Solidity.Address

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments))"
        }

        static func decode(returnData: String) throws -> Return {
            let source = BaseDecoder.partition(returnData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.UInt256.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }
    }

    struct Delegates: SolidityFunction {
        static let methodId = "0d44625b"
        typealias Return = Solidity.UInt256
        typealias Arguments = (param0: Solidity.Address, param1: Solidity.Bytes32, param2: Solidity.Address)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.param0, arguments.param1, arguments.param2))"
        }

        static func decode(returnData: String) throws -> Return {
            let source = BaseDecoder.partition(returnData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.UInt256.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.Address.decode(source: source)
            let param1 = try Solidity.Bytes32.decode(source: source)
            let param2 = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(param0: param0, param1: param1, param2: param2)
        }
    }

    struct AddDelegateSigned: SolidityFunction {
        static let methodId = "9c2c1b2b"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, sigV: Solidity.UInt8, sigR: Solidity.Bytes32, sigS: Solidity.Bytes32, delegateType: Solidity.Bytes32, delegate: Solidity.Address, validity: Solidity.UInt256)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.sigV, arguments.sigR, arguments.sigS, arguments.delegateType, arguments.delegate, arguments.validity))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let sigV = try Solidity.UInt8.decode(source: source)
            let sigR = try Solidity.Bytes32.decode(source: source)
            let sigS = try Solidity.Bytes32.decode(source: source)
            let delegateType = try Solidity.Bytes32.decode(source: source)
            let delegate = try Solidity.Address.decode(source: source)
            let validity = try Solidity.UInt256.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(identity: identity, sigV: sigV, sigR: sigR, sigS: sigS, delegateType: delegateType, delegate: delegate, validity: validity)
        }
    }

    struct SetAttribute: SolidityFunction {
        static let methodId = "7ad4b0a4"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, name: Solidity.Bytes32, value: Solidity.Bytes, validity: Solidity.UInt256)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.name, arguments.value, arguments.validity))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let name = try Solidity.Bytes32.decode(source: source)
            // Ignore location for value (dynamic type)
            _ = try source.consume()
            let validity = try Solidity.UInt256.decode(source: source)
            // Dynamic Types (if any)
            let value = try Solidity.Bytes.decode(source: source)
            return Arguments(identity: identity, name: name, value: value, validity: validity)
        }
    }

    struct RevokeAttribute: SolidityFunction {
        static let methodId = "00c023da"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, name: Solidity.Bytes32, value: Solidity.Bytes)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.name, arguments.value))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let name = try Solidity.Bytes32.decode(source: source)
            // Ignore location for value (dynamic type)
            _ = try source.consume()
            // Dynamic Types (if any)
            let value = try Solidity.Bytes.decode(source: source)
            return Arguments(identity: identity, name: name, value: value)
        }
    }

    struct Owners: SolidityFunction {
        static let methodId = "022914a7"
        typealias Return = Solidity.Address
        typealias Arguments = Solidity.Address

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments))"
        }

        static func decode(returnData: String) throws -> Return {
            let source = BaseDecoder.partition(returnData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }
    }

    struct Nonce: SolidityFunction {
        static let methodId = "70ae92d2"
        typealias Return = Solidity.UInt256
        typealias Arguments = Solidity.Address

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments))"
        }

        static func decode(returnData: String) throws -> Return {
            let source = BaseDecoder.partition(returnData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.UInt256.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }
    }

    struct AddDelegate: SolidityFunction {
        static let methodId = "a7068d66"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, delegateType: Solidity.Bytes32, delegate: Solidity.Address, validity: Solidity.UInt256)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.delegateType, arguments.delegate, arguments.validity))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let delegateType = try Solidity.Bytes32.decode(source: source)
            let delegate = try Solidity.Address.decode(source: source)
            let validity = try Solidity.UInt256.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(identity: identity, delegateType: delegateType, delegate: delegate, validity: validity)
        }
    }

    struct ChangeOwnerSigned: SolidityFunction {
        static let methodId = "240cf1fa"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, sigV: Solidity.UInt8, sigR: Solidity.Bytes32, sigS: Solidity.Bytes32, newOwner: Solidity.Address)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.sigV, arguments.sigR, arguments.sigS, arguments.newOwner))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let sigV = try Solidity.UInt8.decode(source: source)
            let sigR = try Solidity.Bytes32.decode(source: source)
            let sigS = try Solidity.Bytes32.decode(source: source)
            let newOwner = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(identity: identity, sigV: sigV, sigR: sigR, sigS: sigS, newOwner: newOwner)
        }
    }

    struct SetAttributeSigned: SolidityFunction {
        static let methodId = "123b5e98"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, sigV: Solidity.UInt8, sigR: Solidity.Bytes32, sigS: Solidity.Bytes32, name: Solidity.Bytes32, value: Solidity.Bytes, validity: Solidity.UInt256)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.sigV, arguments.sigR, arguments.sigS, arguments.name, arguments.value, arguments.validity))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let sigV = try Solidity.UInt8.decode(source: source)
            let sigR = try Solidity.Bytes32.decode(source: source)
            let sigS = try Solidity.Bytes32.decode(source: source)
            let name = try Solidity.Bytes32.decode(source: source)
            // Ignore location for value (dynamic type)
            _ = try source.consume()
            let validity = try Solidity.UInt256.decode(source: source)
            // Dynamic Types (if any)
            let value = try Solidity.Bytes.decode(source: source)
            return Arguments(identity: identity, sigV: sigV, sigR: sigR, sigS: sigS, name: name, value: value, validity: validity)
        }
    }

    struct RevokeDelegateSigned: SolidityFunction {
        static let methodId = "93072684"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, sigV: Solidity.UInt8, sigR: Solidity.Bytes32, sigS: Solidity.Bytes32, delegateType: Solidity.Bytes32, delegate: Solidity.Address)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.sigV, arguments.sigR, arguments.sigS, arguments.delegateType, arguments.delegate))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let sigV = try Solidity.UInt8.decode(source: source)
            let sigR = try Solidity.Bytes32.decode(source: source)
            let sigS = try Solidity.Bytes32.decode(source: source)
            let delegateType = try Solidity.Bytes32.decode(source: source)
            let delegate = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(identity: identity, sigV: sigV, sigR: sigR, sigS: sigS, delegateType: delegateType, delegate: delegate)
        }
    }

    struct IdentityOwner: SolidityFunction {
        static let methodId = "8733d4e8"
        typealias Return = Solidity.Address
        typealias Arguments = Solidity.Address

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments))"
        }

        static func decode(returnData: String) throws -> Return {
            let source = BaseDecoder.partition(returnData)
            // Decode Static Types & Locations for Dynamic Types
            let param0 = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return param0
        }

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return identity
        }
    }

    struct RevokeDelegate: SolidityFunction {
        static let methodId = "80b29f7c"
        typealias Return = Void
        typealias Arguments = (identity: Solidity.Address, delegateType: Solidity.Bytes32, delegate: Solidity.Address)

        static func encodeCall(arguments: Arguments) -> String {
            return "0x\(methodId)\(BaseEncoder.encode(arguments: arguments.identity, arguments.delegateType, arguments.delegate))"
        }

        static func decode(returnData: String) throws -> Return {}

        static func decode(argumentsData: String) throws -> Arguments {
            let source = BaseDecoder.partition(argumentsData)
            // Decode Static Types & Locations for Dynamic Types
            let identity = try Solidity.Address.decode(source: source)
            let delegateType = try Solidity.Bytes32.decode(source: source)
            let delegate = try Solidity.Address.decode(source: source)
            // Dynamic Types (if any)
            return Arguments(identity: identity, delegateType: delegateType, delegate: delegate)
        }
    }
}
