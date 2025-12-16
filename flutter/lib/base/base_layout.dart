import 'package:flutter/material.dart';
import '../screens/home_screen.dart';

// 全画面共通のベースレイアウト
class BaseLayout extends StatelessWidget {
  final Widget child; // メインコンテンツ
  final String? title; // タイトル（オプション）
  final bool showBackButton; // 戻るボタンを表示するか
  final int? stepCount; // 歩数（オプション、指定すると左上に歩数表示）

  const BaseLayout({
    super.key,
    required this.child,
    this.title,
    this.showBackButton = true,
    this.stepCount,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
            Expanded(child: child),

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
            if (stepCount != null)
              _buildStepCounter(context, stepCount!)
            else if (showBackButton)
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

            // タイトル（オプション）
            if (title != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: iconSize * 0.5,
                  vertical: iconSize * 0.25,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(iconSize * 0.3),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: iconSize * 0.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox.shrink(),

            const Spacer(),

            // 設定アイコン（背景なし）
            SizedBox(
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

    return GestureDetector(
      onTap: () {
        if (isHomeIcon) {
          // ホーム画面に遷移（スタックをクリアして新しくプッシュ）
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
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
