//
//  UPortDIDResolver.swift
//  uPortSDK
//
//  Created by ConsenSys on 3/6/18.
//

import Foundation
import BigInt

public enum UPortDIDResolverError: Error
{
    case failedToCreateIssuerAccount(String)
    case failedToCreateSubjectAccount(String)
    case issuerAndSubjectNotOnSameNetwork
    case networkIdNotConfigured(String)
    case postRequestError(String)
    case invalidResponse
    case errorCallingUPortRegistry
    case couldNotConvertIfpsHashToData
    case failedToFetchJsonProfile(String)
    case invalidJson
    case failedToDecodeDidDocument(String)
}

public struct UPortDIDResolver: DIDResolver
{
    /**
     * Given an MNID, calls the uPort registry and returns the raw json
     */
    public static func synchronousCallRegistry(subjectId: String?,
                                               issuerId: String? = nil,
                                               registrationIdentifier: String = "uPortProfileIPFS1220") throws -> String?
    {
        let issuerMnid = issuerId ?? subjectId ?? ""
        guard let issuerAccount: Account =  MNID.decode(mnid: issuerMnid) else
        {
            throw UPortDIDResolverError.failedToCreateIssuerAccount("MNID:\(issuerMnid), " +
                                                                    "IssuerID:\(issuerId ?? "-"), " +
                                                                    "SubjectID:\(subjectId ?? "-")")
        }
        
        guard let subjectAccount: Account = MNID.decode(mnid: subjectId ?? "") else
        {
            throw UPortDIDResolverError.failedToCreateSubjectAccount("MNID:\(issuerMnid), " +
                                                                     "IssuerID:\(issuerId ?? "-"), " +
                                                                     "SubjectID:\(subjectId ?? "-")")
        }
        
        if issuerAccount.network != subjectAccount.network
        {
            throw UPortDIDResolverError.issuerAndSubjectNotOnSameNetwork
        }
        
        guard let network = EthereumNetwork(network: issuerAccount.network ?? "") else
        {
            throw UPortDIDResolverError.networkIdNotConfigured(issuerAccount.network ?? "-")
        }

        let encodedFunctionCall = try self.encodeRegistryFunctionCall(registrationIdentifier: registrationIdentifier,
                                                                      issuer: issuerAccount,
                                                                      subject: subjectAccount)
        let registeryAddress = MNID.decode(mnid: network.registry)!.address
        let ethCall = EthCall(address: registeryAddress!, data: encodedFunctionCall)
        let jsonBody = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC()!
        let (serverResponse, error) = HTTPClient.synchronousPostRequest(url: network.rpcUrl, jsonBody: jsonBody)
        guard error == nil else
        {
            throw error!
        }

        guard let data = serverResponse?.data(using: String.Encoding.utf8) else
        {
            throw UPortDIDResolverError.invalidResponse
        }
        
        var serverDictionary: [String: Any]?
        serverDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]

        return serverDictionary!["result"] as? String
    }

    public static func encodeRegistryFunctionCall(registrationIdentifier: String,
                                                  issuer: Account,
                                                  subject: Account) throws -> String
    {
        let solidityRegistryIdentifier = try Solidity.Bytes32(registrationIdentifier.data(using: .utf8)!)
        let solidityIssuer = try Solidity.Address(issuer.address)
        let soliditySubject = try Solidity.Address(subject.address)
        let arguments = (registrationIdentifier: solidityRegistryIdentifier, issuer: solidityIssuer, subject: soliditySubject)

        return UportRegistry.Get.encodeCall(arguments: arguments)
    }
    
    ///
    /// Get iPFS hash from uPort Registry given an MNID
    ///
    public static func synchronousIpfsHash(mnid: String) throws -> String
    {
        guard let docAddressHex: String = try UPortDIDResolver.synchronousCallRegistry(subjectId: mnid) else
        {
            throw UPortDIDResolverError.errorCallingUPortRegistry
        }
        
        let formattedIPFSHash = "1220\(docAddressHex.withoutHexPrefix)"
        guard let ipfsHashData = Data(fromHexEncodedString: formattedIPFSHash) else
        {
            throw UPortDIDResolverError.couldNotConvertIfpsHashToData
        }
        
        return ipfsHashData.base58EncodedString()
    }
    
    /// returns Did Document in JSON format from infura
    private static func synchronousJSONProfile(mnid: String) throws -> String
    {
        let ipfsHash = try UPortDIDResolver.synchronousIpfsHash(mnid: mnid)
        let urlString = "https://ipfs.infura.io/ipfs/\(ipfsHash)"

        let (jsonProfile, error) = HTTPClient.synchronousGetRequest(url: urlString)
        guard error == nil else
        {
            throw UPortDIDResolverError.failedToFetchJsonProfile(error?.localizedDescription ?? "-")
        }
        
        return jsonProfile ?? ""
    }
    
    /// returns DIDDocument parsed from fetched JSON
    static func synchronousProfileDocument(mnid: String) throws -> UPortIdentityDocument
    {
        let profileDocumentJSON = try UPortDIDResolver.synchronousJSONProfile(mnid: mnid)

        guard let jsonData = profileDocumentJSON.data(using: .utf8) else
        {
            throw UPortDIDResolverError.invalidJson
        }
        
        let decoder = JSONDecoder()
        do
        {
            return try decoder.decode(UPortIdentityDocument.self, from: jsonData)
        }
        catch
        {
            throw UPortDIDResolverError.failedToDecodeDidDocument(error.localizedDescription)
        }
    }

    /// Public endpoint for retrieving a DID Document from an mnid
    public func profileDocument(mnid: String, callback: @escaping ((UPortIdentityDocument?, Error?) -> Void))
    {
        DispatchQueue.global().async
        {
            do
            {
                let didDocument = try UPortDIDResolver.synchronousProfileDocument(mnid: mnid)

                DispatchQueue.main.async
                {
                    callback(didDocument, nil)
                }
            }
            catch
            {
                DispatchQueue.main.async
                {
                    let error = NSError(domain: "500",
                                        code: 500,
                                        userInfo:["error": "There was an internal error getting " +
                                                  "the DIDDocument given the MNID -> \(mnid)"])
                    callback(nil, error)
                }
            }
        }
    }

    // MARK: - DIDResolver Implementation

    public var method: String
    {
        return "uport"
    }

    public func resolveSync(did: String) throws -> DIDDocument
    {
        var dido = try? DIDObject(did)
        if dido == nil
        {
            dido = try DIDObject("did:\(method):\(did)")
        }

        let document = try UPortDIDResolver.synchronousProfileDocument(mnid: dido!.id)
        let ddo = try document.convertToDIDDocument(did: dido!.did)

        return ddo
    }

    public func canResolve(did: String) -> Bool
    {
        do
        {
            let dido = try DIDObject(did)
            if dido.method == method
            {
                return MNID.decode(mnid: dido.id) != nil
            }
            else
            {
                return false
            }
        }
        catch
        {
            return MNID.decode(mnid: did) != nil
        }
    }
}
