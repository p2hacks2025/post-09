import 'package:flutter/material.dart';
import '../base/base_layout.dart';

// シンボル画面
class SymbolScreen extends StatelessWidget {
  const SymbolScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      title: 'シンボル',
      showBackButton: true,
      child: Center(
        child: Text(
          'シンボル画面',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
