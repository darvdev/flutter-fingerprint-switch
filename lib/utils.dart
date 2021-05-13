
import 'dart:io';

import 'package:fingerprint/pages/start_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Utils {

  static bool validIpAddress(String value) {
    RegExp regex = new RegExp(r"^(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))\.(\d|[1-9]\d|1\d\d|2([0-4]\d|5[0-5]))$");
    return regex.hasMatch(value);
  }

  static Future<void> showReconnectDialog(BuildContext context) {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context){
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Reconnect", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),),
                  SizedBox(height: 20),
                  Text("Please reconnect to device", textAlign: TextAlign.center, style: TextStyle(fontSize: 16),),
                  SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                          child: InkWell(
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              child: Text("Quit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                            ),
                            onTap: (){
                              exit(0);
                              // SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Material(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(5),
                          child: InkWell(
                            child: Container(
                              height: 45,
                              alignment: Alignment.center,
                              child: Text("Reconnect", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),),
                            ),
                            onTap: (){
                              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => StartPage()), (route) => false);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}