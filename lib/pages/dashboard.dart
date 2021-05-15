import 'dart:async';
import 'dart:convert';

import 'package:fingerprint/models/device_model.dart';
import 'package:fingerprint/models/fingerprint_model.dart';
import 'package:fingerprint/models/sensor_model.dart';
import 'package:fingerprint/pages/fingerprints_page.dart';
import 'package:fingerprint/pages/start_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_socket_channel/io.dart';

import '../utils.dart';
import 'sensor_page.dart';

class DashboardPage extends StatefulWidget {
  final IOWebSocketChannel channel;
  final StreamSubscription<dynamic> stream;
  const DashboardPage(this.channel, this.stream, {Key key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  IOWebSocketChannel channel;
  GlobalKey<ScaffoldState> _scaffold = GlobalKey<ScaffoldState>();
  String fingerprintId;
  int pageIndex = 0;
  List<int> indexes = [];

  bool isSensorAvailable = false;
  bool switchState = false;
  bool sensorState = false;
  bool engineState = false;

  bool sensorAvailableRequested = false;
  bool sensorInfoRequested = false;
  bool relayStateRequested = false;
  bool fingerprintsRequested = false;
  bool deviceInfoRequested = false;

  bool enrolling = false;
  bool enrollBegin = false;
  bool enrollError = false;
  String enrollMessage;
  Function enrollState;
  BuildContext enrollContext;

  bool deleting = false;
  bool deleteError = false;
  String deleteMessage;
  Function deleteState;
  BuildContext deleteContext;

  bool changing = false;
  bool changed = false;
  String changeError;
  Function changeState;
  BuildContext changeContext;

  SensorModel sensor = SensorModel();
  DeviceModel device = DeviceModel();
  List<FingerprintModel> fingerprints = [];


  List<String> titles = [
    "Dashboard",
    "Sensor info",
    "Fingerprints",
    "Device settings",
  ];

  void handleSensorSuccess(String message, dynamic data) {
    switch (message) {
      case "available":
        setState(() {
          isSensorAvailable = data == "1" ? true : false;
          sensorAvailableRequested = true;
        });
        if (isSensorAvailable) {
          channel.sink.add("sensor=state");
        }
        break;

      case "info":
        sensor = SensorModel.fromJSON(data);
        indexes = List.generate(int.parse(sensor.capacity), (index) => index).toList();
        indexes.remove(0);
        indexes.insert(indexes.length, indexes.length + 1);
        setState(() => sensorInfoRequested = true);
        break;

      case "state":
        setState(() => sensorState = data == "1" ? true : false);
        break;

      case "download":
        if (data == "done") {
          setState(() => fingerprintsRequested = true);
        }
        break;

      case "template":
        fingerprints.add(FingerprintModel.fromJSON(data));
        break;

      case "enroll":
        if (data == "enrolling") {
          enrollState(() {
            enrolling = true;
            enrollBegin = false;
          });
        } else if (data == "done") {
          enrollState(() {
            enrollMessage = "Fingerprint enrolled successfully.\nRefresh the page to get latest data";
            enrolling = false;
          });
          setState(() {
            fingerprints.add(FingerprintModel(id: fingerprintId, packet: "(Refresh to get latest data)", error: ""));
            // fingerprintId = null;
          });
        } else if (data == "cancel") {
          if (enrollContext != null) Navigator.pop(enrollContext);
        } else {
          enrollState(() {
            enrollMessage = data;
            enrollError = false;
          });
        }
        break;

      case "delete":
        if (data == "deleted") {
          Navigator.pop(deleteContext);
          showDeleteSuccessDialog("Fingerprint $fingerprintId deleted successfully");
          int index = fingerprints.indexWhere((f) => f.id == fingerprintId);
          fingerprintId = null;
          if (index != -1) {
            setState(() {
              fingerprints.removeAt(index);
            });
          }

        }
        break;
      default:
        break;
    }

  }

  void handleSensorError(String message, dynamic data) {
    switch (message) {
      case "enroll":
        if (enrollState != null) {
          enrollState((){
            enrollMessage = data;
            enrollError = true;
            enrolling = false;
            enrollBegin = false;
          });
        }
        break;
      case "delete":
        if (deleteState != null) {
          deleteState((){
            deleteMessage = data;
            deleteError = true;
            deleting = false;
          });
        }
        break;
      default:
        break;
    }
  }

  void handleRelaySuccess(String message, dynamic data) {

    switch (message) {
      case "state":
        setState(() {
          switchState = data == "1" ? true : false;
          relayStateRequested = true;
        });
        print(switchState);
        break;

    }

  }

  void handleEspSuccess(String message, dynamic data) {

    switch (message) {
      case "info":
        device = DeviceModel.fromJSON(data);
        setState(() {
          deviceInfoRequested = true;
        });
        break;

      case "set":
        if (data == "done") {
          if (changeContext != null) Navigator.pop(changeContext);
          changeError = null;
          changing = false;
          showChangeSuccessDialog();
        }
        break;
    }

  }

  void handleEspError(String message, dynamic data) {
    switch (message) {
      case "set":
        changeState(() {
          changeError = data;
        });
        break;
    }
  }

  void streamListener(dynamic d) {
    print("DASHBOARD PAGE");
    print(d);
    try {
      dynamic result = json.decode(d);
      String status = result["status"];
      String type = result["type"];
      String message = result["message"];
      dynamic data = result["data"];

      if (status == "success") {
        switch (type) {
          case "sensor":
            handleSensorSuccess(message, data);
            break;
          case "relay":
            handleRelaySuccess(message, data);
            break;
          case "esp":
            handleEspSuccess(message, data);
            break;
        }
      } else {

        switch (type) {
          case "sensor":
            handleSensorError(message, data);
            break;
          case "esp":
            handleEspError(message, data);
            break;
        }

      }

    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    widget.stream.onData(streamListener);
    widget.stream.onDone((){
      print("Stream done!");
      Utils.showReconnectDialog(context);
    });
    widget.stream.onError((error) {
      print(error.toString());
      Utils.showReconnectDialog(context);
    });
    channel = widget.channel;
    channel.sink.add("relay=state");
    channel.sink.add("sensor=available");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async{
        showLogoutDialog();
        return false;
      },
      child: Scaffold(
        key: _scaffold,
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(FontAwesomeIcons.bars),
            onPressed: () => _scaffold.currentState.openDrawer(),
          ),
          title: Text(titles[pageIndex]),
          actions: [
            if (pageIndex == 2)
              IconButton(
                icon: Icon(FontAwesomeIcons.plus),
                onPressed: !isSensorAvailable || !fingerprintsRequested ? null : (){
                  showEnrollDialog();
                },
              ),
          ],
        ),
        drawer: _buildDrawerWidget(),
        body: SizedBox.expand(
          child: sensorAvailableRequested && relayStateRequested ?
          _buildBodyWidget() :
          _buildLoadingWidget(),
        ),
      ),
    );
  }

