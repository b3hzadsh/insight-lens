import 'package:flutter/material.dart';
import 'package:test_app/services/tensorflow-service.dart'; // مسیر را متناسب با پروژه خود تنظیم کنید

// 1. تبدیل به یک StatelessWidget ساده
class RecognitionWidget extends StatelessWidget {
  // 2. ورودی ویجت، لیستی از نتایج است که از StreamBuilder می‌آید
  final List<Recognition>? results;

  const RecognitionWidget({Key? key, this.results}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF120320)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // عنوان بخش نتایج
            _buildTitleWidget(),
            // محتوای نتایج (لیست پیش‌بینی‌ها)
            Expanded(child: _buildContentWidget(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleWidget() {
    return Container(
      padding: const EdgeInsets.only(top: 15, left: 20, right: 20, bottom: 10),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            "Recognitions",
            style: TextStyle(
              fontSize: 24, // اندازه فونت کمی اصلاح شد
              fontWeight: FontWeight.w300,
              color: Colors.white, // رنگ متن اضافه شد
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget(BuildContext context) {
    // 3. بررسی می‌کند که آیا نتیجه‌ای برای نمایش وجود دارد یا خیر
    if (results == null || results!.isEmpty) {
      return const Center(
        child: Text(
          'Waiting for predictions...',
          style: TextStyle(color: Colors.white, fontSize: 16.0),
        ),
      );
    }

    // اگر نتیجه وجود داشت، لیست را نمایش می‌دهد
    return ListView.builder(
      itemCount: results!.length,
      itemBuilder: (context, index) {
        final recognition = results![index];
        return _buildRecognitionItem(context, recognition);
      },
    );
  }

  Widget _buildRecognitionItem(BuildContext context, Recognition recognition) {
    final double confidencePercentage = recognition.confidence * 100;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: <Widget>[
          // نام لیبل
          Expanded(
            flex: 5, // وزن‌دهی برای تقسیم فضا
            child: Text(
              recognition.label, // 4. دسترسی به داده‌ها با .label
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // نوار پیشرفت (Confidence Bar)
          Expanded(
            flex: 4,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.deepPurpleAccent,
              ),
              value:
                  recognition.confidence, // 4. دسترسی به داده‌ها با .confidence
            ),
          ),
          // درصد اطمینان
          Expanded(
            flex: 2,
            child: Text(
              ' ${confidencePercentage.toStringAsFixed(0)}%',
              textAlign: TextAlign.right, // تراز متن به سمت راست
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
