import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/io.dart';

class MyHomePage extends StatefulWidget {
  final IOWebSocketChannel socketchannel;
  const MyHomePage(
      {super.key, required this.title, required this.socketchannel});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AccelerometerEvent? _accelerometerEvent;
  MagnetometerEvent? _magnetometerEvent;
  GyroscopeEvent? _gyroscopeEvent;

  StreamSubscription? accelerometerStream;
  StreamSubscription? gyroscopeSubscription;
  // Stream accelerometerStream;

  // GyroscopeEvent? _gyroscopeEvent;
// IOWebSocketChannel.connect("ws://192.168.1.71:3000")
  bool connected = false;
  double initialFacing = 0;
  double newFacing = 0;

  // Map<String, double> magnetometerInitial = {'x': 0, 'y': 0, 'z': 0};
  bool checkForInitial = false;
  double currentFacing = 0;
  Map<String, double> currentGyro = {
    'x': 0,
    'y': 0,
    'z': 0,
  };
  Map<String, double> currentGyroRates = {
    'x': 0,
    'y': 0,
    'z': 0,
  };

  String xAngle = "0";
  String yAngle = "0";
  String zAngle = "0";

  final stopwatch = Stopwatch();

  Future<void> checkConnection() async {
    await widget.socketchannel.ready;

    setState(() {
      connected = true;
    });
  }

  double interpolate(
      double inbetween, double min, double max, double newmin, double newmax) {
    return (inbetween - min) * (newmax - newmin) / (max - min) + newmin;
  }

  double limit(double value, double min, double max) {
    if (value < min) {
      return min;
    } else if (value > max) {
      return max;
    }

    return value;
  }

