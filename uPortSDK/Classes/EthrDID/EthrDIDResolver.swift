//
//  EthrDIDResolver.swift
//  uPortSDK
//
//  Created by josh on 8/7/18.
//

import Foundation
import Promises
import BigInt

public enum EthrDIDResolverError: Error
{
    case invalidIdentity
    case invalidRPCResponse
    case invalidRegexResult
    case invalidDelegateType
    case invalidServiceEndpoint
}

public struct EthrDIDResolver: DIDResolver
{
    public static let DEFAULT_REGISTERY_ADDRESS = "0xdca7ef03e98e0dc2b855be647c39abe984fcf21b"
    let veriKey = "veriKey"
    let sigAuth = "sigAuth"
    let attrTypes = [ "sigAuth" : "SignatureAuthentication2018", "veriKey" : "VerificationKey2018" ]
    
    var registryAddress = DEFAULT_REGISTERY_ADDRESS
    var rpc : JsonRPC

    public init(rpc: JsonRPC, registryAddress: String = DEFAULT_REGISTERY_ADDRESS)
    {
        self.rpc = rpc
        self.registryAddress = registryAddress
    }

    // MARK: - Resolver Implementation

    public var method: String
    {
        return "ethr"
    }

    public func canResolve(did: String) -> Bool
    {
        return !NormalizedDID(didCandidate: did).value.isEmpty
    }

    public func resolve(did: String) throws -> DIDDocument
    {
        let normalizedDidObject = NormalizedDID(didCandidate: did)
        guard normalizedDidObject.error == nil else
        {
            throw normalizedDidObject.error!
        }
        
        let identity = self.parseIdentity(normalizedDid: normalizedDidObject.value)
        let ethrDidContract = EthrDID(address: identity, rpc: self.rpc, registry: self.registryAddress)
        let history = self.getHistory(identity: identity)
        var owner: String
        do
        {
            owner = try ethrDidContract.lookupOwnerSynchronous(cache: false)
        }
        catch
        {
            throw error
        }
        
        var ddo: DIDDocument?
        do
        {
            ddo = try self.wrapDidDocument(normalizedDid: normalizedDidObject.value, owner: owner, history: history)
        }
        catch
        {
            throw error
        }
    
        return ddo!
    }
    
    func getHistory(identity: String) -> [Any]
    {
        var lastChangedQueue = [BigUInt]()
        var events = [Any]()
        let lastChanged = try? self.lastChangedSynchronous(identity: identity)
        var lastChangedBigInt: BigUInt?
        let zeroBigInt = BigUInt(integerLiteral: 0)

        guard let lastChangedBigIntUnwrapped = lastChanged?.hexToBigUInt() else
        {
            print("invalid bigint conversion")
            return events
        }
        
        lastChangedBigInt = lastChangedBigIntUnwrapped
        lastChangedQueue.append(lastChangedBigInt!)
        repeat
        {
            lastChangedBigInt = lastChangedQueue.popLast()
            if lastChangedBigInt == nil
            {
                continue
            }
            
            let topics = [nil, identity.hexToBytes32()]
            var logs: [JsonRpcLogItem]?
            do
            {
                logs = try self.rpc.getLogsSynchronous(address: self.registryAddress,
                                                       topics: topics,
                                                       fromBlock: lastChangedBigInt!,
                                                       toBlock: lastChangedBigInt!)
            }
            catch
            {
                print("error fetching logs -> \(error)")
                continue
            }
            
            for log in logs!
            {
                guard let topicsHexPrefixed = log.topics, let dataHexPrefixed = log.data else
                {
                    continue
                }
                
                let topics = topicsHexPrefixed.map(
                { (topic) -> String in
                    return topic.withoutHexPrefix
                })
                
                let data = dataHexPrefixed.withoutHexPrefix
                
                do
                {
                    let event = try EthereumDIDRegistry.Events.DIDOwnerChanged.decode(topics: topics, data: data)
                    lastChangedQueue.append(event.previouschange.value)
                    events.append(event)
                }
                catch
                {
                    /* nop */
                }
                
                do
                {
                    let event = try EthereumDIDRegistry.Events.DIDAttributeChanged.decode(topics: topics, data: data)
                    lastChangedQueue.append(event.previouschange.value)
                    events.append(event)
                }
                catch
                {
                    /* nop */
                }
                
                do
                {
                    let event = try EthereumDIDRegistry.Events.DIDDelegateChanged.decode(topics: topics, data: data)
                    lastChangedQueue.append(event.previouschange.value)
                    events.append(event)
                }
                catch
                {
                    /* nop */
                }
                
                lastChangedQueue.sort { return $1 < $0 }
                
            }
        }
        while lastChangedBigInt != nil &&
              lastChangedBigInt!.hexStringWithoutPrefix() != zeroBigInt.hexStringWithoutPrefix()
        
        return events
    }
    
