
var cordova = require('cordova'),
    exec = require('cordova/exec');

var SITHSManager = function () {
  this.stateChannel = cordova.addWindowEventHandler('sithsstatechange');
  this.debugChannel = cordova.addWindowEventHandler('sithsdebug');

  this.stateChannel.onHasSubscribersChange = SITHSManager.onHasSubscribersChange;
  this.debugChannel.onHasSubscribersChange = SITHSManager.onHasSubscribersChange;
}

function handlers () {
    return manager.stateChannel.numHandlers + manager.debugChannel.numHandlers;
}

SITHSManager.onHasSubscribersChange = function () {
  // If we just registered the first handler, make sure native listener is started.
  if (this.numHandlers === 1 && handlers() === 1) {
      exec(manager._state, manager._stateError, 'SITHSManager', 'start', []);
      exec(manager._debug, manager._debugError, 'SITHSManager', 'startDebug', []);
  } else if (handlers() === 0) {
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
    console.log('Error initializing SITHSManager state: ' + e);
};

SITHSManager.prototype._debug = function (message) {
  if (message) {
    cordova.fireWindowEvent('sithsdebug', message);
  }
}

SITHSManager.prototype._debugError = function (e) {
    console.log('Error initializing SITHSManager debug: ' + e);
};

var manager = new SITHSManager();

module.exports = manager;

module.exports.echo = function(arg0, success, error) {
    exec(success, error, "SITHSManager", "echo", [arg0]);
};