  @override
  void initState() {
    super.initState();
    checkConnection();

    // FlutterCompass.events!.listen(
    //   (CompassEvent event) {
    //     setState(() {
    //       currentFacing = event.heading ?? 0;
    //     });
    //     widget.socketchannel.sink.add(jsonEncode({
    //       'event': "compassevent",
    //       'heading': event.heading ?? 0,
    //     }));
    //   },
    // );

    // accelerometerStream = accelerometerEventStream(
    //         samplingPeriod: const Duration(milliseconds: 100))
    //     .listen((AccelerometerEvent event) {
    //   setState(() {
    //     try {
    //       double zInclination = math.atan2(event.y, event.z) * 180 / math.pi;
    //       // double yInclination = (math.acos(y) * (180 / math.pi));
    //       double xInclination =
    //           math.asin(limit(event.x / 9.81, -1, 1)) * 180 / math.pi;

    //       widget.socketchannel.sink.add(jsonEncode({
    //         'event': "accelerometer_angle",
    //         'x': xInclination.round(),
    //         'z': zInclination.round(),
    //       }));

    //       xAngle = xInclination.round().toString();
    //       zAngle = zInclination.round().toString();
    //     } catch (e) {
    //       print("Whoos something bad happened");
    //     }
    //   });
    // });

    gyroscopeSubscription =
        gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: 15))
            .listen((GyroscopeEvent event) {
      stopwatch.stop();
      Map<String, double> plusRot = {
        'x': (currentGyroRates['x']! * 0.015) +
            ((event.x - currentGyroRates['x']!) * 0.015) / 2,
        'y': (currentGyroRates['y']! * 0.015) +
            ((event.y - currentGyroRates['y']!) * 0.015) / 2,
        'z': (currentGyroRates['z']! * 0.015) +
            ((event.z - currentGyroRates['z']!) * 0.015) / 2,
      };
      currentGyroRates = {
        'x': event.x,
        'y': event.y,
        'z': event.z,
      };
      currentGyro = {
        'x': currentGyro['x']! + plusRot['x']! * 180 / math.pi,
        'y': currentGyro['y']! + plusRot['y']! * 180 / math.pi,
        'z': currentGyro['z']! + plusRot['z']! * 180 / math.pi,
      };

      setState(() {
        currentFacing = currentGyroRates['z']!;
        xAngle = currentGyroRates['x']!.toString();
        zAngle = currentGyroRates['y']!.toString();
      });
      widget.socketchannel.sink
          .add(jsonEncode({'event': "gyroscope", ...currentGyro}));
      stopwatch.reset();
      stopwatch.start();
    });

    // gyroscopeEventStream(samplingPeriod: const Duration(milliseconds: 100))
    //     .listen((GyroscopeEvent event) {
    //   print(currentFacing);
    //   setState(() {
    //     currentFacing = currentFacing +
    //         (((_gyroscopeEvent != null ? _gyroscopeEvent!.y : 0) / 10) *
    //                 (math.pi / 180) -
    //             initialFacing);
    //     _gyroscopeEvent = event;
    //   });

    //   if (connected) {
    //     widget.socketchannel.sink.add(jsonEncode(
    //         {'event': "gyroscope", "x": event.x, "y": event.y, "z": event.z}));
    //   }
    // });

    // magnetometerEventStream(
    //   samplingPeriod: const Duration(
    //     milliseconds: 100,
    //   ),
    // ).listen((MagnetometerEvent event) {
    //   if (checkForInitial) {
    //     initialFacing = atan2(event.y, event.x);
    //     checkForInitial = false;
    //     // magnetometerInitial = {'x': event.x, 'y': event.y, 'z': event.z};
    //   }

    //   if (connected) {
    //     widget.socketchannel.sink.add(jsonEncode({
    //       'event': "magnetometer",
    //       "x": _accelerometerEvent?.x ?? 0,
    //       "y": _accelerometerEvent?.y ?? 0,
    //       "z": _accelerometerEvent?.z ?? 0,
    //       "facing": atan2(event.y, event.x) - initialFacing
    //     }));
    //   }
    //   setState(() {
    //     _magnetometerEvent = event;
    //   });
    // });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    gyroscopeSubscription?.cancel();
    // accelerometerStream?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you ca just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Stack(
            //   children: [
            //     Container(
            //       decoration: const BoxDecoration(
            //           color: Colors.green, shape: BoxShape.circle),
            //       width: 400,
            //       height: 400,
            //     ),
            //     Positioned(
            //         child: Text(
            //             "x: ${_accelerometerEvent?.x ?? 0}\n y: ${_accelerometerEvent?.y ?? 0}\n z: ${_accelerometerEvent?.z ?? 0}")),
            //     Positioned(
            //         child: Text(
            //             "x: ${_accelerometerEvent?.x ?? 0}\n y: ${_accelerometerEvent?.y ?? 0}\n z: ${_accelerometerEvent?.z ?? 0}")),
            //     Positioned(
            //       right: 200 +
            //           double.parse((_accelerometerEvent?.x ?? 0)
            //                   .toStringAsFixed(2)) *
            //               20,
            //       top: 200 +
            //           double.parse((_accelerometerEvent?.y ?? 0)
            //                   .toStringAsFixed(2)) *
            //               20,
            //       child: Container(
            //         width: 20,
            //         height: 20,
            //         decoration: BoxDecoration(
            //             color: Colors.green.shade400, shape: BoxShape.circle),
            //       ),
            //     )
            //   ],
            // ),
            // Text(
            //   'Accelerometer Event: $_accelerometerEvent',
            //   style: Theme.of(context).textTheme.headlineMedium,
            // ),

            Text(
                "Current Facings:\n XAngle: $xAngle \n YAngle: $currentFacing \n ZAngle: $zAngle"),

            // Text(
            //     "Currently facing: ${_magnetometerEvent != null ? atan2(_magnetometerEvent!.y, _magnetometerEvent!.x) - initialFacing : 'n/a'}"),
            // const SizedBox(height: 20),
            // Text(
            //     "Gyroscope: \nx: ${_gyroscopeEvent?.x ?? 0}\n y: ${_gyroscopeEvent?.y ?? 0}\n z: ${_gyroscopeEvent?.z ?? 0}"),
            // const SizedBox(height: 20),
            // Text(
            //     "Accelerometer: \nx: ${_accelerometerEvent?.x ?? 0}\n y: ${_accelerometerEvent?.y ?? 0}\n z: ${_accelerometerEvent?.z ?? 0}"),
            // const SizedBox(height: 20),
            // Text(
            //     "Magnetometer: \nx: ${_magnetometerEvent?.x ?? 0}\n y: ${_magnetometerEvent?.y ?? 0}\n z: ${_magnetometerEvent?.z ?? 0}"),
            TextButton(
                onPressed: () {
                  checkForInitial = true;
                },
                child: const Text("Calibrate"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            checkForInitial = true;
            // send message
            // socketchannel.sink.add(jsonEncode({
            //   'event': "accelerometer",
            //   "x": _accelerometerEvent?.x ?? 0,
            //   "y": _accelerometerEvent?.y ?? 0,
            //   "z": _accelerometerEvent?.z ?? 0
            // }));
          },
          child: connected ? const Icon(Icons.add) : const Icon(Icons.abc)),
    );
  }
}
