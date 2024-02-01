import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobilecontrol/sensors.dart';
import 'package:mobilecontrol/sensors/accelerometer_sensor.dart';
import 'package:mobilecontrol/sensors/gyroscope_sensor.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MaterialApp(
    title: "Mobile Control",
    home: const Beginning(),
    theme: ThemeData.dark(),
    debugShowCheckedModeBanner: false,
  ));
}

class Beginning extends StatefulWidget {
  const Beginning({super.key});

  @override
  State<Beginning> createState() => _BeginningState();
}

class _BeginningState extends State<Beginning> {
  bool _compassHasPermissions = false;
  final TextEditingController _pointingUrl =
      TextEditingController(text: "ws://192.168.1.70:3000");

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
        title: const Text("Project SCRomo"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _pointingUrl,
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: const Text(
                  "Choose a sensor to use",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              InkWell(
                onTap: () {
                  if (!_compassHasPermissions) {
                    openAppSettings().then((opened) {
                      //
                    });
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AccelerometerSensorPage(
                              title: "Accelerometer Sensor",
                              socketchannel: IOWebSocketChannel.connect(
                                  _pointingUrl.text))));
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 38, 116, 242),
                      borderRadius: BorderRadius.circular(10)),
                  width: double.infinity,
                  height: 100,
                  child: const Center(
                      child: Text(
                    "Accelerometer Sensor",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  )),
                ),
              ),
              InkWell(
                onTap: () {
                  if (!_compassHasPermissions) {
                    openAppSettings().then((opened) {
                      //
                    });
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => GyroscopeSensor(
                              title: "Gyroscope Sensor Page",
                              socketchannel: IOWebSocketChannel.connect(
                                  _pointingUrl.text))));
                },
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 38, 116, 242),
                      borderRadius: BorderRadius.circular(10)),
                  width: double.infinity,
                  height: 100,
                  child: const Center(
                      child: Text(
                    "Gyroscope Sensor",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  )),
                ),
              )
            ],
          ),
        ),
      ),
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
                        IOWebSocketChannel.connect("ws://192.168.1.70:3000"))));
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
