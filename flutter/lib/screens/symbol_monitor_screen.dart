import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base/base_layout.dart';
import '../base/base_kirakira.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';
import '../models/step.dart';

// シンボル画面
class SymbolScreen extends StatefulWidget {
  const SymbolScreen({super.key});

  @override
  State<SymbolScreen> createState() => _SymbolScreenState();
}

class _SymbolScreenState extends State<SymbolScreen> with KirakiraLevelMixin {
  StreamSubscription<StepCount>? _stepSub;
  int? _currentSteps; // デバイスの累積歩数
  bool _isMonitoring = false;
  int? _startSteps; // 計測開始時の累積歩数
  int _displaySteps = 0; // 画面に表示する歩数（計測中の差分）
  Key _refreshKey = UniqueKey(); // リロード用のキー

  // SharedPreferencesのキー
  static const String _keyIsMonitoring = 'step_monitoring_active';
  static const String _keyStartSteps = 'step_monitoring_start';

  @override
  void initState() {
    super.initState();
    _loadMonitoringState();
    loadKirakiraLevel();
    _startPedometer();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    super.dispose();
  }

  // 計測状態を読み込み
  Future<void> _loadMonitoringState() async {
    final prefs = await SharedPreferences.getInstance();
    final isMonitoring = prefs.getBool(_keyIsMonitoring) ?? false;
    final startSteps = prefs.getInt(_keyStartSteps);

    if (isMonitoring && startSteps != null) {
      setState(() {
        _isMonitoring = true;
        _startSteps = startSteps;
      });
    }
  }

  // 計測状態を保存
  Future<void> _saveMonitoringState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsMonitoring, _isMonitoring);
    if (_startSteps != null) {
      await prefs.setInt(_keyStartSteps, _startSteps!);
    } else {
      await prefs.remove(_keyStartSteps);
    }
  }

  void _startPedometer() {
    _stepSub = Pedometer.stepCountStream.listen(
      (event) {
        setState(() {
          _currentSteps = event.steps;
          // 計測中の場合、差分を計算して表示
          if (_isMonitoring && _startSteps != null) {
            _displaySteps = _currentSteps! - _startSteps!;
            // 表示歩数を保存（他の画面で参照するため）
            UserStorage.saveDisplaySteps(_displaySteps);
          }
        });
      },
      onError: (error) {
        setState(() {
          _currentSteps = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      showTopStepCounter: false,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              const Spacer(),

              // シンボル表示エリア
              Container(
                key: _refreshKey,
                height: screenHeight * 0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 背景画像
                    Image.asset(
                      'assets/images/symbol&back/back_lv$kirakiraLevel.png',
                      fit: BoxFit.cover,
                    ),
                    // シンボル画像
                    Padding(
                      padding: const EdgeInsets.all(1),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(1),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/symbol&back/symbol_lv$kirakiraLevel.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          _buildStepCounter(screenWidth),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    // リロードボタン（右上）
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // ページを再読み込み（ページ自体を置き換え）
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SymbolScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.rotate_left,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 下部のスタート/ストップボタン
              GestureDetector(
                onTap: _isMonitoring ? _handleStop : _handleStart,
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.09,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F337),
                    borderRadius: BorderRadius.circular(screenHeight * 0.045),
                  ),
                  child: Center(
                    child: Text(
                      _isMonitoring ? 'ストップ' : 'スタート',
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

  Future<void> _handleStart() async {
    if (_currentSteps == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('歩数の取得に失敗しました')));
      return;
    }

    setState(() {
      _isMonitoring = true;
      _startSteps = _currentSteps;
      _displaySteps = 0; // 計測開始時は0にリセット
    });

    // 状態を保存
    await _saveMonitoringState();
    // 表示歩数を0で保存
    await UserStorage.saveDisplaySteps(0);
  }

  Future<void> _handleStop() async {
    if (_currentSteps == null || _startSteps == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('歩数の計測に失敗しました')));
      return;
    }

    final stepDifference = _displaySteps; // 表示されている歩数を記録

    try {
      // 保存されているユーザーUUIDを取得
      final userUuid = await UserStorage.getUserUuid();

      if (userUuid == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ユーザーが登録されていません')));
        }
        return;
      }

      final request = StepCreateRequest(
        userUuid: userUuid,
        step: stepDifference,
        isStarted: false,
        createdAt: DateTime.now(),
      );

      await ApiService.createStep(request);

      // ユーザーのシンボルを取得してキラキラレベルを更新
      try {
        await syncKirakiraLevelToServer(level: kirakiraLevel);
      } catch (e) {
        debugPrint('キラキラレベルの更新に失敗: $e');
      }

      // 記録した歩数を保存
      await UserStorage.saveLastRecordedSteps(stepDifference);

      setState(() {
        _isMonitoring = false;
        _startSteps = null;
        _displaySteps = 0;
      });

      // 状態を保存（計測終了）
      await _saveMonitoringState();
      // 表示歩数をクリア
      await UserStorage.clearDisplaySteps();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${stepDifference}ポイント記録しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('記録に失敗しました: $e')));
      }
    }
  }

  Widget _buildStepCounter(double screenWidth) {
    final iconSize = screenWidth * 0.12;
    // 計測中は差分を表示、計測前は---を表示
    final stepsText = _isMonitoring ? '$_displaySteps pow' : '--- pow';

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
                stepsText,
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
