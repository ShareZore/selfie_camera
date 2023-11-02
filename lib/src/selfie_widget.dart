import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_editor/image_editor.dart';
import 'package:selfie_camera/selfie_camera.dart';
import 'logger.dart';
import 'result_widget.dart';

typedef FlashControlBuilder = Widget Function(
    BuildContext context, CameraFlashType mode);

class SelfieWidget extends StatefulWidget {
  final ImageResolution imageResolution;
  final CameraType defaultCameraType;
  final CameraFlashType defaultFlashType;
  final CameraOrientation? orientation;
  final bool showControls;
  final bool showCaptureControl;
  final bool showFlashControl;
  final bool showCameraTypeControl;
  final bool showCloseControl;
  final void Function(File? image)? onCapture;
  final Widget? captureControlIcon;
  final Widget? typeControlIcon;
  final FlashControlBuilder? flashControlBuilder;
  final Widget? closeControlIcon;

  const SelfieWidget({
    super.key,
    this.imageResolution = ImageResolution.medium,
    this.defaultCameraType = CameraType.front,
    this.showControls = true,
    this.showCaptureControl = true,
    this.showFlashControl = true,
    this.showCameraTypeControl = true,
    this.showCloseControl = true,
    this.defaultFlashType = CameraFlashType.off,
    this.orientation = CameraOrientation.portraitUp,
    this.onCapture,
    this.captureControlIcon,
    this.typeControlIcon,
    this.flashControlBuilder,
    this.closeControlIcon,
  });

  @override
  State<SelfieWidget> createState() => _SelfieWidgetState();
}

class _SelfieWidgetState extends State<SelfieWidget>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  bool isAppInBackground = false;

  CameraController? _controller;

  int _currentFlashMode = 0;
  final List<CameraFlashType> _availableFlashMode = [
    CameraFlashType.off,
    CameraFlashType.auto,
    CameraFlashType.always,
  ];

  int _currentCameraType = 0;
  final List<CameraType> _availableCameraType = [];

  void _getAllAvailableCameraType() {
    for (CameraDescription d in SelfieCamera.cameras) {
      final type = d.lensDirection.cameraType;
      if (type != null && !_availableCameraType.contains(type)) {
        _availableCameraType.add(type);
      }
    }
    try {
      _currentCameraType =
          _availableCameraType.indexOf(widget.defaultCameraType);
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<void> _initCamera() async {
    final cameras = SelfieCamera.cameras
        .where(
          (c) =>
              c.lensDirection ==
              _availableCameraType[_currentCameraType].cameraLensDirection,
        )
        .toList();

    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.first,
        widget.imageResolution.resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
        // imageFormatGroup: Platform.isAndroid
        //     ? ImageFormatGroup.nv21
        //     : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });

      await _changeFlashMode(
          _availableFlashMode.indexOf(widget.defaultFlashType));

      await _controller!
          .lockCaptureOrientation(
        widget.orientation?.deviceOrientation,
      )
          .then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _changeFlashMode(int index) async {
    await _controller!
        .setFlashMode(
      _availableFlashMode[index].flashMode,
    )
        .then((_) {
      if (mounted) setState(() => _currentFlashMode = index);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _getAllAvailableCameraType();
    _initCamera();
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final CameraController? cameraController = _controller;
    if (cameraController != null && cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      setState(() {
        isAppInBackground = true;
      });
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
      setState(() {
        isAppInBackground = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? cameraController = _controller;

    // 设备尺寸
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: isAppInBackground
          ? Container(
              color: Colors.black,
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                if (cameraController != null &&
                    cameraController.value.isInitialized) ...[
                  Transform.scale(
                    scale: 1.0,
                    child: AspectRatio(
                      aspectRatio: size.aspectRatio,
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: SizedBox(
                            width: size.width,
                            height:
                                size.width * cameraController.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                _cameraDisplayWidget(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ] else ...[
                  Container(
                    color: Colors.black,
                  ),
                ],
                if (widget.showControls) ...[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showFlashControl) ...[
                              _flashControlWidget()
                            ],
                            if (widget.showCaptureControl) ...[
                              const SizedBox(width: 20),
                              _captureControlWidget(),
                              const SizedBox(width: 20)
                            ],
                            if (widget.showCameraTypeControl) ...[
                              _typeControlWidget()
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                ],
                if (widget.showControls)
                  Align(
                    alignment: Alignment.topLeft,
                    child: _clearWidget(),
                  )
              ],
            ),
    );
  }

  Widget _cameraDisplayWidget() {
    final CameraController? cameraController = _controller;
    if (cameraController != null && cameraController.value.isInitialized) {
      return CameraPreview(cameraController);
    }
    return const SizedBox.shrink();
  }

  Widget _captureControlWidget() {
    final CameraController? cameraController = _controller;

    return InkWell(
      onTap: cameraController != null && cameraController.value.isInitialized
          ? _onTakePictureButtonPressed
          : null,
      child: Container(
        color: Colors.transparent,
        width: 80,
        height: 80,
        child: widget.captureControlIcon ??
            ClipOval(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8.0),
                child: const Icon(
                  Icons.camera_alt,
                ),
              ),
            ),
      ),
    );
  }

  Widget _flashControlWidget() {
    final CameraController? cameraController = _controller;
    final icon =
        _availableFlashMode[_currentFlashMode] == CameraFlashType.always
            ? Icons.flash_on
            : _availableFlashMode[_currentFlashMode] == CameraFlashType.off
                ? Icons.flash_off
                : Icons.flash_auto;

    return InkWell(
      onTap: cameraController != null && cameraController.value.isInitialized
          ? () => _changeFlashMode(
              (_currentFlashMode + 1) % _availableFlashMode.length)
          : null,
      child: Container(
        color: Colors.transparent,
        width: 60,
        height: 60,
        child: widget.flashControlBuilder
                ?.call(context, _availableFlashMode[_currentFlashMode]) ??
            ClipOval(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
            ),
      ),
    );
  }

  Widget _typeControlWidget() {
    final CameraController? cameraController = _controller;
    return InkWell(
      onTap: cameraController != null && cameraController.value.isInitialized
          ? () {
              _currentCameraType =
                  (_currentCameraType + 1) % _availableCameraType.length;
              _initCamera();
            }
          : null,
      child: Container(
        color: Colors.transparent,
        width: 60,
        height: 60,
        child: widget.typeControlIcon ??
            ClipOval(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(
                    Icons.cameraswitch_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _clearWidget() {
    return IconButton(
      iconSize: 30,
      icon: widget.closeControlIcon ??
          CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.05),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.clear,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void _onTakePictureButtonPressed() async {
    final CameraController? cameraController = _controller;
    try {
      if (cameraController!.value.isStreamingImages) {
        await cameraController.stopImageStream();
      }
      await Future.delayed(const Duration(milliseconds: 500));
      takePicture().then((XFile? file) async {
        if (file != null) {
          var result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                      ResultWidget(file: File(file.path))));
          if (result != null && widget.onCapture != null) {
            widget.onCapture!(File(file.path));
          }
        }
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      logError('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      String path = file.path;
      Uint8List? bytes = await file.readAsBytes();
      if (cameraController.description.lensDirection ==
          CameraLensDirection.front) {
        ImageEditorOption option = ImageEditorOption();
        option.addOption(const FlipOption(horizontal: true));
        bytes = await ImageEditor.editImage(
            image: bytes, imageEditorOption: option);
        await File(path).delete();
        File(path).writeAsBytesSync(bytes!);
      }
      return file;
    } on CameraException catch (e) {
      logError(e.code, e.description);
      return null;
    }
  }
}
