import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../base/base_layout.dart';
import '../base/base_map.dart';
import '../base/base_kirakira.dart';
import 'symbol_monitor_screen.dart';
import 'symbol_pin_screen.dart';

// 実際のホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with KirakiraLevelMixin {
  // 位置情報
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    loadKirakiraLevel();
    fixKirakiraLevelIfExceedsMax(); // レベルが2を超えていたら修正
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
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // シンボルカード（サイズ固定）
            _buildSymbolCard(context),

            const Spacer(flex: 1),

            // マップカード（サイズ固定）
            _buildMapCard(context),

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolCard(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SymbolScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.35,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/symbol&back/back_lv$kirakiraLevel.png',
            ),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/symbol&back/symbol_lv$kirakiraLevel.png',
            fit: BoxFit.contain,
            width: screenWidth * 0.7,
            errorBuilder: (context, error, stack) {
              return const Text('symbol image not found');
            },
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
          MaterialPageRoute(builder: (context) => const SymbolPinScreen()),
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
              : _locationError != null
              ? Center(
                  child: Icon(
                    Icons.location_off,
                    color: Colors.white,
                    size: 40,
                  ),
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
}
