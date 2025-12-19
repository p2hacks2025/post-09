import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../base/base_layout.dart';
import '../base/map_base.dart';
import 'symbol_monitor_screen.dart';

/// シンボルの位置をマップ上で指定する画面（ベース導入）
class SymbolPinScreen extends StatefulWidget {
  const SymbolPinScreen({super.key});

  @override
  State<SymbolPinScreen> createState() => _SymbolPinScreenState();
}

class _SymbolPinScreenState extends State<SymbolPinScreen> {
  Position? _currentPosition;
  String? _locationError;
  bool _isLoadingLocation = true;
  bool _showLabel = true;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showLabel = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationError = null;
      _isLoadingLocation = true;
    });

    final pos = await MapBase.getCurrentPosition();

    if (pos == null) {
      setState(() {
        _locationError = '位置情報の取得に失敗しました。設定を確認してください。';
        _isLoadingLocation = false;
      });
      return;
    }

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
      showBackButton: true,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              const Spacer(),

              // マップベース（共通MapBase + 位置取得の導入）
              if (_isLoadingLocation)
                MapBase.buildLoadingPlaceholder(height: screenHeight * 0.6)
              else if (_locationError != null)
                MapBase.buildErrorPlaceholder(
                  errorMessage: _locationError!,
                  onRetry: _getCurrentLocation,
                  height: screenHeight * 0.6,
                )
              else if (_currentPosition != null)
                Container(
                  height: screenHeight * 0.6,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: MapBase.createMapWidget(
                          latitude: _currentPosition!.latitude,
                          longitude: _currentPosition!.longitude,
                          zoom: 15.0,
                          interactive: true,
                          controller: _mapController,
                          includeCurrentMarker: false,
                          additionalMarkers: const [],
                        ),
                      ),
                      // 曇ったオーバーレイ（濃いグレーで曇ったイメージ、5秒後に消える）
                      if (_showLabel)
                        Positioned.fill(
                          child: Container(color: Colors.grey.withAlpha(180)),
                        ),
                      // 画面中央に固定されたピン（常時表示）
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: IgnorePointer(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/icon_pin.png',
                                  width: 48,
                                  height: 48,
                                ),
                                if (_showLabel) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'シンボルの位置を決めよう',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                MapBase.buildErrorPlaceholder(
                  errorMessage: '位置情報が取得できませんでした',
                  onRetry: _getCurrentLocation,
                  height: screenHeight * 0.6,
                ),

              const Spacer(),

              // 確定ボタン
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SymbolScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.09,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F337),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      'この場所に決めた！',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
