//
//  HTTPClient.swift
//  uPortSDK
//
//  Created by mac on 3/30/18.
//

import UIKit
import Alamofire

class HTTPClient: NSObject {

    class func postRequest( url: String, jsonBody: String, completionHandler: @escaping (_: String?) -> Void ) {
        guard let data = jsonBody.data(using: .utf8) else {
            print( "invalid jsonBody" )
            return
        }
        
        var params: [String: Any]?
        do {
            params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print( "error generating params from jsonBody string \(error.localizedDescription)" )
        }

        let headers = ["Accept": "application/json", "Content-Type": "application/json" ]
        Alamofire.request(url, method: .post, parameters: params, encoding: URLEncoding.httpBody , headers: headers).responseJSON { (response) in
            completionHandler( response.result.value as? String )
        }
    }
}
