import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/home_screen.dart';
import '../screens/map_screen.dart';
import '../screens/step_total_screen.dart';
import '../screens/prof_screen.dart';
import '../screens/setting_screen.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';

// 全画面共通のベースレイアウト
class BaseLayout extends StatefulWidget {
  final Widget child; // メインコンテンツ
  final String? title; // タイトル（オプション）
  final bool showBackButton; // 戻るボタンを表示するか
  final bool showTopStepCounter; // 上部の歩数表示を出すか

  const BaseLayout({
    super.key,
    required this.child,
    this.title,
    this.showBackButton = true,
    this.showTopStepCounter = true,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  StreamSubscription<StepCount>? _stepSub;
  int? _deviceSteps; // デバイスの累積歩数
  int? _apiSteps; // APIから取得した歩数
  String? _currentUserUuid; // 現在のユーザーUUID
  Timer? _updateTimer; // 定期更新用タイマー

  @override
  void initState() {
    super.initState();
    _requestPedometerPermission();
    _loadInitialData();
    _startPeriodicUpdate();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  // 定期的に表示を更新（計測中の歩数を反映）
  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          // 状態を更新してUIを再描画
        });
      }
    });
  }

  // 初期データを読み込み（ユーザーと本日の歩数）
  Future<void> _loadInitialData() async {
    try {
      // 保存されているユーザーUUIDを取得
      final userUuid = await UserStorage.getUserUuid();

      if (userUuid != null) {
        setState(() {
          _currentUserUuid = userUuid;
        });
        _fetchTodaySteps(userUuid);
      }
    } catch (e) {
      debugPrint('Failed to load initial data: $e');
    }
  }

  // 本日の歩数をAPIから取得
  Future<void> _fetchTodaySteps(String userUuid) async {
    try {
      final dailyTotal = await ApiService.getDailyTotalSteps(
        userUuid: userUuid,
        targetDate: DateTime.now(),
      );
      setState(() {
        _apiSteps = dailyTotal.totalSteps;
      });
    } catch (e) {
      debugPrint('Failed to fetch today steps: $e');
    }
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
          _deviceSteps = event.steps;
        });
      },
      onError: (error) {
        debugPrint('Pedometer error: $error');
      },
    );
  }

  // 表示する歩数を取得（計測中なら計測中の歩数、そうでなければ直前の記録）
  Future<int> _getDisplaySteps() async {
    // まず計測中の歩数を確認
    final displaySteps = await UserStorage.getDisplaySteps();
    if (displaySteps != null) {
      return displaySteps;
    }

    // 計測中でなければ直前に記録した歩数を表示
    final lastRecordedSteps = await UserStorage.getLastRecordedSteps();
    if (lastRecordedSteps != null) {
      return lastRecordedSteps;
    }

    // 何もなければ0
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1851), // ダークブルー背景
      body: SafeArea(
        child: Column(
          children: [
            // 上部ナビゲーションとアイコンを重ねて配置
            Stack(
              clipBehavior: Clip.none,
              children: [_buildTopNavigation(context), _buildTopBar(context)],
            ),

            // メインコンテンツ
            Expanded(child: widget.child),

            // ボトムナビゲーション
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final navHeight = screenHeight * 0.09;

    return Container(
      height: navHeight,
      color: const Color(0xFFB0B4CF), // 薄い青のバー
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.12;
    final navHeight = screenHeight * 0.09;
    final stepCounterHeight = iconSize * 1.15; // 歩数表示の高さ
    final maxHeight = iconSize > stepCounterHeight
        ? iconSize
        : stepCounterHeight;

    return Positioned(
      top: (navHeight - maxHeight) / 2,
      bottom: (navHeight - maxHeight) / 2,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Row(
          children: [
            // 左上のウィジェット（歩数表示または戻るボタン）
            if (widget.showTopStepCounter)
              FutureBuilder<int>(
                future: _getDisplaySteps(),
                builder: (context, snapshot) {
                  final steps = snapshot.data ?? 0;
                  return _buildStepCounter(context, steps);
                },
              )
            else if (widget.showBackButton)
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: iconSize * 0.6,
                  ),
                ),
              )
            else
              SizedBox(width: iconSize),

            const Spacer(),

            // タイトル（オプション、無背景で中央に表示）
            if (widget.title != null)
              Text(
                widget.title!,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: iconSize * 0.5,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              const SizedBox.shrink(),

            const Spacer(),

            // 設定アイコン（背景なし）
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingScreen(),
                  ),
                );
              },
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: Center(
                  child: Image.asset(
                    'assets/images/icon_setting.png',
                    width: iconSize * 0.8,
                    height: iconSize * 0.8,
                    color: Colors.black,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.settings,
                        color: Colors.black,
                        size: iconSize * 0.8,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final navHeight = screenHeight * 0.09;
    const iconAssets = [
      'assets/images/icon_home.png',
      'assets/images/icon_map.png',
      'assets/images/icon_step.png',
      'assets/images/icon_prof.png',
    ];

    return Container(
      height: navHeight,
      color: const Color(0xFFB0B4CF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: iconAssets
            .map((assetPath) => _buildNavItem(context, assetPath))
            .toList(),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String assetPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.12;
    const iconColor = Colors.black; // 全アイコンを濃いトーンで統一
    final isMapIcon = assetPath.contains('icon_map');
    final isHomeIcon = assetPath.contains('icon_home');
    final isStepIcon = assetPath.contains('icon_step');
    final isProfIcon = assetPath.contains('icon_prof');

    return GestureDetector(
      onTap: () {
        if (isHomeIcon) {
          // ホーム画面に遷移（スタックをクリアして新しくプッシュ）
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        } else if (isMapIcon) {
          // マップ画面に遷移
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const MapScreen()));
        } else if (isStepIcon) {
          // 足跡累計画面に遷移
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const StepTotalScreen()),
          );
        } else if (isProfIcon) {
          // プロフィール画面に遷移
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const ProfScreen()));
        }
      },
      child: Container(
        width: iconSize,
        height: iconSize,
        decoration: const BoxDecoration(
          color: Color(0xFFB0B4CF),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isMapIcon
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.black, Colors.black],
                  ).createShader(bounds),
                  blendMode: BlendMode.srcATop,
                  child: Image.asset(
                    assetPath,
                    width: iconSize * 0.76,
                    height: iconSize * 0.76,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.map,
                        color: iconColor,
                        size: iconSize * 0.76,
                      );
                    },
                  ),
                )
              : Image.asset(
                  assetPath,
                  width: iconSize * 0.72,
                  height: iconSize * 0.72,
                  color: iconColor,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      color: iconColor,
                      size: iconSize * 0.72,
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildStepCounter(BuildContext context, int steps) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.12;
    final stepsText = steps.toString();

    return Container(
      width: iconSize * 2.8,
      height: iconSize * 1.15,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(iconSize * 0.3),
      ),
      padding: EdgeInsets.symmetric(horizontal: iconSize * 0.2),
      child: Row(
        children: [
          Image.asset(
            'assets/images/icon_step.png',
            width: iconSize * 0.6,
            height: iconSize * 0.6,
            color: Colors.black,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.directions_walk,
                color: Colors.black,
                size: iconSize * 0.6,
              );
            },
          ),
          SizedBox(width: iconSize * 0.16),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '$stepsText pow',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: iconSize * 0.32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
