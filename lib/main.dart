import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'device_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final title = 'BLE Scan & Connection Demo';

  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResultList = [];
  bool _isScanning = false;

  @override
  initState() {
    super.initState();
    // Initialize Bluetooth
    initBle();
  }

  void initBle() {
    // Listener to get BLE scan status
    flutterBlue.isScanning.listen((isScanning) {
      _isScanning = isScanning;
      setState(() {});
    });
  }

  /*
  Scan start/stop function
  */
  scan() async {
    if (!_isScanning) {
      // If not scanning
      // Delete the previously scanned list
      scanResultList.clear();
      // Start scanning, timeout 4 seconds
      flutterBlue.startScan(timeout: Duration(seconds: 4));
      // scan result listener
      flutterBlue.scanResults.listen((results) {
        scanResultList = results;
        // Update UI
        setState(() {});
      });
    } else {
      // if scanning, stop scanning
      flutterBlue.stopScan();
    }
  }

  /*
  From here, functions for output by device
  */
  /*Device signal value widget  */
  Widget deviceSignal(ScanResult r) {
    return Text(r.rssi.toString());
  }

  /*Device MAC Address Widget */
  Widget deviceMacAddress(ScanResult r) {
    return Text(r.device.id.id);
  }

  /* device's people widget  */
  Widget deviceName(ScanResult r) {
    String name = '';

    if (r.device.name.isNotEmpty) {
      // If device.name has a value
      name = r.device.name;
    } else if (r.advertisementData.localName.isNotEmpty) {
      // If advertisementData.localName has a value
      name = r.advertisementData.localName;
    } else {
      // Without both, I don't know the name...
      name = 'N/A';
    }
    return Text(name);
  }

  /* BLE Icon Widget */
  Widget leading(ScanResult r) {
    return const CircleAvatar(
      backgroundColor: Colors.cyan,
      child: Icon(
        Icons.bluetooth,
        color: Colors.white,
      ),
    );
  }

  /* Function called when a device item is tapped */
  void onTap(ScanResult r) {
    //just print the name
    print('${r.device.name}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeviceScreen(device: r.device)),
    );
  }

  /* Device Item Widget */
  Widget listItem(ScanResult r) {
    return ListTile(
      onTap: () => onTap(r),
      leading: leading(r),
      title: deviceName(r),
      subtitle: deviceMacAddress(r),
      trailing: deviceSignal(r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        /*output device list*/
        child: ListView.separated(
          itemCount: scanResultList.length,
          itemBuilder: (context, index) {
            return listItem(scanResultList[index]);
          },
          separatorBuilder: (BuildContext context, int index) {
            return Divider();
          },
        ),
      ),
      /*Search for devices or stop searching */
      floatingActionButton: FloatingActionButton(
        onPressed: scan,
        // If scanning is in progress, a stop icon is displayed, while in a stopped state, a search icon is displayed.
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}