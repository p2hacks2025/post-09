import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// マップ関連の共通処理を提供するクラス
class MapBase {
  /// 位置情報サービスの有効確認と権限チェックを行う
  static Future<bool> checkLocationPermission() async {
    // 1. サービスONかチェック
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 2. 権限チェック
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// 現在の位置情報を取得する
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return pos;
    } catch (e) {
      debugPrint('位置情報取得エラー: $e');
      return null;
    }
  }

  /// OpenStreetMapのタイルレイヤーを作成
  static TileLayer createTileLayer() {
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'powers_app',
      maxNativeZoom: 19,
    );
  }

  /// 現在位置を示すマーカーを作成
  static Marker createCurrentLocationMarker(
    double latitude,
    double longitude, {
    double width = 40,
    double height = 40,
    double iconSize = 20,
  }) {
    return Marker(
      point: LatLng(latitude, longitude),
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withAlpha(200),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(Icons.location_on, color: Colors.white, size: iconSize),
      ),
    );
  }

  /// マップウィジェットを作成（基本設定）
  static Widget createMapWidget({
    required double latitude,
    required double longitude,
    double zoom = 15.0,
    bool interactive = true,
    MapController? controller,
    List<Marker>? additionalMarkers,
  }) {
    final markers = [
      createCurrentLocationMarker(latitude, longitude),
      if (additionalMarkers != null) ...additionalMarkers,
    ];

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: LatLng(latitude, longitude),
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        createTileLayer(),
        MarkerLayer(markers: markers),
      ],
    );
  }

  /// ローディング中のプレースホルダーウィジェット
  static Widget buildLoadingPlaceholder({
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('位置情報を取得中...'),
          ],
        ),
      ),
    );
  }

  /// エラー表示ウィジェット
  static Widget buildErrorPlaceholder({
    required String errorMessage,
    VoidCallback? onRetry,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: Colors.red.shade50,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 40),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('再試行'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
