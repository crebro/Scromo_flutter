import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/io.dart';

class AccelerometerSensorPage extends StatefulWidget {
  final IOWebSocketChannel socketchannel;
  const AccelerometerSensorPage(
      {super.key, required this.title, required this.socketchannel});

  final String title;

  @override
  State<AccelerometerSensorPage> createState() =>
      _AccelerometerSensorPageState();
}

class _AccelerometerSensorPageState extends State<AccelerometerSensorPage> {
  StreamSubscription? accelerometerStream;
  StreamSubscription? gyroscopeSubscription;

  // GyroscopeEvent? _gyroscopeEvent;
// IOWebSocketChannel.connect("ws://192.168.1.71:3000")
  bool connected = false;

  double? xTilt, zTilt;

  // Map<String, double> magnetometerInitial = {'x': 0, 'y': 0, 'z': 0};

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
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    checkConnection();

    accelerometerStream = accelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 100))
        .listen((AccelerometerEvent event) {
      setState(() {
        try {
          double zInclination = math.atan2(event.y, event.z) * 180 / math.pi;
          // double yInclination = (math.acos(y) * (180 / math.pi));
          double xInclination =
              math.asin(limit(event.x / 9.81, -1, 1)) * 180 / math.pi;

          widget.socketchannel.sink.add(jsonEncode({
            'event': "accelerometer_angle",
            'x': xInclination.round(),
            'z': zInclination.round(),
          }));

          setState(() {
            xTilt = xInclination;
            zTilt = zInclination;
          });
        } catch (e) {
          print("Whoos something bad happened");
        }
      });
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    accelerometerStream?.cancel();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
        // Here we take the value from the AccelerometerSensorPage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("X: ${xTilt.toString()}\nZ: ${zTilt.toString()}"),
            TextButton(
                onPressed: () {
                  widget.socketchannel.sink.add(jsonEncode({
                    'event': "place",
                  }));
                },
                child: const Text("Place"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: connected ? const Icon(Icons.add) : const Icon(Icons.abc)),
    );
  }
}
