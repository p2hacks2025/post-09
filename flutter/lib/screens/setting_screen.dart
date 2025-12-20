import 'package:flutter/material.dart';
import '../base/base_layout.dart';
import '../services/user_storage.dart';
import '../services/api_service.dart';
import '../models/step.dart';
import 'start_screen.dart';

/// 設定画面
class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  double _bgmVolume = 0.7;
  double _seVolume = 0.7;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      title: '設定',
      showBackButton: false,
      showTopStepCounter: false,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // サウンド設定
              _buildSettingSection(
                context,
                title: 'サウンド',
                children: [
                  _buildSliderSettingItem(
                    context,
                    title: 'BGM',
                    value: _bgmVolume,
                    onChanged: (value) {
                      setState(() {
                        _bgmVolume = value;
                      });
                      debugPrint(
                        'BGM volume: ${(value * 100).toStringAsFixed(0)}%',
                      );
                    },
                  ),
                  _buildSliderSettingItem(
                    context,
                    title: 'SE',
                    value: _seVolume,
                    onChanged: (value) {
                      setState(() {
                        _seVolume = value;
                      });
                      debugPrint(
                        'SE volume: ${(value * 100).toStringAsFixed(0)}%',
                      );
                    },
                  ),
                ],
              ),

             const Spacer(),

              // 初期化設定
              _buildSettingSection(
                context,
                title: '初期化',
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 12,
                    ),
                    child: _buildPillButton(
                      context,
                      label: 'データを初期化する',
                      onTap: () async {
                        debugPrint('データ初期化ボタンが押されました');
                        // 保存されているユーザーUUIDをクリア
                        await UserStorage.clearUserUuid();
                        // StartScreenに遷移
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StartScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // インフル・コロナ設定
              _buildSettingSection(
                context,
                title: 'インフル・コロナ',
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF3D3A7D), width: 1),
                      ),
                    ),
                    child: const Text(
                      'このボタンを押した場合、期限が一週間伸びます\nインフル・コロナに罹患した時のみ押してください',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05,
                      vertical: 12,
                    ),
                    child: _buildPillButton(
                      context,
                      label: '伸ばす',
                      onTap: () async {
                        debugPrint('期限を一週間伸ばすボタンが押されました');

                        try {
                          // ユーザーUUIDを取得
                          final userUuid = await UserStorage.getUserUuid();
                          if (userUuid == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ユーザーが登録されていません')),
                              );
                            }
                            return;
                          }

                          // 1000歩を追加するステップレコードを作成
                          final request = StepCreateRequest(
                            userUuid: userUuid,
                            step: 1000,
                            isStarted: false,
                            createdAt: DateTime.now(),
                          );

                          await ApiService.createStep(request);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('累計歩数を+1000しました！お大事に！')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('エラー: $e')));
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.03, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2668),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSliderSettingItem(
    BuildContext context, {
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final volumeIcon = _getVolumeIcon(value);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF3D3A7D), width: 1)),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: Image(
              key: ValueKey('${title}_$volumeIcon'),
              image: ExactAssetImage(volumeIcon),
              width: 28,
              height: 28,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              gaplessPlayback: false,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.volume_up,
                  color: Colors.white,
                  size: 28,
                );
              },
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 15.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 15.0,
                      elevation: 2.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 15.0,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: onChanged,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    activeColor: const Color(0xFF368855),
                    inactiveColor: const Color(0xFF3D3A7D),
                    thumbColor: const Color(0xFFF0F337),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _volumeLevelLabel(value),
                      style: const TextStyle(
                        color: Color(0xFFA8ACD1),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${(value * 100).floor()}%',
                      style: const TextStyle(
                        color: Color(0xFFA8ACD1),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFB0B4CF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _getVolumeIcon(double value) {
    // 誤差対策のイプシロン
    const eps = 0.001;
    debugPrint('Volume icon update: value=$value');

    if (value <= eps) {
      return 'assets/images/volume/icon_mute.png';
    } else if (value >= 1.0 - eps) {
      return 'assets/images/volume/icon_max.png';
    } else if (value <= 0.50) {
      // 0.01〜0.50
      return 'assets/images/volume/icon_min.png';
    } else {
      // 0.51〜0.99
      return 'assets/images/volume/icon_mid.png';
    }
  }

  String _volumeLevelLabel(double value) {
    const eps = 0.001;
    if (value <= eps) return 'mute';
    if (value >= 1.0 - eps) return 'max';
    if (value <= 0.50) return 'min';
    return 'mid';
  }
}
