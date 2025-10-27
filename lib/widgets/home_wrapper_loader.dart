import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_app/widgets/home.dart';

class HomeWrapperLoader extends StatefulWidget {
  const HomeWrapperLoader({super.key});

  @override
  _HomeWrapperLoaderState createState() => _HomeWrapperLoaderState();
}

class _HomeWrapperLoaderState extends State<HomeWrapperLoader> {
  late Future<CameraDescription> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadItemData();
  }

  Future<CameraDescription> _loadItemData() async {
    await Permission.camera.request();
    // todo may top line is not needed
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    return firstCamera;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CameraDescription>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData) {
          final data = snapshot.data!;
          return Home(camera: data);
        }

        return Scaffold(body: Center(child: Text('Something went wrong')));
      },
    );
  }
}
