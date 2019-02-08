# uPort iOS SDK

This is the **uPort** SDK for iOS.

## Using the SDK

The [README of the **uPort** demo app](https://github.com/uport-project/uport-ios-demo/blob/master/README.md) describes how to install the SDK and use it in your app.

## Structure

This SDK consists of a number of iOS frameworks that import each other in a simple hierarchy.

The use of frameworks was dictated by our choice for Carthage. A framework is a self-contained unit that can be easily built and imported by an app or other framework; we like that simplicity.

Let's have a look at the SDK frameworks:
* At the 'bottom' is our [OpenSSL](https://github.com/uport-project/uport-ios-openssl) framework. This is a stripped down version of the well know OpenSSL implementation in C, which we moulded into an iOS framework.
* Above is our [Core Ethereum](https://github.com/uport-project/uport-ios-core-eth) framework. This is a copy of [wjmelements/CoreEthereum](https://github.com/wjmelements/CoreEthereum) from which we split off OpenSSL, which is now imported as a framework. (And for completeness, this CoreEthereum was is a modification of [CoreBitcoin](https://github.com/oleganza/CoreBitcoin))
* Then our [UPTEthereumSigner](https://github.com/uport-project/UPTEthereumSigner) framework imports our Core Ethereum. This signer is also used in the [native iOS layer of our React Native mobile app](https://github.com/uport-project/uport-mobile/tree/develop/ios). (This framework also uses [Square/Valet](https://github.com/Square/Valet), a library for secure data storage.)
* Finally, this iOS SDK framework imports our UPTEthereumSigner. This SDK also imports [BigInt](https://github.com/attaswift/BigInt), [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift), and [Swift-Sodium](https://github.com/jedisct1/swift-sodium). This framework adds a lot of functionality that is built on the imported frameworks listed above.

## Contributing

If you wish to contribute, please first discuss your ideas by opening an issue or sending an email.

### Code formatting

We believe in strict code formatting that aids readability and creates a consistent look. We follow many generally accepted rules like placing spaces around binary operator (e.g., `a + b = c`), indenting by 4 spaces, etcetera. But we also do important things differently:

* Opening curly braces `{` are always on an empty line. So it's never placed at the end of a line. This also applies to Swift `guard` statements.
* Every block, even if it's one statement is enclosed by `{` and `}`
* Closing curly braces `}` are also always on an empty line. Again, without exceptions.
* The `case` and `default` clauses of a `switch` statement, are all indented the same amount; so they appear underneath each other.
* Because of their importance, `return` statement may not appear at the bottom of a one or more statements. In such cases there must be an empty line above.
* Statements may not appear immediately under a `}`-line. In such a case there must be an empty line in between. (Of course multiple `}`-lines, which is not a statement, underneath each other are fine.)
* The opening `{` of a completion handler must be indented all the way to the left, to the indent level of its enclosing block. So if you'd have `let someValue = someFunc(_ completionHandler:`, the `{` must appear on the next line under the `l` from `let`. This rule prevents big indentation gaps and the resulting long lines.
* Literals get some extra spaces, for example: `@{ "key" : "value" }`.
* Complex literals are formatted like code with `[`, `]`, `{`, and `}` on separate lines and indented with 4 spaces for each level.
* Lines are no longer than 120 characters. If needed (parts of) long expressions/statements are replaced by helper variables defined in the line above. In rare cases a line may be a little longer if there's no other easy way.
* Place statements/lines together in small logical groups and add an empty line between these groups.

[Here's an example of how that looks](https://github.com/uport-project/uport-ios-sdk/blob/master/UPort/EthrDID/EthrDIDResolver.swift).

Some legacy and generated source files are not fully formatted according to these rules. But for new code these rules apply.

## License

The **uPort** iOS SDK is released under the [Apache-2.0](LICENSE.txt).
