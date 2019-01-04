//
//  JWTPayload.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 24/12/2018.
//

import Foundation

public enum JWTPayloadError: Error
{
    case missingIss
}

public class JWTPayload
{
    /**
     * General
     */
    public var iss: String  // Cannot be null for signature verification
    public var sub: String? = nil
    public var aud: String? = nil
    public var iat: Date? = nil
    public var exp: Date? = nil
    public var callback: String? = nil
    public var type: String? = nil

    /**
     * Specific to selective disclosure REQUEST
     */
    public var net: String? = nil
    public var act: String? = nil
    public var requested: [String]? = nil
    public var verified: [String]? = nil
    public var permissions: [String]? = nil

    /**
     * Specific to selective disclosure RESPONSE
     * Also includes verified
     */
    public var req: String? = nil // original jwt request, REQUIRED for sign selective disclosure responses
    public var nad: String? = nil // The MNID of the Ethereum account requested using act in the Selective Disclosure Request
    public var dad: String? = nil // The devicekey as a regular hex encoded ethereum address as requested using
                                  // act='devicekey' in the Selective Disclosure Request

    //public var own: String?, //The self signed claims requested from a user.
    public var own: [String : String]? = nil
    public var capabilities: [String]? = nil //An array of JWT tokens giving client app the permissions requested. Currently a token allowing them to send push notifications

    /**
     * Specific to Verification
     * Also includes iss, sub, iat, exp, claim
     */
    //An object containing one or more claims about sub eg: {"name":"Carol Crypteau"}
    public var claims: [String : Any]? = nil

    /**
     * Specific to Private Chain
     * Also includes dad
     */
    public var ctl: String? = nil //Ethereum address of the Meta Identity Manager used to control the account
    public var reg: String? = nil //Ethereum address of the Uport Registry used on private chain
    public var rel: String? = nil //Url of relay service for providing gas on private network
    public var fct: String? = nil //Url of fueling service for providing gas on private network
    public var acc: String? = nil //Fuel token used to authenticate on above fct url

    public init(dictionary: [String : Any]) throws
    {
        guard dictionary["iss"] as? String != nil else
        {
            throw JWTPayloadError.missingIss
        }

        iss = dictionary["iss"] as! String
        sub = dictionary["sub"] as? String
        aud = dictionary["aud"] as? String
        iat = try convertToDate(dictionary["iat"] as? NSNumber)
        exp = try convertToDate(dictionary["exp"] as? NSNumber)

        callback = dictionary["callback"] as? String
        type = dictionary["type"] as? String

        claims = dictionary
    }

    private func convertToDate(_ number: NSNumber?) throws -> Date?
    {
        if number == nil
        {
            return nil
        }
        else
        {
            return Date(timeIntervalSince1970: TimeInterval(number!.doubleValue))
        }
    }
}