  Widget _buildDrawerWidget() {
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              color: Colors.teal,
              alignment: Alignment.center,
              child: SafeArea(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.fingerprint, color: Colors.white, size: 50,),
                  SizedBox(height: 10),
                  Text("Fingerprint Switch", style: TextStyle(color: Colors.white, fontSize: 18),),
                  SizedBox(height: 5),
                  Text("© VinStudios", style: TextStyle(color: Colors.white, fontSize: 12),),
                ],
              )),
            ),
            Material(
              child: InkWell(
                child: Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(child: Text("Dashboard", style: TextStyle(fontSize: 16, color: pageIndex == 0 ? Colors.teal : Colors.black, fontWeight: pageIndex == 0 ? FontWeight.bold : FontWeight.normal),)),
                      SizedBox(width: 10),
                      Icon(FontAwesomeIcons.thLarge, color: Colors.teal, size: 18,),
                    ],
                  ),
                ),
                onTap: pageIndex == 0 ? null : (){
                  Navigator.pop(context);
                  setState(() {
                    pageIndex = 0;
                  });
                },
              ),
            ),
            Material(
              child: InkWell(
                child: Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(child: Text("Sensor information", style: TextStyle(fontSize: 16, color: isSensorAvailable ? pageIndex == 1 ? Colors.teal : Colors.black : Colors.grey.shade400, fontWeight: pageIndex == 1 ? FontWeight.bold : FontWeight.normal),)),
                      SizedBox(width: 10),
                      Icon(FontAwesomeIcons.infoCircle, color: isSensorAvailable ? Colors.teal : Colors.grey.shade400, size: 18,),
                    ],
                  ),
                ),
                onTap: !isSensorAvailable || pageIndex == 1 ? null : (){
                  Navigator.pop(context);
                  setState(() {
                    sensorInfoRequested = false;
                    sensor = SensorModel();
                    indexes = [];
                    pageIndex = 1;
                  });
                  channel.sink.add("sensor=info");
                },
              ),
            ),
            Material(
              child: InkWell(
                child: Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(child: Text("Fingerprints", style: TextStyle(fontSize: 16, color: isSensorAvailable ? pageIndex == 2 ? Colors.teal : Colors.black : Colors.grey.shade400, fontWeight: pageIndex == 2 ? FontWeight.bold : FontWeight.normal),)),
                      SizedBox(width: 10),
                      Icon(FontAwesomeIcons.fingerprint, color: isSensorAvailable ? Colors.teal : Colors.grey.shade400, size: 18,),
                    ],
                  ),
                ),
                onTap: !isSensorAvailable || pageIndex == 2 ? null : (){
                  Navigator.pop(context);
                  setState(() {
                    fingerprintsRequested = false;
                    fingerprints.clear();
                    pageIndex = 2;
                  });
                  channel.sink.add("sensor=download");
                },
              ),
            ),
            Material(
              child: InkWell(
                child: Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(child: Text("Device settings", style: TextStyle(fontSize: 16, color: pageIndex == 3 ? Colors.teal : Colors.black, fontWeight: pageIndex == 3 ? FontWeight.bold : FontWeight.normal),)),
                      SizedBox(width: 10),
                      Icon(FontAwesomeIcons.cogs, color: Colors.teal, size: 18,),
                    ],
                  ),
                ),
                onTap: pageIndex == 3 ? null : (){
                  Navigator.pop(context);
                  setState(() {
                    deviceInfoRequested = false;
                    pageIndex = 3;
                  });
                  channel.sink.add("esp=info");
                },
              ),
            ),
            Material(
              child: InkWell(
                child: Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(child: Text("App settings", style: TextStyle(fontSize: 16),)),
                      SizedBox(width: 10),
                      Icon(FontAwesomeIcons.cog, color: Colors.teal, size: 18,),
                    ],
                  ),
                ),
                onTap: (){

                },
              ),
            ),
            Material(
              child: InkWell(
                child: Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Expanded(child: Text("Logout", style: TextStyle(fontSize: 16),)),
                      SizedBox(width: 10),
                      Icon(FontAwesomeIcons.signOutAlt, color: Colors.teal, size: 18,),
                    ],
                  ),
                ),
                onTap: () async {
                  // channel.sink.add("esp=restart");
                  Navigator.pop(context);
                  showLogoutDialog();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildBodyWidget() {

    if (pageIndex == 0) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Material(
                    elevation: isSensorAvailable ? 3 : 0,
                    color: isSensorAvailable ? sensorState ? Colors.orange : Colors.white : Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: !isSensorAvailable || sensorState ? BorderSide.none : BorderSide(width: 2, color: Colors.orange)),
                    child: InkWell(
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        child: Text("Sensor is ${ isSensorAvailable ? sensorState ? "Enabled" : "Disabled" : "Unavailable"}", style: TextStyle(fontSize: 18, color: isSensorAvailable ? sensorState ? Colors.white : Colors.orange : Colors.grey.shade700, fontWeight: FontWeight.bold),),
                      ),
                      onTap: !isSensorAvailable ? null : (){
                        showStateDialog(
                          title: "${sensorState ? "Disable" : "Enable"} sensor?",
                          button: sensorState ? "Disable" : "Enable",
                          query: "sensor=state?${sensorState ? "0" : "1"}",
                          color: Colors.orange,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Material(
                    elevation: 3,
                    color: switchState ? Colors.indigo : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: switchState ? BorderSide.none : BorderSide(width: 2, color: Colors.indigo)),
                    child: InkWell(
                      child: Container(
                        height: 60,
                        alignment: Alignment.center,
                        child: Text("Switch is ${switchState ? "ON" : "OFF"}", style: TextStyle(fontSize: 18, color: switchState ? Colors.white : Colors.indigo, fontWeight: FontWeight.bold),),
                      ),
                      onTap: (){
                        showStateDialog(
                          title: "Switch ${switchState ? "OFF" : "ON"}?",
                          button: switchState ? "OFF" : "ON",
                          query: "relay=state?${switchState ? "0" : "1"}",
                          color: Colors.indigo,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Material(
                    elevation: 3,
                    color: engineState ? Colors.teal : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: engineState ? BorderSide.none : BorderSide(width: 2, color: Colors.teal)),
                    child: InkWell(
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Text("Engine is ${engineState ? "ON" : "OFF"}", style: TextStyle(fontSize: 18, color: engineState ? Colors.white : Colors.teal, fontWeight: FontWeight.bold),),
                      ),
                      onTap: (){
                        showDialog(
                          context: context,
                          builder: (context){
                            return Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("Feature is not available at this time.", textAlign: TextAlign.center, style: TextStyle(fontSize: 18),),
                                    SizedBox(height: 30),
                                    Material(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.teal, width: 2)),
                                      child: InkWell(
                                        child: Container(
                                          height: 50,
                                          alignment: Alignment.center,
                                          child: Text("OK", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal, ),),
                                        ),
                                        onTap: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      );

    } else if (pageIndex == 1) {
      return SensorPage(sensor,
        isSensorAvailable: isSensorAvailable,
        sensorInfoRequested: sensorInfoRequested,
      );

    } else if (pageIndex == 2) {
      return FingerprintsPage(fingerprints,
        fingerprintsRequested: fingerprintsRequested,
        callback: (String id) => showDeleteDialog(id),
      );
    } else if (pageIndex == 3) {
      return deviceSettingsPage();
    }

    return Container();

  }

  Widget deviceSettingsPage() {

    if (!deviceInfoRequested) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Getting device information...", style: TextStyle(color: Colors.grey.shade600, fontSize: 16),),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Version", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(device.version, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                  ],
                ),
              ),
              onTap: (){},
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Device Password", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(device.pass, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  ],
                ),
              ),
              onTap: (){
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context){
                    changeContext = context;
                    String pass = "";

                    return StatefulBuilder(
                      builder: (context, setState1){
                        changeState = setState1;
                        return Dialog(
                          insetPadding: EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Change Admin Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                SizedBox(height: 20),
                                TextField(
                                  onChanged: (v){
                                    setState1(() {
                                      pass = v;
                                    });
                                  },
                                  enabled: changing ? false : true,
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(5),
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                if (changeError != null)
                                Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Text(changeError, textAlign: TextAlign.center, style: TextStyle(color: Colors.red),),
                                  ],
                                ),
                                SizedBox(height: 30),
                                changing ? CircularProgressIndicator() :
                                Row(
                                  children: [
                                    Expanded(
                                      child: Material(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          child: Container(
                                            height: 50,
                                            alignment: Alignment.center,
                                            child: Text("Cancel", style: TextStyle(fontSize: 18, color:  Colors.black, fontWeight: FontWeight.bold),),
                                          ),
                                          onTap: () => Navigator.pop(context),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Material(
                                        color: pass.isEmpty ? Colors.grey : Colors.teal,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          child: Container(
                                            height: 50,
                                            alignment: Alignment.center,
                                            child: Text("Change", style: TextStyle(fontSize: 18, color:  Colors.white, fontWeight: FontWeight.bold),),
                                          ),
                                          onTap: pass.isEmpty ? null : () async {
                                            dynamic result = await showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  content: Text("Are you sure?"),
                                                  actions: [
                                                    TextButton(child: Text("No"), onPressed: () => Navigator.pop(context),),
                                                    TextButton(child: Text("Yes"), onPressed: () => Navigator.pop(context, true),),
                                                  ],
                                                );
                                              },
                                            );

                                            if (result == true) {
                                              setState1(() {
                                                changing = true;
                                              });
                                              channel.sink.add("esp=set?pass=$pass");
                                            }

                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Battery Level", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text("59%", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                  ],
                ),
              ),
              onTap: (){},
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                // alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Mac Address", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                    Text(device.macAddress, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                  ],
                ),
              ),
              onTap: (){},
            ),
          ),
          SizedBox(height: 15),

          Material(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Access Point", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),),
                          Material(
                            color: Colors.white,
                            child: InkWell(
                              customBorder: CircleBorder(),
                              child: Container(
                                height: 50,
                                width: 50,
                                alignment: Alignment.center,
                                child: Icon(FontAwesomeIcons.edit, color: Colors.teal, size: 16,),
                              ),
                              onTap: (){
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context){
                                    changeContext = context;
                                    TextEditingController ssidController = TextEditingController(text: device.apSsid);
                                    TextEditingController passController = TextEditingController(text: device.apPass);
                                    bool valid = true;

                                    return StatefulBuilder(
                                      builder: (context, setState1){
                                        changeState = setState1;
                                        return Dialog(
                                          insetPadding: EdgeInsets.symmetric(horizontal: 20),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text("Change Access Point", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                                SizedBox(height: 20),
                                                TextField(
                                                  onChanged: (_){
                                                    setState1(() {
                                                      valid = ssidController.text.isEmpty ? false : true;
                                                    });
                                                  },
                                                  controller: ssidController,
                                                  enabled: changing ? false : true,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                                    labelText: "SSID",
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    disabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                TextField(
                                                  onChanged: (_){
                                                    setState1(() {
                                                      valid = passController.text.isEmpty ? true : passController.text.length < 8 ? false : true;
                                                    });
                                                  },
                                                  controller: passController,
                                                  enabled: changing ? false : true,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                                    labelText: "Password",
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    disabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                                if (changeError != null)
                                                  Column(
                                                    children: [
                                                      SizedBox(height: 10),
                                                      Text(changeError, textAlign: TextAlign.center, style: TextStyle(color: Colors.red),),
                                                    ],
                                                  ),
                                                SizedBox(height: 30),
                                                changing ? CircularProgressIndicator() :
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Material(
                                                        color: Colors.grey.shade300,
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: InkWell(
                                                          child: Container(
                                                            height: 50,
                                                            alignment: Alignment.center,
                                                            child: Text("Cancel", style: TextStyle(fontSize: 18, color:  Colors.black, fontWeight: FontWeight.bold),),
                                                          ),
                                                          onTap: () => Navigator.pop(context),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: Material(
                                                        color: !valid ? Colors.grey : Colors.teal,
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: InkWell(
                                                          child: Container(
                                                            height: 50,
                                                            alignment: Alignment.center,
                                                            child: Text("Change", style: TextStyle(fontSize: 18, color:  Colors.white, fontWeight: FontWeight.bold),),
                                                          ),
                                                          onTap: !valid ? null : () async {
                                                            dynamic result = await showDialog(
                                                              context: context,
                                                              builder: (context) {
                                                                return AlertDialog(
                                                                  content: Text("Are you sure?"),
                                                                  actions: [
                                                                    TextButton(child: Text("No"), onPressed: () => Navigator.pop(context),),
                                                                    TextButton(child: Text("Yes"), onPressed: () => Navigator.pop(context, true),),
                                                                  ],
                                                                );
                                                              },
                                                            );

                                                            if (result == true) {
                                                              setState1(() {
                                                                changing = true;
                                                              });
                                                              channel.sink.add("esp=set?ap-ssid=${ssidController.text}");
                                                              channel.sink.add("esp=set?ap-pass=${passController.text}");
                                                            }

                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 1, thickness: 1.5,),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Column(
                    children: [
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("SSID", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.apSsid, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Password", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.apPass, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("IP Address", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.apIp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),

          SizedBox(height: 15),

          Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Wifi Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),),
                          Material(
                            color: Colors.white,
                            child: InkWell(
                              customBorder: CircleBorder(),
                              child: Container(
                                height: 50,
                                width: 50,
                                alignment: Alignment.center,
                                child: Icon(FontAwesomeIcons.edit, color: Colors.teal, size: 16,),
                              ),
                              onTap: (){
                                showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (context){
                                    changeContext = context;
                                    TextEditingController ssidController = TextEditingController(text: device.wifiSsid);
                                    TextEditingController passController = TextEditingController(text: device.wifiPass);
                                    bool valid = true;

                                    return StatefulBuilder(
                                      builder: (context, setState1){
                                        changeState = setState1;
                                        return Dialog(
                                          insetPadding: EdgeInsets.symmetric(horizontal: 20),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text("Change Wifi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                                                SizedBox(height: 20),
                                                TextField(
                                                  onChanged: (_){
                                                    setState1(() {
                                                      valid = ssidController.text.isEmpty ? false : true;
                                                    });
                                                  },
                                                  controller: ssidController,
                                                  enabled: changing ? false : true,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                                    labelText: "SSID",
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    disabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                TextField(
                                                  onChanged: (_){
                                                    setState1(() {
                                                      valid = passController.text.isEmpty ? true : passController.text.length < 8 ? false : true;
                                                    });
                                                  },
                                                  controller: passController,
                                                  enabled: changing ? false : true,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                                    labelText: "Password",
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                    disabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(5),
                                                      borderSide: BorderSide(color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                                if (changeError != null)
                                                  Column(
                                                    children: [
                                                      SizedBox(height: 10),
                                                      Text(changeError, textAlign: TextAlign.center, style: TextStyle(color: Colors.red),),
                                                    ],
                                                  ),
                                                SizedBox(height: 30),
                                                changing ? CircularProgressIndicator() :
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Material(
                                                        color: Colors.grey.shade300,
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: InkWell(
                                                          child: Container(
                                                            height: 50,
                                                            alignment: Alignment.center,
                                                            child: Text("Cancel", style: TextStyle(fontSize: 18, color:  Colors.black, fontWeight: FontWeight.bold),),
                                                          ),
                                                          onTap: () => Navigator.pop(context),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: Material(
                                                        color: !valid ? Colors.grey : Colors.teal,
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: InkWell(
                                                          child: Container(
                                                            height: 50,
                                                            alignment: Alignment.center,
                                                            child: Text("Change", style: TextStyle(fontSize: 18, color:  Colors.white, fontWeight: FontWeight.bold),),
                                                          ),
                                                          onTap: !valid ? null : () async {
                                                            dynamic result = await showDialog(
                                                              context: context,
                                                              builder: (context) {
                                                                return AlertDialog(
                                                                  content: Text("Are you sure?"),
                                                                  actions: [
                                                                    TextButton(child: Text("No"), onPressed: () => Navigator.pop(context),),
                                                                    TextButton(child: Text("Yes"), onPressed: () => Navigator.pop(context, true),),
                                                                  ],
                                                                );
                                                              },
                                                            );

                                                            if (result == true) {
                                                              setState1(() {
                                                                changing = true;
                                                              });
                                                              channel.sink.add("esp=set?wifi-ssid=${ssidController.text}");
                                                              channel.sink.add("esp=set?wifi-pass=${passController.text}");
                                                            }

                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 1, thickness: 1.5,),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Column(
                    children: [
                      SizedBox(height: 5),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("SSID", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.wifiSsid, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Password", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.wifiPass, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("IP Address", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.wifiIp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Gateway", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.gatewayIp, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Subnet Mask", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.subnetMask, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Channel", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.channel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: EdgeInsets.symmetric(horizontal: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("State", style: TextStyle(fontSize: 16, color: Colors.grey.shade700),),
                            Text(device.state, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          SizedBox(height: 15),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                alignment: Alignment.center,
                child: Text("Reboot Device", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),),
              ),
              onTap: (){

                showDialog(
                  context: context,
                  builder: (context){
                    bool resetting = false;
                    return StatefulBuilder(
                      builder: (context, setState1){
                        return Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Reboot Device", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),),
                                SizedBox(height: 30),
                                resetting ? CircularProgressIndicator() :
                                Row(
                                  children: [
                                    Expanded(
                                      child: Material(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          child: Container(
                                            height: 50,
                                            alignment: Alignment.center,
                                            child: Text("Cancel", style: TextStyle(fontSize: 18, color:  Colors.black, fontWeight: FontWeight.bold),),
                                          ),
                                          onTap: () => Navigator.pop(context),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Material(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.teal, width: 2)),
                                        child: InkWell(
                                          child: Container(
                                            height: 50,
                                            alignment: Alignment.center,
                                            child: Text("Reboot", style: TextStyle(fontSize: 18, color:  Colors.teal, fontWeight: FontWeight.bold),),
                                          ),
                                          onTap: resetting ? null : () {
                                            setState1((){
                                              resetting = true;
                                            });
                                            channel.sink.add("esp=restart");
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );

              },
            ),
          ),
          Divider(height: 1),
          Material(
            color: Colors.white,
            child: InkWell(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 30),
                alignment: Alignment.center,
                child: Text("Factory Reset", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),),
              ),
              onTap: (){},
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );

  }


  void showEnrollDialog() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context){
        enrollContext = context;
        fingerprintId = "1";

        return WillPopScope(
          onWillPop: () async => false,
          child: StatefulBuilder(
            builder: (context, setState1){

              enrollState = setState1;

              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("ENROLL FINGERPRINT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),),
                      SizedBox(height: 20),
                      Container(
                        height: 30,
                        padding: EdgeInsets.fromLTRB(20, 0, 5, 0),
                        decoration: BoxDecoration(
                          border: Border.all(color: enrolling ? Colors.grey : Colors.teal, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
                            value: fingerprintId,
                            onChanged: enrolling ? null : (index){
                              setState1(() {
                                fingerprintId = index;
                              });
                            },
                            items: indexes.map((i){
                              return DropdownMenuItem<String>(
                                child: Text("$i"),
                                value: i.toString(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Material(
                        color: enrolling ? Colors.teal : Colors.grey,
                        shape: CircleBorder(),
                        child: InkWell(
                          customBorder: CircleBorder(),
                          child: Container(
                            height: 100,
                            width: 100,
                            child: Icon(FontAwesomeIcons.fingerprint, color: Colors.white, size: 50,),
                          ),
                          onTap: (){},
                        ),
                      ),
                      if (enrollMessage != null)
                        Column(
                          children: [
                            SizedBox(height: 20),
                            Text(enrollMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: enrollError ? Colors.red : Colors.black),),
                          ],
                        ),
                      SizedBox(height: 30),
                      enrollBegin ? CircularProgressIndicator() :
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: Text("Cancel", style: TextStyle(fontSize: 18),),
                                ),
                                onTap: (){
                                  if (enrolling) {
                                    setState1(() {
                                      enrollBegin = true;
                                    });
                                    channel.sink.add("sensor=enroll?cancel");
                                  } else {
                                    setState1(() {
                                      enrollBegin = false;
                                      enrollMessage = null;
                                      enrolling = false;
                                    });
                                    Navigator.pop(context);
                                  }

                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: enrolling ? Colors.grey.shade400 : Colors.teal, width: 2)),
                              child: InkWell(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: Text("Enroll", style: TextStyle(fontSize: 18, color: enrolling ? Colors.grey.shade400 : Colors.teal, fontWeight: FontWeight.bold),),
                                ),
                                onTap: enrolling ? null : () {
                                  setState1(() {
                                    enrollMessage = null;
                                    enrollBegin = true;
                                  });
                                  channel.sink.add("sensor=enroll?$fingerprintId");
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    enrollBegin = false;
    enrolling = false;
    enrollError = false;
    enrollMessage = null;
    enrollContext = null;
    fingerprintId = null;
  }

  void showDeleteDialog(String id) async {
    fingerprintId = id;
    await showDialog(
      context: context,
      builder: (context){
        deleteContext = context;
        deleteMessage = "Do you really want to delete fingerprint $id?";

        return WillPopScope(
          onWillPop: () async => true,
          child: StatefulBuilder(
            builder: (context, setState1){
              deleteState = setState1;
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("DELETE FINGERPRINT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),),
                      SizedBox(height: 10),
                      Text(deleteMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: deleteError ? Colors.red : Colors.grey.shade700),),
                      SizedBox(height: 30),
                      deleting ? CircularProgressIndicator() :
                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: Text("Cancel", style: TextStyle(fontSize: 18, color:  Colors.black, fontWeight: FontWeight.bold),),
                                ),
                                onTap: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Material(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.red, width: 2)),
                              child: InkWell(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: Text("Delete", style: TextStyle(fontSize: 18, color:  Colors.red, fontWeight: FontWeight.bold),),
                                ),
                                onTap: deleting ? null : () {
                                  setState1((){
                                    deleting = true;
                                  });
                                  channel.sink.add("sensor=delete?$id");
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    deleteError = false;
    deleting = false;
    deleteMessage = null;
    deleteContext = null;
    // deleteFingerprintId = null;
  }

  void showDeleteSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context){
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FontAwesomeIcons.checkCircle, color: Colors.green, size: 60,),
                SizedBox(height: 15),
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                SizedBox(height: 30),
                Material(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(width: 2, color: Colors.grey.shade700)),
                  child: InkWell(
                    child: Container(
                      height: 50,
                      width: 150,
                      alignment: Alignment.center,
                      child: Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey.shade700),),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showStateDialog({@required String title, @required String button, @required String query, @required Color color}) {

    showDialog(
      context: context,
      builder: (context){
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text("Cancel", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          ),
                          onTap: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color, width: 2)),
                        child: InkWell(
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text(button, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, ),),
                          ),
                          onTap: (){
                            channel.sink.add(query);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showLogoutDialog() async {
    dynamic result = await showDialog(
      context: context,
      builder: (context){
        return AlertDialog(
          content: Text("Do you really want to logout?", style: TextStyle(fontSize: 16),),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(fontSize: 16)),),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Logout", style: TextStyle(fontSize: 16)),),
          ],
        );
      },
    );

    if (result == true) {
      widget.stream?.cancel();
      channel.sink.close();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => StartPage(connect: false,)), (route) => false);
    }

  }

  void showChangeSuccessDialog() {
    showDialog(
      context: context,
      builder: (context){
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FontAwesomeIcons.checkCircle, color: Colors.green, size: 60,),
                SizedBox(height: 15),
                Text("Your changes is save.\nRestart the device to take effect.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                SizedBox(height: 30),
                Material(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(width: 2, color: Colors.grey.shade700)),
                  child: InkWell(
                    child: Container(
                      height: 50,
                      width: 150,
                      alignment: Alignment.center,
                      child: Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey.shade700),),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
