
import Foundation
import BigInt

public struct DIDResolver {
    
    
    /**
     * Given an MNID, calls the uport registry and returns the raw json
     */
    public static func synchronousCallRegistry(subjectId: String?, issuerId: String? = nil, registrationIdentifier: String = "uPortProfileIPFS1220") -> String? {
        let issuerMnid = issuerId ?? subjectId ?? ""
        guard let issuerAccount: Account =  MNID.decode( mnid: issuerMnid ) else {
            print( "could not create issuer account with mnid -> \(issuerMnid), with issuerId -> \(issuerId ?? ""), with subjectID -> \(subjectId ?? "")" )
            return nil
        }
        
        guard let subjectAccount: Account = MNID.decode( mnid: subjectId ?? "") else {
            print( "could not create subject account with mnid -> \(issuerMnid), with issuerId -> \(issuerId ?? ""), with subjectID -> \(subjectId ?? "")" )
            return nil
        }
        
        if issuerAccount.network != subjectAccount.network {
            print( "Issuer and subject must be on the same network" )
            return nil
        }
        
        guard let network = EthereumNetwork( network: issuerAccount.network ?? "" ) else {
            print( "Network id \(issuerAccount.network ?? "" ) is not configured" )
            return nil
        }

        let encodedFunctionCall = self.encodeRegistryFunctionCall( registrationIdentifier: registrationIdentifier, issuer: issuerAccount, subject: subjectAccount)
        let registeryAddress = MNID.decode( mnid: network.registry )!.address
        let ethCall = EthCall(address: registeryAddress!, data: encodedFunctionCall )
        let jsonBody = JsonRpcBaseRequest(ethCall: ethCall).toJsonRPC()!
        let serverResopnse: String? = HTTPClient.synchronousPostRequest(url: network.rpcUrl, jsonBody: jsonBody)
        guard let serverResponseUnwrapped = serverResopnse else {
            print( "Server responsed with no data or data in an unrecognizable format" )
            return nil
        }
        
        guard let serverResponseData = serverResponseUnwrapped.data(using: String.Encoding.utf8) else {
            print( "Server response not convertable to Data" )
            return nil
        }
        
        var serverDictionary: [String: Any]?
        do {
            serverDictionary = try JSONSerialization.jsonObject(with: serverResponseData, options: []) as? [String : Any]
        } catch {
            print( "error converting server response to json -> \(error)" )
            return nil
        }
        
        return serverDictionary![ "result" ] as? String
 
    }

    public static func encodeRegistryFunctionCall( registrationIdentifier: String, issuer: Account, subject: Account ) -> String {
        let solidityRegistryIdentifier = try! Solidity.Bytes32( registrationIdentifier.data(using: .utf8)! )
        let solidityIssuer = try! Solidity.Address( issuer.address )
        let soliditySubject = try! Solidity.Address( subject.address )
        let arguments = ( registrationIdentifier: solidityRegistryIdentifier, issuer: solidityIssuer, subject: soliditySubject )
        return UportRegistry.Get.encodeCall(arguments: arguments)
    }
    
    ///
    /// Get iPFS hash from uPort Registry given an mnid
    ///
    public static func synchronousIpfsHash( mnid: String ) -> String? {
        guard let docAddressHex: String = DIDResolver.synchronousCallRegistry(subjectId: mnid) else {
            print( "error calling uPort Registry" )
            return nil
        }
        
        let formattedIPFSHash = "1220\(docAddressHex.withoutHexPrefix)"
        guard let ipfsHashData = Data( fromHexEncodedString: formattedIPFSHash ) else {
            print( "could not convert ifps hash to data -> \(formattedIPFSHash)" )
            return nil
        }
        
        return ipfsHashData.base58EncodedString()
    }
    
    /// returns Did Document in json format from infura
    private static func synchronousJSONProfile( mnid: String ) -> String? {
        guard let ipfsHash = DIDResolver.synchronousIpfsHash( mnid: mnid ) else {
            return nil
        }
        
        let urlString = "https://ipfs.infura.io/ipfs/\(ipfsHash)"
        return HTTPClient.synchronousGetRequest( url: urlString )
    }
    
    /// returns DIDDocument parsed from fetched json
    static func synchronousProfileDocument( mnid: String ) -> DIDDocument? {
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

