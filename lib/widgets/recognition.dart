import 'package:flutter/material.dart';
import 'package:test_app/recognition_isolate.dart';

class RecognitionWidget extends StatelessWidget {
  final List<Recognition> results;
  const RecognitionWidget({Key? key, required this.results}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        color: Colors.black54,
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: results.isEmpty
              ? [
                  Text(
                    'No results',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ]
              : results
                    .asMap()
                    .entries
                    .map(
                      (entry) => Text(
                        '${entry.key + 1}. ${entry.value.label}: ${(entry.value.confidence * 100).toStringAsFixed(2)}%',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                    .toList(),
        ),
      ),
    );
  }
}
