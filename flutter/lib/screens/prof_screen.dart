import 'package:flutter/material.dart';
import '../base/base_layout.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';
import '../models/user.dart';

/// プロフィール画面
class ProfScreen extends StatefulWidget {
  const ProfScreen({super.key});

  @override
  State<ProfScreen> createState() => _ProfScreenState();
}

class _ProfScreenState extends State<ProfScreen> {
  User? _user;
  bool _isLoading = true;
  String? _error;
  int? _totalSteps; // 累計歩数

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTotalSteps();
  }

  Future<void> _loadUser() async {
    try {
      // 保存されているユーザーUUIDを取得
      final uuid = await UserStorage.getUserUuid();

      if (uuid == null) {
        if (mounted) {
          setState(() {
            _error = 'ユーザーが登録されていません';
            _isLoading = false;
          });
        }
        return;
      }

      // UUIDを使ってユーザー情報を取得
      final user = await ApiService.getUser(uuid);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'ユーザー情報の取得に失敗しました: $e';
          _isLoading = false;
        });
      }
    }
  }

  // 累計歩数を取得
  Future<void> _loadTotalSteps() async {
    try {
      // 保存されているユーザーUUIDを取得
      final uuid = await UserStorage.getUserUuid();

      if (uuid == null) {
        return;
      }

      // ユーザーの全歩数を取得
      final stepEntries = await ApiService.getStepsByUser(
        userUuid: uuid,
        limit: 10000, // 大きな値を設定して全件取得
      );

      // 累計を計算
      final total = stepEntries.fold<int>(0, (sum, entry) => sum + entry.step);

      if (mounted) {
        setState(() {
          _totalSteps = total;
        });
      }
    } catch (e) {
      debugPrint('累計歩数の取得に失敗しました: $e');
    }
  }

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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: _isLoading
                            ? const Text(
                                "読み込み中...",
                                style: TextStyle(
                                  color: Color(0xFFF0F337),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Text(
                                _user != null
                                    ? "Power's ${_user!.name}"
                                    : "Power's ゲスト",
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
                          _totalSteps != null
                              ? '累計歩数：$_totalSteps pow'
                              : '累計歩数：--- pow',
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

              // 編集項目
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showEditNameDialog(context),
                      child: _buildSquareItem(
                        context,
                        'ニックネーム変更',
                        assetPath: 'assets/images/icon_name.png',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.08),
                    GestureDetector(
                      onTap: () => _showEditHeightDialog(context),
                      child: _buildSquareItem(
                        context,
                        '身長変更',
                        assetPath: 'assets/images/icon_height.png',
                        imageFit: BoxFit.contain,
                        imageAlignment: Alignment(0, 0.2),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.08),
                    GestureDetector(
                      onTap: () => _showEditWeightDialog(context),
                      child: _buildSquareItem(
                        context,
                        '体重変更',
                        assetPath: 'assets/images/icon_weight.png',
                      ),
                    ),
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

  // ニックネーム変更ダイアログ
  void _showEditNameDialog(BuildContext context) {
    if (_user == null) return;

    final controller = TextEditingController(text: _user!.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ニックネーム変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ニックネーム',
            hintText: 'ここに文字を入力',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ニックネームを入力してください')),
                );
                return;
              }

              try {
                await ApiService.updateUser(
                  uuid: _user!.uuid,
                  name: controller.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  await _loadUser();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ニックネームを更新しました')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 身長変更ダイアログ
  void _showEditHeightDialog(BuildContext context) {
    if (_user == null) return;

    int selectedHeight = _user!.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('身長変更'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButton<int>(
              value: selectedHeight,
              isExpanded: true,
              items: List.generate(121, (index) => 100 + index).map((height) {
                return DropdownMenuItem<int>(
                  value: height,
                  child: Text('$height cm'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedHeight = value;
                  });
                }
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.updateUser(
                  uuid: _user!.uuid,
                  length: selectedHeight,
                );

                if (mounted) {
                  Navigator.pop(context);
                  await _loadUser();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('身長を更新しました')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 体重変更ダイアログ
  void _showEditWeightDialog(BuildContext context) {
    if (_user == null) return;

    int selectedWeight = _user!.weight;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('体重変更'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButton<int>(
              value: selectedWeight,
              isExpanded: true,
              items: List.generate(121, (index) => 30 + index).map((weight) {
                return DropdownMenuItem<int>(
                  value: weight,
                  child: Text('$weight kg'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedWeight = value;
                  });
                }
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ApiService.updateUser(
                  uuid: _user!.uuid,
                  weight: selectedWeight,
                );

                if (mounted) {
                  Navigator.pop(context);
                  await _loadUser();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('体重を更新しました')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 小さな正方形
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
