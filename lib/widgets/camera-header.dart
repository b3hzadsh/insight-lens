import 'package:flutter/material.dart';

class CameraHeader extends StatelessWidget {
  // 1. اضافه کردن const به کانستراکتور
  const CameraHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 2. حذف Container اضافی که هیچ کاربردی نداشت
    return SafeArea(
      minimum: const EdgeInsets.only(top: 45), // 3. اضافه کردن const
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // 4. استفاده از کانستراکتور Image.asset برای خوانایی بهتر
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
