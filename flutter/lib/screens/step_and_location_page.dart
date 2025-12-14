import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'user_lookup_screen.dart';
import 'user_registration_screen.dart';

// 歩数 & 位置情報取得のデモページ
class StepAndLocationPage extends StatefulWidget {
  const StepAndLocationPage({super.key});

  @override
  State<StepAndLocationPage> createState() => _StepAndLocationPageState();
}

class _StepAndLocationPageState extends State<StepAndLocationPage> {
  // 歩数
  StreamSubscription<StepCount>? _stepSub;
  int? _currentSteps;

  // 位置情報
  Position? _currentPosition;
  String? _locationError;

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

  // 歩数の権限をリクエスト
  Future<void> _requestPedometerPermission() async {
    final status = await Permission.activityRecognition.request();

    if (status.isGranted) {
      _startPedometer();
    } else if (status.isDenied) {
      debugPrint('歩数カウント権限が拒否されました');
    } else if (status.isPermanentlyDenied) {
      debugPrint('歩数カウント権限が永続的に拒否されました。設定から許可してください。');
      openAppSettings();
    }
  }

  // 歩数ストリームの購読
  void _startPedometer() {
    _stepSub = Pedometer.stepCountStream.listen(
      (StepCount event) {
        setState(() {
          _currentSteps = event.steps; // 端末が返す累積歩数（多くは起動 or 再起動から）
        });
      },
      onError: (error) {
        debugPrint("Pedometer error: $error");
      },
    );
  }

  // 位置情報の取得
  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationError = null;
    });

    try {
      // 1. サービスONかチェック
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = '位置情報サービスがOFFです。';
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
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = '設定から位置情報の権限を許可してください。';
        });
        return;
      }

      // 3. 現在地を1回だけ取得
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      setState(() {
        _locationError = '位置情報の取得に失敗しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepsText = _currentSteps != null ? _currentSteps.toString() : '取得中…';

    String locationText;
    if (_locationError != null) {
      locationText = _locationError!;
    } else if (_currentPosition != null) {
      locationText =
          'lat: ${_currentPosition!.latitude.toStringAsFixed(6)},\n'
          'lng: ${_currentPosition!.longitude.toStringAsFixed(6)}';
    } else {
      locationText = '取得中…';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('歩数 & GPS デモ')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '現在の歩数（端末依存）',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(stepsText, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 32),
              const Text(
                '現在地（GPS）',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                locationText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('現在地を再取得'),
              ),
              const SizedBox(height: 32),
              const Text(
                'ユーザー機能',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserRegistrationScreen(),
                    ),
                  );
                },
                child: const Text('ユーザー登録ページへ'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserLookupScreen(),
                    ),
                  );
                },
                child: const Text('ユーザー情報を照会する'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
