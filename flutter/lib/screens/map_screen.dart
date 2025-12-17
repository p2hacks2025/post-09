import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../base/base_layout.dart';
import '../base/map_base.dart';

// マップ画面
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 位置情報
  Position? _currentPosition;
  String? _locationError;
  bool _isLoadingLocation = true;
  String? _address; // 住所情報

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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

    // 住所を取得
    await _getAddressFromPosition(pos.latitude, pos.longitude);

    // ウィジェット描画後にマップを移動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.06),

              // マップコンテンツ
              if (_isLoadingLocation)
                MapBase.buildLoadingPlaceholder(height: screenHeight * 0.5)
              else if (_locationError != null)
                MapBase.buildErrorPlaceholder(
                  errorMessage: _locationError!,
                  onRetry: _getCurrentLocation,
                  height: screenHeight * 0.5,
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
