import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../base/base_layout.dart';
import '../base/map_base.dart';
import '../models/symbol.dart' as symbol_model;
import '../services/api_service.dart';

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

  // シンボル情報
  List<symbol_model.Symbol> _symbols = [];
  bool _isLoadingSymbols = true;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadSymbols();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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

    // ウィジェット描画後にマップを移動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
      }
    });
  }

  // シンボルデータの読み込み
  Future<void> _loadSymbols() async {
    setState(() {
      _isLoadingSymbols = true;
    });

    try {
      final symbols = await ApiService.getSymbols(limit: 1000);
      setState(() {
        _symbols = symbols;
        _isLoadingSymbols = false;
      });
    } catch (e) {
      debugPrint('シンボル取得エラー: $e');
      setState(() {
        _symbols = [];
        _isLoadingSymbols = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Expanded(flex: 16, child: _buildMapCard(context)),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return SizedBox.expand(
      child: _isLoadingLocation
          ? MapBase.buildLoadingPlaceholder()
          : _locationError != null
          ? MapBase.buildErrorPlaceholder(
              errorMessage: _locationError!,
              onRetry: _getCurrentLocation,
            )
          : _currentPosition != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: MapBase.createMapWidget(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
                zoom: 15.0,
                interactive: true,
                controller: _mapController,
                additionalMarkers: _isLoadingSymbols
                    ? null
                    : _symbols
                          .map(
                            (symbol) => MapBase.createAssetMarker(
                              symbol.symbolYCoord,
                              symbol.symbolXCoord,
                              'assets/images/icon_pin.png',
                              width: 40,
                              height: 40,
                            ),
                          )
                          .toList(),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
