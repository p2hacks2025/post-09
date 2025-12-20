import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// プロフィール画面のダイアログ関連
class ProfScreenDialogs {
  /// ニックネーム変更ダイアログを表示
  static void showEditNameDialog(
    BuildContext context,
    User user,
    VoidCallback onSuccess,
  ) {
    final controller = TextEditingController(text: user.name);

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
                  uuid: user.uuid,
                  name: controller.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  onSuccess();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ニックネームを更新しました')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
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

  /// 身長変更ダイアログを表示
  static void showEditHeightDialog(
    BuildContext context,
    User user,
    VoidCallback onSuccess,
  ) {
    int selectedHeight = user.length;

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
                  uuid: user.uuid,
                  length: selectedHeight,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  onSuccess();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('身長を更新しました')));
                }
              } catch (e) {
                if (context.mounted) {
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

  /// 体重変更ダイアログを表示
  static void showEditWeightDialog(
    BuildContext context,
    User user,
    VoidCallback onSuccess,
  ) {
    int selectedWeight = user.weight;

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
                  uuid: user.uuid,
                  weight: selectedWeight,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  onSuccess();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('体重を更新しました')));
                }
              } catch (e) {
                if (context.mounted) {
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
}
