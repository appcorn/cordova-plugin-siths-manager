import Foundation

extension SITHSManagerState {
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
                    "derData": certificate.derData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)),
                    "cardNumber": certificate.cardNumber,
                    "serialNumber": certificate.serialNumber.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0)),
                    "serialString": certificate.serialString,
                    "subject": certificate.subject.reduce([String:String]()) { dict, pair in
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
    var callbackId: String?
    var debugCallbackId: String?

    var manager: SITHSManager?

    override func pluginInitialize() {
        manager = SITHSManager()
        super.pluginInitialize()
    }

    private func sendState(state: SITHSManagerState) {
        guard let callbackId = callbackId else {
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:state.dictionaryRepresentation())
        result.keepCallback = true
        commandDelegate!.sendPluginResult(result, callbackId: callbackId)
    }

    func start(command: CDVInvokedUrlCommand) {
        callbackId = command.callbackId

        manager?.stateClosure = { [weak self] state in
            self?.sendState(state)
        }
    }

    func stop(command: CDVInvokedUrlCommand) {
        if let callbackId = callbackId {
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            result.keepCallback = false
            commandDelegate!.sendPluginResult(result, callbackId: callbackId)
        }
        callbackId = nil
        manager?.stateClosure = nil
    }

    private func sendDebug(message: String) {
        guard let callbackId = debugCallbackId else {
            return
        }

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsDictionary:["message": message])
        result.keepCallback = true
        commandDelegate!.sendPluginResult(result, callbackId: callbackId)
    }

    func startDebug(command: CDVInvokedUrlCommand) {
        debugCallbackId = command.callbackId

        manager?.debugLogClosure = { [weak self] message in
            self?.sendDebug(message)
        }
    }

    func stopDebug(command: CDVInvokedUrlCommand) {
        if let callbackId = debugCallbackId {
            let result = CDVPluginResult(status: CDVCommandStatus_OK)
            result.keepCallback = false
            commandDelegate!.sendPluginResult(result, callbackId: callbackId)
        }
        debugCallbackId = nil
        manager?.stateClosure = nil
    }



    func echo(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        let msg = command.arguments[0] as? String ?? ""

        if msg.characters.count > 0 {
            /* UIAlertController is iOS 8 or newer only. */
            let toastController: UIAlertController =
                UIAlertController(
                    title: "",
                    message: msg,
                    preferredStyle: .Alert
            )

            self.viewController?.presentViewController(
                toastController,
                animated: true,
                completion: nil
            )

            let duration = Double(NSEC_PER_SEC) * 3.0

            dispatch_after(
                dispatch_time(
                    DISPATCH_TIME_NOW,
                    Int64(duration)
                ),
                dispatch_get_main_queue(),
                {
                    toastController.dismissViewControllerAnimated(
                        true,
                        completion: nil
                    )
                }
            )

            pluginResult = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAsString: msg
            )
        }

        self.commandDelegate!.sendPluginResult(
            pluginResult,
            callbackId: command.callbackId
        )
    }
}