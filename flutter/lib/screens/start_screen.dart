import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';
import 'home_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _showWelcome = true;
  bool _showCompleteMessage = false;
  int? _selectedHeight;
  int? _selectedWeight;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 3秒後にユーザー登録画面に切り替える
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showWelcome = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1851),
      body: _showWelcome
          ? _buildWelcomeScreen()
          : _showCompleteMessage
          ? _buildCompleteMessageScreen()
          : _buildUserRegistrationScreen(),
    );
  }

  Future<void> _registerUser() async {
    // 入力チェック
    if (_nameController.text.isEmpty) {
      _showErrorDialog('ニックネームを入力してください');
      return;
    }
    if (_selectedHeight == null) {
      _showErrorDialog('身長を選択してください');
      return;
    }
    if (_selectedWeight == null) {
      _showErrorDialog('体重を選択してください');
      return;
    }

    try {
      // APIにユーザー情報を保存
      final user = await ApiService.createUser(
        name: _nameController.text,
        length: _selectedHeight!,
        weight: _selectedWeight!,
      );

      // ユーザーUUIDをローカルに保存
      await UserStorage.saveUserUuid(user.uuid);

      // 完了メッセージを表示
      if (mounted) {
        setState(() {
          _showCompleteMessage = true;
        });
      }

      // 3秒後にホーム画面に遷移
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showErrorDialog('登録に失敗しました: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteMessageScreen() {
    return Center(
      child: Text(
        '最高の体験を始めましょう',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'こんにちは',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'ユーザー情報を登録しましょう',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRegistrationScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ニックネームフィールド
              _buildTextFormField(
                label: 'ニックネーム',
                hintText: 'ここに文字を入力',
                controller: _nameController,
              ),
              const SizedBox(height: 32),
              // 身長と体重を横並びに
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: '身長（cm）',
                      value: _selectedHeight,
                      items: List.generate(121, (index) => 100 + index),
                      onChanged: (value) {
                        setState(() {
                          _selectedHeight = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: '体重（kg）',
                      value: _selectedWeight,
                      items: List.generate(121, (index) => 30 + index),
                      onChanged: (value) {
                        setState(() {
                          _selectedWeight = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),
              // 次へボタン
              GestureDetector(
                onTap: _registerUser,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F337),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Center(
                    child: Text(
                      '次へ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFB0B4CF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required int? value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFB0B4CF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              hint: const Text('選択', style: TextStyle(color: Colors.grey)),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              dropdownColor: const Color(0xFFB0B4CF),
              items: items.map((int item) {
                return DropdownMenuItem<int>(
                  value: item,
                  child: Text(
                    item.toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
