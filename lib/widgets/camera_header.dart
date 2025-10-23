import 'package:flutter/material.dart';

class CameraHeader extends StatelessWidget {
  const CameraHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: 45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset(
            'assets/white_logo.png',
            height: 40,
            width: 40,
          ),
        ],
      ),
    );
  }
}
