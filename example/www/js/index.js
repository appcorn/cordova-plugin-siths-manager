var app = {
    // Application Constructor
    initialize: function() {
        this.bindEvents();
    },
    // Bind Event Listeners
    //
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        // Subscribe to state changes
        window.addEventListener('sithsstatechange', logState, false);
        // Subscribe to debug messages
        window.addEventListener('sithsdebug', logDebugMessage, false);
    
        // Get initial state and write to screen
        sithsmanager.getState(function(info) {
            logState(info);
        }, function(error) {
            console.log(error);
        });
    }
};

// Log SITHSManager state info object to screen.
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

// Log SITHSManager debug message to screen.
function logDebugMessage(info) {
    var parent = document.getElementById("debuglog");
    parent.innerHTML = '<span>' + info.message + '</span><br />' + parent.innerHTML;
}
