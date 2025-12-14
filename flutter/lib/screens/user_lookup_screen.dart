import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

//ユーザー照会画面
class UserLookupScreen extends StatefulWidget {
  const UserLookupScreen({super.key});

  @override
  State<UserLookupScreen> createState() => _UserLookupScreenState();
}

class _UserLookupScreenState extends State<UserLookupScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  User? _result;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'ユーザー名を入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });
    try {
      final users = await ApiService.getUsers();
      final match = users.firstWhere(
        (u) => u.name == name,
        orElse: () => User(uuid: '', name: '', length: 0, weight: 0),
      );
      if (match.uuid.isEmpty) {
        setState(() {
          _errorMessage = '該当のユーザーは見つかりませんでした';
        });
      } else {
        setState(() {
          _result = match;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '検索中にエラーが発生しました: $e';
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
        title: const Text('ユーザー情報照会'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ユーザー名を入力して検索します'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _lookup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('APIを叩く'),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            if (_result != null) ...[
              const Divider(),
              Text('名前: ${_result!.name}'),
              Text('身長: ${_result!.length} cm'),
              Text('体重: ${_result!.weight} kg'),
            ],
          ],
        ),
      ),
    );
  }
}
