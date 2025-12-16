import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../base/base_layout.dart';
import '../base/map_base.dart';
import 'map_screen.dart';

// 実際のホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<StepCount>? _stepSub;
  int? _currentSteps;

  // 位置情報
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _requestPedometerPermission();
    _getCurrentLocation();
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

  // 位置情報の取得
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final pos = await MapBase.getCurrentPosition();

    setState(() {
      _currentPosition = pos;
      _isLoadingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      stepCount: _currentSteps,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.06),

              // シンボルカード
              _buildSymbolCard(context),

              SizedBox(height: screenHeight * 0.06),

              // マップカード
              _buildMapCard(context),

              SizedBox(height: screenHeight * 0.06),

              // 黄色いボタン2つ
              _buildYellowButtons(context),

              SizedBox(height: screenHeight * 0.06),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymbolCard(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.35,
      decoration: BoxDecoration(
        color: const Color(0xFFD4D4D4),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Text(
          'シンボル',
          style: TextStyle(
            fontSize: screenWidth * 0.09,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1851),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.18,
        decoration: BoxDecoration(
          color: const Color(0xFF7EC593),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: _isLoadingLocation
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _currentPosition != null
              ? Stack(
                  children: [
                    MapBase.createMapWidget(
                      latitude: _currentPosition!.latitude,
                      longitude: _currentPosition!.longitude,
                      zoom: 14.0,
                      interactive: false,
                    ),
                    // タップ可能なオーバーレイ
                    Container(color: Colors.transparent),
                  ],
                )
              : const Center(
                  child: Icon(
                    Icons.location_off,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildYellowButtons(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenHeight * 0.09;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F337),
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.06),
        Expanded(
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F337),
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ),
        ),
      ],
    );
  }
}
