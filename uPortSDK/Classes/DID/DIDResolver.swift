
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
    class func synchronousCallRegistry(subjectId: String?, issuerId: String? = nil, registrationIdentifier: String = "uPortProfileIPFS1220") throws -> String? {
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
        let serverResopnse: String? = HTTPClient.synchronousPostRequest(url: network.rpcUrl, jsonBody: jsonBody)
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

    class func encodeRegistryFunctionCall( registrationIdentifier: String, issuer: Account, subject: Account ) -> String {
        let solidityRegistryIdentifier = try! Solidity.Bytes32( registrationIdentifier.data(using: .utf8)! )
        let solidityIssuer = try! Solidity.Address( issuer.address )
        let soliditySubject = try! Solidity.Address( subject.address )
        let arguments = ( registrationIdentifier: solidityRegistryIdentifier, issuer: solidityIssuer, subject: soliditySubject )
        return UportRegistry.Get.encodeCall(arguments: arguments)
    }
    
    ///
    /// Get iPFS hash from uPort Registry given an mnid
    ///
    class func synchronousIpfsHash( mnid: String ) -> String? {
        var docAddressHex: String? = nil
        do {
            docAddressHex = try DIDResolver.synchronousCallRegistry(subjectId: mnid)
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
    
    /// returns Did Document in json format from infura
    private class func synchronousJSONProfile( mnid: String ) -> String? {
        guard let ipfsHash = DIDResolver.synchronousIpfsHash( mnid: mnid ) else {
            return nil
        }
        
        let urlString = "https://ipfs.infura.io/ipfs/\(ipfsHash)"
        return HTTPClient.synchronousGetRequest( url: urlString )
    }
    
    /// returns DIDDocument parsed from fetched json
    class func synchronousProfileDocument( mnid: String ) -> DIDDocument? {
        guard let profileDocumentJSON = DIDResolver.synchronousJSONProfile( mnid: mnid ) else {
            print( "Error fetching DIDDocument json from infura" )
            return nil
        }
        
        guard let jsonData = profileDocumentJSON.data( using: .utf8 ) else {
            print( "could not convert json string into Data" )
            return nil
        }
        
        let decoder = JSONDecoder()
        var didDocument: DIDDocument?
        do {
            didDocument = try decoder.decode( DIDDocument.self, from: jsonData )
        } catch {
            print( "could not decode json into DIDDocument object with error -> \(error)" )
            return nil
        }
        
        return didDocument
    }

    /// Public endpoint for retrieving a DID Document from an mnid
    /// TODO: errors should bubble to this function
    public func profileDocument( mnid: String, callback: @escaping ((DIDDocument?, Error?) -> Void) ) {
        DispatchQueue.global().async {
            guard let didDocument = DIDResolver.synchronousProfileDocument( mnid: mnid ) else {
                DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                    let error = NSError(domain:"500", code:500, userInfo:["error": "There was an internal error getting the DIDDocument given the mnid -> \(mnid)"] )
                    callback( nil, error )
                })
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                callback( didDocument, nil )
            })
        }
    }
    
    
    
}