    func wrapDidDocument(normalizedDid: String, owner: String, history: [Any]) throws -> DIDDocument
    {
        let now = Int64(Date().timeIntervalSince1970 / 1000)
        
        let owner = PublicKeyEntry(id: "\(normalizedDid)#owner",
                                   type: .Secp256k1VerificationKey2018,
                                   owner: normalizedDid,
                                   ethereumAddress: owner)
        var pkEntries = ["owner": owner]
        
        let authenticationEntry = AuthenticationEntry(type: .Secp256k1SignatureAuthentication2018,
                                                      publicKey: "\(normalizedDid)#owner")
        var authEntries = ["owner": authenticationEntry]
        
        var serviceEntries = [String: ServiceEntry]()
        var delegateCount = 0
        
        for baseEvent in history
        {
            if baseEvent is EthereumDIDRegistry.Events.DIDDelegateChanged.Arguments
            {
                let event = baseEvent as! EthereumDIDRegistry.Events.DIDDelegateChanged.Arguments
                let delegateTypeOptional = String(data: event.delegatetype.value, encoding: .utf8)
                let delegate = event.delegate.encodeUnpadded().withoutHexPrefix.withHexPrefix
                let key = "DIDDelegateChanged-\(delegateTypeOptional ?? "<unknown-delegatetype>")-\(delegate)"
                let validTo = Int64(event.validto.value)
                
                if now <= validTo
                {
                    delegateCount += 1
                    
                    guard let delegateType = delegateTypeOptional else
                    {
                        print("invalid delegate type")

                        continue
                    }
                    
                    switch delegateType
                    {
                    case DelegateType.Secp256k1SignatureAuthentication2018.rawValue, self.sigAuth:
                        authEntries[key] = AuthenticationEntry(type: .Secp256k1SignatureAuthentication2018,
                                                               publicKey: "\(normalizedDid)#delegate-\(delegateCount)")

                    case DelegateType.Secp256k1VerificationKey2018.rawValue, self.veriKey:
                        pkEntries[key] = PublicKeyEntry(id: "\(normalizedDid)#delegate-\(delegateCount)",
                                                        type: .Secp256k1VerificationKey2018,
                                                        owner: normalizedDid,
                                                        ethereumAddress: delegate)
                    default:
                        print("unknown delegateType -> \(delegateType)")
                    }
                }
            }
            
            if baseEvent is EthereumDIDRegistry.Events.DIDAttributeChanged.Arguments
            {
                let event = baseEvent as! EthereumDIDRegistry.Events.DIDAttributeChanged.Arguments
                let validTo = Int64(event.validto.value)
                if now <= validTo
                {
                    let nameOptional = String(data: event.name.value, encoding: .utf8)
                    
                    guard let name = nameOptional else
                    {
                        print("invalid DIDAttributeChanged event name")

                        continue
                    }
                    
                    let key = "DIDAttributeChanged-\(name)-\(event.value.value.hexEncodedString())"
                    let (section, algorithm, rawType, encoding) = try self.destructuredAttributeChanged(eventName: name)
                    let type = try self.parseType(algorithm: algorithm, rawType: rawType)
                    switch section
                    {
                    case "pub":
                        delegateCount += 1
                        let publicKeyOwner = "\(normalizedDid)#delegate-\(delegateCount)"
                        var pk = PublicKeyEntry(id: publicKeyOwner, type: type, owner: normalizedDid)

                        let enc = encoding ?? ""
                        switch enc
                        {
                        case "", "null", "hex":
                            pk.publicKeyHex = event.value.value.toHexString()

                        case "base64":
                            pk.publicKeyBase64 = event.value.value.base64EncodedString()

                        case "base58":
                            pk.publicKeyBase58 = event.value.value.base58EncodedString()

                        default:
                            pk.value = event.value.value.toHexString()
                        }
                        
                        pkEntries[key] = pk
                        
                    case "svc":
                        guard let serviceEndpoint = String(data: event.value.value, encoding: .utf8) else
                        {
                            throw EthrDIDResolverError.invalidServiceEndpoint
                        }
                        
                        serviceEntries[key] = ServiceEntry(type: algorithm, serviceEndpoint: serviceEndpoint)
                    default:
                        break
                    }
                }
            }
        }
        
        return DIDDocument(id: normalizedDid,
                           publicKey: Array(pkEntries.values),
                           authentication: Array(authEntries.values),
                           service: Array(serviceEntries.values))
    }
    
