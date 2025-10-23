import 'package:flutter/material.dart';

class CameraButton extends StatelessWidget {
  const CameraButton({
    Key? key,
    required this.onToggle,
    required this.ripplesAnimationController,
  }) : super(key: key);
  final VoidCallback onToggle;
  final AnimationController ripplesAnimationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          _buildRipples(),
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              border: Border.all(width: 3, color: Colors.white),
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
          ),

          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              height: 50,
              width: 50,
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
