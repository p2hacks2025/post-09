import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../base/base_layout.dart';
import '../base/map_base.dart';

// マップ画面
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  StreamSubscription<StepCount>? _stepSub;
  int? _currentSteps;

  // 位置情報
  Position? _currentPosition;
  String? _locationError;
  bool _isLoadingLocation = true;
  String? _address; // 住所情報

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _requestPedometerPermission();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _mapController.dispose();
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

  // 緯度経度から住所を取得
  Future<void> _getAddressFromPosition(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        setState(() {
          _address =
              '${place.country} ${place.administrativeArea} ${place.locality} ${place.street}';
        });
      }
    } catch (e) {
      debugPrint('住所取得エラー: $e');
      setState(() {
        _address = '住所の取得に失敗しました';
      });
    }
  }

  // 位置情報の取得
  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationError = null;
      _isLoadingLocation = true;
    });

    try {
      // 1. サービスONかチェック
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = '位置情報サービスがOFFです。';
          _isLoadingLocation = false;
        });
        return;
      }

      // 2. 権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = '位置情報の権限が拒否されています。';
          _isLoadingLocation = false;
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = '設定から位置情報の権限を許可してください。';
          _isLoadingLocation = false;
        });
        return;
      }

      // 3. 現在地を取得
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = pos;
        _isLoadingLocation = false;
      });

      // 住所を取得
      await _getAddressFromPosition(pos.latitude, pos.longitude);

      // ウィジェット描画後にマップを移動
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        }
      });
    } catch (e) {
      setState(() {
        _locationError = '位置情報の取得に失敗しました: $e';
        _isLoadingLocation = false;
      });
    }
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

              // マップコンテンツ
              if (_isLoadingLocation)
                Container(
                  height: screenHeight * 0.5,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(height: screenHeight * 0.02),
                        const Text('位置情報を取得中...'),
                      ],
                    ),
                  ),
                )
              else if (_locationError != null)
                Container(
                  height: screenHeight * 0.5,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red.shade50,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 40),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            _locationError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.refresh),
                            label: const Text('再試行'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_currentPosition != null)
                // マップウィジェット
                Container(
                  height: screenHeight * 0.75,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: MapBase.createMapWidget(
                      latitude: _currentPosition!.latitude,
                      longitude: _currentPosition!.longitude,
                      zoom: 15.0,
                      interactive: true,
                      controller: _mapController,
                    ),
                  ),
                ),

              SizedBox(height: screenHeight * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}
