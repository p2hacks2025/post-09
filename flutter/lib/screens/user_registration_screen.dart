import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

// ユーザー登録画面
class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  User? _createdUser;

  @override
  void dispose() {
    _nameController.dispose();
    _lengthController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _createdUser = null;
    });

    try {
      final user = await ApiService.createUser(
        name: _nameController.text,
        length: int.parse(_lengthController.text),
        weight: int.parse(_weightController.text),
      );

      setState(() {
        _createdUser = user;
        _successMessage = 'ユーザーを登録しました！';
        _nameController.clear();
        _lengthController.clear();
        _weightController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'エラー: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー登録'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ユーザー情報を入力してください',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // 名前フィールド
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '名前',
                      hintText: '例：田中太郎',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '名前は必須です';
                      }
                      if (value.length > 255) {
                        return '名前は255文字以下にしてください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // 身長フィールド
                  TextFormField(
                    controller: _lengthController,
                    decoration: InputDecoration(
                      labelText: '身長 (cm)',
                      hintText: '例：170',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '身長は必須です';
                      }
                      final intVal = int.tryParse(value);
                      if (intVal == null) {
                        return '身長は数値で入力してください';
                      }
                      if (intVal < 0) {
                        return '身長は0以上である必要があります';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // 体重フィールド
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: '体重 (kg)',
                      hintText: '例：70',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '体重は必須です';
                      }
                      final intVal = int.tryParse(value);
                      if (intVal == null) {
                        return '体重は数値で入力してください';
                      }
                      if (intVal < 0) {
                        return '体重は0以上である必要があります';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // 送信ボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('登録する'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // エラーメッセージ
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[900]),
                ),
              ),
            // 成功メッセージ
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green[900]),
                    ),
                    if (_createdUser != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        '名前: ${_createdUser!.name}',
                        style: TextStyle(color: Colors.green[900]),
                      ),
                      Text(
                        '身長: ${_createdUser!.length} cm',
                        style: TextStyle(color: Colors.green[900]),
                      ),
                      Text(
                        '体重: ${_createdUser!.weight} kg',
                        style: TextStyle(color: Colors.green[900]),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
