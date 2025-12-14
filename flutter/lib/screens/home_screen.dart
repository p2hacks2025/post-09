import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

// 実際のホーム画面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<StepCount>? _stepSub;
  int? _currentSteps;

  @override
  void initState() {
    super.initState();
    _requestPedometerPermission();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final stepsText = _currentSteps != null ? _currentSteps.toString() : '---';

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

            // メインコンテンツ（スクロール可能）
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight * 0.06),

                      // シンボルカード
                      _buildSymbolCard(context),

                      SizedBox(height: screenHeight * 0.06),

                      // マップカード
                      _buildMapCard(context),

                      SizedBox(height: screenHeight * 0.06),

                      // 黄色いボタン2つ
                      _buildYellowButtons(context),

                      SizedBox(height: screenHeight * 0.06),
                    ],
                  ),
                ),
              ),
            ),

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

    return Container(height: navHeight, color: const Color(0xFFB0B4CF));
  }

  Widget _buildTopBar(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.12;
    final navHeight = screenHeight * 0.09;
    final stepsText = _currentSteps != null ? _currentSteps.toString() : '---';

    return Positioned(
      top: navHeight / 2 - iconSize / 2,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        child: Row(
          children: [
            // 足跡アイコン + 歩数表示（白背景・黒色）
            Container(
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
            ),

            const Spacer(),

            // ハンバーガーメニュー（白背景・黒色）
            Container(
              width: iconSize,
              height: iconSize,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: iconSize * 0.18,
                  vertical: iconSize * 0.18,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: iconSize * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      height: iconSize * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      height: iconSize * 0.12,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolCard(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.35,
      decoration: BoxDecoration(
        color: const Color(0xFFD4D4D4),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Text(
          'シンボル',
          style: TextStyle(
            fontSize: screenWidth * 0.09,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1851),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.18,
      decoration: BoxDecoration(
        color: const Color(0xFF7EC593),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Text(
          '簡易的なマップ?',
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1851),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildYellowButtons(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenHeight * 0.09;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F337),
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.06),
        Expanded(
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F337),
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final navHeight = screenHeight * 0.09;

    return Container(
      height: navHeight,
      color: const Color(0xFFB0B4CF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(4, (index) => _buildNavItem(context)),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.12;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: const BoxDecoration(
        color: Color(0xFFB0B4CF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/icon_prof.png',
          width: iconSize * 0.6,
          height: iconSize * 0.6,
          color: Colors.black,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              color: Colors.black,
              size: iconSize * 0.6,
            );
          },
        ),
      ),
    );
  }
}
