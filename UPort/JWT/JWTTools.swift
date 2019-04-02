//
//  JWTTools.swift
//  UPort
//
//  Created by Cornelis van der Bent on 20/12/2018.
//

import Foundation
import BigInt
import CoreEth
import Security

public enum JWTToolsError: Error
{
    case notValidIssuedInFuture
    case notValidPastExpiryDate
    case malformedNotThreeParts
    case malformedEmptyHeader
    case malformedEmptyPayload
    case malformedEmptySignature
    case malformedNotBase64Url
    case malformedNotBase64
    case malformedNotUtf8
    case malformedNotDictionary
    case deserializationError(String)
    case invalidSignatureSize(Int)
    case failedToVerify
    case missingDidDocument
}

/// Protocol to support testing and demo code only; do not use in production code.
public protocol JWTToolsDateProvider
{
    func now() -> Date
}

/// Class with JWT related functionality.
///
/// Current implementation supports the "ES256K" and "ES256K-R" algorithms.  It's forgiving and does not check the
/// "alg" JWT header field.
public struct JWTTools
{
    private struct Constants
    {
        static let signatureSize = 64
        static let timeSkew = TimeInterval(5 * 60)
    }

    private static var universalResolver: UniversalDIDResolver?
    {
        var resolver = UniversalDIDResolver()

        // TODO: Make this endpoint configurable.
        let ethrResolver = EthrDIDResolver(rpc: JsonRPC(rpcURL: Networks.shared.rinkeby.rpcUrl))
        let uPortResolver = UPortDIDResolver()
        try! resolver.register(resolver: ethrResolver)
        try! resolver.register(resolver: uPortResolver)

        return resolver
    }

    /// Optional source of current date.
    ///
    /// Allows verification of expired JWT (in tests and demo code). Do not set `dataProvider` in production code!
    public static var dateProvider: JWTToolsDateProvider?

    private static func now() -> Date
    {
        if let dateProvider = dateProvider
        {
            return dateProvider.now()
        }
        else
        {
            return Date()
        }
    }
    
    
    
    public static func create(payload: [String: Any],
                              issuerDID: String,
                              signer: Signer,
                              expiresIn: Int64,
                              completionHandler: @escaping (_ fullJWT: String?, _ error: Error?) -> Void)
    {
        // Construct header and convert to  base64
        let headerArgs: [String: Any] = ["typ":"JWT", "alg":"ES256K-R"]
        let headerData: Data = try! JSONSerialization.data(withJSONObject: headerArgs,
                                                               options: JSONSerialization.WritingOptions.init(rawValue: 0))
        let headerString = headerData.base64EncodedString().replacingOccurrences(of: "=", with: "")
        let headerBase64Url = JWTTools.base64ToBase64Url(base64String: headerString)
            
            
        // Extract issuer address - possibly check if its equal to address in signer impl
        let issuerDidArray = issuerDID.split(separator: ":")
        let issuerDidAddress = String(issuerDidArray[2])
            
        // Fill out payload with iss, iat, and exp
        var filledOutPayload = payload
        filledOutPayload["iss"] = issuerDidAddress
        filledOutPayload["iat"] = Int64(now().timeIntervalSince1970)
        if filledOutPayload["exp"] == nil
        {
            filledOutPayload["exp"] = Int64(now().timeIntervalSince1970) + expiresIn
        }
            
        // Convert filled out payload to base64
        let payloadData: Data = try! JSONSerialization.data(withJSONObject: filledOutPayload, options: JSONSerialization.WritingOptions.prettyPrinted)
        let payloadBase64 = payloadData.base64EncodedString().replacingOccurrences(of: "=", with: "")
        let payloadBase64Url = JWTTools.base64ToBase64Url(base64String: payloadBase64)
            
        // Join the header/payload and base64 encode for signing
        let signingInput = [headerBase64Url, payloadBase64Url].joined(separator: ".")
        let signingData = signingInput.data(using: .utf8)
        let signingInputBase64 = signingData?.base64EncodedString().replacingOccurrences(of: "=", with: "")
        let signingInputBase64Url = JWTTools.base64ToBase64Url(base64String: signingInputBase64!)
            
        // Sign jwt
        signer.signJWT(rawPayload: signingInputBase64Url)
        { (sig,error) in
            guard error == nil else
            {
                completionHandler(nil, error)
                return
            }
            do
            {
                if(sig != nil)
                {
                    let rData = try! (sig!["r"] as! String).decodeBase64()
                    let sData = try! (sig!["s"] as! String).decodeBase64()
                    let vNum = [sig!["v"] as! UInt8]
                    let vData: Data = Data(vNum)
                    let rsv = rData + sData + vData
                    let sigBase64 = rsv.base64EncodedString().replacingOccurrences(of: "=", with: "")
                    let sigBase64Url = JWTTools.base64ToBase64Url(base64String: sigBase64)
                    let fullJWT = [headerBase64Url, payloadBase64Url, sigBase64Url].joined(separator: ".")
                    completionHandler(fullJWT, error)
                }
            }
        }
    }

