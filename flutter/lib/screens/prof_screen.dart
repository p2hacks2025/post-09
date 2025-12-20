import 'package:flutter/material.dart';
import '../base/base_layout.dart';
import '../base/base_kirakira.dart';
import '../services/api_service.dart';
import '../services/user_storage.dart';
import '../models/user.dart';
import 'prof_screen_dialogs.dart';
import 'prof_screen_widgets.dart';

/// プロフィール画面
class ProfScreen extends StatefulWidget {
  const ProfScreen({super.key});

  @override
  State<ProfScreen> createState() => _ProfScreenState();
}

class _ProfScreenState extends State<ProfScreen> with KirakiraLevelMixin {
  User? _user;
  bool _isLoading = true;
  String? _error;
  int? _totalSteps; // 累計歩数

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTotalSteps();
    loadKirakiraLevel();
    fixKirakiraLevelIfExceedsMax(); // レベルが2を超えていたら修正
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

  // データ再読み込み
  Future<void> _reloadData() async {
    await _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      showBackButton: false,
      child: SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              const Spacer(),

              // プロフィールカード
              ProfScreenWidgets.buildProfileCard(
                context,
                isLoading: _isLoading,
                user: _user,
                totalSteps: _totalSteps,
                kirakiraLevel: kirakiraLevel,
              ),

              const Spacer(),

              // 編集項目
              ProfScreenWidgets.buildEditItems(
                context,
                onNameTap: () {
                  if (_user != null) {
                    ProfScreenDialogs.showEditNameDialog(
                      context,
                      _user!,
                      _reloadData,
                    );
                  }
                },
                onHeightTap: () {
                  if (_user != null) {
                    ProfScreenDialogs.showEditHeightDialog(
                      context,
                      _user!,
                      _reloadData,
                    );
                  }
                },
                onWeightTap: () {
                  if (_user != null) {
                    ProfScreenDialogs.showEditWeightDialog(
                      context,
                      _user!,
                      _reloadData,
                    );
                  }
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
