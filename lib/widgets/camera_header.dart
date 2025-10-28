import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameraHeader extends StatelessWidget {
  const CameraHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: 45),
      child: ElevatedButton(
        child: Icon(Icons.language),
        onPressed: () {
          context.go('/settings/language');
        },
      ),
    );
  }
}
