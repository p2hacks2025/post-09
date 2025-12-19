import 'package:flutter/material.dart';
import '../base/base_layout.dart';
import '../base/base_kirakira.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';

/// 足跡の累計を表示する画面
class StepTotalScreen extends StatefulWidget {
  const StepTotalScreen({super.key});

  @override
  State<StepTotalScreen> createState() => _StepTotalScreenState();
}

class _StepTotalScreenState extends State<StepTotalScreen>
    with KirakiraLevelMixin {
  int? _totalSteps; // 累計歩数
  bool _isLoading = true;
  String? _error;
  bool _isProcessing = false; // 処理中フラグ

  @override
  void initState() {
    super.initState();
    _loadTotalSteps();
    loadKirakiraLevel();
  }

  // 累計歩数を取得
  Future<void> _loadTotalSteps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 保存されているユーザーUUIDを取得
      final userUuid = await UserStorage.getUserUuid();

      if (userUuid == null) {
        setState(() {
          _error = 'ユーザーが登録されていません';
          _isLoading = false;
        });
        return;
      }

      // ユーザーの全歩数を取得
      final stepEntries = await ApiService.getStepsByUser(
        userUuid: userUuid,
        limit: 10000, // 大きな値を設定して全件取得
      );

      // 累計を計算
      final total = stepEntries.fold<int>(0, (sum, entry) => sum + entry.step);

      setState(() {
        _totalSteps = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '累計歩数の取得に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      showBackButton: false,
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              // 緑色のカード
              _buildStepCard(context),

              const Spacer(),

              // 黄色いボタン
              _buildSubmitButton(context),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // 歩数表示カード
  Widget _buildStepCard(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300, maxHeight: 380),
      decoration: BoxDecoration(
        color: const Color(0xFF368855), // 緑色
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // 足跡アイコン
          Image.asset(
            'assets/images/icon_step.png',
            width: 160,
            height: 160,
            color: const Color(0xFFF0F337), // 黄色にする
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.directions_walk,
                color: Color(0xFFF0F337),
                size: 160,
              );
            },
          ),

          const SizedBox(height: 20),

          // 「今までの歩数」テキスト
          const Text(
            '今までの歩数',
            style: TextStyle(
              color: Color(0xFFF0F337),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // 歩数の数値
          _isLoading
              ? const CircularProgressIndicator(color: Color(0xFFF0F337))
              : _error != null
              ? const Text(
                  'エラー',
                  style: TextStyle(
                    color: Color(0xFFF0F337),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Text(
                  '$_totalSteps歩',
                  style: const TextStyle(
                    color: Color(0xFFF0F337),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ポイントをシンボルに捧げるボタン
  Widget _buildSubmitButton(BuildContext context) {
    // ボタンの有効/無効を判定
    bool canLevelUp = false;
    String buttonText = 'ポイントをシンボルに捧げる';

    if (_totalSteps != null && !_isProcessing) {
      if (kirakiraLevel == 0 && _totalSteps! >= 1000) {
        canLevelUp = true;
      } else if (kirakiraLevel == 1 && _totalSteps! >= 3000) {
        canLevelUp = true;
      }
    }

    return GestureDetector(
      onTap: canLevelUp ? _handleLevelUp : null,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: canLevelUp
              ? const Color(0xFFF0F337) // 黄色
              : Colors.grey, // 無効時は灰色
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.black)
              : Text(
                  buttonText,
                  style: TextStyle(
                    color: canLevelUp ? Colors.black : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  // キラキラレベルを上げる処理
  Future<void> _handleLevelUp() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await incrementAndSyncKirakiraLevel();
    } catch (e) {
      // エラーハンドリングはincrementAndSyncKirakiraLevel内で行われる
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
