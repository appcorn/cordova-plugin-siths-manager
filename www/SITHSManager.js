
var cordova = require('cordova'),
    exec = require('cordova/exec');

var SITHSManager = function () {
    this.stateChannel = cordova.addWindowEventHandler('sithsstatechange');
    this.debugChannel = cordova.addWindowEventHandler('sithsdebug');

    this.stateChannel.onHasSubscribersChange = SITHSManager.onHasSubscribersChange;
    this.debugChannel.onHasSubscribersChange = SITHSManager.onHasSubscribersChange;
}

// Fetches the current SITHSManager state and calls the success callback. If the state could not be fetched, the error callback is called.
SITHSManager.prototype.getState = function (successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'SITHSManager', 'getState', []);
}

SITHSManager.onHasSubscribersChange = function () {
    var handlers = manager.stateChannel.numHandlers + manager.debugChannel.numHandlers;

    // If we just registered the first handler, make sure native listener is started.
    if (this.numHandlers === 1 && handlers === 1) {
        exec(manager._state, manager._stateError, 'SITHSManager', 'start', []);
        exec(manager._debug, manager._debugError, 'SITHSManager', 'startDebug', []);
    } else if (handlers === 0) {
        exec(null, null, 'SITHSManager', 'stop', []);
        exec(null, null, 'SITHSManager', 'stopDebug', []);
    }
};

SITHSManager.prototype._state = function (info) {
    if (info) {
      cordova.fireWindowEvent('sithsstatechange', info);
    }
}

SITHSManager.prototype._stateError = function (e) {
    console.log('Error subscribing to SITHSManager state: ' + e);
};

SITHSManager.prototype._debug = function (message) {
    if (message) {
      cordova.fireWindowEvent('sithsdebug', message);
    }
}

SITHSManager.prototype._debugError = function (e) {
    console.log('Error subscribing to SITHSManager debug messages: ' + e);
};

var manager = new SITHSManager();

module.exports = manager;
