
import Foundation
import BigInt

public enum DIDResolverError: Error {
    case networkMismatch( String )
    case invalidNetwork( String )
    case invalidIssuerOrSubject( String )
    case invalidServerResponse( String )
}


public class DIDResolver: NSObject {
    
    
    /**
     * Given an MNID, calls the uport registry and returns the raw json
     */
    public class func callRegistry(subjectId: String?, issuerId: String? = nil, registrationIdentifier: String = "uPortProfileIPFS1220") throws -> String? {
        let issuerMnid = issuerId ?? subjectId ?? ""
        var issuerAccount: Account?
        do {
            issuerAccount = try MNID.decode( mnid: issuerMnid )
        } catch {
            print( "error -> \(error), with mnid -> \(issuerMnid), with issuerId -> \(issuerId ?? ""), with subjectID -> \(subjectId ?? "")" )
        }
        
        var subjectAccount: Account?
        do {
            subjectAccount = try MNID.decode( mnid: subjectId ?? "")
        } catch {
            print( "error -> \(error), with mnid -> \(issuerMnid), with issuerId -> \(issuerId ?? ""), with subjectID -> \(subjectId ?? "")" )
        }
        
        guard issuerAccount != nil && subjectAccount != nil else {
            throw DIDResolverError.invalidIssuerOrSubject( "could not create accounts with given subjectId \(subjectId ?? "") and issuerId \(issuerId ?? "")" )
            
        }
        
        if issuerAccount?.network != subjectAccount?.network {
            throw DIDResolverError.networkMismatch( "Issuer and subject must be on the same network" )
        }
        
        guard let network = EthereumNetwork( network: issuerAccount?.network ?? "" ) else {
            throw DIDResolverError.invalidNetwork( "Network id \(issuerAccount?.network ?? "" ) is not configured" )
        }

        let encodedFunctionCall = self.encodeRegistryFunctionCall( registrationIdentifier: registrationIdentifier, issuer: issuerAccount!, subject: subjectAccount!)
        let registeryAddress = try MNID.decode( mnid: network.registry )!.address
        let ethCall = EthCall(address: registeryAddress!, data: encodedFunctionCall )
        let jsonBody = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC()!
        let serverResopnse: String? = HTTPClient.syncronousPostRequest(url: network.rpcUrl, jsonBody: jsonBody)
        guard let serverResponseUnwrapped = serverResopnse else {
            throw DIDResolverError.invalidServerResponse( "Server responsed with no data or data in an unrecognizable format" )
        }
        
        guard let serverResponseData = serverResponseUnwrapped.data(using: String.Encoding.utf8) else {
            throw DIDResolverError.invalidServerResponse( "Server response not convertable to Data" )
        }
        
        var serverDictionary: [String: Any]?
        do {
            serverDictionary = try JSONSerialization.jsonObject(with: serverResponseData, options: []) as? [String : Any]
        } catch {
            print( "error converting server response to json -> \(error)" )
            throw error
        }
        
        return serverDictionary![ "result" ] as? String
 
    }

    public class func encodeRegistryFunctionCall( registrationIdentifier: String, issuer: Account, subject: Account ) -> String {
        let solidityRegistryIdentifier = try! Solidity.Bytes32( registrationIdentifier.data(using: .utf8)! )
        let solidityIssuer = try! Solidity.Address( issuer.address )
        let soliditySubject = try! Solidity.Address( subject.address )
        let arguments = ( registrationIdentifier: solidityRegistryIdentifier, issuer: solidityIssuer, subject: soliditySubject )
        return UportRegistry.Get.encodeCall(arguments: arguments)
    }
    
    ///
    /// Get iPFS hash from uPort Registry
    ///
    public class func ipfsHash( mnid: String ) -> String? {
        var docAddressHex: String? = nil
        do {
            docAddressHex = try DIDResolver.callRegistry(subjectId: mnid)
        } catch {
            print( "error calling uPort Registry -> \(error)" )
            return nil
        }
        
        guard let docAddressHexUnwrapped = docAddressHex else {
            return nil
        }
        
        let formattedIPFSHash = "1220\(docAddressHexUnwrapped.withoutHexPrefix)"
        guard let ipfsHashData = Data( fromHexEncodedString: formattedIPFSHash ) else {
            print( "could not convert ifps hash to data -> \(formattedIPFSHash)" )
            return nil
        }
        
        return ipfsHashData.base58EncodedString()
    }
    
    private class func jsonProfile( mnid: String ) -> String {
        let ipfsHash = DIDResolver.ipfsHash( mnid: mnid )
        let url = "https://ipfs.infura.io/ipfs/\(ipfsHash)"
        return url //urlGet(url)
    }
    
    
    /**
     * Given an [mnid], obtains the JSON encoded DID doc then tries to convert it to a [DDO] object
     *
     * TODO: Should [callback] with non-`null` error if anything goes wrong
     */
    public func profileDocument( mnid: String, callback: ((dIDDocument: DIDDocument, error: Error)) ) {
        /// from the spec it looks like it takes a DID, gets the network, looks up the IPFS hash from the uport registery (smart contract) on the specified network, and then fetches the DID document IPFS via infura, and then returns the DID document as hashmap to whoever calls this function for there inspection
        /*
        let mnidObject = MNID( mnid )
        let network = mnidObject.network
        let uportRegistryURL = URL( UPORT_REGISTRY_BASE_URL + network )
        let ipfsHash = URLRequest( url: uportRegistryURL )
        let infuraURL = URL( infuraURL + ipfsHash )
        let dIDDocumentDictionary = URLRequest( url: infraURL )
        let dIDDocument = DIDDocument( dIDDocumentDictionary )
        
        
        jsonProfile()
        
        
        DispatchQueue.main.async {
            if dIDDocument {
                callback( dIDDocument, nil )
            } else {
                callback( nil, Error() )
            }
        }
        */
    }
    
    
    
}
