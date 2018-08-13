//
//  HTTPClient.swift
//  uPortSDK
//
//  Created by mac on 3/30/18.
//

import UIKit

public struct HTTPClient {

    public static func synchronousGetRequest( url: String ) -> String? {
        guard let requestURL = URL(string:url) else {
            return nil
        }
        
        var urlRequest = URLRequest( url: requestURL )
        urlRequest.httpMethod = "GET"
        
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
    
    public static func synchronousPostRequest( url: String, jsonBody: String ) -> String? {
        guard let bodyData = jsonBody.data(using: .utf8) else {
            print( "invalid jsonBody" )
            return nil
        }
        
        guard let requestURL = URL( string: url ) else {
            return nil
        }
        
        var urlRequest = URLRequest( url: requestURL )
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