    func destructuredAttributeChanged(eventName: String) throws -> (section : String,
                                                                    algorithm: String,
                                                                    rawType: String?,
                                                                    encoding: String?)
    {
        let regex = try? NSRegularExpression(pattern: "^did/(pub|auth|svc)/(\\w+)(/(\\w+))?(/(\\w+))?$",
                                            options: .caseInsensitive)
        let textCheckingResults = regex?.matches(in: eventName,
                                                 options: [],
                                                 range: NSRange(location: 0, length: eventName.count))
        guard let textCheckingResult = textCheckingResults?.first else
        {
            throw EthrDIDResolverError.invalidRegexResult
        }
        
        var section: String?
        if let sectionRange = Range(textCheckingResult.range(at: 1), in: eventName)
        {
            let sectionSlice = eventName[sectionRange]
            section = String(sectionSlice)
        }
        
        var algorithm: String?
        if let algorithmRange = Range(textCheckingResult.range(at: 2), in: eventName)
        {
            let algorithmSlice = eventName[algorithmRange]
            algorithm = String(algorithmSlice)
        }
        
        var rawType: String?
        if let rawTypeRange = Range(textCheckingResult.range(at: 4), in: eventName)
        {
            let rawTypeSlice = eventName[rawTypeRange]
            rawType = String(rawTypeSlice)
        }
        
        var encoding: String?
        if let encodingRange = Range(textCheckingResult.range(at: 6), in: eventName)
        {
            let encodingSlice = eventName[encodingRange]
            encoding = String(encodingSlice)
        }
        
        guard section != nil && algorithm != nil else
        {
            throw EthrDIDResolverError.invalidRegexResult
        }
        
        return (section!, algorithm!, rawType, encoding)
    }
    
    
    func lastChanged(identity: String) -> Promise<String>
    {
        return Promise<String>
        { fulfill, reject in
            guard let address = BigUInt(identity.withoutHexPrefix, radix: 16),
                let solidityAddress = try? Solidity.Address(bigUInt: address) else
            {
                reject(EthrDIDResolverError.invalidIdentity)

                return
            }
            
            let encodedCall = EthereumDIDRegistry.Changed.encodeCall(arguments: solidityAddress)
            self.rpc.ethCall(address: self.registryAddress, data: encodedCall).then(
            { response in
                guard let responseUnwrapped = response else
                {
                    reject(EthrDIDResolverError.invalidRPCResponse)

                    return
                }
                
                let parsedResponse = JsonRpcBaseResponse.fromJson(json: responseUnwrapped)
                guard parsedResponse.error == nil || parsedResponse.result != nil else
                {
                    reject(EthrDIDResolverError.invalidRPCResponse)

                    return
                }
                
                fulfill("\(parsedResponse.result!)")
            }).catch(
            { error in
                reject(error)
            })
        }
    }
    
    func lastChangedSynchronous(identity: String) throws -> String
    {
        guard let address = BigUInt(identity.withoutHexPrefix, radix: 16),
            let solidityAddress = try? Solidity.Address(bigUInt: address) else
        {
            throw EthrDIDResolverError.invalidIdentity
        }
        
        let encodedCall = EthereumDIDRegistry.Changed.encodeCall(arguments: solidityAddress)
        let response = try? self.rpc.ethCallSynchronous(address: self.registryAddress, data: encodedCall)
        guard let responseUnwrapped = response else
        {
            throw EthrDIDResolverError.invalidRPCResponse
        }
        
        let parsedResponse = JsonRpcBaseResponse.fromJson(json: responseUnwrapped)
        guard parsedResponse.error == nil || parsedResponse.result != nil else
        {
            throw EthrDIDResolverError.invalidRPCResponse
        }
        
        return "\(parsedResponse.result!)"
    }
    
    public let identityExtractionPattern = try? NSRegularExpression(pattern: "^did:ethr:(0x[0-9a-fA-F]{40})",
                                                                    options: .caseInsensitive)
    
    func parseIdentity(normalizedDid: String) -> String
    {
        let range = NSRange(location: 0, length: normalizedDid.count)
        let textCheckingResults = self.identityExtractionPattern?.matches(in: normalizedDid, options: [], range: range)
        
        guard let textCheckingResult = textCheckingResults?.first else
        {
            return ""
        }
        
        var matches = [String]()
        for index in 1 ..< textCheckingResult.numberOfRanges
        {
            let range = Range(textCheckingResult.range(at: index), in: normalizedDid)
            if range != nil
            {
                let stringSlice = normalizedDid[range!]
                let match = String(stringSlice)
                matches.append(match)
            }
        }

        return matches.first ?? ""
    }
    
    func parseType(algorithm: String, rawType: String?) throws -> DelegateType
    {
        var type = rawType != nil && rawType!.isEmpty ? rawType : veriKey
        type = attrTypes[type!] ?? type
        guard let delegateType = DelegateType(rawValue: "\(algorithm)\(type!)") else
        {
            throw EthrDIDResolverError.invalidDelegateType
        }
        
        return delegateType
    }
}
