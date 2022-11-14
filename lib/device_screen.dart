import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DeviceScreen extends StatefulWidget {
  DeviceScreen({Key? key, required this.device}) : super(key: key);
  // Receive device information
  final BluetoothDevice device;

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  // flutterBlue
  FlutterBlue flutterBlue = FlutterBlue.instance;

  // connection status display string
  String stateText = 'Connecting';

  // connect button string
  String connectButtonText = 'Disconnect';

  // For saving the current connection state
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;

  // Connection status listener handle To release the listener when the screen is closed
  StreamSubscription<BluetoothDeviceState>? _stateListener;

  @override
  initState() {
    super.initState();
    // Registering a state-connected listener
    _stateListener = widget.device.state.listen((event) {
      debugPrint('event :  $event');
      if (deviceState == event) {
        // Ignore if status is the same
        return;
      }
      // Change connection state information
      setBleConnectionState(event);
    });
    // start connection
    connect();
  }

  @override
  void dispose() {
    // clear status lister
    _stateListener?.cancel();
    // disconnect
    disconnect();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      //Update only when the screen is mounted
      super.setState(fn);
    }
  }

  /* Connection status update */
  setBleConnectionState(BluetoothDeviceState event) {
    switch (event) {
      case BluetoothDeviceState.disconnected:
        stateText = 'Disconnected';
        // change button state
        connectButtonText = 'Connect';
        break;
      case BluetoothDeviceState.disconnecting:
        stateText = 'Disconnecting';
        break;
      case BluetoothDeviceState.connected:
        stateText = 'Connected';
        // change button state
        connectButtonText = 'Disconnect';
        break;
      case BluetoothDeviceState.connecting:
        stateText = 'Connecting';
        break;
    }
    //Save previous state events
    deviceState = event;
    setState(() {});
  }

  /* start connection */
  Future<bool> connect() async {
    Future<bool>? returnValue;
    setState(() {
      /* Change status display to Connecting */
      stateText = 'Connecting';
    });

    /* 
      Set timeout to 10 seconds (10000 ms) and turn off autoconnect
       For reference, if autoconnect is set to true, the connection may be delayed.
     */
    await widget.device
        .connect(autoConnect: false)
        .timeout(Duration(milliseconds: 10000), onTimeout: () {
      //timeout occurs
      // set returnValue to false
      returnValue = Future.value(false);
      debugPrint('timeout failed');

      //Change the connection state to disconnected
      setBleConnectionState(BluetoothDeviceState.disconnected);
    }).then((data) {
      if (returnValue == null) {
        // If returnValue is null, the connection is successful because timeout has not occurred.
        debugPrint('connection successful');
        returnValue = Future.value(true);
      }
    });

    return returnValue ?? Future.value(false);
  }

  /* Disconnect */
  void disconnect() {
    try {
      setState(() {
        stateText = 'Disconnecting';
      });
      widget.device.disconnect();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /* Disconnect */
        title: Text(widget.device.name),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /* connection status */
          Text('$stateText'),
          /* connect and disconnect button */
          OutlinedButton(
              onPressed: () {
                if (deviceState == BluetoothDeviceState.connected) {
                  /* Disconnect if connected */
                  disconnect();
                } else if (deviceState == BluetoothDeviceState.disconnected) {
                  /* Connect if disconnected */
                  connect();
                } else {}
              },
              child: Text(connectButtonText)),
        ],
      )),
    );
  }
}
