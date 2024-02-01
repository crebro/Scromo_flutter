import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobilecontrol/sensors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MaterialApp(title: "Mobile Control", home: Beginning()
      // home: MyHomePage(
      //   title: "Flutter Mobile Control",
      // ),
      ));
}

class Beginning extends StatefulWidget {
  const Beginning({super.key});

  @override
  State<Beginning> createState() => _BeginningState();
}

class _BeginningState extends State<Beginning> {
  bool _compassHasPermissions = false;

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(
            () => _compassHasPermissions = status == PermissionStatus.granted);
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchPermissionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Hello there"),
      ),
      body: Text("Hello my dear students"),
      floatingActionButton: FloatingActionButton(onPressed: () {
        if (!_compassHasPermissions) {
          openAppSettings().then((opened) {
            //
          });
        }
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MyHomePage(
                    title: "Flutter Mobile Control",
                    socketchannel:
                        IOWebSocketChannel.connect("ws://192.168.1.68:3000"))));
      }),
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Location Permission Required'),
          ElevatedButton(
            child: Text('Request Permissions'),
            onPressed: () {
              Permission.locationWhenInUse.request().then((ignored) {
                _fetchPermissionStatus();
              });
            },
          ),
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Open App Settings'),
            onPressed: () {
              openAppSettings().then((opened) {
                //
              });
            },
          )
        ],
      ),
    );
  }
}
