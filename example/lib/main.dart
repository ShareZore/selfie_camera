import 'dart:io';

import 'package:flutter/material.dart';
import 'package:selfie_camera/selfie_camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SelfieCamera.initialize(isLog: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? currentFile;

  void _incrementCounter() async {
    File? file = await SelfieCamera.selfieCameraFile(
      context,
      imageResolution: ImageResolution.max,
      defaultCameraType: CameraType.front,
      defaultFlashType: CameraFlashType.off,
    );
    if (file != null) {
      setState(() {
        currentFile = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("selfie"),
      ),
      body: Center(
        child: Container(
          width: double.infinity,
          color: Colors.blueAccent,
          child: currentFile != null
              ? Image.file(
                  currentFile!,
                  fit: BoxFit.fitWidth,
                )
              : null,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
