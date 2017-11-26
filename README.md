---
title: SITHSManager
description: SITHSManager Apache Cordova plugin
---

# cordova-plugin-siths-manager

This plugin provides an implementation of the [SITSHManager](https://github.com/appcorn/SITHSManager) Swift iOS module, used for reading and parsing the basic contents of Swedish SITHS identification smart cards with a Precise Biometrics card reader.

This plugin adds the following two events to the `window` object:

* `sithsstatechange`
* `sithsdebug`

Applications may use `window.addEventListener` to attach an event listener for any of the above events after the `deviceready` event fires.

This plugin also adds the following method to the `sithsmanager` object:

* `getState(successCallback, errorCallback)`

## Installation

First, add the plugin to your application, either by using the command line tools (`cordova` or `phonegap`):

    cordova plugin add cordova-plugin-siths-manager

Or by adding the plugin to your `config.xml` file:

    <plugin name="cordova-plugin-siths-manager" spec="~1.0.0" />

## Example project

There is an example project in the `example` directory. This project has been successfully built and tested with [PhoneGap Build](https://build.phonegap.com/).

## State object

The state info object this plugin returns has the __state__ property that can be one of the following state strings:

- `"unknown"` The state of the reader has not yet been determined. This is the initial state.
- `"readingFromCard"` The SITHS Manager is currently reading from an inserted SITHS card, parsing any certificates found.
- `"error"` An error has occured. In this state, the state info object also contains the following properties:
  - __errorMessage__: An descriptive error message.
  - __errorCode__: A numeric error code passed down from the Precise iOS SDK. Only present on errors in the Precise SDK and not internal errors SITHSManager.
- `"readerDisconnected"` There is no card reader connected.
- `"unknownCardInserted"` There is a smart card inserted to a connected reader, but it does not appear to be a SITHS Card.
- `"cardWithoutCertificatesInserted"` There is a SITHS Card inserted to a connected reader, but the SITHS Manager failed to read any certificates.
- `"readerConnected"` There is a reader connected, but no inserted card.
- `"cardInserted"` The reader is connected, and there is a SITHS card, containing at least one certificate. The parsed certificates are accessed in the __certificates__ state info property (an array guaranteed to have at least one element). The certificates has the following properties:
  - __derData__: The raw DER data, as a Base64 encoded string, that was parsed to result in the certificate.
  - __cardNumber__: The SITHS card number as an unformatted string, for example `"9752278900000000000"`
  - __serialNumber__: The serial raw X.509 serial number data, as a Base64 encoded string. By specification, this data represents a signed integer of maximum 20 bytes.

    NOTE: This is not to be confused with the HSAID (`"SE000000000000-0000"`), that is found on the subject OID `serialNumber`.
  - __serialString__: The `serialNumber` value represented as a uppercase HEX string without byte separators, example: `"63D0DAC6F31D6BE4C68658C487863CC0"`

    NOTE: This is not to be confused with the HSAID (`"SE000000000000-0000"`), that is found on the subject OID `serialNumber`.
  - __subject__: All the X.509 subject string fields contained in the certificate, contained in properties on the subject property. Usually, these card holder subject OIDs are present in a SITHS card:
    - __surname__: The surename, example: `"Alléus"`
    - __givenName__: The given name, example: `"Martin Nils"`
    - __title__: The title, example: `"CTO"`
    - __countryName__: The country name string, example: `"se"`
    - __organizationName__: The organization name, example: `"Appcorn AB"`
    - __commonName__: The common name for the card holder, example: `"Martin Alléus"`
    - __serialNumber__: The card HSAID, in its proper form, example: `"SE000000000000-0000"`

## getState function

The `getState(successCallback, errorCallback)` function can be called to manually fetch the SITHSManager state. This is for example useful for fetching the initial state on app launch.

### Example

    sithsmanager.getState(function(info) {
        var parent = document.getElementById("state");
        parent.innerHTML = '<b>State:</b> ' + info.state;
    }, function(error) {
        console.log(error);
    });

## sithsstatechange event

Fires when the state of the SITHSManager changes. Provides a State object containing state information.

### Example

    window.addEventListener('sithsstatechange', logState, false);

    function logState(info) {
        var message;
        var color;
    
        switch (info.state) {
        case "unknown":
            message = "Unknown";
            color = "black";
            break;
        case "readingFromCard":
            message = "Reading From Card...";
            color = "black";
            break;
        case "error":
            if (info.errorCode != null) {
                message = "Error (smartcard) " + info.errorCode + ": " + info.errorMessage;
            } else {
                message = "Error (internal): " + info.errorMessage;
            }
            color = "red";
            break;
        case "readerDisconnected":
            message = "Reader Disconnected";
            color = "red";
            break;
        case "unknownCardInserted":
            message = "Unknown Card Inserted";
            color = "red";
            break;
        case "cardWithoutCertificatesInserted":
            message = "Card Without Certificates Inserted";
            color = "red";
            break;
        case "readerConnected":
            message = "Reader Connected";
            color = "blue";
            break;
        case "cardInserted":
            message = "Card Inserted, certificates:";
            for (i = 0; i < info.certificates.length; ++i) {
                var certificate = info.certificates[i];
                message += "<br />• " + certificate.cardNumber + " " + certificate.serialString + " " + certificate.subject.commonName;
            }
            color = "green";
            break;
        }
    
        var parent = document.getElementById("debuglog");
        parent.innerHTML = '<b>State:</b> <span style="color: ' + color + '">' + message + '</span><br />' + parent.innerHTML;
    }

## sithsdebug event

Fires when SITHSManager emmits debug messages. Can be helpful to troubleshoot any issues, but it's a bit verbose and can somethings be hard to follow. Provides a debug info object containing a message at the __message__ property.

### Example

    window.addEventListener('sithsdebug', logDebugMessage, false);

    function logDebugMessage(info) {
        var parent = document.getElementById("debuglog");
        parent.innerHTML = '<span>' + info.message + '</span><br />' + parent.innerHTML;
    }

## Supported Platforms

- iOS

## Author

Martin Alléus, Appcorn AB, martin@appcorn.se

## License

Made by [Appcorn AB](https://www.appcorn.se) for [Svensk e-identitet](http://www.e-identitet.se).

Copyright (c) 2017 [Svensk e-identitet AB](http://www.e-identitet.se). cordova-plugin-siths-manager is available under the MIT license. See the LICENSE file for more info.
