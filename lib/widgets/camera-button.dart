import 'package:flutter/material.dart';

class CameraButton extends StatelessWidget {
  const CameraButton({
    Key? key,
    required this.onToggle,
    required this.ripplesAnimationController,
  }) : super(key: key);

  // استفاده از VoidCallback به جای Function برای خوانایی و امنیت تایپ بهتر
  final VoidCallback onToggle;
  final AnimationController ripplesAnimationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      // ارتفاع این کانتینر برای محدود کردن انیمیشن موجی ضروری است
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 1. ویجت انیمیشن موجی (ripples)
          _buildRipples(),

          // 2. دایره بیرونی (border)
          Container(
            height: 80,
            width: 80, // عرض هم اضافه شد تا دایره کامل باشد
            decoration: BoxDecoration(
              border: Border.all(width: 3, color: Colors.white),
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
          ),

          // 3. دایره داخلی قابل کلیک
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(50), // برای افکت کلیک دایره‌ای
            child: Container(
              height: 50,
              width: 50, // عرض هم اضافه شد
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF00FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRipples() {
    return AnimatedBuilder(
      animation: CurvedAnimation(
        parent: ripplesAnimationController,
        curve: Curves.fastOutSlowIn,
      ),
      builder: (context, child) {
        // از آنجایی که Stack در _buildRipples فقط یک فرزند داشت،
        // می‌توانیم آن را حذف کرده و مستقیماً ویجت دایره را برگردانیم.
        final double rippleSize = 150 * ripplesAnimationController.value;
        final double rippleOpacity = 1 - ripplesAnimationController.value;

        return Container(
          width: rippleSize,
          height: rippleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF00FF).withOpacity(rippleOpacity),
          ),
        );
      },
    );
  }
}
