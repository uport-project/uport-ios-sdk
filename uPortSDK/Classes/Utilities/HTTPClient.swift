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

    class func syncronousPostRequest( url: String, jsonBody: String ) -> String? {
        guard let bodyData = jsonBody.data(using: .utf8) else {
            print( "invalid jsonBody" )
            return nil
        }
        
        var requestURL: URL? = nil
        do {
            requestURL = try url.asURL()
        } catch {
            print( "error creating URL -> \(error), from url string -> \(url)" )
            return nil
        }
        
        guard requestURL != nil else {
            return nil
        }
        
        var urlRequest = URLRequest( url: requestURL! )
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = bodyData
        
        let (responseData, _, error) = URLSession.shared.synchronousDataTask(urlRequest: urlRequest)
        guard error == nil else {
            print( "error making request -> \(error!)" )
            return nil
        }
        
        guard let responseDataUnwrapped = responseData else {
            print( "server response was nil" )
            return nil
        }
        
        let responseString = String(data: responseDataUnwrapped, encoding: .utf8 )
        guard let responseStringUnwrapped = responseString else {
            print( "could not convert server response to String" )
            return nil
        }
        
        return responseStringUnwrapped
    }
}

extension URLSession {
    fileprivate func synchronousDataTask(urlRequest: URLRequest) -> (Data?, URLResponse?, Error?){
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        let dataTask = self.dataTask(with: urlRequest) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        
        dataTask.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return (data, response, error)
    }
}
