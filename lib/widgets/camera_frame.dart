import 'package:flutter/material.dart';

class CameraFrame extends StatelessWidget {
  const CameraFrame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var focusLineWidth = 2.0;
    return Padding(
      padding: EdgeInsets.only(bottom: 250),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 250 - 100,
          width: MediaQuery.of(context).size.width - 40,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                      left: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                      right: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                      right: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                      left: BorderSide(
                          color: Colors.white, width: focusLineWidth),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
