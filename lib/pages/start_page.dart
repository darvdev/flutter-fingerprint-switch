import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import '../utils.dart';
import 'dashboard.dart';


class StartPage extends StatefulWidget {
  final bool connect;
  const StartPage({this.connect = true, Key key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  SharedPreferences prefs;
  StreamSubscription<dynamic> stream;
  IOWebSocketChannel channel;
  static String port = "4848";

  bool logging = false;
  bool connecting = false;
  bool connected = false;

  bool sensorState = false;
  bool sensorRequesting = false;
  bool sensorLogin = false;
  bool sensorError = false;
  String sensorMessage;
  Function sensorStateSetter;


  bool ipError = true;
  bool isObscure = true;
  String error;
  String token;
  String pass = "";
  TextEditingController ipController = TextEditingController();

  Timer timer;
  bool loadForever = false;


  void handleConnectSuccess(String message, dynamic data) {
    if (message == "connected") {
      timer?.cancel();
      prefs.setString("ip", ipController.text);

      if (sensorRequesting) {
        channel.sink.add("sensor=state");
      } else {
        if (pass.isNotEmpty) {
          setState(() => logging = true);
          token = Uuid().v4();
          channel.sink.add("login=$pass?$token");
        }
      }

      setState(() {
        connecting = false;
        connected = true;
      });

    } else {
      print("Error: message: $message");
    }
  }

  void handleLoginSuccess(String message, dynamic data) {
    if (message == "success") {
      prefs.setString("token", token);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(channel, stream)));
    } else {
      print("Message: $message");
      setState(() {
        error = message;
        logging = false;
      });
    }
  }

  void handleSensorSuccess(String message, dynamic data) {
    sensorState = message == "1" ? true : false;
    if (sensorRequesting) {
      setState(() {
         sensorRequesting = false;
      });
      sensorMessage = "Place your finger to the sensor";
      showScanDialog();
    }

  }

