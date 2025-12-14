import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


String get baseUrl {
  final raw = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
  return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step & GPS Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StepAndLocationPage(),
    );
  }
}

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

  // FastAPIからのメッセージ
  String? _apiMessage;
  String? _apiError;
  bool _isCallingApi = false;

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
        desiredAccuracy: LocationAccuracy.high,
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

  // FastAPI のテスト用エンドポイントを叩く
  Future<void> _callTestApi() async {
    setState(() {
      _isCallingApi = true;
      _apiError = null;
    });

    try {
      final uri = Uri.parse('$baseUrl/tests/test-db');

      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final body = res.body;
        // JSON なら decode して message を拾う
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic> &&
              decoded.containsKey('message')) {
            setState(() {
              _apiMessage = decoded['message']?.toString();
            });
          } else {
            setState(() {
              _apiMessage = body;
            });
          }
        } catch (_) {
          // JSON でなければそのまま表示
          setState(() {
            _apiMessage = body;
          });
        }
      } else {
        setState(() {
          _apiError = 'ステータスコード: ${res.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _apiError = 'API 呼び出しエラー: $e';
      });
    } finally {
      setState(() {
        _isCallingApi = false;
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
                'FastAPI との通信テスト',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isCallingApi ? null : _callTestApi,
                child: const Text('API を叩く'),
              ),
              const SizedBox(height: 8),
              if (_isCallingApi)
                const Text('通信中...')
              else if (_apiError != null)
                Text(_apiError!, style: const TextStyle(color: Colors.red))
              else if (_apiMessage != null)
                Text('レスポンス: $_apiMessage'),
            ],
          ),
        ),
      ),
    );
  }
}
