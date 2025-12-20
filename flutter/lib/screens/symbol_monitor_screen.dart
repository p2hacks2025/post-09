import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../base/base_layout.dart';
import '../base/base_kirakira.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';
import '../models/step.dart';
import '../models/symbol.dart';

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

  // シンボル関連
  List<Symbol> _userSymbols = []; // ユーザーのシンボルリスト
  int _currentSymbolIndex = 0; // 現在表示中のシンボルインデックス
  bool _isLoadingSymbols = true; // シンボル読み込み中フラグ

  // キラキラ残り時間関連
  int? _kirakiraRemainingTime; // 残り時間（秒）
  Timer? _remainingTimeTimer; // 残り時間更新用タイマー

  // 捧げる条件関連
  bool _canOfferCurrently = false; // 現在捧げられる状態かどうか

  // SharedPreferencesのキー
  static const String _keyIsMonitoring = 'step_monitoring_active';
  static const String _keyStartSteps = 'step_monitoring_start';

  @override
  void initState() {
    super.initState();
    _loadMonitoringState();
    loadKirakiraLevel();
    fixKirakiraLevelIfExceedsMax(); // レベルが2を超えていたら修正
    _startPedometer();
    _loadUserSymbols();
    _startRemainingTimeUpdate();
    // 初回の条件チェック
    _checkOfferConditions();
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _remainingTimeTimer?.cancel();
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

  // ユーザーのシンボルリストを読み込み
  Future<void> _loadUserSymbols() async {
    try {
      final userUuid = await UserStorage.getUserUuid();
      if (userUuid == null) {
        setState(() {
          _isLoadingSymbols = false;
        });
        return;
      }

      final userSymbols = await ApiService.getSymbolsByUser(userUuid: userUuid);
      setState(() {
        _userSymbols = userSymbols.symbols;
        _isLoadingSymbols = false;
      });
      // シンボルがロードされた後に残り時間を取得
      _updateRemainingTime();
    } catch (e) {
      debugPrint('シンボルの読み込みに失敗: $e');
      setState(() {
        _isLoadingSymbols = false;
      });
    }
  }

  // 次のシンボルに切り替え
  void _showNextSymbol() {
    if (_userSymbols.isEmpty) return;
    setState(() {
      _currentSymbolIndex = (_currentSymbolIndex + 1) % _userSymbols.length;
    });
    _updateRemainingTime(); // シンボル変更時に残り時間も更新
    _checkOfferConditions(); // シンボル変更時に条件をチェック
  }

  // 前のシンボルに切り替え
  void _showPreviousSymbol() {
    if (_userSymbols.isEmpty) return;
    setState(() {
      _currentSymbolIndex =
          (_currentSymbolIndex - 1 + _userSymbols.length) % _userSymbols.length;
    });
    _updateRemainingTime(); // シンボル変更時に残り時間も更新
    _checkOfferConditions(); // シンボル変更時に条件をチェック
  }

  // 現在のシンボル
  Symbol? get _currentSymbol {
    if (_userSymbols.isEmpty) return null;
    return _userSymbols[_currentSymbolIndex];
  }

  // 残り時間の定期更新を開始
  void _startRemainingTimeUpdate() {
    _updateRemainingTime();
    _remainingTimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateRemainingTime();
    });
  }

  // 残り時間を取得して更新
  Future<void> _updateRemainingTime() async {
    final currentSymbol = _currentSymbol;
    if (currentSymbol == null) return;

    try {
      final remainingTime = await ApiService.getKirakiraRemainingTime(
        currentSymbol.uuid,
      );
      if (mounted) {
        setState(() {
          _kirakiraRemainingTime = remainingTime;
        });
      }
    } catch (e) {
      debugPrint('残り時間の取得に失敗: $e');
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
        // 歩数更新時に条件をチェック
        _checkOfferConditions();
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

    // 表示するキラキラレベル（現在のシンボルがあればそのレベル、なければデフォルト）
    final displayKirakiraLevel = _currentSymbol?.kirakiraLevel ?? kirakiraLevel;

    return BaseLayout(
      showBackButton: false,
      showTopStepCounter: false,
      customTopLeftWidget: _kirakiraRemainingTime != null
           ? _buildRemainingTimeWidget(screenWidth)
           : null,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              const Spacer(),

              // インジケーターとシンボル名を上部に表示
              if (!_isLoadingSymbols && _userSymbols.isNotEmpty)
                _buildSymbolIndicatorAndName(screenWidth),

              const Spacer(),

              // シンボル表示エリア（背景サイズを少し小さく）
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  // フリック（スワイプ）の検出
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! > 0) {
                      // 右スワイプ（前のシンボル）
                      _showPreviousSymbol();
                    } else if (details.primaryVelocity! < 0) {
                      // 左スワイプ（次のシンボル）
                      _showNextSymbol();
                    }
                  }
                },
                child: Container(
                  key: _refreshKey,
                  height: screenHeight * 0.52, // 背景サイズを若干小さく（0.6 -> 0.52）
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 背景画像
                      Image.asset(
                        'assets/images/symbol&back/back_lv$displayKirakiraLevel.png',
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
                                    'assets/images/symbol&back/symbol_lv$displayKirakiraLevel.png',
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
              ),

              const Spacer(),

              // 下部のボタン（スタート時は1つ、計測中は2つ）
              if (_isMonitoring)
                // 計測中：「ポイントを捧げる」と「ゴール」の2つのボタン
                Row(
                  children: [
                    // 左：ポイントを捧げるボタン
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleOfferPoints,
                        child: Container(
                          height: screenHeight * 0.09,
                          decoration: BoxDecoration(
                            color: _canOfferCurrently
                                ? const Color(0xFFF0F337) // 黄色
                                : const Color(0xFFB0B4CF), // 薄い青（グレーブルー）
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Center(
                            child: Text(
                              'ポイントを捧げる',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 右：ゴールボタン
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleStop,
                        child: Container(
                          height: screenHeight * 0.09,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F337),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Center(
                            child: Text(
                              'ゴール',
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
                    ),
                  ],
                )
              else
                // スタート前：スタートボタン
                GestureDetector(
                  onTap: _handleStart,
                  child: Container(
                    width: double.infinity,
                    height: screenHeight * 0.09,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F337),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Center(
                      child: Text(
                        'スタート',
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

  // インジケーターとシンボル名を表示するウィジェット
  Widget _buildSymbolIndicatorAndName(double screenWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        children: [
          // インジケーター（小さい丸）
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_userSymbols.length, (index) {
              final isActive = index == _currentSymbolIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 10 : 8,
                height: isActive ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? const Color(0xFFF0F337) // 黄色
                      : const Color(0xFFB0B4CF), // グレーブルー
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // シンボル名
          Text(
            _currentSymbol?.symbolName ?? '---',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // キラキラ残り時間を表示するウィジェット
  Widget _buildRemainingTimeWidget(double screenWidth) {
    final iconSize = screenWidth * 0.12;

    // APIから返される値は既に時間単位（int型）なので、そのまま表示
    final timeText = '$_kirakiraRemainingTime 時間';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: iconSize * 0.3,
        vertical: iconSize * 0.2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(iconSize * 0.3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 時計アイコン（赤色、外周が矢印）
          Icon(Icons.update, color: Colors.red, size: iconSize * 0.6),
          SizedBox(width: iconSize * 0.16),
          // 残り時間テキスト
          Text(
            timeText,
            style: TextStyle(
              color: Colors.black,
              fontSize: iconSize * 0.32,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 捧げる条件を定期的にチェック（UIの色変更用、エラーメッセージなし）
  Future<void> _checkOfferConditions() async {
    if (!_isMonitoring) {
      setState(() {
        _canOfferCurrently = false;
      });
      return;
    }

    // キラキラレベルが既にMAX（2）の場合は捧げられない
    if (kirakiraLevel >= 2) {
      setState(() {
        _canOfferCurrently = false;
      });
      return;
    }

    // 歩数条件チェック
    bool stepsOk = false;
    if (kirakiraLevel == 0 && _displaySteps >= 1000) {
      stepsOk = true;
    } else if (kirakiraLevel == 1 && _displaySteps >= 4000) {
      stepsOk = true;
    }

    if (!stepsOk) {
      setState(() {
        _canOfferCurrently = false;
      });
      return;
    }

    // シンボルが存在するか
    final currentSymbol = _currentSymbol;
    if (currentSymbol == null) {
      setState(() {
        _canOfferCurrently = false;
      });
      return;
    }

    // 距離条件チェック
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _canOfferCurrently = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distance = Geolocator.distanceBetween(
        currentSymbol.symbolYCoord,
        currentSymbol.symbolXCoord,
        position.latitude,
        position.longitude,
      );

      setState(() {
        _canOfferCurrently = distance <= 30.0;
      });
    } catch (e) {
      setState(() {
        _canOfferCurrently = false;
      });
    }
  }

  // ポイントを捧げるボタンが有効かどうかを判定（タップ時の詳細チェック、エラーメッセージあり）
  Future<bool> _canOfferPoints() async {
    // キラキラレベルが既にMAX（2）の場合は捧げられない
    if (kirakiraLevel >= 2) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('レベルがMAXです')));
      }
      return false;
    }

    // 歩数条件チェック
    if (kirakiraLevel == 0 && _displaySteps < 1000) {
      return false;
    }
    if (kirakiraLevel == 1 && _displaySteps < 4000) {
      return false;
    }

    // 距離条件チェック（30m以内）
    final currentSymbol = _currentSymbol;
    if (currentSymbol == null) {
      return false;
    }

    try {
      // 位置情報の権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('位置情報の権限が必要です')));
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('設定から位置情報の権限を許可してください')));
        }
        return false;
      }

      // 現在位置を取得
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // シンボルとの距離を計算（メートル単位）
      final distance = Geolocator.distanceBetween(
        currentSymbol.symbolYCoord, // 緯度
        currentSymbol.symbolXCoord, // 経度
        position.latitude,
        position.longitude,
      );

      // 30m以内かチェック
      if (distance > 30.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'シンボルから${distance.toStringAsFixed(0)}m離れています。30m以内に近づいてください',
              ),
            ),
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('位置情報の取得に失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('位置情報の取得に失敗しました: $e')));
      }
      return false;
    }
  }

  // ポイントを捧げる処理
  Future<void> _handleOfferPoints() async {
    if (!await _canOfferPoints()) return;

    try {
      // キラキラレベルを+1
      final newLevel = kirakiraLevel + 1;
      await syncKirakiraLevelToServer(level: newLevel);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('キラキラレベルが${newLevel}に上がりました！')));
      }

      // UIを更新
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('レベルアップに失敗しました: $e')));
      }
    }
  }

  Future<void> _handleStart() async {
    if (_currentSteps == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('歩数の取得に失敗しました')));
      return;
    }

    // 追加歩数（ボーナス歩数）を取得
    final bonusSteps = await UserStorage.getBonusSteps();

    setState(() {
      _isMonitoring = true;
      _startSteps = _currentSteps;
      _displaySteps = bonusSteps; // 追加歩数から開始
    });

    // 状態を保存
    await _saveMonitoringState();
    // 表示歩数を追加歩数で保存
    await UserStorage.saveDisplaySteps(bonusSteps);
    // 追加歩数をクリア（使用済み）
    await UserStorage.clearBonusSteps();

    // 追加歩数があった場合は通知
    if (bonusSteps > 0 && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ボーナス歩数+${bonusSteps}が適用されました！')));
    }
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
