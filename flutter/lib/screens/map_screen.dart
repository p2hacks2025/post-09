import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'base_layout.dart';

// マップ画面
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  StreamSubscription<StepCount>? _stepSub;
  int? _currentSteps;

  @override
  void initState() {
    super.initState();
    _requestPedometerPermission();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }

  Future<void> _requestPedometerPermission() async {
    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _startPedometer();
    }
  }

  void _startPedometer() {
    _stepSub = Pedometer.stepCountStream.listen(
      (event) {
        setState(() {
          _currentSteps = event.steps;
        });
      },
      onError: (error) {
        debugPrint('Pedometer error: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      title: 'MAP',
      showBackButton: false,
      stepCount: _currentSteps,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.06),

              // ここにマップコンテンツを追加
              SizedBox(height: screenHeight * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
