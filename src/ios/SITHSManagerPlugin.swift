import Foundation

extension SITHSManagerState {

    /// Creates a dictionary representation of the state, ready to be sent in the JS bridge.
    ///
    /// - Returns: A dictionary representation of the state enum value, including more detailed information when available.
    func dictionaryRepresentation() -> [String: Any] {
        let dictionary: [String: Any]

        // Switch for the different states
        switch self {
        case .unknown:
            dictionary = [
                "state": "unknown"
            ]
        case .readingFromCard:
            dictionary = [
                "state": "readingFromCard"
            ]
        case .error(let error):
            switch error {
            case .smartcardError(let message, let code):
                dictionary = [
                    "state": "error",
                    "errorMessage": message,
                    "errorCode": code
                ]
            case .internalError(let error):
                dictionary = [
                    "state": "error",
                    "errorMessage": "\(error)",
                    "errorCode": NSNull()
                ]
            }

        case .readerDisconnected:
            dictionary = [
                "state": "readerDisconnected"
            ]
        case .unknownCardInserted:
            dictionary = [
                "state": "unknownCardInserted"
            ]
        case .cardWithoutCertificatesInserted:
            dictionary = [
                "state": "cardWithoutCertificatesInserted"
            ]
        case .readerConnected:
            dictionary = [
                "state": "readerConnected"
            ]
        case .cardInserted(let certificates):
            // We have a set of at least one SITHS certificate (see the `SITHSCardCertificate` struct for more information)
            let certificates: [[String: Any]] = certificates.map { (certificate: SITHSCardCertificate) in
                return [
                    "derData": certificate.derData.base64EncodedString(),
                    "cardNumber": certificate.cardNumber,
                    "serialNumber": certificate.serialNumber.base64EncodedString(),
                    "serialString": certificate.serialString,
                    "subject": certificate.subject.reduce([String:String]()) { dict, pair in
                        var subject = dict
                        subject[pair.0.dictionaryKeyRepresentation()] = pair.1
                        return subject
                    }
                ]
            }

            dictionary = [
                "state": "cardInserted",
                "certificates": certificates
            ]
        }

        return dictionary
    }

}

extension ASN1ObjectIdentifier {

    /// Creates a camel cased string representation of the object identifier, suitable for a dictionary key.
    ///
    /// - Returns: A basic string representation of the enum value.
    func dictionaryKeyRepresentation() -> String {
        // Switch for the different states
        switch self {
        case .undefined(_):
            return "undefined"
        case .sha1WithRSAEncryption:
            return "SHA1WithRSAEncryption"
        case .countryName:
            return "countryName"
        case .organizationName:
            return "organizationName"
        case .commonName:
            return "commonName"
        case .surname:
            return "surname"
        case .givenName:
            return "givenName"
        case .serialNumber:
            return "serialNumber"
        case .title:
            return "title"
        case .keyUsage:
            return "keyUsage"
        case .subjectDirectoryAttributes:
            return "subjectDirectoryAttributes"
        case .cardNumber:
            return "cardNumber"
        }
    }

}

@objc(SITHSManagerPlugin) class SITHSManagerPlugin : CDVPlugin {

    /// Cordova plugin callback ID for state change subscription.
    var callbackId: String?

    /// Cordova plugin callback ID for debug message subscription.
    var debugCallbackId: String?

    /// The main SITHSManager instance.
    var manager: SITHSManager?


    // MARK: Initialization

    override func pluginInitialize() {
        manager = SITHSManager()
        super.pluginInitialize()
    }


    // MARK: Public methods, exposed in JS bridge

    /// Fetches the current SITHSManager state and calls the success callback. If the state could not be fetched, the error callback is called.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func getState(_ command: CDVInvokedUrlCommand) {
        guard let state = manager?.state else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR)
            commandDelegate!.send(result, callbackId: command.callbackId)
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:state.dictionaryRepresentation())
        commandDelegate!.send(result, callbackId: command.callbackId)
    }

    /// Starts subscribing the SITHSManager state, continously calling the success callback on changes.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func start(_ command: CDVInvokedUrlCommand) {
        callbackId = command.callbackId

        manager?.stateClosure = { [weak self] state in
            self?.send(state: state)
        }
    }

    /// Stops the subscription of SITHSManager state changes.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func stop(_ command: CDVInvokedUrlCommand) {
        if let callbackId = callbackId {
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            result?.keepCallback = false
            commandDelegate!.send(result, callbackId: callbackId)
        }
        callbackId = nil
        manager?.stateClosure = nil
    }

    /// Starts subscribing the SITHSManager debug log messages, continously calling the success callback on new messages.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func startDebug(_ command: CDVInvokedUrlCommand) {
        debugCallbackId = command.callbackId

        manager?.debugLogClosure = { [weak self] message in
            self?.sendDebug(message: message)
        }
    }

    /// Stops the subscription of SITHSManager debug log messages.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func stopDebug(_ command: CDVInvokedUrlCommand) {
        if let callbackId = debugCallbackId {
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            result?.keepCallback = false
            commandDelegate!.send(result, callbackId: callbackId)
        }
        debugCallbackId = nil
        manager?.stateClosure = nil
    }


    // MARK: Private methods

    /// Sends the provided state via the subscription callback.
    ///
    /// - Parameter state: The default Cordova Invocation Command.
    private func send(state: SITHSManagerState) {
        guard let callbackId = callbackId else {
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:state.dictionaryRepresentation())
        result?.keepCallback = true
        commandDelegate!.send(result, callbackId: callbackId)
    }

    /// Sends the provided debug message via the subscription callback.
    ///
    /// - Parameter state: The default Cordova Invocation Command.
    private func sendDebug(message: String) {
        guard let callbackId = debugCallbackId else {
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs:["message": message])
        result?.keepCallback = true
        commandDelegate!.send(result, callbackId: callbackId)
    }

}
