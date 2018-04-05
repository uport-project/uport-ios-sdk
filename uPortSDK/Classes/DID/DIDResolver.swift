
import Foundation
import BigInt

public enum DIDResolverError: Error {
    case networkMismatch( String )
    case invalidNetwork( String )
    case invalidIssuerOrSubject( String )
}


public class DIDResolver: NSObject {
    
    
    /**
     * Given an MNID, calls the uport registry and returns the raw json
     */
    private func callRegistrySync(subjectId: String?, issuerId: String? = nil, registrationIdentifier: String = "uPortProfileIPFS1220", completionHandler: @escaping (_: String?) -> Void ) throws {
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
        let jsonPayload = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC()!
        HTTPClient.postRequest(url: network.rpcUrl, jsonBody: jsonPayload) { result in
            completionHandler( result )
        }

    }

    internal func encodeRegistryFunctionCall( registrationIdentifier: String, issuer: Account, subject: Account ) -> String {
        let solidityRegistryIdentifier = try! Solidity.Bytes32( registrationIdentifier.data(using: .utf8)! )
        let solidityIssuer = try! Solidity.Address( issuer.address )
        let soliditySubject = try! Solidity.Address( subject.address )
        let arguments = ( registrationIdentifier: solidityRegistryIdentifier, issuer: solidityIssuer, subject: soliditySubject )
        return UportRegistry.Get.encodeCall(arguments: arguments)
    }
    
    ///
    /// Get iPFS hash from uPort Registry
    ///
    private func ipfsHash() {
        
    }
    
    private func jsonProfile() {
        ipfsHash()
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