    /// Decodes a secured JWT into its three parts.
    ///
    /// This function only accepts secured (i.e. containing a signature
    ///
    /// - Parameters:
    ///     - jwt: The JWT string to be decoded.
    ///
    /// - Throws: An error if one of the decoding checks or steps fails.
    ///
    /// - Returns: The decoded header, payload, signature, plus the signed data (i.e. "<header>.<payload>")
    public static func decode(jwt: String) throws -> (header: JWTHeader,
                                                      payload: JWTPayload,
                                                      signature: Data,
                                                      signedData: Data)
    {
        let parts = jwt.components(separatedBy: ".")
        try validate(parts: parts)

        let headerBase64 = try JWTTools.base64urlToBase64(base64url: parts[0])
        let payloadBase64 = try JWTTools.base64urlToBase64(base64url: parts[1])
        let signatureBase64 = try JWTTools.base64urlToBase64(base64url: parts[2])

        let header = try JWTHeader(dictionary: JWTTools.base64ToDictionary(base64: headerBase64))
        let payload = try JWTPayload(dictionary: JWTTools.base64ToDictionary(base64: payloadBase64))
        guard let signature = Data(base64Encoded: signatureBase64) else
        {
            throw JWTToolsError.malformedNotBase64
        }

        // TODO: This check only covers the two currently supported algorithms.  This check should be tied to the
        //       JWT header's "alg" field.
        guard signature.count == Constants.signatureSize ||       // Covers "ES256K".
              signature.count == Constants.signatureSize + 1 else // Covers "ES256K-R".
        {
            throw JWTToolsError.invalidSignatureSize(signature.count)
        }

        return (header, payload, signature, Data((parts[0] + "." + parts[1]).utf8))
    }

    /// Verifies a JWT asynchronously on background thread.
    ///
    /// Verification involves resolving the DID, which is the `iss` payload field, over internet. This is done on a
    /// background thread, so it's fine to call this function on the main thread.
    ///
    /// DID types currently supported are uPort and Ethereum.
    ///
    /// - Parameters:
    ///   - jwt: The JWT string.
    ///   - completionHandler: Called when the verification result becomes available. This handler is called on the
    ///                        main thread.
    ///   - payload: When verification is succesful, the JWT's payload is returned.
    ///   - error: The error is something went wrong.
    public static func verify(jwt: String, completionHandler: @escaping (_ payload: JWTPayload?, _ error: Error?) -> Void)
    {
        do
        {
            let (_, payload, signature, signedData) = try JWTTools.decode(jwt: jwt)

            try JWTTools.checkDates(payload: payload)

            JWTTools.universalResolver?.resolveAsync(did: payload.iss)
            { (document, error) in
                guard error == nil else
                {
                    completionHandler(nil, error)

                    return
                }

                guard let document = document else
                {
                    completionHandler(nil, JWTToolsError.missingDidDocument)

                    return
                }

                var matchCount = 0
                do
                {
                    let hash = signedData.sha256()
                    let signatures = JWTTools.makeCompactSignatures(signature: signature)
                    try signatures.forEach
                    { signature in
                        try matchCount += JWTTools.matchPublicKeys(publicKeys: document.publicKey,
                                                                   signature: signature,
                                                                   hash: hash)
                    }
                }
                catch
                {
                    completionHandler(nil, error)

                    return
                }

                if matchCount > 0
                {
                    completionHandler(payload, nil)
                }
                else
                {
                    completionHandler(nil, JWTToolsError.failedToVerify)
                }
            }
        }
        catch
        {
            completionHandler(nil, error)
        }
    }

