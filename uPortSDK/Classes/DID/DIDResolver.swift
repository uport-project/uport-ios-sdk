
import Foundation

public class DIDResolver: NSObject {
    
    
    
    /**
     * Given an MNID, calls the uport registry and returns the raw json
     */
    private func callRegistrySync(subjectId: String?, issuerId: String? = null, registrationIdentifier: String = "uPortProfileIPFS1220") -> String {
    
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
        
    }
    
    
    
}

