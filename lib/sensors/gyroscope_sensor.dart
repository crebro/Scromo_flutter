import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobilecontrol/lib/shake.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:web_socket_channel/io.dart';

class GyroscopeSensor extends StatefulWidget {
  final IOWebSocketChannel socketchannel;
  const GyroscopeSensor(
      {super.key, required this.title, required this.socketchannel});

  final String title;

  @override
  State<GyroscopeSensor> createState() => _GyroscopeSensorState();
}

class _GyroscopeSensorState extends State<GyroscopeSensor> {
  StreamSubscription? gyroscopeSubscription;

  bool connected = false;
  ShakeDetector? shake;

  // Map<String, double> magnetometerInitial = {'x': 0, 'y': 0, 'z': 0};
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

  @override
  void initState() {
    super.initState();

    shake = ShakeDetector.autoStart(onPhoneShake: () {
      widget.socketchannel.sink.add(jsonEncode({'event': "shake"}));
    });

    checkConnection();

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
        xAngle = currentGyro['x']!.toString();
        zAngle = currentGyro['y']!.toString();
        yAngle = currentGyro['z']!.toString();
      });
      widget.socketchannel.sink
          .add(jsonEncode({'event': "gyroscope", ...currentGyro}));
      stopwatch.reset();
      stopwatch.start();
    });
  }

  @override
  void dispose() {
    super.dispose();
    gyroscopeSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'X: $xAngle\nY:$yAngle\nZ: $zAngle',
            ),
            TextButton(
                onPressed: () {
                  currentGyro = {'x': 0, 'y': 0, 'z': 0};
                },
                child: const Text("Calibrate"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (connected) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Currently Connected to the server")));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Currently not connected to the server")));
            }
          },
          child: connected ? const Icon(Icons.add) : const Icon(Icons.abc)),
    );
  }
}
