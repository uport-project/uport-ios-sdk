//
//  DIDDocument.swift
//  uPortSDK
//
//  Created by josh on 3/6/18.
//

import Foundation


public class DIDDocument: NSObject {
    var type: String? //ex: "Organization", "Person"
    
    var publicKey: String?  //ex: "0x04613bb3a4874d27032618f020614c21cbe4c4e4781687525f6674089f9bd3d6c7f6eb13569053d31715a3ba32e0b791b97922af6387f087d6b5548c06944ab062"
    
    var publicEncKey: String?  //ex: "0x04613bb3a4874d27032618f020614c21cbe4c4e4781687525f6674089f9bd3d6c7f6eb13569053d31715a3ba32e0b791b97922af6387f087d6b5548c06944ab062"
    
    var image: String?     //ex: {"@type":"ImageObject","name":"avatar","contentUrl":"/ipfs/QmSCnmXC91Arz2gj934Ce4DeR7d9fULWRepjzGMX6SSazB"}
    
    var name: String? //ex: "uPort @ Devcon3" , "Vitalik Buterout"
    
    var didDescription: String? // ex: "uPort Attestation"
}
