import Foundation

extension SITHSManagerState {

    /// Creates a dictionary representation of the state, ready to be sent in the JS bridge.
    ///
    /// - Returns: A dictionary representation of the state enum value, including more detailed information when available.
    func dictionaryRepresentation() -> [String: AnyObject] {
        let dictionary: [String: AnyObject]

        // Switch for the different states
        switch self {
        case .Unknown:
            dictionary = [
                "state": "Unknown"
            ]
        case .ReadingFromCard:
            dictionary = [
                "state": "ReadingFromCard"
            ]
        case .Error(let error):
            switch error {
            case .SmartcardError(let message, let code):
                dictionary = [
                    "state": "Error",
                    "errorMessage": message,
                    "errorCode": code
                ]
            case .InternalError(let error):
                dictionary = [
                    "state": "Error",
                    "errorMessage": "\(error)",
                    "errorCode": NSNull()
                ]
            }

        case .ReaderDisconnected:
            dictionary = [
                "state": "ReaderDisconnected"
            ]
        case .UnknownCardInserted:
            dictionary = [
                "state": "UnknownCardInserted"
            ]
        case .CardWithoutCertificatesInserted:
            dictionary = [
                "state": "CardWithoutCertificatesInserted"
            ]
        case .ReaderConnected:
            dictionary = [
                "state": "ReaderConnected"
            ]
        case .CardInserted(let certificates):
            // We have a set of at least one SITHS certificate (see the `SITHSCardCertificate` struct for more information)
            let certificates: [[String: AnyObject]] = certificates.map { certificate in
                return [
                    "DerData": certificate.derData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)),
                    "CardNumber": certificate.cardNumber,
                    "SerialNumber": certificate.serialNumber.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)),
                    "SerialString": certificate.serialString,
                    "Subject": certificate.subject.reduce([String:String]()) { dict, pair in
                        var subject = dict
                        subject["\(pair.0)"] = pair.1
                        return subject
                    }
                ]
            }

            dictionary = [
                "state": "CardInserted",
                "certificates": certificates
            ]
        }

        return dictionary
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
    func getState(command: CDVInvokedUrlCommand) {
        guard let state = manager?.state else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR)
            commandDelegate!.sendPluginResult(result, callbackId: command.callbackId)
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:state.dictionaryRepresentation())
        commandDelegate!.sendPluginResult(result, callbackId: command.callbackId)
    }

    /// Starts subscribing the SITHSManager state, continously calling the success callback on changes.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func start(command: CDVInvokedUrlCommand) {
        callbackId = command.callbackId

        manager?.stateClosure = { [weak self] state in
            self?.sendState(state)
        }
    }

    /// Stops the subscription of SITHSManager state changes.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func stop(command: CDVInvokedUrlCommand) {
        if let callbackId = callbackId {
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            result.keepCallback = false
            commandDelegate!.sendPluginResult(result, callbackId: callbackId)
        }
        callbackId = nil
        manager?.stateClosure = nil
    }

    /// Starts subscribing the SITHSManager debug log messages, continously calling the success callback on new messages.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func startDebug(command: CDVInvokedUrlCommand) {
        debugCallbackId = command.callbackId

        manager?.debugLogClosure = { [weak self] message in
            self?.sendDebug(message)
        }
    }

    /// Stops the subscription of SITHSManager debug log messages.
    ///
    /// - Parameter command: The default Cordova Invocation Command.
    func stopDebug(command: CDVInvokedUrlCommand) {
        if let callbackId = debugCallbackId {
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            result.keepCallback = false
            commandDelegate!.sendPluginResult(result, callbackId: callbackId)
        }
        debugCallbackId = nil
        manager?.stateClosure = nil
    }


    // MARK: Private methods

    /// Sends the provided state via the subscription callback.
    ///
    /// - Parameter state: The default Cordova Invocation Command.
    private func sendState(state: SITHSManagerState) {
        guard let callbackId = callbackId else {
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:state.dictionaryRepresentation())
        result.keepCallback = true
        commandDelegate!.sendPluginResult(result, callbackId: callbackId)
    }

    /// Sends the provided debug message via the subscription callback.
    ///
    /// - Parameter state: The default Cordova Invocation Command.
    private func sendDebug(message: String) {
        guard let callbackId = debugCallbackId else {
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:["message": message])
        result.keepCallback = true
        commandDelegate!.sendPluginResult(result, callbackId: callbackId)
    }

}
