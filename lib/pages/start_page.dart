import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import '../utils.dart';
import 'connect_page.dart';
import 'dashboard.dart';


class StartPage extends StatefulWidget {
  const StartPage({Key key}) : super(key: key);

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {

  SharedPreferences prefs;
  StreamSubscription<dynamic> stream;
  IOWebSocketChannel channel;
  static String port = "4848";
  String ip;
  bool login = false;
  bool loading = true;
  bool ipError = true;
  String error;
  String token;
  String pass = "";
  TextEditingController ipController = TextEditingController();

  Timer timer;
  bool loadForever = false;

  void startTimer(int timeout) {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (t.tick >= timeout) {
        t.cancel();
        timer.cancel();
        setState(() => loadForever = true);
      }
    });
  }

  void connect() async {
    stream?.cancel();
    channel = IOWebSocketChannel.connect('ws://$ip:$port/v1');
    startTimer(10);
    stream = channel.stream.listen((d) {
      print(d);
      try {
        dynamic result = json.decode(d);
        String status = result["status"];
        String type = result["type"];
        String message = result["message"];
        // dynamic data = result["data"];

        if (status == "success") {
          if (type == "connect") {
            if (message == "connected") {
              timer?.cancel();
              prefs.setString("ip", ip);
              setState(() {
                loading = false;
              });
            }
          } else if (type == "login") {
            if (message == "success") {
              prefs.setString("token", token);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardPage(channel, stream)));
            } else {
              setState(() {
                error = message;
                login = false;
              });
            }
          }
        } else { // status = "error"

          if (login) {
            setState(() {
              error = message;
              login = false;
            });
          }
        }

      } catch (e) {
        print(e.toString());
      }

    }, onDone: (){
      print("Stream done!");
      Utils.showReconnectDialog(context);
    }, onError: (error) async {
      print(error.toString());
      ip = null;
      setIpAddress(message: error.toString());
    });
  }

  Future<void> setIpAddress({String message}) async {
    // if (ip == null) ip = await Navigator.push(context, MaterialPageRoute(builder: (_) => ConnectPage(message: message)));
    // connect();
  }

  void initialize() async {
    prefs = await SharedPreferences.getInstance();
    String ip = prefs.getString("ip");
    token = prefs.getString("token");

    // ipController.text = "123123123";
    if (ip != null) {
      ipController.text = ip;
    }

    print(ip);
    print(token);
    setIpAddress();
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
          child: Center(
            child: !loading ? SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.fingerprint, size: 60, color: Colors.teal,),
                      SizedBox(height: 20),
                      Text("Connecting...", style: TextStyle(fontSize: 16, color: Colors.teal,),),
                    ],
                  ),
                  if (loadForever)
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.25,
                    child: Material(
                      color: Colors.teal,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        child: Container(
                          height: 45,
                          width: 130,
                          alignment: Alignment.center,
                          child: Text("STOP", style: TextStyle(color: Colors.white, fontSize: 18),),
                        ),
                        onTap: () {
                          setState((){
                            loadForever = false;
                            ip = null;
                          });
                          setIpAddress();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ) :
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    Icon(FontAwesomeIcons.fingerprint, color: Colors.teal, size: 80,),
                    SizedBox(height: 10),
                    Text("Fingerprint Ignition", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal,),),
                    SizedBox(height: 5),
                    Text("© VinStudios", style: TextStyle(fontSize: 16),),
                    SizedBox(height: 30,),
                    TextField(
                      controller: ipController,
                      onChanged: (v){
                        setState(() {
                          ipError = v.trim().isNotEmpty ?  !Utils.validIpAddress(v) : true;
                        });
                        print(ipError);
                      },
                      decoration: InputDecoration(
                          hintText: "Device IP address",
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          prefixIcon: Icon(FontAwesomeIcons.globeAsia, size: 18,),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: ipController.text.isEmpty ? Colors.grey : ipError ? Colors.red : Colors.teal),
                          ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ipController.text.isEmpty ? Colors.grey : ipError ? Colors.red : Colors.teal),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      onChanged: (v) => setState(() => pass = v),
                      obscureText: true,
                      decoration: InputDecoration(
                          hintText: "Admin password",
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          prefixIcon: Icon(FontAwesomeIcons.lock, size: 18,),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          )
                      ),
                    ),
                    if(error != null)
                      Column(
                        children: [
                          SizedBox(height: 10),
                          Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.red),)
                        ],
                      ),
                    SizedBox(height: 20),
                    login ? CircularProgressIndicator() :
                    Column(
                      children: [
                        Material(
                          color: pass.isNotEmpty ? Colors.teal : Colors.grey,
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
                            onTap: pass.isEmpty ? null : () {
                              setState((){
                                login = true;

                                error = null;
                              });
                              token = Uuid().v4();
                              print(token);
                              channel.sink.add("login=$pass?$token");
                            },
                          ),
                        ),
                        SizedBox(height: 15),
                        Text("or", style: TextStyle(fontSize: 20),),
                        SizedBox(height: 15),
                        Material(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.teal, width: 2)),
                          child: InkWell(
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.fingerprint, color: Colors.teal, size: 18,),
                                  SizedBox(width: 10),
                                  Text("SCAN", style: TextStyle(color: Colors.teal, fontSize: 18, fontWeight: FontWeight.bold),),
                                ],
                              ),
                            ),
                            onTap: () {
                              token = Uuid().v4();
                              // print(token);
                              // channel.sink.add("login=$pass&$token");
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
