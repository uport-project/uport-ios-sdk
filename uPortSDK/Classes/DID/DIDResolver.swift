
import Foundation

public enum DIDResolverError: Error {
    case netowrkMismatch(String)
}


public class DIDResolver: NSObject {
    
    
    /**
     * Given an MNID, calls the uport registry and returns the raw json
     */
    private func callRegistrySync(subjectId: String?, issuerId: String? = nil, registrationIdentifier: String = "uPortProfileIPFS1220") throws -> String? {
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
            print( "could not create accounts with given subjectId \(subjectId ?? "") and issuerId \(issuerId ?? "")" )
            return nil
        }
        
        if issuerAccount?.network != subjectAccount?.network {
            throw DIDResolverError.netowrkMismatch( "Issuer and subject must be on the same network" )
        }
        
        
        
        return ""
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