  void startTimer(int timeout) {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (t.tick >= timeout) {
        t.cancel();
        timer.cancel();
        print("Timer timeout");
        setState(() {
          error = "This is taking too long.\nPlease change device ip and try again.";
          sensorRequesting = false;
          loadForever = true;
        });
      }
    });
  }

  void connect() async {
    setState((){
      error = null;
      connecting= true;
    });

    stream?.cancel();
    channel = IOWebSocketChannel.connect('ws://${ipController.text}:$port/v1');
    startTimer(10);
    stream = channel.stream.listen((d) {
      print(d);

      try {
        dynamic result = json.decode(d);
        String status = result["status"];
        String type = result["type"];
        String message = result["message"];
        dynamic data = result["data"];

        if (status == "success") {

          switch (type) {
            case "connect":
              handleConnectSuccess(message, data);
              break;

            case "login":
              handleLoginSuccess(message, data);
              break;

            case "sensor":
              handleSensorSuccess(message, data);
              break;

            default:
              print("Type: ");
              break;
          }

        } else {

          print("Status $status");

          if (connecting) {
            setState(() {
              error = message;
              connecting = false;
            });
          }

        }

      } catch (e) {
        print(e.toString());
      }

    }, onDone: (){
      stream?.cancel();
      timer?.cancel();
      print("onDone");
      setState(() {
        error = "Device ip address is not available";
        connecting = false;
        logging = false;
        loadForever = false;
        sensorRequesting = false;
      });

    }, onError: (e) async {
      stream?.cancel();
      timer?.cancel();
      print("onError");
      print(e.toString());
      setState(() {
        error = e.toString();
        connecting = false;
        logging = false;
        loadForever = false;
        sensorRequesting = false;
      });
    });
  }

  void initialize() async {
    prefs = await SharedPreferences.getInstance();
    String ip = prefs.getString("ip");
    token = prefs.getString("token");
    if (ip != null) {
      ipController.text = ip;
      setState(() => ipError = !Utils.validIpAddress(ipController.text));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SizedBox.expand(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
                        Icon(FontAwesomeIcons.fingerprint, color: Colors.teal, size: 80,),
                        SizedBox(height: 10),
                        Text("Fingerprint Switch", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal,),),
                        SizedBox(height: 5),
                        Text("© VinStudios", style: TextStyle(fontSize: 16),),
                        SizedBox(height: 30,),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                enabled: connected || connecting ? false : true,
                                controller: ipController,
                                onChanged: (v){
                                  setState(() => ipError = v.trim().isNotEmpty ?  !Utils.validIpAddress(v) : true);
                                },
                                style: TextStyle(color: connected ? Colors.grey : Colors.black),
                                decoration: InputDecoration(
                                    hintText: "IP address",
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                    prefixIcon: Icon(FontAwesomeIcons.globeAsia, size: 18, color: connecting ? Colors.grey.shade300 : connected ? Colors.green : ipController.text.isEmpty ? Colors.grey : ipError ? Colors.red : Colors.teal),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: ipController.text.isEmpty ? Colors.grey : ipError ? Colors.red : Colors.teal),
                                    ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: ipController.text.isEmpty ? Colors.grey : ipError ? Colors.red : Colors.teal),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    borderSide: BorderSide(color: connected ? Colors.green : Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ),
                            Visibility(
                              visible: connected ? true : false,
                              child: Row(
                                children: [
                                  SizedBox(width: 5),
                                  Material(
                                    color: Colors.teal,
                                    borderRadius: BorderRadius.circular(5),
                                    child: InkWell(
                                      child: Container(
                                        height: 47,
                                        width: 47,
                                        alignment: Alignment.center,
                                        child: Icon(FontAwesomeIcons.times, color: Colors.white, size: 20,),
                                      ),
                                      onTap: (){
                                        channel.sink.close();
                                        stream?.cancel();
                                        setState(() {
                                          error = "Disconnected";
                                          connected = false;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        TextField(
                          enabled: connecting ? false : true,
                          onChanged: (v) => setState(() => pass = v),
                          obscureText: isObscure,
                          decoration: InputDecoration(
                              hintText: "Password",
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              prefixIcon: Icon(FontAwesomeIcons.lock, size: 18, color: connecting ? Colors.grey.shade300 : pass.isNotEmpty ? Colors.teal : Colors.grey,),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: pass.isNotEmpty ? Colors.teal : Colors.grey, width: 1),
                              ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: pass.isNotEmpty ? Colors.teal : Colors.grey, width: 1),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                            suffixIcon: //pass.isEmpty ? null :
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                customBorder: CircleBorder(),
                                child: Icon(FontAwesomeIcons.solidEye, size: 18, color: isObscure ? Colors.grey : Colors.teal,),
                                onTap: (){
                                  setState(() => isObscure = !isObscure);
                                  print("eye");
                                },
                              ),
                            ),
                          ),
                        ),
                        if(error != null)
                          Column(
                            children: [
                              SizedBox(height: 10),
                              Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.red),)
                            ],
                          ),
                        SizedBox(height: 25),
                        connecting || logging ?
                        Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Visibility(
                              visible: loadForever,
                              child: Material(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(5),
                                child: InkWell(
                                  child: Container(
                                    height: 40,
                                    width: 130,
                                    alignment: Alignment.center,
                                    child: Text("Retry", style: TextStyle(color: Colors.white, fontSize: 16),),
                                  ),
                                  onTap: (){
                                    stream?.cancel();
                                    setState(() {
                                      error = null;
                                      connecting = false;
                                      loadForever = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ) :
                        Column(
                          children: [
                            Material(
                              color: pass.isNotEmpty && !ipError ? Colors.teal : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(FontAwesomeIcons.signInAlt, color: Colors.white, size: 18,),
                                      SizedBox(width: 10),
                                      Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),),
                                    ],
                                  ),
                                ),
                                onTap: pass.isEmpty && !ipError ? null : (){
                                  if (connected) {
                                    setState(() => logging = true);
                                    token = Uuid().v4();
                                    channel.sink.add("login=$pass?$token");
                                  } else {
                                    connect();
                                  }
                                },
                              ),
                            ),
                            // SizedBox(height: 15),
                            // Text("or", style: TextStyle(fontSize: 20),),
                            // SizedBox(height: 15),
                            // Material(
                            //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: ipError ? Colors.grey :  Colors.teal, width: 2)),
                            //   child: InkWell(
                            //     child: Container(
                            //       height: 50,
                            //       alignment: Alignment.center,
                            //       child: Row(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: [
                            //           Icon(FontAwesomeIcons.fingerprint, color: ipError ? Colors.grey :  Colors.teal, size: 18,),
                            //           SizedBox(width: 10),
                            //           Text("SCAN", style: TextStyle(color: ipError ? Colors.grey : Colors.teal, fontSize: 18, fontWeight: FontWeight.bold),),
                            //         ],
                            //       ),
                            //     ),
                            //     onTap: ipError ? null : () {
                            //       if (connected) {
                            //
                            //         if (sensorState) {
                            //           sensorMessage = "Place your finger to the sensor";
                            //           showScanDialog();
                            //         } else {
                            //           setState(() {
                            //             sensorRequesting = true;
                            //           });
                            //           token = Uuid().v4();
                            //           channel.sink.add("sensor=state?$token");
                            //         }
                            //       } else {
                            //         setState((){
                            //           sensorRequesting = true;
                            //         });
                            //         connect();
                            //       }
                            //     },
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (sensorRequesting)
                SizedBox.expand(
                  child: Material(
                    color: Colors.white.withOpacity(0.5),
                    child: Center(
                      child: Material(
                        color: Colors.white,
                        elevation: 5,
                        shape: CircleBorder(),
                        child: Container(
                          height: 80,
                          width: 80,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void showScanDialog() async {

    if (token != null) {
      if (token.isNotEmpty) {
        token = Uuid().v4();
      }
    }

    channel.sink.add("sensor=login?$token");
    await showDialog(
      context: context,
      builder: (context){
        return StatefulBuilder(
          builder: (context, setState1){
            sensorStateSetter = setState1;
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      shape: CircleBorder(),
                      color: Colors.teal,
                      child: Container(
                        height: 100,
                        width: 100,
                        child: Icon(FontAwesomeIcons.fingerprint, color: Colors.white, size: 50,),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(sensorMessage, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: sensorError ? Colors.red : Colors.black),),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    channel.sink.add("sensor=logout?$token");
    token = null;
  }

}