    private static func makeCompactSignatures(signature: Data) -> [Data]
    {
        // CoreEthereum's compact signature format requires recovery byte at index 0 (not 64).
        var signatures = [Data]()
        if (signature.count == Constants.signatureSize)
        {
            signatures.append([27] + signature)
            signatures.append([28] + signature)
        }
        else
        {
            signatures.append([signature[64]] + signature[0 ..< Constants.signatureSize])
        }

        return signatures
    }

    private static func matchPublicKeys(publicKeys: [PublicKeyEntry], signature: Data, hash: Data) throws -> Int
    {
        var matchCount = 0

        try publicKeys.forEach
        { publicKey in
            if let keyData = try (publicKey.publicKeyHex?.decodeFullHex() ??
                publicKey.publicKeyBase64?.decodeBase64() ??
                publicKey.publicKeyBase58?.decodeBase58())
            {
                if let key = BTCKey.verifyCompactSignature(signature, forHash: hash)
                {
                    matchCount += (keyData == Data(referencing: key.publicKey)) ? 1 : 0
                }
            }
        }

        return matchCount
    }

    private static func validate(parts: [String]) throws
    {
        guard parts.count == 3 else
        {
            throw JWTToolsError.malformedNotThreeParts
        }

        guard !parts[0].isEmpty else
        {
            throw JWTToolsError.malformedEmptyHeader
        }

        guard !parts[1].isEmpty else
        {
            throw JWTToolsError.malformedEmptyPayload
        }

        guard !parts[2].isEmpty else
        {
            throw JWTToolsError.malformedEmptySignature
        }
    }

    private static func checkDates(payload: JWTPayload) throws
    {
        if let issueDate = payload.iat, issueDate > (now() + Constants.timeSkew)
        {
            throw JWTToolsError.notValidIssuedInFuture
        }

        if let expiryDate = payload.exp, expiryDate <= (now() - Constants.timeSkew)
        {
            throw JWTToolsError.notValidPastExpiryDate
        }
    }

    private static func base64urlToBase64(base64url: String) throws -> String
    {
        let regex = try NSRegularExpression(pattern: "^[a-zA-Z0-9_-]*$")
        guard regex.numberOfMatches(in: base64url, range: NSRange(location: 0, length: base64url.count)) == 1 else
        {
            throw JWTToolsError.malformedNotBase64Url
        }

        var base64 = base64url.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")

        if base64.count % 4 != 0
        {
            base64.append(String(repeating: "=", count: 4 - (base64.count % 4)))
        }

        return base64
    }
    
    private static func base64ToBase64Url(base64String: String) -> String
    {
        let base64 = base64String.replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        return base64
    }

    private static func base64ToDictionary(base64: String) throws -> [String: Any]
    {
        guard let data = Data(base64Encoded: base64) else
        {
            throw JWTToolsError.malformedNotBase64
        }

        guard String(data: data, encoding: .utf8) != nil else
        {
            throw JWTToolsError.malformedNotUtf8
        }

        do
        {
            let object = try JSONSerialization.jsonObject(with: data)

            guard let dictionary = object as? [String : Any] else
            {
                throw JWTToolsError.malformedNotDictionary
            }

            return dictionary
        }
        catch
        {
            throw JWTToolsError.deserializationError(error.localizedDescription)
        }
    }
}
