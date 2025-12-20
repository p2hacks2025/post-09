import 'package:flutter/material.dart';
import '../models/user.dart';

/// プロフィール画面のウィジェット部品
class ProfScreenWidgets {
  /// プロフィールカードを構築
  static Widget buildProfileCard(
    BuildContext context, {
    required bool isLoading,
    User? user,
    int? totalSteps,
    required int kirakiraLevel,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      height: screenHeight * 0.33,
      decoration: BoxDecoration(
        color: const Color(0xFF368855),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          // テキスト（左）
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 40),
              child: isLoading
                  ? const Text(
                      "読み込み中...",
                      style: TextStyle(
                        color: Color(0xFFF0F337),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      user != null ? "${user.name}" : "ゲスト",
                      style: const TextStyle(
                        color: Color(0xFFF0F337),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          // 画像（右下）
          Positioned(
            right: -screenWidth * 0.08,
            bottom: -screenWidth * 0.08,
            child: Image.asset(
              'assets/images/symbol&back/symbol_lv$kirakiraLevel.png',
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
              errorBuilder: (context, error, stackTrace) {
                return SizedBox(
                  width: screenWidth * 0.4,
                  height: screenWidth * 0.4,
                  child: const Icon(Icons.image, color: Color(0xFFF0F337)),
                );
              },
            ),
          ),
          // 累計歩数テキスト（左下）
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 40, bottom: 16),
              child: Text(
                totalSteps != null ? '累計歩数：$totalSteps pow' : '累計歩数：--- pow',
                style: const TextStyle(
                  color: Color(0xFFF0F337),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 編集項目の小さな正方形アイテムを構築
  static Widget buildSquareItem(
    BuildContext context,
    String label, {
    String? assetPath,
    BoxFit imageFit = BoxFit.cover,
    AlignmentGeometry imageAlignment = Alignment.center,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final squareSize = screenWidth * 0.1;

    return Row(
      children: [
        if (assetPath == null)
          Container(
            width: squareSize,
            height: squareSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              assetPath,
              width: squareSize,
              height: squareSize,
              fit: imageFit,
              alignment: imageAlignment,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: squareSize,
                  height: squareSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
        SizedBox(width: screenWidth * 0.04),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 編集可能な項目一覧を構築
  static Widget buildEditItems(
    BuildContext context, {
    required VoidCallback onNameTap,
    required VoidCallback onHeightTap,
    required VoidCallback onWeightTap,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onNameTap,
            child: buildSquareItem(
              context,
              'ニックネーム変更',
              assetPath: 'assets/images/icon_name.png',
            ),
          ),
          SizedBox(height: screenHeight * 0.08),
          GestureDetector(
            onTap: onHeightTap,
            child: buildSquareItem(
              context,
              '身長変更',
              assetPath: 'assets/images/icon_height.png',
              imageFit: BoxFit.contain,
              imageAlignment: Alignment(0, 0.2),
            ),
          ),
          SizedBox(height: screenHeight * 0.08),
          GestureDetector(
            onTap: onWeightTap,
            child: buildSquareItem(
              context,
              '体重変更',
              assetPath: 'assets/images/icon_weight.png',
            ),
          ),
        ],
      ),
    );
  }
}
