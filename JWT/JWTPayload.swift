//
//  JWTPayload.swift
//  uPortSDK
//
//  Created by Cornelis van der Bent on 24/12/2018.
//

import Foundation

/// Possible errors thrown.
public enum JWTPayloadError: Error
{
    case missingIss
}

/// Contains JWT payload data.
public struct JWTPayload
{
    /// General JWT fields.
    public var iss: String  // Cannot be `nil` for signature verification.
    public var sub: String? = nil
    public var aud: String? = nil
    public var iat: Date? = nil
    public var exp: Date? = nil
    public var callback: String? = nil
    public var type: String? = nil

    /// Dictionary containing the full JWT payload, including the fields above. Note that `"iat"` and `"exp"`
    /// will return the raw/string value (not a `Date` object).
    public var claims: [String : Any]? = nil

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
