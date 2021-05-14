import 'package:fingerprint/utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ConnectPage extends StatefulWidget {
  final String message;
  const ConnectPage({this.message, Key key}) : super(key: key);

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {

  String ip;
  bool ready = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [

                      if(widget.message != null)
                        Column(
                          children: [
                            SizedBox(height: 10),
                            Text(widget.message, textAlign: TextAlign.center, style: TextStyle(color: Colors.red),)
                          ],
                        ),
                      SizedBox(height: 20),
                      Material(
                        color: ready ? Colors.teal : Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                        child: InkWell(
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            child: Text("CONNECT", style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),),
                          ),
                          onTap: !ready ? null : () => Navigator.pop(context, ip),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
