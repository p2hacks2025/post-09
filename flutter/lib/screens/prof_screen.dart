import 'package:flutter/material.dart';
import '../base/base_layout.dart';

/// プロフィール画面
class ProfScreen extends StatefulWidget {
  const ProfScreen({super.key});

  @override
  State<ProfScreen> createState() => _ProfScreenState();
}

class _ProfScreenState extends State<ProfScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.06),

              // 緑色の長方形
              Container(
                width: double.infinity,
                height: screenHeight * 0.33,
                decoration: BoxDecoration(
                  color: const Color(0xFF368855),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Stack(
                  children: [
                    // テキスト（左）
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 40),
                        child: Text(
                          "Power's とがし",
                          style: TextStyle(
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
                        'assets/images/symbol_1.png',
                        width: screenWidth * 0.4,
                        height: screenWidth * 0.4,
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            width: screenWidth * 0.4,
                            height: screenWidth * 0.4,
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFFF0F337),
                            ),
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
                          '累計歩数：--- pow',
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
              ),

              SizedBox(height: screenHeight * 0.06),

              // 4つの小さな正方形（仮置き）
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSquareItem(
                      context,
                      'ニックネーム入力',
                      assetPath: 'assets/images/icon_name.png',
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    _buildSquareItem(
                      context,
                      '身長入力',
                      assetPath: 'assets/images/icon_height.png',
                      imageFit: BoxFit.contain,
                      imageAlignment: Alignment(0, 0.2),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    _buildSquareItem(
                      context,
                      '体重入力',
                      assetPath: 'assets/images/icon_weight.png',
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    _buildSquareItem(context, '---'),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.06),
            ],
          ),
        ),
      ),
    );
  }

  // 小さな正方形（仮置き）
  Widget _buildSquareItem(
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
}
