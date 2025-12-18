import 'package:flutter/material.dart';
import '../base/base_layout.dart';

/// 足跡の累計を表示する画面
class StepTotalScreen extends StatefulWidget {
  const StepTotalScreen({super.key});

  @override
  State<StepTotalScreen> createState() => _StepTotalScreenState();
}

class _StepTotalScreenState extends State<StepTotalScreen> {
  final String _currentSteps = '---'; // 未実装（後で合計歩数を表示）

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // 緑色のカード
              _buildStepCard(context),

              const SizedBox(height: 24),

              // 黄色いボタン
              _buildSubmitButton(context),

              const SizedBox(height: 24),
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
        color: const Color(0xFF7CC078), // 緑色
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
            color: Colors.white, // 白色にする
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.directions_walk,
                color: Colors.white,
                size: 160,
              );
            },
          ),

          const SizedBox(height: 20),

          // 「今までの歩数」テキスト
          const Text(
            '今までの歩数',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // 歩数の数値
          Text(
            '$_currentSteps歩',
            style: const TextStyle(
              color: Colors.white,
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
    return GestureDetector(
      onTap: () {
        // TODO: ポイントをシンボルに捧げる処理
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F337), // 黄色
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            'ポイントをシンボルに捧げる',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
